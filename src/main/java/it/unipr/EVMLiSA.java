package it.unipr;

import it.unipr.analysis.*;
import it.unipr.analysis.contract.SmartContract;
import it.unipr.analysis.taint.TimestampDependencyAbstractDomain;
import it.unipr.analysis.taint.TxOriginAbstractDomain;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Jump;
import it.unipr.cfg.Jumpi;
import it.unipr.checker.JumpSolver;
import it.unipr.checker.ReentrancyChecker;
import it.unipr.checker.TimestampDependencyChecker;
import it.unipr.checker.TxOriginChecker;
import it.unipr.frontend.EVMFrontend;
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
	private static int CORES = 1;
	private static boolean TEST_MODE = false;
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
	 * Sets the number of processing cores.
	 *
	 * @param cores the number of cores
	 */
	public static void setCores(int cores) {
		if (cores > Runtime.getRuntime().availableProcessors())
			cores = Runtime.getRuntime().availableProcessors() - 1;
		EVMLiSA.CORES = Math.max(cores, 1);
	}

	/**
	 * Sets the linking of unsound jumps to all JUMPDEST instructions.
	 */
	public static void setLinkUnsoundJumpsToAllJumpdest() {
		JumpSolver.setLinkUnsoundJumpsToAllJumpdest();
	}

	/**
	 * Enables all security checkers.
	 */
	public static void enableAllSecurityCheckers() {
		EVMLiSA.enableReentrancyChecker();
		EVMLiSA.enableTimestampDependencyCheckerChecker();
		EVMLiSA.enableTxOriginChecker();
	}

	/**
	 * Enables the reentrancy checker.
	 */
	public static void enableReentrancyChecker() {
		ReentrancyChecker.enableChecker();
	}

	/**
	 * Enables the timestamp dependency checker.
	 */
	public static void enableTimestampDependencyCheckerChecker() {
		TimestampDependencyChecker.enableChecker();
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
	 * Executes the analysis workflow.
	 *
	 * @param args command-line arguments
	 */
	private void go(String[] args) {
		CommandLine cmd = parseCommandLine(args);
		if (cmd == null)
			return;

		setupGlobalOptions(cmd);

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
		log.info("Building contracts...");
		List<SmartContract> contracts = buildContractsFromFile(filePath);
		analyzeSetOfContracts(contracts);
	}

	/**
	 * Analyzes a set of smart contracts from a list of {@link SmartContract}.
	 *
	 * @param contracts the list of {@link SmartContract} to be analyzed
	 */
	public static void analyzeSetOfContracts(List<SmartContract> contracts) {
		log.info("Analyzing {} contracts...", contracts.size());

		ExecutorService executor = Executors.newFixedThreadPool(CORES);
		List<Future<?>> futures = new ArrayList<>();

		for (SmartContract contract : contracts)
			futures.add(executor.submit(() -> analyzeContract(contract)));

		log.info("{} contracts submitted to Thread pool with {} workers.", contracts.size(), CORES);

		waitForCompletion(futures);

		executor.shutdown();
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
	}

	/**
	 * Analyzes a given smart contract.
	 *
	 * @param contract the smart contract to analyze
	 */
	public static void analyzeContract(SmartContract contract) {
		log.info("Analyzing contract {}...", contract.getAddress());

		Program program = null;
		try {
			program = EVMFrontend.generateCfgFromFile(contract.getMnemonicBytecodePath().toString());
		} catch (IOException e) {
			System.err.println(
					JSONManager.throwNewError("Unable to generate partial CFG from file", contract.toJson()));
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

		log.info("Analysis ended {}", contract.getAddress());

		contract.setStatistics(
				computeStatistics(checker, lisa, program));
		contract.setCFG(checker.getComputedCFG());

		if (TEST_MODE)
			return;

		contract.computeFunctionsSignatureEntryPoints();
		contract.computeFunctionsSignatureExitPoints();
		contract.computeEventsSignatureEntryPoints();
		contract.computeEventsExitPoints();

		if (ReentrancyChecker.isEnabled()) {
			log.info("Running reentrancy checker...");
			conf.semanticChecks.clear();
			conf.semanticChecks.add(new ReentrancyChecker());
			lisa.run(program);
			log.info("{} vulnerabilities found",
					MyCache.getInstance().getReentrancyWarnings(checker.getComputedCFG().hashCode()));
		}
		if (TxOriginChecker.isEnabled()) {
			log.info("Running tx. origin checker...");
			conf.semanticChecks.clear();
			conf.semanticChecks.add(new TxOriginChecker());
			conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new TxOriginAbstractDomain(),
					new TypeEnvironment<>(new InferredTypes()));
			lisa.run(program);
			log.info("{} vulnerabilities found",
					MyCache.getInstance().getTxOriginWarnings(checker.getComputedCFG().hashCode()));
		}
		if (TimestampDependencyChecker.isEnabled()) {
			log.info("Running timestamp dependency checker...");
			conf.semanticChecks.clear();
			conf.semanticChecks.add(new TimestampDependencyChecker());
			conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(),
					new TimestampDependencyAbstractDomain(),
					new TypeEnvironment<>(new InferredTypes()));
			lisa.run(program);
			log.info("{} vulnerabilities found",
					MyCache.getInstance().getTimestampDependencyWarnings(checker.getComputedCFG().hashCode()));
		}

		contract.setVulnerabilities(
				VulnerabilitiesObject.newVulnerabilitiesObject()
						.reentrancy(
								MyCache.getInstance().getReentrancyWarnings(checker.getComputedCFG().hashCode()))
						.txOrigin(MyCache.getInstance().getTxOriginWarnings(checker.getComputedCFG().hashCode()))
						.timestamp(MyCache.getInstance()
								.getTimestampDependencyWarnings(checker.getComputedCFG().hashCode()))
						.build());
		contract.generateCFGWithBasicBlocks();
		contract.toFile();
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
	public static StatisticsObject computeStatistics(JumpSolver checker, LiSA lisa, Program program) {
		Set<Statement> soundlySolved = getSoundlySolvedJumps(checker, lisa, program);
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
	private static StatisticsObject computeJumps(JumpSolver checker, Set<Statement> soundlySolved) {
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
					// maybeFakeMissedJump
					definitelyUnreachable++;
					continue;
				}
				if (!topStackValuesPerJump.contains(StackElement.TOP)) {
					// If the elements at the top of the stacks are all
					// different from NUMERIC_TOP, then we are sure that it
					// is definitelyFakeMissedJumps
					resolvedJumps++;
					continue;
				}
				if (soundlySolved != null && !soundlySolved.contains(jumpNode)) {
					unsoundJumps++;
					log.error("{} not solved", jumpNode);
					log.error("getTopStackValuesPerJump: {}", topStackValuesPerJump);
					continue;
				}
				if (checker.getMaybeUnsoundJumps().contains(jumpNode)) {
					maybeUnsoundJumps++;
					continue;
				}

				resolvedJumps++;
			}
		}

		StatisticsObject stats = StatisticsObject.newStatisticsObject()
				.totalOpcodes(cfg.getOpcodeCount())
				.totalJumps(cfg.getAllJumps().size())
				.resolvedJumps(resolvedJumps)
				.definitelyUnreachableJumps(definitelyUnreachable)
				.maybeUnreachableJumps(maybeUnreachable)
				.unsoundJumps(unsoundJumps)
				.maybeUnsoundJumps(maybeUnsoundJumps)
				.build();

		log.info("### Calculating statistics ###\n{}", stats);

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
				for (Statement unsoundNode : checker.getUnsoundJumps())
					if (!soundlySolved.contains(unsoundNode)) {
						fixpoint = true;
						for (Statement jumpdest : jumpdestNodes)
							cfg.addEdge(new SequentialEdge(unsoundNode, jumpdest));
					}

				soundlySolved.addAll(checker.getUnsoundJumps());

				program.addCodeMember(cfg);
				lisa.run(program);
			} while (fixpoint && checker.getUnsoundJumps() != null && ++currentIteration < MAX_ITER);
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

	private void setupGlobalOptions(CommandLine cmd) {
		try {
			CORES = cmd.hasOption("cores") ? Integer.parseInt(cmd.getOptionValue("cores")) : 1;
		} catch (Exception e) {
			log.warn("Cores set to 1: {}", e.getMessage());
			CORES = 1;
		}

		if (cmd.hasOption("checker-reentrancy") || cmd.hasOption("checker-all"))
			ReentrancyChecker.enableChecker();
		if (cmd.hasOption("checker-txorigin") || cmd.hasOption("checker-all"))
			TxOriginChecker.enableChecker();
		if (cmd.hasOption("checker-timestampdependency") || cmd.hasOption("checker-all"))
			TimestampDependencyChecker.enableChecker();

		if (cmd.hasOption("output-directory-path"))
			OUTPUT_DIRECTORY_PATH = Path.of(cmd.getOptionValue("output-directory-path"));
		else
			OUTPUT_DIRECTORY_PATH = Path.of("execution", "results");
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
			EVMFrontend.setEtherscanAPIKey(cmd.getOptionValue("etherscan-api-key"));
	}

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

		Option enableTimestampDependencyCheckerOption = Option.builder()
				.longOpt("checker-timestampdependency")
				.desc("Enable timestamp-dependency checker.")
				.required(false)
				.hasArg(false)
				.build();

		Option etherscanAPIKeyOption = Option.builder()
				.longOpt("etherscan-api-key")
				.desc("Insert your Etherscan API key.")
				.required(false)
				.hasArg(true)
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
		options.addOption(enableTimestampDependencyCheckerOption);
		options.addOption(outputDirectoryPathOption);
		options.addOption(etherscanAPIKeyOption);
		options.addOption(abiOption);

		return options;
	}

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

	/**
	 * Waits for all submitted tasks in the given list of futures to complete.
	 *
	 * @param futures A list of {@link Future} objects representing running
	 *                    tasks.
	 */
	static private void waitForCompletion(List<Future<?>> futures) {
		for (Future<?> future : futures)
			try {
				future.get();
			} catch (ExecutionException e) {
				System.err.println(JSONManager.throwNewError("Error during task execution: " + e.getMessage()));
				System.exit(1);
			} catch (InterruptedException ie) {
				System.err.println(JSONManager.throwNewError("Interrupted during task execution: " + ie.getMessage()));
				System.exit(1);
			}
	}
}
