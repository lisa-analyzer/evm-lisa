package it.unipr.crossChainAnalysis;

import it.unipr.EVMLiSA;
import it.unipr.analysis.*;
import it.unipr.analysis.taint.TimestampDependencyAbstractDomain;
import it.unipr.analysis.taint.TxOriginAbstractDomain;
import it.unipr.analysis.taint.UncheckedExternalInfluenceAbstractDomain;
import it.unipr.analysis.taint.UncheckedStateUpdateAbstractDomain;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.ProgramCounterLocation;
import it.unipr.checker.*;
import it.unipr.crossChainAnalysis.edges.ConservativeCrossChainEdge;
import it.unipr.crossChainAnalysis.edges.CrossChainEdge;
import it.unipr.frontend.EVMFeatures;
import it.unipr.frontend.EVMFrontend;
import it.unipr.frontend.EVMTypeSystem;
import it.unipr.utils.LiSAConfigurationManager;
import it.unipr.utils.MyCache;
import it.unive.lisa.LiSA;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.conf.LiSAConfiguration;
import it.unive.lisa.program.ClassUnit;
import it.unive.lisa.program.Program;
import it.unive.lisa.program.cfg.CodeMemberDescriptor;
import it.unive.lisa.program.cfg.edge.Edge;
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
	private boolean CONSERVATIVE_LINK = false;

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
		CONSERVATIVE_LINK = false;
		_crossChainEdges = getCrossChainEdgesUsingEventsAndFunctionsEntrypoint();

		// Add edges to xCFG
		for (Edge edge : _crossChainEdges)
			_xCFG.addEdge(edge);

		log.info("Final xCFG");
		printInfo(_xCFG);

		_bridge.printVulnerabilities();

		shutdownExecutor();
	}

	/**
	 * Runs a series of intra-chain security checkers on a given smart contract.
	 * Each checker is executed asynchronously using the thread pool.
	 *
	 * @param contract The smart contract to analyze.
	 */
	private void runIntraChainCheckersPerContract(SmartContract contract) {
		log.info("Running checkers for contract: {}", contract.getName());
		_executor.submit(() -> runReentrancyChecker(contract));
		_executor.submit(() -> runEventOrderChecker(contract));
		_executor.submit(() -> runUncheckedStateUpdateChecker(contract));
		_executor.submit(() -> runUncheckedExternalInfluenceChecker(contract));
		_executor.submit(() -> runTxOriginChecker(contract));
		_executor.submit(() -> runTimestampDependencyChecker(contract));
	}

	/**
	 * Executes all security checkers in parallel on the smart contracts in the
	 * bridge.
	 */
	public void runCheckers() {
		log.info("Running checkers");

		List<Future<?>> futures = new ArrayList<>();

		for (SmartContract contract : _bridge) {
			futures.add(_executor.submit(() -> runReentrancyChecker(contract)));
			futures.add(_executor.submit(() -> runEventOrderChecker(contract)));
			futures.add(_executor.submit(() -> runUncheckedStateUpdateChecker(contract)));
			futures.add(_executor.submit(() -> runUncheckedExternalInfluenceChecker(contract)));
			futures.add(_executor.submit(() -> runTxOriginChecker(contract)));
			futures.add(_executor.submit(() -> runTimestampDependencyChecker(contract)));
		}

		try {
			waitForCompletion(futures);
		} catch (InterruptedException e) {
			log.error("Thread pool interrupted: {}", e.getMessage());
		}
	}

	/**
	 * Runs the timestamp dependency checker on the given smart contract.
	 *
	 * @param contract The smart contract to analyze.
	 */
	private void runTimestampDependencyChecker(SmartContract contract) {
		// Setup configuration
		Program program = new Program(new EVMFeatures(), new EVMTypeSystem());
		program.addCodeMember(contract.getCFG());
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
		LiSA lisa = new LiSA(conf);

		// Timestamp dependency checker
		TimestampDependencyChecker checker = new TimestampDependencyChecker();
		conf.semanticChecks.add(checker);
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(),
				new TimestampDependencyAbstractDomain(),
				new TypeEnvironment<>(new InferredTypes()));
		lisa.run(program);
	}

	/**
	 * Runs the tx. origin checker on the given smart contract.
	 *
	 * @param contract The smart contract to analyze.
	 */
	private void runTxOriginChecker(SmartContract contract) {
		// Setup configuration
		Program program = new Program(new EVMFeatures(), new EVMTypeSystem());
		program.addCodeMember(contract.getCFG());
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
		LiSA lisa = new LiSA(conf);

		// Tx. Origin checker
		TxOriginChecker checker = new TxOriginChecker();
		conf.semanticChecks.add(checker);
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(),
				new TxOriginAbstractDomain(),
				new TypeEnvironment<>(new InferredTypes()));
		lisa.run(program);
	}

	/**
	 * Runs the unchecked state update checker on the given smart contract.
	 *
	 * @param contract The smart contract to analyze.
	 */
	private void runUncheckedExternalInfluenceChecker(SmartContract contract) {
		// Setup configuration
		Program program = new Program(new EVMFeatures(), new EVMTypeSystem());
		program.addCodeMember(contract.getCFG());
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
		LiSA lisa = new LiSA(conf);

		// Unchecked external influence checker
		UncheckedExternalInfluenceChecker checker = new UncheckedExternalInfluenceChecker();
		conf.semanticChecks.add(checker);
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(),
				new UncheckedExternalInfluenceAbstractDomain(),
				new TypeEnvironment<>(new InferredTypes()));
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
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
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
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
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
			functionsEntrypoints.addAll(function.getEntryPoints());

		EVMCFG cfg = contract.getCFG();
		Set<Statement> sstoreSet = cfg.getAllSstore();
		Set<Statement> logSet = cfg.getAllLogX();

