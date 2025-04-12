package it.unipr.crosschain;

import it.unipr.EVMLiSA;
import it.unipr.analysis.contract.Signature;
import it.unipr.analysis.contract.SmartContract;
import it.unipr.cfg.*;
import it.unipr.crosschain.checker.*;
import it.unipr.crosschain.edges.ConservativeCrossChainEdge;
import it.unipr.crosschain.edges.CrossChainEdge;
import it.unipr.crosschain.taint.*;
import it.unipr.frontend.EVMLiSAFeatures;
import it.unipr.frontend.EVMLiSATypeSystem;
import it.unipr.utils.EVMLiSAExecutor;
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
import java.util.concurrent.Future;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;

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
		EVMLiSA.setLinkUnsoundJumpsToAllJumpdest();
		EVMLiSA.setCores(Runtime.getRuntime().availableProcessors() / 4 * 3);

		Bridge bridge = new Bridge(bytecodeDirectoryPath, abiDirectoryPath);

		analyzeBridge(bridge);

		runInterCrossChainCheckers(bridge);
		runIntraCrossChainCheckers(bridge);

		printVulnerabilities(bridge);
		EVMLiSAExecutor.shutdown();

		JSONObject json = new JSONObject();
		log.info("Bridge {}", bridge.getName());
		json.put("bridge", bridge.getName());

		JSONArray contracts = new JSONArray();

		for (SmartContract contract : bridge) {
			JSONObject contractJson = new JSONObject();
			contractJson.put("contract",
					contract.getName());
			contractJson.put("vulnerabilities",
					MyCache.getInstance().getOlli(
							contract.getCFG().hashCode()));
			contracts.put(contractJson);
		}
		json.put("contracts", contracts);
		log.info(json.toString(4));

