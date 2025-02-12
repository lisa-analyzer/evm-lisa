package it.unipr.crossChainAnalysis;

import it.unipr.EVMLiSA;
import it.unipr.analysis.*;
import it.unipr.analysis.taint.UncheckedStateUpdateAbstractDomain;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.ProgramCounterLocation;
import it.unipr.checker.CallDataLoadChecker;
import it.unipr.checker.JumpSolver;
import it.unipr.checker.ReentrancyChecker;
import it.unipr.checker.UncheckedStateUpdateChecker;
import it.unipr.frontend.EVMFeatures;
import it.unipr.frontend.EVMFrontend;
import it.unipr.frontend.EVMTypeSystem;
import it.unipr.utils.EthereumUtils;
import it.unipr.utils.MyCache;
import it.unive.lisa.LiSA;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.conf.LiSAConfiguration;
import it.unive.lisa.interprocedural.ModularWorstCaseAnalysis;
import it.unive.lisa.interprocedural.callgraph.RTACallGraph;
import it.unive.lisa.program.ClassUnit;
import it.unive.lisa.program.Program;
import it.unive.lisa.program.cfg.CodeMemberDescriptor;
import it.unive.lisa.program.cfg.edge.Edge;
import it.unive.lisa.program.cfg.edge.SequentialEdge;
import it.unive.lisa.program.cfg.statement.Statement;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;
import java.util.concurrent.*;
import org.apache.commons.io.FilenameUtils;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class CrossChainAnalysis {
	private static final Logger log = LogManager.getLogger(CrossChainAnalysis.class);

	private final Path _abiFolder;
	private final Path _bytecodeFolder;
	private final Bridge _bridge;
	private EVMCFG _xCFG;
	private Set<Edge> _crossChainEdges;
	private final ExecutorService _executor;

	public CrossChainAnalysis(Path abi, Path bytecode) {
		this._abiFolder = abi;
		this._bytecodeFolder = bytecode;
		this._bridge = new Bridge(abi, bytecode);
		this._xCFG = null;
		this._crossChainEdges = new HashSet<>();

		int _cores = Runtime.getRuntime().availableProcessors() - 1;
		this._executor = Executors.newFixedThreadPool(_cores > 0 ? _cores : 1);
	}

	/**
	 * Runs the cross-chain smart contract analysis. Starts the analysis, builds
	 * the partial cross-chain CFG (xCFG), and adds cross-chain edges.
	 */
	public void run() {
		try {
			startAnalysis();
		} catch (InterruptedException e) {
			log.error("Thread pool interrupted during single analysis: {}", e.getMessage());
		}

		_bridge.computeFunctionsAndEvents();

		_xCFG = buildPartialXCFG();

//		_crossChainEdges = getCrossChainEdgesUsingEventsEntrypoint(); // SmartAxe solution
		_crossChainEdges = getCrossChainEdgesUsingEventsAndFunctionsEntrypoint();

		// Add edges to xCFG
		for (Edge edge : _crossChainEdges)
			_xCFG.addEdge(edge);

		log.debug("Final xCFG");
		printInfo(_xCFG);

		runCheckers();

		shutdownExecutor();
	}

	/**
	 * Executes all security checkers in parallel on the smart contracts in the
	 * bridge.
	 */
	public void runCheckers() {
		List<Future<?>> futures = new ArrayList<>();

		for (SmartContract contract : _bridge) {
			futures.add(_executor.submit(() -> runReentrancyChecker(contract)));
			futures.add(_executor.submit(() -> runEventOrderChecker(contract)));
			futures.add(_executor.submit(() -> runUncheckedStateUpdateChecker(contract)));
//			futures.add(_executor.submit(() -> runCallDataLoadChecker(contract))); // debug
		}

		try {
			waitForCompletion(futures);
		} catch (InterruptedException e) {
			log.error("Thread pool interrupted: {}", e.getMessage());
		}

		log.warn("Vulnerabilities");
		for (SmartContract contract : _bridge) {
			log.info("Contract {} analyzed", contract.getName());

			if (MyCache.getInstance().getReentrancyWarnings(contract.getCFG().hashCode()) > 0)
				log.warn("{} reentrancy warning",
						MyCache.getInstance().getReentrancyWarnings(contract.getCFG().hashCode()));

			if (MyCache.getInstance().getEventOrderWarnings(contract.getCFG().hashCode()) > 0)
				log.warn("{} event order warning",
						MyCache.getInstance().getEventOrderWarnings(contract.getCFG().hashCode()));

			if (MyCache.getInstance().getUncheckedStateUpdateWarnings(contract.getCFG().hashCode()) > 0)
				log.warn("{} unchecked state update warning",
						MyCache.getInstance().getUncheckedStateUpdateWarnings(contract.getCFG().hashCode()));
		}
	}

	// Debug
	private void runCallDataLoadChecker(SmartContract contract) {
		// Setup configuration
		Program program = new Program(new EVMFeatures(), new EVMTypeSystem());
		program.addCodeMember(contract.getCFG());
		LiSAConfiguration conf = createConfiguration(contract);
		LiSA lisa = new LiSA(conf);

		CallDataLoadChecker checker = new CallDataLoadChecker();
		conf.semanticChecks.add(checker);
		lisa.run(program);
	}

	/**
	 * Runs the unchecked state update checker on the given smart contract.
	 *
	 * @param contract The smart contract to analyze.
	 */
	private void runUncheckedStateUpdateChecker(SmartContract contract) {
		// Setup configuration
		Program program = new Program(new EVMFeatures(), new EVMTypeSystem());
		program.addCodeMember(contract.getCFG());
		LiSAConfiguration conf = createConfiguration(contract);
		LiSA lisa = new LiSA(conf);

		// Unchecked state update checker
		UncheckedStateUpdateChecker checker = new UncheckedStateUpdateChecker();
		conf.semanticChecks.add(checker);
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new UncheckedStateUpdateAbstractDomain(),
				new TypeEnvironment<>(new InferredTypes()));
		lisa.run(program);
	}

	/**
	 * Runs the reentrancy checker on the given smart contract.
	 *
	 * @param contract The smart contract to analyze.
	 */
	private void runReentrancyChecker(SmartContract contract) {
		// Setup configuration
		Program program = new Program(new EVMFeatures(), new EVMTypeSystem());
		program.addCodeMember(contract.getCFG());
		LiSAConfiguration conf = createConfiguration(contract);
		LiSA lisa = new LiSA(conf);

		// Reentrancy checker
		ReentrancyChecker checker = new ReentrancyChecker();
		conf.semanticChecks.add(checker);
		lisa.run(program);
	}

	/**
	 * Runs the event order checker on the given smart contract. This method
	 * verifies whether events are emitted before state modifications (SSTORE
	 * instructions). It identifies vulnerabilities where an event is emitted
	 * without prior state changes, potentially leading to inconsistencies.
	 *
	 * @param contract The smart contract to analyze.
	 */
	private void runEventOrderChecker(SmartContract contract) {
		Set<Statement> functionsEntrypoints = new HashSet<>();

		for (Signature function : contract.getFunctionsSignature())
			functionsEntrypoints.addAll(function.getEntrypoints());

		EVMCFG cfg = contract.getCFG();
		Set<Statement> sstoreSet = cfg.getAllSstore();
		Set<Statement> logSet = cfg.getAllLogX();

		log.debug("Contract: {}", contract.getName());
		log.debug("Functions: {}", contract.getFunctionsSignature().size());
		log.debug("Functions entry points: {}", functionsEntrypoints.size());
		log.debug("Sstore set: {}", sstoreSet.size());
		log.debug("Log set: {}", logSet.size());

		for (Statement functionEntrypoint : functionsEntrypoints) {
			for (Statement emitEvent : logSet) {
				if (cfg.reachableFrom(functionEntrypoint, emitEvent)) {
					if (!cfg.reachableFromCrossing(functionEntrypoint, emitEvent, sstoreSet)) {

						ProgramCounterLocation functionEntrypointLocation = (ProgramCounterLocation) functionEntrypoint
								.getLocation();
						ProgramCounterLocation emitEventLocation = (ProgramCounterLocation) emitEvent.getLocation();

						String warn = "Event Order vulnerability at " + emitEventLocation.getPc();

						log.warn("Event Order vulnerability at {} at line no. {} coming from line {}",
								emitEventLocation.getPc(),
								emitEventLocation.getSourceCodeLine(), functionEntrypointLocation.getSourceCodeLine());

						MyCache.getInstance().addEventOrderWarning(cfg.hashCode(), warn);
					}
				}
			}
		}
	}

	/**
	 * Shuts down the executor service and waits for tasks to complete.
	 */
	private void shutdownExecutor() {
		_executor.shutdown();
		try {
			if (!_executor.awaitTermination(1, TimeUnit.HOURS)) {
				log.error("Timeout reached while waiting for thread pool to terminate.");
				_executor.shutdownNow();
			}
		} catch (InterruptedException e) {
			log.error("Executor shutdown interrupted: {}", e.getMessage());
			_executor.shutdownNow();
		}
	}

	private Set<Edge> addEdges(Set<Statement> sources, Set<Statement> targets) {
		Set<Edge> edges = new HashSet<>();

		for (Statement source : sources)
			for (Statement target : targets)
				edges.add(new SequentialEdge(source, target));

		return edges;
	}

	/**
	 * Gets cross-chain edges by linking events entry points to function entry
	 * points in different contracts.
	 *
	 * @return A list of added cross-chain edges.
	 */
	private Set<Edge> getCrossChainEdgesUsingEventsAndFunctionsEntrypoint() {
		Set<Edge> crossChainEdges = new HashSet<>();
		Set<Signature> eventsWithoutMatch = new HashSet<>();
		Set<Signature> functionsWithoutMatch = new HashSet<>();

		log.info("Functions count: {}", _bridge.getFunctions().size());
		log.info("Events count: {}", _bridge.getEvents().size());

		boolean match = false;
		int matchCounter = 0;

		for (Signature event : _bridge.getEvents()) {
			match = false;
			for (Signature function : _bridge.getFunctions()) {
				if (event.getName().equalsIgnoreCase(function.getName())) {
					match = true;
//					log.debug("Perfect match! Event: {}/{}, Function: {}/{}", event.getName(), event.getParamCount(), function.getName(), function.getParamCount());
					crossChainEdges.addAll(addEdges(event.getEntrypoints(), function.getEntrypoints()));
				}
			}

			if (!match) {
				// We link this event to all functions entry points
				for (Signature function : _bridge.getFunctions())
					crossChainEdges.addAll(addEdges(event.getEntrypoints(), function.getEntrypoints()));

				eventsWithoutMatch.add(event);
				log.warn("No match! Event {}/{} (0x{}) linked to {} functions", event.getName(), event.getParamCount(),
						event.getSelector(), _bridge.getFunctions().size());
			} else
				++matchCounter;
		}

		debugPrint(eventsWithoutMatch, functionsWithoutMatch);

		log.info("Perfect match on {}/{} events", matchCounter, _bridge.getEvents().size());
		log.info("Conservative match on {}/{} events", eventsWithoutMatch.size(), _bridge.getEvents().size());
		log.debug("Added {} cross chain edges using events and functions entrypoint", crossChainEdges.size());

		return crossChainEdges;
	}

	/**
	 * Gets cross-chain edges by linking LOG statements to function entry points
	 * in different contracts.
	 *
	 * @return A list of added cross-chain edges.
	 */
	private Set<Edge> getCrossChainEdgesUsingFunctionsEntrypoint() {
		Set<Edge> crossChainEdges = new HashSet<>();

		for (SmartContract contract : _bridge)
			for (Signature signature : contract.getFunctionsSignature())
				crossChainEdges.addAll(addEdges(_xCFG.getAllLogX(), signature.getEntrypoints()));

		log.debug("Added {} cross chain edges using functions entrypoint", crossChainEdges.size());
		return crossChainEdges;
	}

	/**
	 * Gets cross-chain edges by linking emitting blocks to information blocks
	 * in different contracts.
	 *
	 * @return A list of added cross-chain edges.
	 */
	private Set<Edge> getCrossChainEdgesUsingEventsEntrypoint() {
		Set<Edge> crossChainEdges = new HashSet<>();

		Set<Statement> emittingBlocks = new HashSet<>();
		Set<Statement> informationBlocks = new HashSet<>();

		for (SmartContract contract : _bridge) {
			for (Signature signature : contract.getEmittingBlocksSignature())
				emittingBlocks.addAll(signature.getEntrypoints());

			for (Signature signature : contract.getInformationBlocksSignature())
				informationBlocks.addAll(signature.getEntrypoints());
		}

		crossChainEdges.addAll(addEdges(emittingBlocks, informationBlocks));

		log.debug("Added {} cross chain edges using events entrypoint", crossChainEdges.size());
		return crossChainEdges;
	}

	/**
	 * Builds the partial cross-chain control flow graph (xCFG) by merging
	 * individual smart contract CFGs into a unified representation.
	 *
	 * @return The constructed xCFG.
	 */
	private EVMCFG buildPartialXCFG() {
		log.info("Building partial xCFG");

		String filePath = _bytecodeFolder.toString();
		ClassUnit unit = new ClassUnit(new ProgramCounterLocation(-1, -1), null, "program", false);
		String normalizedFilePath = FilenameUtils.separatorsToUnix(filePath);
		CodeMemberDescriptor cfgDesc = new CodeMemberDescriptor(new ProgramCounterLocation(-1, -1), unit, false,
				normalizedFilePath);

		EVMCFG xCFG = new EVMCFG(cfgDesc);

		log.debug("xCFG generated");
		printInfo(xCFG);

		for (SmartContract contract : _bridge) {
			for (Statement n : contract.getCFG().getNodes())
				xCFG.addNode(n);

			for (Edge e : contract.getCFG().getEdges())
				xCFG.addEdge(e);

			for (Statement log : contract.getCFG().getAllLogX())
				xCFG.getAllLogX().add(log);

			for (Statement entry : contract.getCFG().getEntrypoints())
				xCFG.getEntrypoints().add(entry);

			log.debug("xCFG updated adding {}", contract.getName());
			printInfo(xCFG);
		}

		return xCFG;
	}

	/**
	 * Creates a LiSA configuration for analyzing the given smart contract.
	 *
	 * @param contract The smart contract to be analyzed.
	 * 
	 * @return A configured instance of {@link LiSAConfiguration}.
	 */
	private LiSAConfiguration createConfiguration(SmartContract contract) {
		String address = EthereumUtils.isValidEVMAddress(contract.getName()) ? contract.getName() : null;

		LiSAConfiguration conf = new LiSAConfiguration();
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(),
				new EVMAbstractState(address),
				new TypeEnvironment<>(new InferredTypes()));
		conf.workdir = contract.getBytecodePath().toString();
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		conf.callGraph = new RTACallGraph();
		conf.serializeResults = false;
		conf.optimize = false;
		conf.useWideningPoints = false;

		return conf;
	}

	/**
	 * Starts the analysis of smart contracts in parallel using a thread pool.
	 * It submits each contract analysis task to the executor and waits for all
	 * tasks to complete before proceeding.
	 *
	 * @throws InterruptedException If the execution is interrupted while
	 *                                  waiting for tasks to complete.
	 */
	private void startAnalysis() throws InterruptedException {
		log.info("Starting analysis");

		// Setup options
		EVMFrontend.setUseCreationCode();
		AbstractStack.setStackLimit(32);
		AbstractStackSet.setStackSetSize(16);
		JumpSolver.setLinkUnsoundJumpsToAllJumpdest();

		List<Future<?>> futures = new ArrayList<>();

		for (SmartContract contract : _bridge) {
			Future<?> future = _executor.submit(() -> analyzeContract(contract));
			futures.add(future);
		}

		// Wait for all the analyses to be completed
		waitForCompletion(futures);

		log.info("Finished analysis");
	}

	/**
	 * Waits for all submitted tasks in the given list of futures to complete.
	 *
	 * @param futures A list of {@link Future} objects representing running
	 *                    tasks.
	 * 
	 * @throws InterruptedException If the thread is interrupted while waiting.
	 */
	private void waitForCompletion(List<Future<?>> futures) throws InterruptedException {
		for (Future<?> future : futures)
			try {
				future.get();
			} catch (ExecutionException e) {
				log.error("Error during task execution: {}", e.getMessage());
			}
	}

	/**
	 * Performs the analysis of a single smart contract.
	 *
	 * @param contract The smart contract to analyze.
	 */
	public void analyzeContract(SmartContract contract) {
		try {
			log.info("[{}] Analyzing contract: {}", Thread.currentThread().getName(), contract.getName());

			String bytecodeFullPath = contract.getBytecodePath().toString();
			String bytecode = new String(Files.readAllBytes(Paths.get(bytecodeFullPath)));

			if (bytecode.startsWith("0x"))
				EVMFrontend.opcodesFromBytecode(bytecode, bytecodeFullPath);

			Program program = EVMFrontend.generateCfgFromFile(bytecodeFullPath);
			LiSAConfiguration conf = createConfiguration(contract);
			JumpSolver checker = new JumpSolver();
			conf.semanticChecks.add(checker);

			LiSA lisa = new LiSA(conf);
			lisa.run(program);

			contract.setCFG(checker.getComputedCFG());
			contract.computeFunctionsSignatureEntrypoints();
			contract.computeEventsSignatureEntrypoints();
			contract.computeKnowledgeBlocks();

			log.debug("Computing events knowledge of {}", contract.getName());
			for (Signature event : contract.getEventsSignature()) {
				log.debug("{}: {}", event.getName(), EventKnowledge.getKnowledge(event.getName()));
			}

			// Check soundness
			if (!Objects
					.requireNonNull(
							EVMLiSA.dumpStatistics(checker, EVMLiSA.getSoundlySolvedJumps(checker, lisa, program)))
					.isSound()) {
				log.warn("UNSOUND on {}", contract.getName());
			}

		} catch (NullPointerException npe) {
			log.error("Error checking soundness in bytecode {}: {}", contract.getName(), npe.getMessage());
		} catch (Exception e) {
			log.error("Error processing contract {}: {}", contract.getName(), e.getMessage());
		}
	}

	private void printInfo(EVMCFG xCFG) {
		log.info("Nodes count: {}", xCFG.getNodesCount());
		log.info("Edge count: {}", xCFG.getEdgesCount());
		log.info("Opcode count: {}", xCFG.getOpcodeCount());
		log.info("xCFG entrypoints: {}", xCFG.getEntrypoints());
		log.info("xCFG LOGx opcodes: {}", xCFG.getAllLogX().size());
	}

	private void debugPrint(Set<Signature> eventsWithoutMatch, Set<Signature> functionsWithoutMatch) {
		boolean match = false;

		for (Signature function : _bridge.getFunctions()) {
			match = false;
			for (Signature event : _bridge.getEvents())
				if (event.getName().equalsIgnoreCase(function.getName())) {
					match = true;
					break;
				}
			if (!match)
				functionsWithoutMatch.add(function);
		}

		log.info("Events without match:");
		for (Signature event : new HashSet<>(eventsWithoutMatch))
			log.debug("Event: {}/{} -> {}", event.getName(), event.getParamCount(), event.getSelector());

		log.info("Functions without match:");
		for (Signature function : new HashSet<>(functionsWithoutMatch))
			log.debug("Function: {}/{} -> {}", function.getName(), function.getParamCount(), function.getSelector());

	}
}
