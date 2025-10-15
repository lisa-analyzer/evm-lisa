package it.unipr;

import it.unipr.analysis.*;
import it.unipr.analysis.contract.SmartContract;
import it.unipr.analysis.taint.RandomnessDependencyAbstractDomain;
import it.unipr.analysis.taint.TxOriginAbstractDomain;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Jump;
import it.unipr.cfg.Jumpi;
import it.unipr.checker.JumpSolver;
import it.unipr.checker.RandomnessDependencyChecker;
import it.unipr.checker.ReentrancyChecker;
import it.unipr.checker.TxOriginChecker;
import it.unipr.crosschain.xEVMLiSA;
import it.unipr.frontend.EVMFrontend;
import it.unipr.frontend.EVMLiSAFeatures;
import it.unipr.frontend.EVMLiSATypeSystem;
import it.unipr.utils.*;
import it.unive.lisa.LiSA;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.conf.LiSAConfiguration;
import it.unive.lisa.program.Program;
import it.unive.lisa.program.cfg.edge.SequentialEdge;
import it.unive.lisa.program.cfg.statement.Statement;
import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.commons.collections4.SetUtils;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * EVMLiSA is the entry point for analyzing EVM bytecode smart contracts using
 * LiSA. It generates a control flow graph (CFG) and applies various security
 * checkers.
 */
public class EVMLiSA {
	private static final Logger log = LogManager.getLogger(EVMLiSA.class);

	// Configuration
	private static boolean TEST_MODE = false;
	private static boolean PAPER_MODE = false;
	private static Path OUTPUT_DIRECTORY_PATH;

	/**
	 * Main entry point for EVMLiSA.
	 *
	 * @param args configuration options
	 */
	public static void main(String[] args) throws Exception {
		new EVMLiSA().go(args);
	}

	/**
	 * Sets the stack limit.
	 *
	 * @param limit the maximum stack size
	 */
	public static void setStackLimit(int limit) {
		AbstractStack.setStackLimit(limit);
	}

	/**
	 * Sets the stack set size.
	 *
	 * @param size the stack set size
	 */
	public static void setStackSetSize(int size) {
		AbstractStackSet.setStackSetSize(size);
	}

	/**
	 * Sets the working directory.
	 *
	 * @param workingDirectoryPath the path to the working directory
	 */
	public static void setWorkingDirectory(Path workingDirectoryPath) {
		EVMLiSA.OUTPUT_DIRECTORY_PATH = workingDirectoryPath;
		SmartContract.setWorkingDirectory(workingDirectoryPath);
	}

	/**
	 * Gets the working directory path.
	 *
	 * @return the path to the working directory
	 */
	public static Path getWorkingDirectory() {
		return EVMLiSA.OUTPUT_DIRECTORY_PATH;
	}

	/**
	 * Gets the number of available cores.
	 *
	 * @return the number of cores available
	 */
	public static int getCores() {
		return EVMLiSAExecutor.getCoresAvailable();
	}

	/**
	 * Sets the number of processing cores.
	 *
	 * @param cores the number of cores
	 */
	public static void setCores(int cores) {
		EVMLiSAExecutor.setCoresAvailable(cores);
	}

	/**
	 * Sets the linking of unsound jumps to all JUMPDEST instructions.
	 */
	public static void setLinkUnsoundJumpsToAllJumpdest() {
		JumpSolver.setLinkUnsoundJumpsToAllJumpdest();
	}

	/**
	 * Enables all security checkers (i.e., reentrancy, randomness dependency,
	 * tx.origin).
	 */
	public static void enableAllSecurityCheckers() {
		EVMLiSA.enableReentrancyChecker();
		EVMLiSA.enableRandomnessDependencyChecker();
		EVMLiSA.enableTxOriginChecker();
	}

	/**
	 * Enables the reentrancy checker.
	 */
	public static void enableReentrancyChecker() {
		ReentrancyChecker.enableChecker();
	}

	/**
	 * Enables the randomness dependency checker.
	 */
	public static void enableRandomnessDependencyChecker() {
		RandomnessDependencyChecker.enableChecker();
	}

	/**
	 * Enables the tx. origin checker.
	 */
	public static void enableTxOriginChecker() {
		TxOriginChecker.enableChecker();
	}

	/**
	 * Enables the test mode (i.e., it does not compute functions, events).
	 */
	public static void setTestMode() {
		TEST_MODE = true;
	}

