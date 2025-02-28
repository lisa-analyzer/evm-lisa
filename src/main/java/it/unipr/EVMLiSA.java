package it.unipr;

import it.unipr.analysis.*;
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

public class EVMLiSA {
	private static final Logger log = LogManager.getLogger(EVMLiSA.class);

	// Configuration
	private static int CORES;
	private static boolean ENABLE_REENTRANCY_CHECKER = false;
	private static boolean ENABLE_TXORIGIN_CHECKER = false;
	private static boolean ENABLE_TIMESTAMPDEPENDENCY_CHECKER = false;

	/**
	 * Generates a control flow graph (represented as a LiSA {@code Program})
	 * from an EVM bytecode smart contract and runs the analysis on it.
	 * 
	 * @param args configuration options
	 */
	public static void main(String[] args) {
		try {
			new EVMLiSA().go(args);
//			new EVMLiSA().examples();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	private void go(String[] args) throws Exception {
		CommandLine cmd = parseCommandLine(args);
		if (cmd == null)
			return;

		setupGlobalOptions(cmd);

		// Benchmark case
		if (cmd.hasOption("benchmark")) {
			EVMLiSA.analyzeSetOfContracts(Path.of(cmd.getOptionValue("benchmark")));
			// TODO check and print statistics
			// TODO add checkers
			return;
		}

		// Ensure that at least one valid option is provided to specify the
		// bytecode source
		if (!cmd.hasOption("address") && !cmd.hasOption("bytecode-path") && !cmd.hasOption("bytecode")) {
			log.error("Address, bytecode or filepath required.");
			new HelpFormatter().printHelp("help", getOptions());
			System.exit(1);
		}

		SmartContract contract = new SmartContract();

		// Single analysis case (address)
		if (cmd.hasOption("address"))
			contract = new SmartContract(cmd.getOptionValue("address"));

		// Single analysis case (bytecode and abi as a path)
		if (cmd.hasOption("bytecode-path") && cmd.hasOption("abi-path"))
			contract = new SmartContract(
					Path.of(cmd.getOptionValue("bytecode-path")),
					Path.of(cmd.getOptionValue("abi-path")));

		// Single analysis case (bytecode as a path)
		if (cmd.hasOption("bytecode-path"))
			contract = new SmartContract(
					Path.of(cmd.getOptionValue("bytecode-path")));

		// Single analysis case (bytecode as a string)
		if (cmd.hasOption("bytecode"))
			contract = new SmartContract()
					.setBytecode(cmd.getOptionValue("bytecode"));

		EVMLiSA.analyzeContract(contract);
		System.err.println(contract);
	}

	private void examples() throws Exception {
		// Single case (address)
		SmartContract sc = new SmartContract("0x3932f366886d2b981485503a182173da80d15c97");
		EVMLiSA.analyzeContract(sc);
		sc.generateGraphWithBasicBlocks(); // generate .dot file
		sc.toFile(); // save results to file
		// print basic blocks as pairs (i.e., (from_block, to_block) pairs)
		log.debug(BasicBlock.basicBlocksToLongArrayToString(
				BasicBlock.basicBlocksToLongArray(sc.getBasicBlocks())));

		// Single case (bytecode as a path)
		EVMLiSA.analyzeContract(new SmartContract(Path.of("execution", "results",
				"0x26366920975b24A89CD991A495d0D70CB8E1BA1F", "0x26366920975b24A89CD991A495d0D70CB8E1BA1F.bytecode")));

		// Single case (bytecode as a string)
		EVMLiSA.analyzeContract(new SmartContract().setBytecode(
				"0x608060405234801561001057600080fd5b50600436106100415760003560e01c80636146195414610046578063d88bba1114610050578063fbc7f20e14610087575b600080fd5b61004e6100a2565b005b61006b735a98fcbea516cf06857215779fd812ca3bef1b3281565b6040516001600160a01b03909116815260200160405180910390f35b61006b7387d93d9b2c672bf9c9642d853a8682546a5012b581565b6040516328a1b1ad60e21b8152735a98fcbea516cf06857215779fd812ca3bef1b3260048201527387d93d9b2c672bf9c9642d853a8682546a5012b5602482015273223d844fc4b006d67c0cdbd39371a9f73f69d9749063a286c6b490604401600060405180830381600087803b15801561011c57600080fd5b505af1158015610130573d6000803e3d6000fd5b5050505056fea2646970667358221220bae0c5370f53dc13f1e3000d78511979d423220e1cd1c5e47b343314ab833ff964736f6c63430008110033"));

		// Multiple contracts
		EVMLiSA.analyzeSetOfContracts(Path.of("benchmark", "50-ground-truth.txt"));
	}

	public static void analyzeSetOfContracts(Path filePath) throws Exception {
		log.info("Analyzing set of contracts...");

		List<SmartContract> contracts = buildContractsFromFile(filePath);

		ExecutorService executor = Executors.newFixedThreadPool(CORES);

		List<Future<?>> futures = new ArrayList<>();

		for (SmartContract contract : contracts)
			futures.add(executor.submit(() -> analyzeContract(contract)));

		log.info("{} contracts submitted to Thread pool with {} workers.", contracts.size(), CORES);

		waitForCompletion(futures);

		executor.shutdown();
		log.info("Finished analyzing {} contracts.", contracts.size());

		log.info("Multi analysis results:");
		log.info(EVMLiSA.analyzeResults(contracts));

		Path outputDir = Path.of("execution", "results", "set-of-contracts");
		try {
			Files.createDirectories(outputDir);
			Files.writeString(
					outputDir.resolve(System.currentTimeMillis() + ".json"),
					JSONManager.aggregateSmartContractsToJson(contracts).toString(4),
					StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
		} catch (IOException e) {
			log.error("Failed to save results in {}", outputDir, e);
		}
	}

	public static void analyzeContract(SmartContract contract) {
		Program program;
		try {
			program = EVMFrontend.generateCfgFromFile(contract.getMnemonicBytecodePath().toString());
		} catch (IOException e) {
			log.error("Unable to generate CFG from file");
			return;
		}

		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(contract);
		JumpSolver checker = new JumpSolver();
		conf.semanticChecks.add(checker);

		LiSA lisa = new LiSA(conf);
		lisa.run(program);

		if (ENABLE_REENTRANCY_CHECKER) {
			conf.semanticChecks.clear();
			conf.semanticChecks.add(new ReentrancyChecker());
			lisa.run(program);
		}
		if (ENABLE_TXORIGIN_CHECKER) {
			conf.semanticChecks.clear();
			conf.semanticChecks.add(new TxOriginChecker());
			conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new TxOriginAbstractDomain(),
					new TypeEnvironment<>(new InferredTypes()));
			lisa.run(program);
		}
		if (ENABLE_TIMESTAMPDEPENDENCY_CHECKER) {
			conf.semanticChecks.clear();
			conf.semanticChecks.add(new TimestampDependencyChecker());
			conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(),
					new TimestampDependencyAbstractDomain(),
					new TypeEnvironment<>(new InferredTypes()));
			lisa.run(program);
		}

		contract.setCFG(checker.getComputedCFG());
		contract.computeFunctionsSignatureEntryPoints();
		contract.computeFunctionsSignatureExitPoints();
		contract.computeEventsSignatureEntryPoints();
		contract.computeEventsExitPoints();
		contract.setStatistics(
				computeStatistics(checker, lisa, program));
		contract.setVulnerabilities(
				VulnerabilitiesObject.newVulnerabilitiesObject()
						.reentrancy(MyCache.getInstance().getReentrancyWarnings(checker.getComputedCFG().hashCode()))
						.txOrigin(MyCache.getInstance().getTxOriginWarnings(checker.getComputedCFG().hashCode()))
						.timestamp(MyCache.getInstance()
								.getTimestampDependencyWarnings(checker.getComputedCFG().hashCode()))
						.build());
		contract.generateGraphWithBasicBlocks();
		contract.toFile(); // save results to file
	}

