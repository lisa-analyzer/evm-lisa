package it.unipr.crosschain;

import static it.unipr.EVMLiSA.waitForCompletion;

import it.unipr.EVMLiSA;
import it.unipr.analysis.contract.Signature;
import it.unipr.analysis.contract.SmartContract;
import it.unipr.analysis.taint.TimestampDependencyAbstractDomain;
import it.unipr.analysis.taint.TxOriginAbstractDomain;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.ProgramCounterLocation;
import it.unipr.checker.ReentrancyChecker;
import it.unipr.checker.TimestampDependencyChecker;
import it.unipr.checker.TxOriginChecker;
import it.unipr.crosschain.checker.UncheckedExternalInfluenceChecker;
import it.unipr.crosschain.checker.UncheckedStateUpdateChecker;
import it.unipr.crosschain.edges.ConservativeCrossChainEdge;
import it.unipr.crosschain.edges.CrossChainEdge;
import it.unipr.crosschain.taint.UncheckedExternalInfluenceAbstractDomain;
import it.unipr.crosschain.taint.UncheckedStateUpdateAbstractDomain;
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
	private static boolean CONSERVATIVE_LINK = false;

	public static void runAnalysis(Path bytecodeDirectoryPath, Path abiDirectoryPath) {
		Bridge bridge = new Bridge(bytecodeDirectoryPath, abiDirectoryPath);
		analyzeBridge(bridge);
	}

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

		log.info("Computing cross chain edges");
		log.info("Functions count: {}", bridge.getFunctions().size());
		log.info("Events count: {}", bridge.getEvents().size());
		log.info("Log count: {}", bridge.getXCFG().getAllLogX().size());

		boolean match = false;

		for (Statement logStatement : bridge.getXCFG().getAllLogX()) {

			Set<String> selectorsInLOG = MyCache.getInstance().getEventExitPoints(logStatement);
			match = false;

			if (selectorsInLOG.isEmpty())
				continue;

			for (String selector : selectorsInLOG) {
				for (Signature event : bridge.getEvents()) {
					if (selector.equals(event.getSelector())) {
						for (Signature function : bridge.getFunctions()) {
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
				for (Signature function : bridge.getFunctions())
					crossChainEdges.addAll(addConservativeCrossChainEdges(Collections.singleton(logStatement),
							function.getEntryPoints()));

				log.warn("No match! LOG at source-code line {} conservative linked to {} functions",
						((ProgramCounterLocation) logStatement.getLocation()).getSourceCodeLine(),
						bridge.getFunctions().size());
			}
		}

		log.debug("Added {} cross chain edges using events exit points and functions entry points",
				crossChainEdges.size());
		log.info("Cross chain edges computed");

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

		log.debug("Added {} cross chain edges using events entrypoint", crossChainEdges.size());
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
		log.info("Running checkers...");

		ExecutorService executor = Executors.newFixedThreadPool(EVMLiSA.getCores());
		List<Future<?>> futures = new ArrayList<>();

		for (SmartContract contract : bridge) {
			futures.add(executor.submit(() -> runReentrancyChecker(contract)));
			futures.add(executor.submit(() -> runEventOrderChecker(contract)));
			futures.add(executor.submit(() -> runUncheckedStateUpdateChecker(contract)));
			futures.add(executor.submit(() -> runUncheckedExternalInfluenceChecker(contract)));
			futures.add(executor.submit(() -> runTxOriginChecker(contract)));
			futures.add(executor.submit(() -> runTimestampDependencyChecker(contract)));
		}

		waitForCompletion(futures);
		executor.shutdown();

		log.info("Saving checkers results...");

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

						log.warn("Event Order vulnerability at {} at line no. {} coming from line {}",
								emitEventLocation.getPc(),
								emitEventLocation.getSourceCodeLine(), functionEntrypointLocation.getSourceCodeLine());

						MyCache.getInstance().addEventOrderWarning(cfg.hashCode(), warn);
					}
				}
			}
		}
	}

	public static void printVulnerabilities(Bridge bridge) {
		log.info("Printing vulnerabilities...");
		for (SmartContract contract : bridge) {
			if (contract.getCFG() == null)
				return;

			log.info("{}: {}", contract.getName(), contract.getVulnerabilities());
		}
	}
}