	/**
	 * Disables the test mode (i.e., it computes functions, events).
	 */
	public static void disableTestMode() {
		TEST_MODE = false;
	}

	/**
	 * Checks if EVMLiSA is running in test mode.
	 *
	 * @return true if test mode is enabled, false otherwise
	 */
	public static boolean isInTestMode() {
		return TEST_MODE;
	}

	/**
	 * Checks if EVMLiSA is running in paper mode.
	 *
	 * @return true if paper mode is enabled, false otherwise
	 */
	public static boolean isInPaperMode() {
		return PAPER_MODE;
	}

	/**
	 * Enables the paper mode (i.e., statistics contains jump classifications as
	 * in the reference paper).
	 */
	public static void setPaperMode() {
		PAPER_MODE = true;
	}

	/**
	 * Disables the paper mode (i.e., statistics contains jump classifications
	 * as in the reference paper).
	 */
	public static void disablePaperMode() {
		PAPER_MODE = false;
	}

	/**
	 * Executes the analysis workflow.
	 *
	 * @param args command-line arguments
	 */
	private void go(String[] args) {
		CommandLine cmd = parseCommandLine(args);
		if (cmd == null)
			return;

		setupGlobalOptions(cmd);

		// Cross chain analysis
		if (cmd.hasOption("cross-chain-analysis")
				&& cmd.hasOption("bytecode-directory-path")
				&& cmd.hasOption("abi-directory-path")) {
			Path policyPath = null;
			if (cmd.hasOption("cross-chain-policy"))
				policyPath = Path.of(cmd.getOptionValue("cross-chain-policy"));

			xEVMLiSA.runAnalysis(
					Path.of(cmd.getOptionValue("bytecode-directory-path")),
					Path.of(cmd.getOptionValue("abi-directory-path")),
					policyPath);
			return;
		}

		// Benchmark case
		if (cmd.hasOption("benchmark")) {
			EVMLiSA.analyzeSetOfContracts(Path.of(cmd.getOptionValue("benchmark")));
			return;
		}

		// Ensure that at least one valid option is provided to specify the
		// bytecode source
		if (!cmd.hasOption("address")
				&& !cmd.hasOption("bytecode-path")
				&& !cmd.hasOption("bytecode")) {
			log.error("Address, bytecode or filepath required.");
			new HelpFormatter().printHelp("help", getOptions());
			System.exit(1);
		}

		SmartContract contract = null;

		// Single analysis case (address)
		if (cmd.hasOption("address"))
			contract = new SmartContract(cmd.getOptionValue("address"));

		// Single analysis case (bytecode and abi as a path)
		else if (cmd.hasOption("bytecode-path") && cmd.hasOption("abi-path"))
			contract = new SmartContract(
					Path.of(cmd.getOptionValue("bytecode-path")),
					Path.of(cmd.getOptionValue("abi-path")));

		// Single analysis case (bytecode as a path)
		else if (cmd.hasOption("bytecode-path"))
			contract = new SmartContract(
					Path.of(cmd.getOptionValue("bytecode-path")));

		// Single analysis case (bytecode as a string)
		else if (cmd.hasOption("bytecode")) {
			contract = new SmartContract()
					.setBytecode(cmd.getOptionValue("bytecode"));
			if (cmd.hasOption("abi"))
				contract.setAbi(cmd.getOptionValue("abi"));
		}

		else {
			JSONManager.throwNewError("No valid option provided.");
			new HelpFormatter().printHelp("help", getOptions());
			System.exit(1);
		}

		EVMLiSA.analyzeContract(contract);
		System.err.println(contract);
	}

	/**
	 * Analyzes a set of smart contracts from a given file.
	 *
	 * @param filePath the path to the file containing contract addresses
	 */
	public static void analyzeSetOfContracts(Path filePath) {
		log.info("Building contracts.");
		List<SmartContract> contracts = buildContractsFromFile(filePath);
		analyzeSetOfContracts(contracts);
	}