	public static StatisticsObject computeStatistics(JumpSolver checker, LiSA lisa, Program program) {
		Set<Statement> soundlySolved = getSoundlySolvedJumps(checker, lisa, program);
		return computeJumps(checker, soundlySolved);
	}

	private static StatisticsObject computeJumps(JumpSolver checker, Set<Statement> soundlySolved) {
		EVMCFG cfg = checker.getComputedCFG();

		log.info("### Calculating statistics ###");

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

		log.info("Total opcodes: {}", cfg.getOpcodeCount());
		log.info("Total jumps: {}", cfg.getAllJumps().size());
		log.info("Resolved jumps: {}", resolvedJumps);
		log.info("Definitely unreachable jumps: {}", definitelyUnreachable);
		log.info("Maybe unreachable jumps: {}", maybeUnreachable);
		log.info("Unsound jumps: {}", unsoundJumps);
		log.info("Maybe unsound jumps: {}", maybeUnsoundJumps);

		return StatisticsObject.newStatisticsObject()
				.totalOpcodes(cfg.getOpcodeCount())
				.totalJumps(cfg.getAllJumps().size())
				.resolvedJumps(resolvedJumps)
				.definitelyUnreachableJumps(definitelyUnreachable)
				.maybeUnreachableJumps(maybeUnreachable)
				.unsoundJumps(unsoundJumps)
				.maybeUnsoundJumps(maybeUnsoundJumps)
				.build();
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

	public static List<SmartContract> buildContractsFromFile(Path filePath) throws Exception {
		log.info("Parsing contracts from {}", filePath);

		List<SmartContract> contracts = new ArrayList<>();

		try {
			File myObj = new File(String.valueOf(filePath));
			Scanner myReader = new Scanner(myObj);

			while (myReader.hasNextLine()) {
				String address = myReader.nextLine();
				contracts.add(new SmartContract(address));

				log.info("Created contract: {}", address);
				Thread.sleep(500);
			}
			myReader.close();

		} catch (FileNotFoundException e) {
			log.error("{} not found.", filePath);
			throw e;
		}

		log.info("Created {} contracts.", contracts.size());
		return contracts;
	}

	/**
	 * Reads smart contracts from a file and returns a list of strings.
	 *
	 * @return A list of strings containing the smart contracts read from the
	 *             file.
	 * 
	 * @throws Exception If an error occurs while reading the file.
	 */
	public static ArrayList<String> readSmartContractsFromFile(String SMARTCONTRACTS_FULLPATH) throws Exception {
		ArrayList<String> smartContractsRead = new ArrayList<String>();

		try {
			File myObj = new File(SMARTCONTRACTS_FULLPATH);
			Scanner myReader = new Scanner(myObj);

			while (myReader.hasNextLine()) {
				String data = myReader.nextLine();
				smartContractsRead.add(data);
			}
			myReader.close();

		} catch (FileNotFoundException e) {
			log.error("{} not found.", SMARTCONTRACTS_FULLPATH);
			throw e;
		}

		return smartContractsRead;
	}

	private static StatisticsObject analyzeResults(List<SmartContract> contracts) {
		int totalOpcodes = 0;
		int totalJumps = 0;
		int resolvedJumps = 0;
		int maybeUnreachableJumps = 0;
		int definitelyUnreachableJumps = 0;
		int maybeUnsoundJumps = 0;
		int unsoundJumps = 0;

		for (SmartContract contract : contracts) {
			StatisticsObject s = contract.getStatistics();
			totalOpcodes += s.getTotalOpcodes();
			totalJumps += s.getTotalJumps();
			resolvedJumps += s.getResolvedJumps();
			maybeUnreachableJumps += s.getMaybeUnreachableJumps();
			definitelyUnreachableJumps += s.getDefinitelyUnreachableJumps();
			maybeUnsoundJumps += s.getMaybeUnsoundJumps();
			unsoundJumps += s.getUnsoundJumps();
		}

		return StatisticsObject.newStatisticsObject()
				.totalOpcodes(totalOpcodes)
				.totalJumps(totalJumps)
				.resolvedJumps(resolvedJumps)
				.maybeUnreachableJumps(maybeUnreachableJumps)
				.definitelyUnreachableJumps(definitelyUnreachableJumps)
				.maybeUnsoundJumps(maybeUnsoundJumps)
				.unsoundJumps(unsoundJumps);
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

		Option bytecodeOption = Option.builder("b")
				.longOpt("bytecode")
				.desc("Bytecode to be analyzed (e.g., 0x6080...).")
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

	private void setupGlobalOptions(CommandLine cmd) {
		try {
			CORES = cmd.hasOption("cores") ? Integer.parseInt(cmd.getOptionValue("cores")) : 1;
		} catch (Exception e) {
			log.warn("Cores set to 1: {}", e.getMessage());
			CORES = 1;
		}

		ENABLE_REENTRANCY_CHECKER = cmd.hasOption("checker-reentrancy") || cmd.hasOption("checker-all");
		ENABLE_TXORIGIN_CHECKER = cmd.hasOption("checker-txorigin") || cmd.hasOption("checker-all");
		ENABLE_TIMESTAMPDEPENDENCY_CHECKER = cmd.hasOption("checker-timestampdependency")
				|| cmd.hasOption("checker-all");

		try {
			if (cmd.hasOption("stack-size"))
				AbstractStack.setStackLimit(Integer.parseInt(cmd.getOptionValue("stack-size")));

			if (cmd.hasOption("stack-set-size"))
				AbstractStackSet.setStackSetSize(Integer.parseInt(cmd.getOptionValue("stack-set-size")));
		} catch (NumberFormatException e) {
			log.error("Size must be an integer.");
			System.exit(1);
		}

		if (cmd.hasOption("link-unsound-jumps-to-all-jumpdest"))
			JumpSolver.setLinkUnsoundJumpsToAllJumpdest();
		if (cmd.hasOption("use-live-storage") && (cmd.hasOption("address") || cmd.hasOption("benchmark")))
			EVMAbstractState.setUseStorageLive();
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
				log.error("Error during task execution: {}", e.getMessage());
			} catch (InterruptedException ie) {
				log.error("Interrupted during task execution: {}", ie.getMessage());
			}
	}
}