//		log.debug(bridge);
	}

	/**
	 * Analyzes a bridge by examining its smart contracts, building its partial
	 * cross-chain control flow graph (xCFG) creating cross-chain edges.
	 *
	 * @param bridge The bridge object containing the set of smart contracts to
	 *                   be analyzed.
	 */
	public static void analyzeBridge(Bridge bridge) {
		log.info("Number of contracts to be analyzed: {}.", bridge.getSmartContracts().size());

		EVMLiSA.analyzeSetOfContracts(bridge.getSmartContracts());
		bridge.buildPartialXCFG();
		bridge.addEdges(
				getCrossChainEdgesUsingEventsAndFunctionsEntrypoint(bridge));

		log.info("Bridge {} analyzed.", bridge.getName());
	}

	/**
	 * Gets cross-chain edges by linking events exit points to function entry
	 * points in different contracts.
	 *
	 * @return A list of added cross-chain edges.
	 */
	public static Set<Edge> getCrossChainEdgesUsingEventsAndFunctionsEntrypoint(Bridge bridge) {
		Set<Edge> crossChainEdges = new HashSet<>();
		Set<String> functionsUsed = new HashSet<>();
		Set<String> eventUsed = new HashSet<>();

		log.info("Computing cross chain edges of {}.", bridge.getName());
		log.debug("Functions in bridge: {}.", bridge.getFunctions().size());
		log.debug("Events in bridge: {}.", bridge.getEvents().size());
		log.debug("Log statement in bridge: {}.", bridge.getXCFG().getAllLogX().size());

		for (Signature event : bridge.getEvents()) {
			for (Signature function : bridge.getFunctions()) {
				/*
				 * We may perform additional checks (e.g., parameter types,
				 * parameter count, etc.) to link an event to a function, as
				 * currently we are only linking them based on matching names.
				 */
				if (event.getName().equalsIgnoreCase(function.getName())) {
					functionsUsed.add(function.getFullSignature());
					eventUsed.add(event.getFullSignature());

					crossChainEdges.addAll(
							addCrossChainEdges(event.getExitPoints(), function.getEntryPoints()));

					MyCache.getInstance().addMapEventsFunctions(event, function);

					// Debug print
					for (Statement e : event.getExitPoints()) {
						for (Statement f : function.getEntryPoints()) {
							log.debug(
									"Cross-chain edge added: event {} (name: {}, selector: {}, line: {}) -> function {} (name: {}, selector: {}, line: {}).",
									e, event.getFullSignature(), event.getSelector(),
									((ProgramCounterLocation) e.getLocation()).getSourceCodeLine(),
									f, function.getFullSignature(), function.getSelector(),
									((ProgramCounterLocation) f.getLocation()).getSourceCodeLine());
						}
					}
				}
			}
		}

		log.debug("Added {} cross chain edges using events exit points and functions entry points.",
				crossChainEdges.size());
		log.info("Functions used: {}/{} ({})\"", functionsUsed.size(), bridge.getFunctions().size(), functionsUsed);
		log.info("Events used: {}/{} ({})", eventUsed.size(), bridge.getEvents().size(), eventUsed);
		log.info("Cross chain edges of {} computed.", bridge.getName());

		return crossChainEdges;
	}

	/**
	 * Gets cross-chain edges by linking emitting blocks to information blocks
	 * in different contracts (SmartAxe solution).
	 *
	 * @return A list of added cross-chain edges.
	 */
	public static Set<Edge> getCrossChainEdgesUsingEventsEntrypoint(Bridge bridge) {
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
	public static Set<Edge> addCrossChainEdges(Set<Statement> sources, Set<Statement> targets) {
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
	public static Set<Edge> addConservativeCrossChainEdges(Set<Statement> sources, Set<Statement> targets) {
		Set<Edge> edges = new HashSet<>();

		for (Statement source : sources)
			for (Statement target : targets)
				edges.add(new ConservativeCrossChainEdge(source, target));

		return edges;
	}

	/**
	 * Executes a series of intra cross-chain checkers for the given bridge,
	 * which analyze associated smart contracts for various vulnerabilities. The
	 * results of the checkers are saved and stored in the bridge and its smart
	 * contracts.
	 *
	 * @param bridge The bridge containing the set of smart contracts to be
	 *                   analyzed.
	 */
	public static void runIntraCrossChainCheckers(Bridge bridge) {
		log.info("[IN] Running intra cross-chain checkers.");

		List<Future<?>> futures = new ArrayList<>();
		for (SmartContract contract : bridge) {
//			futures.add(EVMLiSAExecutor.submit(() -> EVMLiSA.runTxOriginChecker(contract)));
//			futures.add(EVMLiSAExecutor.submit(() -> EVMLiSA.runRandomnessDependencyChecker(contract)));
//			futures.add(EVMLiSAExecutor.submit(() -> EVMLiSA.runTxOriginChecker(contract)));
			futures.add(EVMLiSAExecutor.submit(() -> runEventOrderChecker(bridge, contract)));
			futures.add(EVMLiSAExecutor.submit(() -> runUncheckedExternalCallChecker(bridge, contract)));
//			futures.add(EVMLiSAExecutor.submit(() -> runUncheckedExternalInfluenceChecker(contract)));
			futures.add(EVMLiSAExecutor.submit(() -> runSemanticIntegrityViolationChecker(bridge, contract)));
			futures.add(EVMLiSAExecutor.submit(() -> runMissingEventNotificationChecker(contract)));
		}
		EVMLiSAExecutor.awaitCompletionFutures(futures);

		log.info("Saving intra cross-chain checkers results.");
		for (SmartContract contract : bridge) {
			contract.setVulnerabilities(
					VulnerabilitiesObject.buildFromCFG(
							contract.getCFG()));
		}

		log.info("[OUT] Intra cross-chain checkers results saved.");
	}

	/**
	 * Executes the inter cross-chain checkers to analyze vulnerabilities
	 * related to time synchronization across the given bridge of smart
	 * contracts (i.e., time synchronization dependency).
	 *
	 * @param bridge The bridge object which contains the collection of smart
	 *                   contracts to be analyzed. It serves as the main context
	 *                   for the inter cross-chain analysis.
	 */
	public static void runInterCrossChainCheckers(Bridge bridge) {
		log.info("[IN] Running inter cross-chain checkers.");

		List<Future<?>> futures = new ArrayList<>();

		log.info("[TimeSynchronizationChecker] Computing vulnerable LOGs.");
		for (SmartContract contract : bridge)
			futures.add(EVMLiSAExecutor.submit(() -> computeVulnerablesLOGsForTimeSynchronizationChecker(contract)));
		EVMLiSAExecutor.awaitCompletionFutures(futures);
		log.info("[TimeSynchronizationChecker] Vulnerable LOGs computed.");

		log.info("[TimeSynchronizationChecker] Computing tainted CallData.");
		for (SmartContract contract : bridge)
			futures.add(EVMLiSAExecutor.submit(() -> computeTaintedCallDataForTimeSynchronizationChecker(contract)));
		EVMLiSAExecutor.awaitCompletionFutures(futures);
		log.info("[TimeSynchronizationChecker] Tainted CallData computed.");

		for (SmartContract contract : bridge)
			futures.add(EVMLiSAExecutor.submit(() -> runTimeSynchronizationChecker(contract)));
		EVMLiSAExecutor.awaitCompletionFutures(futures);

		log.info("Saving inter cross-chain checkers results.");

		log.info("[OUT] Inter cross-chain checkers results saved.");
	}

	/**
	 * Runs the unchecked state update checker on the given smart contract.
	 *
	 * @param contract The smart contract to analyze.
	 */
	public static void runUncheckedExternalInfluenceChecker(SmartContract contract) {
		log.info("[IN] Running unchecked external influence checker on {}.", contract.getName());

		// Setup configuration
		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
		program.addCodeMember(contract.getCFG());
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
		LiSA lisa = new LiSA(conf);

		// Unchecked external influence checker
		UncheckedExternalInfluenceChecker checker = new UncheckedExternalInfluenceChecker(contract);
		conf.semanticChecks.add(checker);
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(),
				new UncheckedExternalInfluenceAbstractDomain(),
				new TypeEnvironment<>(new InferredTypes()));
		lisa.run(program);

		log.info("[OUT] Unchecked external influence checker ended on {}, with {} vulnerabilities found.",
				contract.getName(),
				MyCache.getInstance().getUncheckedExternalInfluenceWarnings(contract.getCFG().hashCode()));
	}

	/**
	 * Runs the Semantic integrity violation checker on the given smart
	 * contract.
	 *
	 * @param contract The smart contract to analyze.
	 */
	public static void runSemanticIntegrityViolationChecker(Bridge bridge, SmartContract contract) {
		log.info("[IN] Running semantic integrity violation checker on {}.", contract.getName());

		// Setup configuration
		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
		program.addCodeMember(contract.getCFG());
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
		LiSA lisa = new LiSA(conf);

		// Checker build
		SemanticIntegrityViolationChecker checker = new SemanticIntegrityViolationChecker(contract, bridge.getXCFG());
		conf.semanticChecks.add(checker);
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(),
				new SemanticIntegrityViolationAbstractDomain(),
				new TypeEnvironment<>(new InferredTypes()));
		lisa.run(program);

		log.info(
				"[OUT] Semantic integrity violation checker ended on {}, with {} definite and {} possible vulnerabilities found.",
				contract.getName(),
				MyCache.getInstance().getSemanticIntegrityViolationWarnings(contract.getCFG().hashCode()),
				MyCache.getInstance().getPossibleSemanticIntegrityViolationWarnings(contract.getCFG().hashCode()));
	}

	/**
	 * Runs the unchecked state update checker on the given smart contract.
	 *
	 * @param contract The smart contract to analyze.
	 */
	public static void runUncheckedExternalCallChecker(Bridge bridge, SmartContract contract) {
		log.info("[IN] Running unchecked state update checker on {}.", contract.getName());

		// Setup configuration
		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
		program.addCodeMember(contract.getCFG());
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
		LiSA lisa = new LiSA(conf);

		// Unchecked state update checker
		UncheckedExternalCallChecker checker = new UncheckedExternalCallChecker(contract, bridge.getXCFG());
		conf.semanticChecks.add(checker);
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new UncheckedExternalCallAbstractDomain(),
				new TypeEnvironment<>(new InferredTypes()));
		lisa.run(program);

		log.info("[OUT] Unchecked state update checker ended on {}, with {} vulnerabilities found.",
				contract.getName(),
				MyCache.getInstance().getUncheckedExternalCallWarnings(contract.getCFG().hashCode()));
	}

	/**
	 * Runs the event order checker on the given smart contract. This method
	 * verifies whether events are emitted before state modifications (SSTORE
	 * instructions). It identifies vulnerabilities where an event is emitted
	 * without prior state changes, potentially leading to inconsistencies.
	 *
	 * @param bridge   The bridge that contains the smart contract and the xCFG.
	 * @param contract The smart contract to analyze.
	 */
	public static void runEventOrderChecker(Bridge bridge, SmartContract contract) {
		log.info("[IN] Running event order checker on {}.", contract.getName());

		EVMCFG cfg = contract.getCFG();

		for (Signature function : contract.getFunctionsSignature()) {
			for (Statement entrypoint : function.getEntryPoints()) {
				/*
				 * It means that this vulnerability is inside a private
				 * function: we need to check only the public functions
				 */
				if (contract.getFunctionSignatureFromEntryPoint(entrypoint).equals("no-function-found"))
					continue;

				for (Statement exitpoint : function.getExitPoints()) {
					/* We need to check only the successful termination paths */
					if (!(exitpoint instanceof Stop
							|| exitpoint instanceof Return))
						continue;

					/* We take only the state updates inside the function */
					Set<Statement> sstores = cfg.getStatementsInAPathWithTypes(entrypoint, exitpoint,
							Set.of(Sstore.class));
					/* We take only the log instructions inside the function */
					Set<Statement> logs = cfg.getStatementsInAPathWithTypes(entrypoint, exitpoint,
							Set.of(Log1.class, Log2.class, Log3.class, Log4.class));

					/*
					 * If there is no state update but at least a LOG
					 * instruction, a (possible) warning is raised
					 */
					if (sstores.isEmpty() && !logs.isEmpty()) {
						for (Statement emitEvent : logs) {
							ProgramCounterLocation entrypointLocation = (ProgramCounterLocation) entrypoint
									.getLocation();
							ProgramCounterLocation emitEventLocation = (ProgramCounterLocation) emitEvent.getLocation();

							if (bridge.getXCFG().hasAtLeastOneCrossChainEdge(emitEvent)) {
								String warn = "[DEFINITE] Event Order vulnerability at " + emitEventLocation.getPc();

								log.warn(
										"[DEFINITE] Event Order vulnerability at pc {} (line {}) coming from pc {} (line {}).",
										emitEventLocation.getPc(),
										emitEventLocation.getSourceCodeLine(),
										entrypointLocation.getPc(),
										entrypointLocation.getSourceCodeLine());

								MyCache.getInstance().addEventOrderWarning(cfg.hashCode(), warn);

								warn = "[DEFINITE] Event Order vulnerability in " + contract.getName() + " at "
										+ function.getFullSignature()
										+ " (pc: " + emitEventLocation.getPc() + ", "
										+ "line: " + emitEventLocation.getSourceCodeLine() + ")";
								MyCache.getInstance().addOlli(cfg.hashCode(), warn);

							} else {
								String warn = "[POSSIBLE] Event Order vulnerability at " + emitEventLocation.getPc();

								log.warn(
										"[POSSIBLE] Event Order vulnerability at pc {} (line {}) coming from pc {} (line {}).",
										emitEventLocation.getPc(),
										emitEventLocation.getSourceCodeLine(),
										entrypointLocation.getPc(),
										entrypointLocation.getSourceCodeLine());

								MyCache.getInstance().addPossibleEventOrderWarning(cfg.hashCode(), warn);

//						warn = "[POSSIBLE] Event Order vulnerability in " + contract.getName() + " at " + contract.getFunctionSignatureByStatement(emitEvent);
//						MyCache.getInstance().addOlli(cfg.hashCode(), warn);
							}
						}
					}
				}
			}
		}

		log.info("[OUT] Event order checker ended on {}, with {} definite and {} possible vulnerabilities found.",
				contract.getName(),
				MyCache.getInstance().getEventOrderWarnings(contract.getCFG().hashCode()),
				MyCache.getInstance().getPossibleEventOrderWarnings(contract.getCFG().hashCode()));
	}

	/**
	 * Runs the missing event notification checker on the given smart contract.
	 * This method analyzes the contract's CFG to detect if in a function of the
	 * given contract there is (at least) a state update and there is no event
	 * notification (identified by the LOG instruction). If this condition is
	 * true, it indicates that there is a missing event notification.
	 *
	 * @param contract the smart contract to analyze.
	 */
	public static void runMissingEventNotificationChecker(SmartContract contract) {
		log.info("[IN] Running missing event notification checker on {}.", contract.getName());

		EVMCFG cfg = contract.getCFG();

		for (Signature function : contract.getFunctionsSignature()) {
			for (Statement entrypoint : function.getEntryPoints()) {
				/*
				 * It means that this vulnerability is inside a private
				 * function: we need to check only the public functions
				 */
				if (contract.getFunctionSignatureFromEntryPoint(entrypoint).equals("no-function-found"))
					continue;

				for (Statement exitpoint : function.getExitPoints()) {
					/* We need to check only the successful termination paths */
					if (!(exitpoint instanceof Stop
							|| exitpoint instanceof Return))
						continue;

					/* We take only the state update inside the function */
					Set<Statement> sstores = cfg.getStatementsInAPathWithTypes(entrypoint, exitpoint,
							Set.of(Sstore.class));

					for (Statement sstore : sstores) {
						if (cfg.reachableFromWithoutTypes(entrypoint, sstore, Set.of(Log.class))
								&& cfg.reachableFromWithoutTypes(sstore, exitpoint, Set.of(Log.class))) {

							ProgramCounterLocation sstoreLocation = (ProgramCounterLocation) sstore
									.getLocation();
							ProgramCounterLocation exitpointLocation = (ProgramCounterLocation) exitpoint
									.getLocation();

							String warn = "Missing Event Notification vulnerability at " + sstoreLocation.getPc();
							log.warn(
									"Missing Event Notification vulnerability at pc {} (line {}) coming from pc {} (line {}).",
									exitpointLocation.getPc(),
									exitpointLocation.getSourceCodeLine(),
									sstoreLocation.getPc(),
									sstoreLocation.getSourceCodeLine());

							MyCache.getInstance().addMissingEventNotificationWarning(cfg.hashCode(), warn);

							warn = "Missing Event Notification vulnerability in " + contract.getName() + " at "
									+ contract.getFunctionSignatureFromEntryPoint(entrypoint)
									+ " (pc: " + sstoreLocation.getPc() + ", "
									+ "line: " + sstoreLocation.getSourceCodeLine() + ")";
							MyCache.getInstance().addOlli(cfg.hashCode(), warn);
						}
					}

				}
			}
		}

		log.info("[OUT] Missing event notification checker ended on {}, with {} vulnerabilities found.",
				contract.getName(),
				MyCache.getInstance().getMissingEventNotificationWarnings(contract.getCFG().hashCode()));
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
	 * @param contract The smart contract to be analyzed.
	 */
	public static void computeTaintedCallDataForTimeSynchronizationChecker(SmartContract contract) {
		if (contract == null)
			return;

		try {
			Set<Statement> logsVulnerable = MyCache.getInstance()
					.getSetOfVulnerableLogStatementForTimeSynchronizationChecker();

			/* For each event of this event */
			for (Signature event : contract.getEventsSignature()) {
				for (Statement emit : event.getExitPoints()) {
					if (logsVulnerable.contains(emit)) {
						/* Functions linked to this event */
						Set<Signature> functionsLinked = MyCache.getInstance().getMapEventsFunctions(event);
						log.warn("No linked function found for event {} in contract {}.", event.getFullSignature(),
								contract.getName());
						for (Signature functionLinked : functionsLinked) {

							for (Statement entrypoint : functionLinked.getEntryPoints()) {
								for (Statement exitpoint : functionLinked.getExitPoints()) {
									/*
									 * We need to check only the successful
									 * termination paths
									 */
									if (!(exitpoint instanceof Stop
											|| exitpoint instanceof Return))
										continue;

									/*
									 * We take only the call data inside the
									 * function
									 */
									EVMCFG newCFG = (EVMCFG) entrypoint.getCFG();
									Set<Statement> externalData = newCFG
											.getStatementsInAPathWithTypes(
													entrypoint,
													exitpoint,
													Set.of(Calldataload.class, Calldatacopy.class));

									for (Statement data : externalData) {
										MyCache.getInstance().addLinkFromLogToCallDataLoad(emit, data);
										MyCache.getInstance().addTaintedCallDataLoad(data);

										log.debug(
												"(computeTaintedCallData) Reachable with cross-chain edge: {} (line: {}, cfg: {}) -> {} (line: {}, cfg: {}). Event {} (contract {}) to function {}.",
												emit,
												((ProgramCounterLocation) emit.getLocation()).getSourceCodeLine(),
												emit.getCFG().hashCode(),
												data,
												((ProgramCounterLocation) data.getLocation()).getSourceCodeLine(),
												data.getCFG().hashCode(),
												event.getFullSignature(),
												contract.getName(),
												functionLinked.getFullSignature());
									}
								}
							}
						}
					}
				}
			}
		} catch (Exception e) {
			System.err.println(e.getMessage());
			e.printStackTrace();
			System.err.println(contract);
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
		TimeSynchronizationChecker checker = new TimeSynchronizationChecker(contract);
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
