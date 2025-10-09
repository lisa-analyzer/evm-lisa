package it.unipr.crosschain;

import it.unipr.EVMLiSA;
import it.unipr.analysis.contract.Signature;
import it.unipr.analysis.contract.SmartContract;
import it.unipr.cfg.*;
import it.unipr.crosschain.checker.*;
import it.unipr.crosschain.edges.ConservativeCrossChainEdge;
import it.unipr.crosschain.edges.CrossChainEdge;
import it.unipr.crosschain.events.EventKnowledge;
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
import org.apache.commons.lang3.tuple.Pair;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;

public class xEVMLiSA {
	private static final Logger log = LogManager.getLogger(xEVMLiSA.class);

	/**
	 * Main entry point for running cross-chain analysis on a bridge. This
	 * method configures EVMLiSA, creates a bridge from the provided paths,
	 * analyzes it, runs cross-chain checkers, and prints the results.
	 *
	 * @param bytecodeDirectoryPath path to the directory containing bytecode
	 *                                  files
	 * @param abiDirectoryPath      path to the directory containing ABI files
	 * @param policyPath            path to the policy JSON file
	 */
	public static void runAnalysis(Path bytecodeDirectoryPath, Path abiDirectoryPath, Path policyPath) {
		EVMLiSA.setLinkUnsoundJumpsToAllJumpdest();
		EVMLiSA.setCores(Runtime.getRuntime().availableProcessors() - 1);

		Bridge bridge = new Bridge(bytecodeDirectoryPath, abiDirectoryPath, policyPath);

		analyzeBridge(bridge);

		runCrossChainCheckers(bridge);

		printVulnerabilities(bridge);
		printVulnerabilitiesPerFunction(bridge);
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

		for (SmartContract contractSource : bridge.getSmartContracts()) {
			for (SmartContract contractDestination : bridge.getSmartContracts()) {
				if (contractSource.equals(contractDestination))
					continue; // Avoid auto-link

				for (Signature event : contractSource.getEventsSignature()) {
					for (Signature function : contractDestination.getFunctionsSignature()) {

						if (xEVMLiSA.applyPolicy(bridge.getPolicy(), event, function)) {
							functionsUsed.add(function.getFullSignature());
							eventUsed.add(event.getFullSignature());

							crossChainEdges.addAll(
									addCrossChainEdges(event.getExitPoints(), function.getEntryPoints()));

							MyCache.getInstance().addMapEventsFunctions(event, function);

							// Debug print
							for (Statement e : event.getExitPoints()) {
								for (Statement f : function.getEntryPoints()) {
									log.debug(
											"Cross-chain edge added: from contract {} with event {} (name: {}, selector: {}, line: {}) to contract {} with function {} (name: {}, selector: {}, line: {}).",
											contractSource.getName(),
											e, event.getFullSignature(), event.getSelector(),
											((ProgramCounterLocation) e.getLocation()).getSourceCodeLine(),
											contractDestination.getName(),
											f, function.getFullSignature(), function.getSelector(),
											((ProgramCounterLocation) f.getLocation()).getSourceCodeLine());
								}
							}
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
	 * Applies the cross-chain policy to determine if an event should be linked
	 * to a function. If no policy is provided, it defaults to matching events
	 * and functions by name.
	 *
	 * @param policy   the list of event-function pairs from the policy
	 * @param event    the event signature to match
	 * @param function the function signature to match
	 *
	 * @return true if the event should be linked to the function according to
	 *             the policy
	 */
	public static boolean applyPolicy(List<Pair<String, String>> policy, Signature event, Signature function) {
		if (policy == null || policy.isEmpty())
			return event.getName().equalsIgnoreCase(function.getName());

		for (Pair<String, String> pair : policy) {
			String eventPolicy = pair.getLeft();
			String functionPolicy = pair.getRight();
			if (eventPolicy.equalsIgnoreCase(event.getName())
					&& functionPolicy.equalsIgnoreCase(function.getName()))
				return true;
		}
		return false;
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
	 * Executes a series of cross-chain checkers for the given bridge, which
	 * analyze associated smart contracts for various vulnerabilities. The
	 * results of the checkers are saved and stored in the bridge and its smart
	 * contracts.
	 *
	 * @param bridge The bridge containing the set of smart contracts to be
	 *                   analyzed.
	 */
	public static void runCrossChainCheckers(Bridge bridge) {
		log.info("[IN] Running cross-chain checkers.");

		List<Future<?>> futures = new ArrayList<>();
		for (SmartContract contract : bridge) {
			futures.add(
					EVMLiSAExecutor.submit(xEVMLiSA.class, () -> runEventOrderChecker(bridge, contract)));
			futures.add(
					EVMLiSAExecutor.submit(xEVMLiSA.class, () -> runUncheckedExternalCallChecker(bridge, contract)));
			futures.add(
					EVMLiSAExecutor.submit(xEVMLiSA.class,
							() -> runUncheckedExternalInfluenceChecker(bridge, contract)));
			futures.add(
					EVMLiSAExecutor.submit(xEVMLiSA.class, () -> runMissingEventNotificationChecker(contract)));
			futures.add(
					EVMLiSAExecutor.submit(xEVMLiSA.class, () -> runAccessControlIncompleteness(bridge, contract)));
		}
		futures.add(
				EVMLiSAExecutor.submit(xEVMLiSA.class, () -> runLocalDependencyCheckers(bridge)));
		EVMLiSAExecutor.awaitCompletionFutures(futures);

		log.info("Saving cross-chain checkers results.");
		for (SmartContract contract : bridge)
			contract.setVulnerabilities(
					VulnerabilitiesObject.buildFromCFG(
							contract.getCFG()));

		EVMLiSAExecutor.shutdown(xEVMLiSA.class);
		log.info("[OUT] Cross-chain checkers results saved.");
	}

	/**
	 * Executes the Local Dependency analysis for all contracts in the given
	 * bridge. This method performs three phases in parallel across all
	 * contracts: (i) Identify vulnerable LOG statements for the Local
	 * Dependency Checker. (ii) Mark any CALLDATALOAD sites reachable from those
	 * LOGs as tainted. (iii) Run the core Local Dependency Checker logic on
	 * each contract.
	 *
	 * @param bridge the Bridge instance whose contracts will be analyzed
	 */
	public static void runLocalDependencyCheckers(Bridge bridge) {
		log.info("[IN] Running Local Dependency checker.");

		List<Future<?>> futures = new ArrayList<>();

		log.info("[LocalDependencyChecker] Computing vulnerable LOGs.");
		for (SmartContract contract : bridge)
			futures.add(
					EVMLiSAExecutor.submit(xEVMLiSA.class,
							() -> computeVulnerablesLOGsForLocalDependencyChecker(contract)));
		EVMLiSAExecutor.awaitCompletionFutures(futures);
		log.info("[LocalDependencyChecker] Vulnerable LOGs computed.");

		log.info("[LocalDependencyChecker] Computing tainted Call Data.");
		for (SmartContract contract : bridge)
			futures.add(
					EVMLiSAExecutor.submit(xEVMLiSA.class,
							() -> computeTaintedCallDataForLocalDependencyChecker(contract)));
		EVMLiSAExecutor.awaitCompletionFutures(futures);
		log.info("[LocalDependencyChecker] Tainted Call Data computed.");

		for (SmartContract contract : bridge)
			futures.add(
					EVMLiSAExecutor.submit(xEVMLiSA.class,
							() -> runLocalDependencyChecker(contract)));
		EVMLiSAExecutor.awaitCompletionFutures(futures);

		log.info("[OUT] Local Dependency checker ended.");
	}

	/**
	 * Runs the Unchecked External Influence Checker on a single contract. This
	 * sets up the LiSA analysis environment, registers the
	 * UncheckedExternalInfluenceChecker, and executes the analysis to find
	 * event emit influenced by unvalidated external inputs. Reports definite
	 * and possible findings to the configured cache.
	 *
	 * @param bridge   the Bridge providing the cross-chain CFG context
	 * @param contract the specific SmartContract to analyze
	 */
	public static void runUncheckedExternalInfluenceChecker(Bridge bridge, SmartContract contract) {
		log.info("[IN] Running unchecked external influence checker on {}.", contract.getName());

		// Setup configuration
		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
		program.addCodeMember(contract.getCFG());
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
		LiSA lisa = new LiSA(conf);

		// Unchecked external influence checker
		UncheckedExternalInfluenceChecker checker = new UncheckedExternalInfluenceChecker(contract, bridge.getXCFG());
		conf.semanticChecks.add(checker);
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(),
				new UncheckedExternalInfluenceAbstractDomain(),
				new TypeEnvironment<>(new InferredTypes()));
		lisa.run(program);

		log.info(
				"[OUT] Unchecked external influence checker ended on {}, with {} definite and {} possible vulnerabilities found.",
				contract.getName(),
				MyCache.getInstance().getUncheckedExternalInfluenceWarnings(contract.getCFG().hashCode()),
				MyCache.getInstance().getPossibleUncheckedExternalInfluenceWarnings(contract.getCFG().hashCode()));
	}

	public static void runAccessControlIncompleteness(Bridge bridge, SmartContract contract) {
		log.info("[IN] Running Access Control Incompleteness checker on {}.", contract.getName());

		// Setup configuration
		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
		program.addCodeMember(contract.getCFG());
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
		LiSA lisa = new LiSA(conf);

		AccessControlIncompletenessChecker checker = new AccessControlIncompletenessChecker();
		conf.semanticChecks.add(checker);
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(),
				new AccessControlIncompletenessAbstractDomain(),
				new TypeEnvironment<>(new InferredTypes()));
		lisa.run(program);

		log.info("[OUT] Access Control Incompleteness checker ended on {}, with {} vulnerabilities found.",
				contract.getName(),
				MyCache.getInstance().getUncheckedExternalCallWarnings(contract.getCFG().hashCode()));
	}

	/**
	 * Runs the Unchecked External Call Checker on a single contract. This
	 * configures and invokes LiSA with the UncheckedExternalCallChecker to
	 * detect any CALL, STATICCALL or DELEGATECALL instructions whose results
	 * directly influence event emit without proper validation.
	 *
	 * @param bridge   the Bridge providing the cross-chain CFG context
	 * @param contract the specific SmartContract to analyze
	 */
	public static void runUncheckedExternalCallChecker(Bridge bridge, SmartContract contract) {
		log.info("[IN] Running unchecked external call  checker on {}.", contract.getName());

		// Setup configuration
		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
		program.addCodeMember(contract.getCFG());
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
		LiSA lisa = new LiSA(conf);

		// Unchecked external call checker
		UncheckedExternalCallChecker checker = new UncheckedExternalCallChecker(contract, bridge.getXCFG());
		conf.semanticChecks.add(checker);
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new UncheckedExternalCallAbstractDomain(),
				new TypeEnvironment<>(new InferredTypes()));
		lisa.run(program);

		log.info("[OUT] Unchecked external call  checker ended on {}, with {} vulnerabilities found.",
				contract.getName(),
				MyCache.getInstance().getUncheckedExternalCallWarnings(contract.getCFG().hashCode()));
	}

	/**
	 * Executes the Event Order Checker on a single contract. For each public
	 * function: (i) Follow only successful return paths (STOP for void, RETURN
	 * otherwise). (ii) Collect any SSTORE and LOG instructions on that path.
	 * (iii) If LOGs occur without a preceding SSTORE, flag an event-order
	 * issue. (iv) Classify as definite if across a cross‑chain edge, else
	 * possible.
	 *
	 * @param bridge   the Bridge providing the cross-chain CFG context
	 * @param contract the specific SmartContract to analyze
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

					/*
					 * Only paths congruent with the function's return type need
					 * to be checked, i.e., if a function has return type void,
					 * then the function's exitpoint will be indicated by the
					 * Stop statement; if it returns something else, the
					 * exitpoint will be indicated by the Return statement
					 */
					if (function.getOutputParamCount() > 0
							&& exitpoint instanceof Stop)
						continue;
					if (function.getOutputParamCount() == 0
							&& exitpoint instanceof Return)
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
								MyCache.getInstance().addVulnerabilityPerFunction(cfg.hashCode(), warn);

							} else {
								String warn = "[POSSIBLE] Event Order vulnerability at " + emitEventLocation.getPc();

								log.warn(
										"[POSSIBLE] Event Order vulnerability at pc {} (line {}) coming from pc {} (line {}).",
										emitEventLocation.getPc(),
										emitEventLocation.getSourceCodeLine(),
										entrypointLocation.getPc(),
										entrypointLocation.getSourceCodeLine());

								MyCache.getInstance().addPossibleEventOrderWarning(cfg.hashCode(), warn);
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
	 * Executes the Missing Event Notification Checker on a single contract. For
	 * each public function: (i) Follow only successful return paths (STOP for
	 * void, RETURN otherwise). (ii) Identify any SSTORE instructions on that
	 * path. (iii) Ensure that each such SSTORE is followed by at least one LOG
	 * before termination. (iv) Flag any missing notifications as
	 * vulnerabilities.
	 *
	 * @param contract the SmartContract to analyze for missing event logs
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

					/*
					 * Only paths congruent with the function's return type need
					 * to be checked, i.e., if a function has return type void,
					 * then the function's exitpoint will be indicated by the
					 * Stop statement; if it returns something else, the
					 * exitpoint will be indicated by the Return statement
					 */
					if (function.getOutputParamCount() > 0
							&& exitpoint instanceof Stop)
						continue;
					if (function.getOutputParamCount() == 0
							&& exitpoint instanceof Return)
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
							MyCache.getInstance().addVulnerabilityPerFunction(cfg.hashCode(), warn);
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
	public static void computeVulnerablesLOGsForLocalDependencyChecker(SmartContract contract) {
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
	 * Computes and traces tainted call data in the context of the Local
	 * Dependency Checker. This method identifies and links call data loads that
	 * are reachable from vulnerable log statements via cross-chain edges,
	 * marking them as tainted.
	 *
	 * @param contract The smart contract to be analyzed.
	 */
	public static void computeTaintedCallDataForLocalDependencyChecker(SmartContract contract) {
		if (contract == null)
			return;

		try {
			Set<Statement> logsVulnerable = MyCache.getInstance()
					.getSetOfVulnerableLogStatementForLocalDependencyChecker();

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
									 * Only paths congruent with the function's
									 * return type need to be checked, i.e., if
									 * a function has return type void, then the
									 * function's exitpoint will be indicated by
									 * the Stop statement; if it returns
									 * something else, the exitpoint will be
									 * indicated by the Return statement
									 */
									if (functionLinked.getOutputParamCount() > 0
											&& exitpoint instanceof Stop)
										continue;
									if (functionLinked.getOutputParamCount() == 0
											&& exitpoint instanceof Return)
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
												"[computeTaintedCallData] Reachable with cross-chain edge: {} (line: {}, cfg: {}) -> {} (line: {}, cfg: {}). Event {} (contract {}) to function {}.",
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
	 * Runs the Local Dependency checker on the given smart contract.
	 *
	 * @param contract The smart contract to analyze for Local Dependency
	 *                     issues.
	 */
	public static void runLocalDependencyChecker(SmartContract contract) {
		// Setup configuration
		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
		program.addCodeMember(contract.getCFG());
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
		LiSA lisa = new LiSA(conf);

		// Local dependency checker
		LocalDependencyChecker checker = new LocalDependencyChecker(contract);
		conf.semanticChecks.add(checker);
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(),
				new LocalDependencyAbstractDomain(),
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
	}

	/**
	 * Prints the functions vulnerable of each smart contract in the given
	 * bridge.
	 *
	 * @param bridge The bridge containing the smart contracts to analyze for
	 *                   vulnerabilities.
	 */
	public static void printVulnerabilitiesPerFunction(Bridge bridge) {
		JSONObject json = new JSONObject();
		json.put("bridge", bridge.getName());

		JSONArray contracts = new JSONArray();

		for (SmartContract contract : bridge) {
			JSONObject contractJson = new JSONObject();
			contractJson.put("contract",
					contract.getName());
			contractJson.put("vulnerabilities",
					MyCache.getInstance().getVulnerabilityPerFunction(
							contract.getCFG().hashCode()));
			contracts.put(contractJson);
		}
		json.put("contracts", contracts);
		log.debug("Vulnerabilities per functions: {}", json.toString(4));
	}
}
