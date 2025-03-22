package it.unipr.crosschain;

import static it.unipr.EVMLiSA.waitForCompletion;

import it.unipr.EVMLiSA;
import it.unipr.analysis.contract.Signature;
import it.unipr.analysis.contract.SmartContract;
import it.unipr.analysis.taint.TimestampDependencyAbstractDomain;
import it.unipr.analysis.taint.TxOriginAbstractDomain;
import it.unipr.cfg.Calldataload;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.ProgramCounterLocation;
import it.unipr.checker.ReentrancyChecker;
import it.unipr.checker.TimestampDependencyChecker;
import it.unipr.checker.TxOriginChecker;
import it.unipr.crosschain.checker.TimeSynchronizationChecker;
import it.unipr.crosschain.checker.UncheckedExternalInfluenceChecker;
import it.unipr.crosschain.checker.UncheckedStateUpdateChecker;
import it.unipr.crosschain.checker.VulnerableLOGsComputer;
import it.unipr.crosschain.edges.ConservativeCrossChainEdge;
import it.unipr.crosschain.edges.CrossChainEdge;
import it.unipr.crosschain.taint.TimeSynchronizationAbstractDomain;
import it.unipr.crosschain.taint.UncheckedExternalInfluenceAbstractDomain;
import it.unipr.crosschain.taint.UncheckedStateUpdateAbstractDomain;
import it.unipr.crosschain.taint.VulnerableLOGsAbstractDomain;
import it.unipr.frontend.EVMLiSAFeatures;
import it.unipr.frontend.EVMLiSATypeSystem;
import it.unipr.utils.LiSAConfigurationManager;
import it.unipr.utils.MyCache;
import it.unipr.utils.VulnerabilitiesObject;
import it.unive.lisa.LiSA;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.conf.LiSAConfiguration;
import it.unive.lisa.program.Program;
import it.unive.lisa.program.cfg.edge.Edge;
import it.unive.lisa.program.cfg.statement.Statement;
import java.nio.file.Path;
import java.util.*;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class xEVMLiSA {
	private static final Logger log = LogManager.getLogger(xEVMLiSA.class);

	/**
	 * Runs analysis by initializing a bridge using the specified bytecode
	 * directory path and ABI directory path, and then invoking the
	 * analyzeBridge method on the bridge.
	 *
	 * @param bytecodeDirectoryPath The path to the directory containing the
	 *                                  smart contract bytecode files.
	 * @param abiDirectoryPath      The path to the directory containing the ABI
	 *                                  (Application Binary Interface) files.
	 */
	public static void runAnalysis(Path bytecodeDirectoryPath, Path abiDirectoryPath) {
		Bridge bridge = new Bridge(bytecodeDirectoryPath, abiDirectoryPath);
		analyzeBridge(bridge);
	}

	/**
	 * Analyzes a bridge by examining its smart contracts, building its partial
	 * cross-chain control flow graph (xCFG), creating cross-chain edges, and
	 * executing various security checkers to identify vulnerabilities.
	 *
	 * @param bridge The bridge object containing the set of smart contracts to
	 *                   be analyzed.
	 */
	public static void analyzeBridge(Bridge bridge) {
		EVMLiSA.setLinkUnsoundJumpsToAllJumpdest();
		EVMLiSA.setCores(
				Runtime.getRuntime().availableProcessors() / 4 * 3);
		EVMLiSA.analyzeSetOfContracts(bridge.getSmartContracts());
		bridge.buildPartialXCFG();
		bridge.addEdges(
				getCrossChainEdgesUsingEventsAndFunctionsEntrypoint(bridge));
		runCheckers(bridge);
		printVulnerabilities(bridge);

		// log.debug("Bridge after analysis \n {}", bridge);
	}

	/**
	 * Gets cross-chain edges by linking events exit points to function entry
	 * points in different contracts.
	 *
	 * @return A list of added cross-chain edges.
	 */
	private static Set<Edge> getCrossChainEdgesUsingEventsAndFunctionsEntrypoint(Bridge bridge) {
		Set<Edge> crossChainEdges = new HashSet<>();

		log.info("Computing cross chain edge.");
		log.debug("Functions in bridge: {}.", bridge.getFunctions().size());
		log.debug("Events in bridge: {}.", bridge.getEvents().size());
		log.debug("Log statement in bridge: {}.", bridge.getXCFG().getAllLogX().size());

		for (Signature event : bridge.getEvents()) {
			for (Signature function : bridge.getFunctions()) {
				/*
				 * TODO: We may perform additional checks (e.g., parameter
				 * types, parameter count, etc.) to link an event to a function,
				 * as currently we are only linking them based on matching
				 * names.
				 */
				if (event.getName().equalsIgnoreCase(function.getName())) {

					crossChainEdges.addAll(
							addCrossChainEdges(event.getExitPoints(), function.getEntryPoints()));

					// Debug print
					for (Statement e : event.getExitPoints()) {
						for (Statement f : function.getEntryPoints()) {
							log.debug(
									"Cross-chain edge added: event {} (name: {}, selector: {}, line: {}) -> function {} (name: {}, selector: {}, line: {}).",
									e, event.getName(), event.getSelector(),
									((ProgramCounterLocation) e.getLocation()).getSourceCodeLine(),
									f, function.getName(), function.getSelector(),
									((ProgramCounterLocation) f.getLocation()).getSourceCodeLine());
						}
					}
				}
			}
		}

		log.debug("Added {} cross chain edges using events exit points and functions entry points.",
				crossChainEdges.size());
		log.info("Cross chain edges computed.");

		return crossChainEdges;
	}

	/**
	 * Gets cross-chain edges by linking emitting blocks to information blocks
	 * in different contracts (SmartAxe solution).
	 *
	 * @return A list of added cross-chain edges.
	 */
	private static Set<Edge> getCrossChainEdgesUsingEventsEntrypoint(Bridge bridge) {
		Set<Statement> emittingBlocks = new HashSet<>();
		Set<Statement> informationBlocks = new HashSet<>();

		for (SmartContract contract : bridge) {
			for (Signature signature : EventKnowledge.getEmittingBlocksSignature(contract.getEventsSignature()))
				emittingBlocks.addAll(signature.getEntryPoints());

			for (Signature signature : EventKnowledge.getInformationBlocksSignature(contract.getEventsSignature()))
				informationBlocks.addAll(signature.getEntryPoints());
		}

		Set<Edge> crossChainEdges = new HashSet<>(addCrossChainEdges(emittingBlocks, informationBlocks));

		log.debug("Added {} cross chain edges using events entrypoint.", crossChainEdges.size());
		return crossChainEdges;
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
	private static Set<Edge> addCrossChainEdges(Set<Statement> sources, Set<Statement> targets) {
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
	private static Set<Edge> addConservativeCrossChainEdges(Set<Statement> sources, Set<Statement> targets) {
		Set<Edge> edges = new HashSet<>();

		for (Statement source : sources)
			for (Statement target : targets)
				edges.add(new ConservativeCrossChainEdge(source, target));

		return edges;
	}

	/**
	 * Executes all security checkers in parallel on the smart contracts in the
	 * bridge.
	 */
	public static void runCheckers(Bridge bridge) {
		log.info("Running checkers.");

		ExecutorService executor = Executors.newFixedThreadPool(EVMLiSA.getCores());
		List<Future<?>> futures = new ArrayList<>();

		// Intra-chain checkers
		for (SmartContract contract : bridge) {
			futures.add(executor.submit(() -> runReentrancyChecker(contract)));
			futures.add(executor.submit(() -> runEventOrderChecker(contract)));
			futures.add(executor.submit(() -> runUncheckedStateUpdateChecker(contract)));
			futures.add(executor.submit(() -> runUncheckedExternalInfluenceChecker(contract)));
			futures.add(executor.submit(() -> runTxOriginChecker(contract)));
			futures.add(executor.submit(() -> runTimestampDependencyChecker(contract)));
			futures.add(executor.submit(() -> computeVulnerablesLOGsForTimeSynchronizationChecker(contract)));
		}
		waitForCompletion(futures);

		computeTaintedCallDataForTimeSynchronizationChecker(bridge);

		// Cross-chain checkers
		for (SmartContract contract : bridge) {
			futures.add(executor.submit(() -> runTimeSynchronizationChecker(contract)));
		}

		waitForCompletion(futures);

		log.info("Saving checkers results.");

		for (SmartContract contract : bridge) {
			contract.setVulnerabilities(
					VulnerabilitiesObject.newVulnerabilitiesObject()
							.reentrancy(
									MyCache.getInstance().getReentrancyWarnings(contract.getCFG().hashCode()))
							.txOrigin(MyCache.getInstance().getTxOriginWarnings(contract.getCFG().hashCode()))
							.timestamp(MyCache.getInstance()
									.getTimestampDependencyWarnings(contract.getCFG().hashCode()))
							.eventOrder(MyCache.getInstance()
									.getEventOrderWarnings(contract.getCFG().hashCode()))
							.uncheckedExternalInfluence(MyCache.getInstance()
									.getUncheckedExternalInfluenceWarnings(contract.getCFG().hashCode()))
							.uncheckedStateUpdate(MyCache.getInstance()
									.getUncheckedStateUpdateWarnings(contract.getCFG().hashCode()))
							.build());
		}

		bridge.setVulnerabilities(
				VulnerabilitiesObject.newVulnerabilitiesObject()
						.timeSynchronization(MyCache.getInstance().getTimeSynchronizationWarnings())
						.build());

		log.info("Checkers results saved.");
		executor.shutdown();
	}

	/**
	 * Runs the timestamp dependency checker on the given smart contract.
	 *
	 * @param contract The smart contract to analyze.
	 */
	public static void runTimestampDependencyChecker(SmartContract contract) {
		// Setup configuration
		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
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
	public static void runTxOriginChecker(SmartContract contract) {
		// Setup configuration
		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
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
	public static void runUncheckedExternalInfluenceChecker(SmartContract contract) {
		// Setup configuration
		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
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
	public static void runUncheckedStateUpdateChecker(SmartContract contract) {
		// Setup configuration
		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
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
	public static void runReentrancyChecker(SmartContract contract) {
		// Setup configuration
		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
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
	public static void runEventOrderChecker(SmartContract contract) {
		Set<Statement> functionsEntrypoints = new HashSet<>();

		for (Signature function : contract.getFunctionsSignature())
			functionsEntrypoints.addAll(function.getEntryPoints());

		EVMCFG cfg = contract.getCFG();
		Set<Statement> sstoreSet = cfg.getAllSstore();
		Set<Statement> logSet = cfg.getAllLogX();

		for (Statement functionEntrypoint : functionsEntrypoints) {
			for (Statement emitEvent : logSet) {
				if (cfg.reachableFrom(functionEntrypoint, emitEvent)) {
					if (!cfg.reachableFromCrossing(functionEntrypoint, emitEvent, sstoreSet)) {

						ProgramCounterLocation functionEntrypointLocation = (ProgramCounterLocation) functionEntrypoint
								.getLocation();
						ProgramCounterLocation emitEventLocation = (ProgramCounterLocation) emitEvent.getLocation();

						String warn = "Event Order vulnerability at " + emitEventLocation.getPc();

						log.warn("Event Order vulnerability at pc {} at line {} coming from line {}.",
								emitEventLocation.getPc(),
								emitEventLocation.getSourceCodeLine(),
								functionEntrypointLocation.getSourceCodeLine());

						MyCache.getInstance().addEventOrderWarning(cfg.hashCode(), warn);
					}
				}
			}
		}
	}

	/**
	 * Executes the vulnerable logs checker for detecting issues related to time
	 * synchronization in a given smart contract.
	 *
	 * @param contract The smart contract to be analyzed for vulnerabilities
	 *                     related to time synchronization.
	 */
	public static void computeVulnerablesLOGsForTimeSynchronizationChecker(SmartContract contract) {
		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
		program.addCodeMember(contract.getCFG());
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
		LiSA lisa = new LiSA(conf);

		VulnerableLOGsComputer checker = new VulnerableLOGsComputer();
		conf.semanticChecks.add(checker);
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(),
				new VulnerableLOGsAbstractDomain(),
				new TypeEnvironment<>(new InferredTypes()));
		lisa.run(program);
	}

	/**
	 * Computes and traces tainted call data in the context of the Time
	 * Synchronization Checker. This method identifies and links call data loads
	 * that are reachable from vulnerable log statements via cross-chain edges,
	 * marking them as tainted.
	 *
	 * @param bridge The bridge object containing the cross-chain control flow
	 *                   graph (xCFG) and other data necessary for the analysis.
	 */
	private static void computeTaintedCallDataForTimeSynchronizationChecker(Bridge bridge) {
		EVMCFG xcfg = bridge.getXCFG();
		Set<Statement> logsVulnerable = MyCache.getInstance()
				.getSetOfVulnerableLogStatementForTimeSynchronizationChecker();

		for (Statement logVulnerable : logsVulnerable) {
			for (Statement externalDataStatement : xcfg.getExternalData()) {
				if (externalDataStatement instanceof Calldataload
						&& xcfg.reachableFromCrossingACrossChainEdge(logVulnerable, externalDataStatement)) {

					MyCache.getInstance().addLinkFromLogToCallDataLoad(logVulnerable, externalDataStatement);
					MyCache.getInstance().addTaintedCallDataLoad(externalDataStatement);

					log.debug(
							"(Time Synchronization vulnerability) Reachable with cross-chain edge: {} (line: {}, cfg: {}) -> {} (line: {}, cfg: {}).",
							logVulnerable, ((ProgramCounterLocation) logVulnerable.getLocation()).getSourceCodeLine(),
							logVulnerable.getCFG().hashCode(),
							externalDataStatement,
							((ProgramCounterLocation) externalDataStatement.getLocation()).getSourceCodeLine(),
							externalDataStatement.getCFG().hashCode());
				}
			}
		}
	}

	/**
	 * Runs the time synchronization checker on the given smart contract.
	 *
	 * @param contract The smart contract to analyze for time synchronization
	 *                     issues.
	 */
	public static void runTimeSynchronizationChecker(SmartContract contract) {
		// Setup configuration
		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
		program.addCodeMember(contract.getCFG());
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
		LiSA lisa = new LiSA(conf);

		// Time synchronization checker
		TimeSynchronizationChecker checker = new TimeSynchronizationChecker();
		conf.semanticChecks.add(checker);
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(),
				new TimeSynchronizationAbstractDomain(),
				new TypeEnvironment<>(new InferredTypes()));
		lisa.run(program);
	}

	/**
	 * Prints the vulnerabilities of each smart contract in the given bridge.
	 *
	 * @param bridge The bridge containing the smart contracts to analyze for
	 *                   vulnerabilities.
	 */
	public static void printVulnerabilities(Bridge bridge) {
		for (SmartContract contract : bridge) {
			if (contract.getCFG() == null)
				return;
			log.debug("Contract {} vulnerabilities: {}", contract.getName(), contract.getVulnerabilities());
		}
		log.debug("Bridge vulnerabilities: {}", bridge.getVulnerabilities());
	}
}