	/**
	 * Analyzes a set of smart contracts from a list of {@link SmartContract}.
	 *
	 * @param contracts the list of {@link SmartContract} to be analyzed
	 */
	public static void analyzeSetOfContracts(List<SmartContract> contracts) {
		log.info("Analyzing {} contracts.", contracts.size());

		List<Future<?>> futures = new ArrayList<>();

		for (SmartContract contract : contracts)
			futures.add(EVMLiSAExecutor.submit(EVMLiSA.class, () -> analyzeContract(contract)));

		log.debug("{} contracts submitted to Thread pool with {} workers.", contracts.size(),
				EVMLiSAExecutor.getCoresAvailable());

		EVMLiSAExecutor.awaitCompletionFutures(futures);

		log.info("Finished analysis of {} contracts.", contracts.size());

		Path outputDir = OUTPUT_DIRECTORY_PATH.resolve("set-of-contracts");
		try {
			Files.createDirectories(outputDir);
			Files.writeString(
					outputDir.resolve("results.json"),
					JSONManager.aggregateSmartContractsToJson(contracts).toString(4),
					StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
			log.info("Results saved in {}", outputDir.resolve("results.json"));
		} catch (IOException e) {
			System.err.println(JSONManager.throwNewError("Failed to save results in " + outputDir));
			System.exit(1);
		}

		EVMLiSAExecutor.shutdown(EVMLiSA.class);
	}

	/**
	 * Builds the Control Flow Graph (CFG) for the given smart contract. This
	 * method generates the CFG from the contract's mnemonic bytecode,
	 * configures and runs the LiSA analysis, and stores the computed CFG and
	 * statistics in the contract object.
	 *
	 * @param contract the smart contract for which the CFG is to be built
	 */
	public static void buildCFG(SmartContract contract) {
		if (contract == null)
			return;

		log.info("[IN] Building CFG of contract {}.", contract.getName());

		Program program = null;
		try {
			program = EVMFrontend.generateCfgFromFile(contract.getMnemonicBytecodePath().toString());
		} catch (IOException e) {
			System.err.println(
					JSONManager.throwNewError("Unable to generate partial CFG from file.", contract.toJson()));
			System.exit(1);
		}

		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract, true);
		if (TEST_MODE)
			conf = LiSAConfigurationManager.createConfiguration(contract);
		JumpSolver checker = new JumpSolver();
		conf.semanticChecks.add(checker);

		LiSA lisa = new LiSA(conf);

		long startTime = System.currentTimeMillis();
		lisa.run(program);
		contract.setExecutionTime(System.currentTimeMillis() - startTime);

		log.info("[OUT] CFG of contract {} built.", contract.getName());
		log.info("[IN] Computing statistics of contract {}.", contract.getName());
		contract.setStatistics(
				computeStatistics(checker, lisa, program));
		contract.setCFG(checker.getComputedCFG());

		log.debug("[OUT] Contract {} statistics: {}", contract.getAddress(), contract.getStatistics());

		if (TEST_MODE)
			return;

		log.info("[IN] Computing functions and events of contract {}.", contract.getName());
		contract.computeFunctionsSignatureEntryPoints();
		contract.computeFunctionsSignatureExitPoints();
		contract.computeEventsSignatureEntryPoints();
		contract.computeEventsExitPoints();
		log.info("[OUT] Functions and events of contract {} computed.", contract.getName());
	}

	/**
	 * Runs all enabled security checkers on the given smart contract. This
	 * method executes various security checkers (e.g., Reentrancy, TxOrigin,
	 * and Randomness Dependency checkers) on the computed CFG of the contract.
	 * It then stores the detected vulnerabilities in the contract object.
	 *
	 * @param contract the smart contract on which security checkers are
	 *                     executed
	 */
	public static void runCheckers(SmartContract contract) {
		if (contract == null || contract.getCFG() == null)
			return;

		log.info("[IN] Running checkers on contract {}.", contract.getName());

		if (ReentrancyChecker.isEnabled())
			runReentrancyChecker(contract);
		if (TxOriginChecker.isEnabled())
			runTxOriginChecker(contract);
		if (RandomnessDependencyChecker.isEnabled())
			runRandomnessDependencyChecker(contract);

		contract.setVulnerabilities(
				VulnerabilitiesObject.buildFromCFG(
						contract.getCFG()));

		log.info("[OUT] Checkers run on contract {}.", contract.getName());
	}

	/**
	 * Analyzes a given smart contract.
	 *
	 * @param contract the smart contract to analyze
	 */
	public static void analyzeContract(SmartContract contract) {
		log.info("[IN] Analyzing contract {}.", contract.getName());

		buildCFG(contract);

		if (!TEST_MODE) {
			runCheckers(contract);
			contract.generateCFGWithBasicBlocks();
			contract.toFile();
		}

		log.info("[OUT] Analysis ended of contract {}.", contract.getName());
	}