//		log.debug("Contract: {}", contract.getName());
//		log.debug("Functions: {}", contract.getFunctionsSignature().size());
//		log.debug("Functions entry points: {}", functionsEntrypoints.size());
//		log.debug("Sstore set: {}", sstoreSet.size());
//		log.debug("Log set: {}", logSet.size());

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
	 * Creates cross-chain edges between a set of source statements and a set of
	 * target statements.
	 *
	 * @param sources The set of source statements.
	 * @param targets The set of target statements.
	 * 
	 * @return A set of cross-chain edges connecting the given sources to the
	 *             targets.
	 */
	private Set<Edge> addCrossChainEdges(Set<Statement> sources, Set<Statement> targets) {
		Set<Edge> edges = new HashSet<>();

		for (Statement source : sources)
			for (Statement target : targets)
				edges.add(new CrossChainEdge(source, target));

		return edges;
	}

	/**
	 * Creates conservative cross-chain edges between a set of source statements
	 * and a set of target statements.
	 *
	 * @param sources The set of source statements.
	 * @param targets The set of target statements.
	 * 
	 * @return A set of conservative cross-chain edges connecting the given
	 *             sources to the targets.
	 */
	private Set<Edge> addConservativeCrossChainEdges(Set<Statement> sources, Set<Statement> targets) {
		Set<Edge> edges = new HashSet<>();

		for (Statement source : sources)
			for (Statement target : targets)
				edges.add(new ConservativeCrossChainEdge(source, target));

		return edges;
	}

	/**
	 * Gets cross-chain edges by linking events exit points to function entry
	 * points in different contracts.
	 *
	 * @return A list of added cross-chain edges.
	 */
	private Set<Edge> getCrossChainEdgesUsingEventsAndFunctionsEntrypoint() {
		Set<Edge> crossChainEdges = new HashSet<>();

		log.info("Computing cross chain edges");
		log.info("Functions count: {}", _bridge.getFunctions().size());
		log.info("Events count: {}", _bridge.getEvents().size());
		log.info("Log count: {}", _xCFG.getAllLogX().size());

		boolean match = false;

		for (Statement logStatement : _xCFG.getAllLogX()) {

			Set<String> selectorsInLOG = MyCache.getInstance().getEventExitPoints(logStatement);
			match = false;

			if (selectorsInLOG.isEmpty())
				continue;

			for (String selector : selectorsInLOG) {
				for (Signature event : _bridge.getEvents()) {
					if (selector.equals(event.getSelector())) {
						for (Signature function : _bridge.getFunctions()) {
							if (event.getName().equalsIgnoreCase(function.getName())) {
								match = true;
								crossChainEdges.addAll(
										addCrossChainEdges(event.getEntryPoints(), function.getEntryPoints()));
								log.debug(
										"Perfect match! Event: {}/{} from LOG source-code line: {}, to Function: {}/{}",
										event.getName(), event.getParamCount(),
										((ProgramCounterLocation) logStatement.getLocation()).getSourceCodeLine(),
										function.getName(), function.getParamCount());
							}
						}
					}
				}
			}

			if (!match && CONSERVATIVE_LINK) {
				// We link this event to all functions entry points
				for (Signature function : _bridge.getFunctions())
					crossChainEdges.addAll(addConservativeCrossChainEdges(Collections.singleton(logStatement),
							function.getEntryPoints()));

				log.warn("No match! LOG at source-code line {} conservative linked to {} functions",
						((ProgramCounterLocation) logStatement.getLocation()).getSourceCodeLine(),
						_bridge.getFunctions().size());
			}
		}

		log.debug("Added {} cross chain edges using events exit points and functions entry points",
				crossChainEdges.size());
		log.info("Cross chain edges computed");

		return crossChainEdges;
	}

	// Old version
	private Set<Edge> getCrossChainEdgesUsingEventsAndFunctionsEntrypointOld() {
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
					crossChainEdges.addAll(addCrossChainEdges(event.getEntryPoints(), function.getEntryPoints()));
				}
			}

			if (!match) {
				// We link this event to all functions entry points
				for (Signature function : _bridge.getFunctions())
					crossChainEdges.addAll(addCrossChainEdges(event.getEntryPoints(), function.getEntryPoints()));

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
				crossChainEdges.addAll(addConservativeCrossChainEdges(_xCFG.getAllLogX(), signature.getEntryPoints()));

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
				emittingBlocks.addAll(signature.getEntryPoints());

			for (Signature signature : contract.getInformationBlocksSignature())
				informationBlocks.addAll(signature.getEntryPoints());
		}

		crossChainEdges.addAll(addCrossChainEdges(emittingBlocks, informationBlocks));

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

		for (SmartContract contract : _bridge) {
			for (Statement n : contract.getCFG().getNodes())
				xCFG.addNode(n);

			for (Edge e : contract.getCFG().getEdges())
				xCFG.addEdge(e);

			xCFG.getAllSha3().addAll(contract.getCFG().getAllSha3());
			xCFG.getAllLogX().addAll(contract.getCFG().getAllLogX());
			xCFG.getAllCall().addAll(contract.getCFG().getAllCall());
			xCFG.getAllSstore().addAll(contract.getCFG().getAllSstore());
			xCFG.getEntrypoints().addAll(contract.getCFG().getEntrypoints());
			xCFG.getAllJumpdest().addAll(contract.getCFG().getAllJumpdest());
			xCFG.getAllJumpdestLocations().addAll(contract.getCFG().getAllJumpdestLocations());
			xCFG.getAllJumpI().addAll(contract.getCFG().getAllJumpI());
			xCFG.getAllJumps().addAll(contract.getCFG().getAllJumps());
			xCFG.getAllPushedJumps().addAll(contract.getCFG().getAllPushedJumps());

//			log.debug("xCFG updated adding {}", contract.getName());
//			printInfo(xCFG);
		}

		log.info("Partial xCFG built");
		return xCFG;
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
			futures.add(_executor.submit(() -> {
				analyzeContract(contract);
				runIntraChainCheckersPerContract(contract);
			}));
		}

		// Wait for all the analyses to be completed
		waitForCompletion(futures);
	}

	/**
	 * Performs the analysis of a single smart contract.
	 *
	 * @param contract The smart contract to analyze.
	 */
	public void analyzeContract(SmartContract contract) {
		try {
			log.debug("[{}] Analyzing contract: {}", Thread.currentThread().getName(), contract.getName());

			String bytecodeFullPath = contract.getBytecodePath().toString();
			String bytecode = new String(Files.readAllBytes(Paths.get(bytecodeFullPath)));

			if (bytecode.startsWith("0x"))
				EVMFrontend.opcodesFromBytecode(bytecode, bytecodeFullPath);

			Program program = EVMFrontend.generateCfgFromFile(bytecodeFullPath);
			LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
			JumpSolver checker = new JumpSolver();
			conf.semanticChecks.add(checker);

			LiSA lisa = new LiSA(conf);
			lisa.run(program);

			// Check soundness
			if (!Objects
					.requireNonNull(
							EVMLiSA.dumpStatistics(checker, EVMLiSA.getSoundlySolvedJumps(checker, lisa, program)))
					.isSound()) {
				log.warn("UNSOUND on {}", contract.getName());
			}

			contract.setCFG(checker.getComputedCFG());
			contract.computeFunctionsSignatureEntryPoints();
			contract.computeFunctionsSignatureExitPoints();
			contract.computeEventsSignatureEntryPoints();
			contract.computeKnowledgeBlocks();
			contract.computeEventsExitPoints();

		} catch (NullPointerException npe) {
			log.error("Error checking soundness in bytecode {}: {}", contract.getName(), npe.getMessage());
		} catch (Exception e) {
			log.error("Error processing contract {}: {}", contract.getName(), e.getMessage());
		}
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

	private void printInfo(EVMCFG xCFG) {
		log.info("Nodes count: {}", xCFG.getNodesCount());
		log.info("Edge count: {}", xCFG.getEdgesCount());
		log.info("Opcode count: {}", xCFG.getOpcodeCount());
//		log.info("xCFG entrypoints: {}", xCFG.getEntrypoints());
//		log.info("xCFG LOGx opcodes: {}", xCFG.getAllLogX().size());
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