	/**
	 * Runs the reentrancy checker on the given smart contract.
	 *
	 * @param contract The smart contract to analyze.
	 */
	public static void runReentrancyChecker(SmartContract contract) {
		log.info("[IN] Running reentrancy checker on {}.", contract.getName());

		// Setup configuration
		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
		program.addCodeMember(contract.getCFG());
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
		LiSA lisa = new LiSA(conf);

		// Reentrancy checker
		ReentrancyChecker checker = new ReentrancyChecker();
		conf.semanticChecks.add(checker);
		lisa.run(program);

		log.info("[OUT] Reentrancy checker ended on {}, with {} vulnerabilities found.",
				contract.getName(),
				MyCache.getInstance().getReentrancyWarnings(contract.getCFG().hashCode()));
	}

	/**
	 * Runs the randomness dependency checker on the given smart contract.
	 *
	 * @param contract The smart contract to analyze.
	 */
	public static void runRandomnessDependencyChecker(SmartContract contract) {
		log.info("[IN] Running randomness dependency checker on {}.", contract.getName());

		// Setup configuration
		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
		program.addCodeMember(contract.getCFG());
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
		LiSA lisa = new LiSA(conf);

		// Randomness dependency checker
		RandomnessDependencyChecker checker = new RandomnessDependencyChecker();
		conf.semanticChecks.add(checker);
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(),
				new RandomnessDependencyAbstractDomain(),
				new TypeEnvironment<>(new InferredTypes()));
		lisa.run(program);

		log.info(
				"[OUT] Randomness dependency checker ended on {}, with {} definite and {} possible vulnerabilities found.",
				contract.getName(),
				MyCache.getInstance().getRandomnessDependencyWarnings(contract.getCFG().hashCode()),
				MyCache.getInstance().getPossibleRandomnessDependencyWarnings(contract.getCFG().hashCode()));
	}

	/**
	 * Runs the tx. origin checker on the given smart contract.
	 *
	 * @param contract The smart contract to analyze.
	 */
	public static void runTxOriginChecker(SmartContract contract) {
		log.info("[IN] Running tx. origin checker on {}.", contract.getName());

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

		log.info("[OUT] Tx. origin checker ended on {}, with {} vulnerabilities found.",
				contract.getName(),
				MyCache.getInstance().getTxOriginWarnings(contract.getCFG().hashCode()));
	}

	/**
	 * Computes statistics based on the analysis of jumps within the given
	 * program.
	 *
	 * @param checker the jump solver used for the analysis
	 * @param lisa    the LiSA framework instance
	 * @param program the program being analyzed
	 *
	 * @return a {@link StatisticsObject} containing the computed statistics
	 */
	public static StatisticsObject<?> computeStatistics(JumpSolver checker, LiSA lisa, Program program) {
		Set<Statement> soundlySolved = getSoundlySolvedJumps(checker, lisa, program);
		if (PAPER_MODE)
			return computePaperJumps(checker, soundlySolved);
		return computeJumps(checker, soundlySolved);
	}

	/**
	 * Computes jump-related statistics based on the analysis results.
	 *
	 * @param checker       the jump solver used for analysis
	 * @param soundlySolved the set of jumps that have been soundly solved
	 *
	 * @return a {@link StatisticsObject} containing the computed jump
	 *             statistics
	 */
	private static StatisticsObject<?> computeJumps(JumpSolver checker, Set<Statement> soundlySolved) {
		EVMCFG cfg = checker.getComputedCFG();
		Set<Statement> unreachableJumpNodes = checker.getUnreachableJumps();

		int resolvedJumps = 0;
		int definitelyUnreachable = 0;
		int maybeUnreachable = 0;
		int unsoundJumps = 0;
		int maybeUnsoundJumps = 0;

		boolean allJumpAreSound = true;

		if (cfg.getEntrypoints().stream().findAny().isEmpty()) {
			log.warn("There are no entrypoints.");
			return null;
		}

		Statement entryPoint = cfg.getEntrypoints().stream().findAny().get();
		Set<Statement> pushedJumps = cfg.getAllPushedJumps();

		if (!JumpSolver.getLinkUnsoundJumpsToAllJumpdest())
			for (Statement jumpNode : cfg.getAllJumps()) {
				if (pushedJumps.contains(jumpNode))
					continue;

				Set<StackElement> topStackValuesPerJump = checker.getTopStackValuesPerJump(jumpNode);

				if (topStackValuesPerJump != null && topStackValuesPerJump.contains(StackElement.TOP)) {
					allJumpAreSound = false;
					break;
				}
			}

		// we are safe supposing that we have a single entry point
		for (Statement jumpNode : cfg.getAllJumps()) {
			if ((jumpNode instanceof Jump) || (jumpNode instanceof Jumpi)) {
				Set<StackElement> topStackValuesPerJump = checker.getTopStackValuesPerJump(jumpNode);

				if (pushedJumps.contains(jumpNode)) {
					resolvedJumps++;
					continue;
				}

				boolean reachableFrom = cfg.reachableFrom(entryPoint, jumpNode);
				if (reachableFrom && unreachableJumpNodes.contains(jumpNode)) {
					definitelyUnreachable++;
					continue;
				}
				if (!reachableFrom) {
					if (allJumpAreSound)
						definitelyUnreachable++;
					else
						maybeUnreachable++;
					continue;
				}
				if (topStackValuesPerJump == null) {
					// If all stacks are bottom, then we have a
					// definitelyUnreachable
					definitelyUnreachable++;
					continue;
				}
				if (!topStackValuesPerJump.contains(StackElement.TOP)) {
					// If the elements at the top of the stacks are all
					// different from TOP, then we are sure that it
					// is resolved
					resolvedJumps++;
					continue;
				}
				if (checker.getMaybeUnsoundJumps().contains(jumpNode)) {
					maybeUnsoundJumps++;
					continue;
				}
				if (!soundlySolved.contains(jumpNode)) {
					unsoundJumps++;
					log.error("{} not solved", jumpNode);
					log.error("getTopStackValuesPerJump: {}", topStackValuesPerJump);
					continue;
				}

				resolvedJumps++;
			}
		}

		StandardStatisticsObject stats = StandardStatisticsObject.newStatisticsObject()
				.totalOpcodes(cfg.getOpcodeCount())
				.totalJumps(cfg.getAllJumps().size())
				.totalEdges(cfg.getEdges().size())
				.resolvedJumps(resolvedJumps)
				.definitelyUnreachableJumps(definitelyUnreachable)
				.maybeUnreachableJumps(maybeUnreachable)
				.unsoundJumps(unsoundJumps)
				.maybeUnsoundJumps(maybeUnsoundJumps)
				.build();

		return stats;
	}

	/**
	 * Computes jump-related statistics based on the analysis results, with the
	 * same classification of the reference paper.
	 *
	 * @param checker       the jump solver used for analysis
	 * @param soundlySolved the set of jumps that have been soundly solved
	 *
	 * @return a {@link StatisticsObject} containing the computed jump
	 *             statistics
	 */
	private static StatisticsObject<?> computePaperJumps(JumpSolver checker, Set<Statement> soundlySolved) {
		EVMCFG cfg = checker.getComputedCFG();

		int resolved = 0;
		int unreachable = 0;
		int erroneous = 0;
		int unknown = 0;
		int topState = 0;

		if (cfg.getEntrypoints().stream().findAny().isEmpty()) {
			log.warn("There are no entrypoints.");
			return null;
		}

		Statement entryPoint = cfg.getEntrypoints().stream().findAny().get();

		// we are safe supposing that we have a single entry point
		for (Statement jumpNode : cfg.getAllJumps())
			if ((jumpNode instanceof Jump) || (jumpNode instanceof Jumpi))
				if (cfg.getAllPushedJumps().contains(jumpNode))
					// stacks of pushed jumps are not stored for optimization
					resolved++;
				else if (soundlySolved.contains(jumpNode))
					// soundlySolved contains getMaybeUnsoundJumps() (whole
					// value state went to top)
					// and getUnsoundJumps() (at least one stack has top on
					// front)
					unknown++;
				else if (checker.getUnsoundJumps().contains(jumpNode))
					// getUnsoundJumps() contains jumps where at least one top
					// stack is top
					unknown++;
				else if (checker.getMaybeUnsoundJumps().contains(jumpNode)) {
					// getMaybeUnsoundJumps() contains jumps where the whole
					// value state went to top
					unknown++;
					topState++;
				} else if (!cfg.reachableFrom(entryPoint, jumpNode) || checker.getUnreachableJumps().contains(jumpNode))
					// getUnreachableJumps() contains jumps where the whole
					// value state went to bottom
					unreachable++;
				else {
					Set<StackElement> topStacks = checker.getTopStackValuesPerJump(jumpNode);
					if (topStacks.isEmpty())
						unreachable++;
					else if (topStacks.stream().allMatch(StackElement::isBottom))
						erroneous++;
					else if (topStacks.stream().anyMatch(StackElement::isTop))
						unknown++;
					else
						resolved++;
				}

		PaperStatisticsObject stats = PaperStatisticsObject.newStatisticsObject()
				.totalOpcodes(cfg.getOpcodeCount())
				.totalJumps(cfg.getAllJumps().size())
				.totalEdges(cfg.getEdges().size())
				.resolved(resolved)
				.unknown(unknown)
				.unreachable(unreachable)
				.erroneous(erroneous)
				.topState(topState)
				.build();

		return stats;
	}

	/**
	 * Computes the set of jumps that are soundly solved by the JumpSolver. This
	 * method applies an iterative approach to resolve unsound jumps by
	 * conservatively attaching them to all jump destinations, as per the
	 * configuration.
	 *
	 * @param checker the {@link JumpSolver} instance responsible for resolving
	 *                    jumps
	 * @param lisa    the {@link LiSA} instance used to perform static analysis
	 * @param program the {@link Program} containing the code being analyzed
	 *
	 * @return a {@link Set} of {@link Statement} objects representing the
	 *             soundly solved jumps after applying the iterative resolution
	 *             process
	 */
	private static Set<Statement> getSoundlySolvedJumps(JumpSolver checker, LiSA lisa, Program program) {
		HashSet<Statement> soundlySolved = new HashSet<>();
		if (JumpSolver.getLinkUnsoundJumpsToAllJumpdest()) {
			int currentIteration = 0;
			int MAX_ITER = 5;
			boolean fixpoint;
			do {
				fixpoint = false;
				EVMCFG cfg = checker.getComputedCFG();
				Set<Statement> jumpdestNodes = cfg.getAllJumpdest();
				Set<Statement> unsoundJumps = checker.getUnsoundJumps();
				Set<Statement> maybeUnsoundJumps = checker.getMaybeUnsoundJumps();
				Set<Statement> unsound = unsoundJumps == null ? Collections.emptySet() : unsoundJumps;
				unsound = maybeUnsoundJumps == null ? unsound : SetUtils.union(unsound, maybeUnsoundJumps);
				for (Statement unsoundNode : unsound)
					if (!soundlySolved.contains(unsoundNode)) {
						fixpoint = true;
						for (Statement jumpdest : jumpdestNodes)
							cfg.addEdge(new SequentialEdge(unsoundNode, jumpdest));
					}

				soundlySolved.addAll(unsound);

				program.addCodeMember(cfg);
				lisa.run(program);
			} while (fixpoint && ++currentIteration < MAX_ITER);
		}
		return soundlySolved;
	}

	/**
	 * Builds a list of smart contracts from a given file.
	 *
	 * @param filePath the path to the file containing contract addresses
	 *
	 * @return a list of {@link SmartContract} objects
	 */
	public static List<SmartContract> buildContractsFromFile(Path filePath) {
		log.info("Parsing contracts from {}", filePath);

		List<SmartContract> contracts = new ArrayList<>();

		try {
			File myObj = new File(String.valueOf(filePath));
			Scanner myReader = new Scanner(myObj);
			int counter = 0;

			while (myReader.hasNextLine()) {
				String address = myReader.nextLine();
				contracts.add(new SmartContract(address));
				log.info("Created contract ({}): {}", ++counter, address);
			}
			myReader.close();

		} catch (FileNotFoundException e) {
			JSONManager.throwNewError("Unable to read " + filePath + ". File not found.");
			System.exit(1);
		}

		log.info("Created {} contracts.", contracts.size());
		return contracts;
	}

	/**
	 * Sets up global options based on command-line arguments.
	 *
	 * @param cmd the parsed command line arguments
	 */
	private void setupGlobalOptions(CommandLine cmd) {
		try {
			EVMLiSAExecutor
					.setCoresAvailable(cmd.hasOption("cores") ? Integer.parseInt(cmd.getOptionValue("cores")) : 1);
		} catch (Exception e) {
			log.warn("Cores set to 1: {}", e.getMessage());
			EVMLiSAExecutor.setCoresAvailable(1);
		}

		if (cmd.hasOption("checker-reentrancy") || cmd.hasOption("checker-all"))
			ReentrancyChecker.enableChecker();
		if (cmd.hasOption("checker-txorigin") || cmd.hasOption("checker-all"))
			TxOriginChecker.enableChecker();
		if (cmd.hasOption("checker-randomnessdependency") || cmd.hasOption("checker-all"))
			RandomnessDependencyChecker.enableChecker();

		if (cmd.hasOption("output-directory-path"))
			OUTPUT_DIRECTORY_PATH = Path.of(cmd.getOptionValue("output-directory-path"));
		else
			OUTPUT_DIRECTORY_PATH = Path.of("outputs", MyTimestampUtil.getCurrentTimestamp());
		SmartContract.setWorkingDirectory(OUTPUT_DIRECTORY_PATH);

		try {
			if (cmd.hasOption("stack-size"))
				AbstractStack.setStackLimit(Integer.parseInt(cmd.getOptionValue("stack-size")));

			if (cmd.hasOption("stack-set-size"))
				AbstractStackSet.setStackSetSize(Integer.parseInt(cmd.getOptionValue("stack-set-size")));
		} catch (NumberFormatException e) {
			System.err.println(JSONManager.throwNewError("Size must be an integer."));
			System.exit(1);
		}

		if (cmd.hasOption("link-unsound-jumps-to-all-jumpdest"))
			JumpSolver.setLinkUnsoundJumpsToAllJumpdest();
		if (cmd.hasOption("use-live-storage") && (cmd.hasOption("address") || cmd.hasOption("benchmark")))
			EVMAbstractState.setUseStorageLive();
		if (cmd.hasOption("etherscan-api-key"))
			EtherscanAPIManager.setAPIKey(cmd.getOptionValue("etherscan-api-key"));
		if (cmd.hasOption("test-mode"))
			EVMLiSA.setTestMode();
		if (cmd.hasOption("paper-stats"))
			EVMLiSA.setPaperMode();
		if (cmd.hasOption("show-all-instructions-in-cfg"))
			DOTFileManager.showAllInstructions();
	}

	/**
	 * Builds and returns the command-line options for EVMLiSA.
	 *
	 * @return the configured Options object containing all available
	 *             command-line parameters
	 */
	private Options getOptions() {
		Options options = new Options();

		// String parameters
		Option addressOption = Option.builder("a")
				.longOpt("address")
				.desc("Address of an Ethereum smart contract.")
				.required(false)
				.hasArg(true)
				.build();

		Option bytecodePathOption = Option.builder()
				.longOpt("bytecode-path")
				.desc("Filepath of the bytecode file.")
				.required(false)
				.hasArg(true)
				.build();

		Option abiPathOption = Option.builder()
				.longOpt("abi-path")
				.desc("Filepath of the abi file.")
				.required(false)
				.hasArg(true)
				.build();

		Option outputDirectoryPathOption = Option.builder()
				.longOpt("output-directory-path")
				.desc("Filepath of the output directory.")
				.required(false)
				.hasArg(true)
				.build();

		Option bytecodeOption = Option.builder("b")
				.longOpt("bytecode")
				.desc("Bytecode to be analyzed (e.g., 0x6080...).")
				.required(false)
				.hasArg(true)
				.build();

		Option abiOption = Option.builder()
				.longOpt("abi")
				.desc("ABI of the bytecode to be analyzed (JSON format).")
				.required(false)
				.hasArg(true)
				.build();

		Option stackSizeOption = Option.builder()
				.longOpt("stack-size")
				.desc("Dimension of stack (default: 32).")
				.required(false)
				.hasArg(true)
				.build();

		Option stackSetSizeOption = Option.builder()
				.longOpt("stack-set-size")
				.desc("Dimension of stack-set (default: 8).")
				.required(false)
				.hasArg(true)
				.build();

		Option benchmarkOption = Option.builder()
				.longOpt("benchmark")
				.desc("Filepath of the benchmark.")
				.required(false)
				.hasArg(true)
				.build();

		Option coresOption = Option.builder("c")
				.longOpt("cores")
				.desc("Number of cores used in benchmark.")
				.required(false)
				.hasArg(true)
				.build();

		Option useStorageLiveOption = Option.builder()
				.longOpt("use-live-storage")
				.desc("Use the live storage in SLOAD.")
				.required(false)
				.hasArg(false)
				.build();

		Option linkUnsoundJumpsToAllJumpdestOption = Option.builder()
				.longOpt("link-unsound-jumps-to-all-jumpdest")
				.desc("Link all the unsound jumps to all jumpdest.")
				.required(false)
				.hasArg(false)
				.build();

		Option enableAllCheckerOption = Option.builder()
				.longOpt("checker-all")
				.desc("Enable all security checkers.")
				.required(false)
				.hasArg(false)
				.build();

		Option enableReentrancyCheckerOption = Option.builder()
				.longOpt("checker-reentrancy")
				.desc("Enable reentrancy checker.")
				.required(false)
				.hasArg(false)
				.build();

		Option enableTxOriginCheckerOption = Option.builder()
				.longOpt("checker-txorigin")
				.desc("Enable tx-origin checker.")
				.required(false)
				.hasArg(false)
				.build();

		Option enableRandomnessDependencyCheckerOption = Option.builder()
				.longOpt("checker-randomnessdependency")
				.desc("Enable randomness-dependency checker.")
				.required(false)
				.hasArg(false)
				.build();

		Option etherscanAPIKeyOption = Option.builder()
				.longOpt("etherscan-api-key")
				.desc("Insert your Etherscan API key.")
				.required(false)
				.hasArg(true)
				.build();

		Option useTestModeOption = Option.builder()
				.longOpt("test-mode")
				.desc("Use the test mode (i.e., do not compute functions and events).")
				.required(false)
				.hasArg(false)
				.build();

		Option usePaperStats = Option.builder()
				.longOpt("paper-stats")
				.desc("In each contract statistics, classify jumps using the same categories of the reference paper.")
				.required(false)
				.hasArg(false)
				.build();

		Option enableCrossChainAnalysisOption = Option.builder()
				.longOpt("cross-chain-analysis")
				.desc("Run a cross-chain analysis.")
				.required(false)
				.hasArg(false)
				.build();

		Option crossChainPolicyOption = Option.builder()
				.longOpt("cross-chain-policy")
				.desc("Import a cross-chain policy.")
				.required(false)
				.hasArg(true)
				.build();

		Option crossChainBytecodeDirectoryPathOption = Option.builder()
				.longOpt("bytecode-directory-path")
				.desc("Directory path of bytecode files.")
				.required(false)
				.hasArg(true)
				.build();

		Option crossChainAbiDirectoryPathOption = Option.builder()
				.longOpt("abi-directory-path")
				.desc("Directory path of abi files.")
				.required(false)
				.hasArg(true)
				.build();

		Option showAllInstructionsInCFG = Option.builder()
				.longOpt("show-all-instructions-in-cfg")
				.desc("Show all instructions in the Control Flow Graph representation.")
				.required(false)
				.hasArg(false)
				.build();

		options.addOption(addressOption);
		options.addOption(bytecodeOption);
		options.addOption(bytecodePathOption);
		options.addOption(abiPathOption);
		options.addOption(stackSizeOption);
		options.addOption(stackSetSizeOption);
		options.addOption(benchmarkOption);
		options.addOption(coresOption);
		options.addOption(useStorageLiveOption);
		options.addOption(linkUnsoundJumpsToAllJumpdestOption);
		options.addOption(enableAllCheckerOption);
		options.addOption(enableReentrancyCheckerOption);
		options.addOption(enableTxOriginCheckerOption);
		options.addOption(enableRandomnessDependencyCheckerOption);
		options.addOption(outputDirectoryPathOption);
		options.addOption(etherscanAPIKeyOption);
		options.addOption(abiOption);
		options.addOption(useTestModeOption);
		options.addOption(usePaperStats);
		options.addOption(showAllInstructionsInCFG);
		options.addOption(enableCrossChainAnalysisOption);
		options.addOption(crossChainBytecodeDirectoryPathOption);
		options.addOption(crossChainAbiDirectoryPathOption);
		options.addOption(crossChainPolicyOption);

		return options;
	}

	/**
	 * Parses the command-line arguments into a CommandLine object.
	 *
	 * @param args the command-line arguments to parse
	 *
	 * @return the parsed CommandLine object, or null if parsing fails
	 */
	private CommandLine parseCommandLine(String[] args) {
		Options options = getOptions();
		CommandLineParser parser = new DefaultParser();
		HelpFormatter formatter = new HelpFormatter();

		try {
			return parser.parse(options, args);
		} catch (ParseException e) {
			log.error(e.getMessage());
			formatter.printHelp("help", options);
			System.exit(1);
			return null;
		}
	}
}
