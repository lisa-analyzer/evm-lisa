package it.unipr;

import it.unipr.analysis.AbstractStack;
import it.unipr.analysis.AbstractStackSet;
import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.MyCache;
import it.unipr.analysis.MyLogger;
import it.unipr.analysis.StackElement;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Jump;
import it.unipr.cfg.Jumpi;
import it.unipr.checker.JumpSolver;
import it.unipr.frontend.EVMFrontend;
import it.unive.lisa.LiSA;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.conf.LiSAConfiguration;
import it.unive.lisa.conf.LiSAConfiguration.GraphType;
import it.unive.lisa.interprocedural.ModularWorstCaseAnalysis;
import it.unive.lisa.interprocedural.callgraph.RTACallGraph;
import it.unive.lisa.program.Program;
import it.unive.lisa.program.cfg.statement.Statement;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;
import java.util.Set;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONObject;

public class EVMLiSA {
	private static final Logger log = LogManager.getLogger(EVMLiSA.class);
	private String OUTPUT_DIR = "execution/results";

	// Path
	private String STATISTICS_FULLPATH = OUTPUT_DIR + "/statistics.csv";
	private String STATISTICSZEROJUMP_FULLPATH = OUTPUT_DIR + "/statisticsZeroJumps.csv";
	private String FAILURE_FULLPATH = OUTPUT_DIR + "/failure.csv";
	private String LOGS_FULLPATH = OUTPUT_DIR + "/logs.txt";
	private static String SMARTCONTRACTS_FULLPATH = "";

	// Statistics
	private int numberOfAPIEtherscanRequest = 0;
	private int numberOfAPIEtherscanRequestOnSuccess = 0;
	private static final SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss,SSS");
	private int CORES;

	private static final boolean REGENERATE = false;

	/**
	 * Generates a control flow graph (represented as a LiSA {@code Program})
	 * from an EVM bytecode smart contract and runs the analysis on it.
	 * 
	 * @param args configuration options
	 */
	public static void main(String[] args) throws Exception {
		new EVMLiSA().go(args);
	}

	public void go(String[] args) throws Exception {
		Options options = new Options();

		// String parameters
		Option addressOption = new Option("a", "address", true, "address of an Ethereum smart contract");
		addressOption.setRequired(false);
		options.addOption(addressOption);

		Option outputOption = new Option("o", "output", true, "output directory path");
		outputOption.setRequired(false);
		options.addOption(outputOption);

		Option dumpAnalysisOption = new Option("d", "dump-analysis", true, "dump the analysis (html, dot)");
		dumpAnalysisOption.setRequired(false);
		options.addOption(dumpAnalysisOption);

		Option filePathOption = new Option("f", "filepath", true, "filepath of the Etherem smart contract");
		filePathOption.setRequired(false);
		options.addOption(filePathOption);

		Option stackSizeOption = new Option("q", "stack-size", true, "dimension of stack");
		stackSizeOption.setRequired(false);
		options.addOption(stackSizeOption);

		Option stackSetSizeOption = new Option("w", "stack-set-size", true, "dimension of stack-set");
		stackSetSizeOption.setRequired(false);
		options.addOption(stackSetSizeOption);

		Option benchmarkOption = new Option("b", "benchmark", true, "filepath of the benchmark");
		benchmarkOption.setRequired(false);
		options.addOption(benchmarkOption);

		Option coresOption = new Option("C", "cores", true, "number of cores used");
		coresOption.setRequired(false);
		options.addOption(coresOption);

		// Boolean parameters
		Option dumpStatisticsOption = Option.builder("s")
				.longOpt("dump-stats")
				.desc("dump statistics")
				.required(false)
				.hasArg(false)
				.build();

		Option dumpCFGOption = Option.builder("c")
				.longOpt("dump-cfg")
				.desc("dump the CFG")
				.required(false)
				.hasArg(false)
				.build();

		Option downloadBytecodeOption = Option.builder("D")
				.longOpt("download-bytecode")
				.desc("download the bytecode")
				.required(false)
				.hasArg(false)
				.build();

		Option useStorageLiveOption = Option.builder("S")
				.longOpt("use-live-storage")
				.desc("use the live storage in SLOAD")
				.required(false)
				.hasArg(false)
				.build();

		Option dumpAnalysisReport = Option.builder("r")
				.longOpt("dump-report")
				.desc("dump analysis report")
				.required(false)
				.hasArg(false)
				.build();

		options.addOption(dumpStatisticsOption);
		options.addOption(dumpCFGOption);
		options.addOption(downloadBytecodeOption);
		options.addOption(useStorageLiveOption);
		options.addOption(dumpAnalysisReport);

		CommandLineParser parser = new DefaultParser();
		HelpFormatter formatter = new HelpFormatter();
		CommandLine cmd = null;

		try {
			cmd = parser.parse(options, args);
		} catch (ParseException e) {
			log.error(e.getMessage());
			formatter.printHelp("help", options);

			System.exit(1);
		}

		String addressSC = cmd.getOptionValue("address");
		String outputDir = cmd.getOptionValue("output");
		boolean dumpCFG = cmd.hasOption("dumpcfg");
		String dumpAnalysis = cmd.getOptionValue("dump-analysis");
		boolean dumpStatistics = cmd.hasOption("dump-stats");
		boolean downloadBytecode = cmd.hasOption("download-bytecode");
		boolean useStorageLive = cmd.hasOption("use-live-storage");
		String filepath = cmd.getOptionValue("filepath");
		String stackSize = cmd.getOptionValue("stack-size");
		String stackSetSize = cmd.getOptionValue("stack-set-size");
		String benchmark = cmd.getOptionValue("benchmark");
		String coresOpt = cmd.getOptionValue("cores");
		boolean dumpReport = cmd.hasOption("dump-report");

		// Download bytecode case
		if (downloadBytecode && benchmark != null) {
			SMARTCONTRACTS_FULLPATH = benchmark;
			OUTPUT_DIR = "download";
			saveSmartContractsFromEtherscan();
			return;
		}

		// Setting cores
		if (coresOpt != null && Integer.parseInt(coresOpt) > 0)
			CORES = Integer.parseInt(coresOpt);
		else
			CORES = 1;

		// Setting AbstractStack size and AbstractStackSet size
		try {
			if (stackSize != null && Integer.parseInt(stackSize) > 0)
				AbstractStack.setStackLimit(Integer.parseInt(stackSize));

			if (stackSetSize != null && Integer.parseInt(stackSetSize) > 0)
				AbstractStackSet.setStackSetSize(Integer.parseInt(stackSetSize));

		} catch (NumberFormatException e) {
			log.error("Size must be an integer.");
			formatter.printHelp("help", options);

			System.exit(1);
		}

		// Setting output directories
		if (outputDir != null) {
			OUTPUT_DIR = outputDir;
			STATISTICS_FULLPATH = OUTPUT_DIR + "/statistics.csv";
			STATISTICSZEROJUMP_FULLPATH = OUTPUT_DIR + "/statisticsZeroJumps.csv";
			FAILURE_FULLPATH = OUTPUT_DIR + "/failure.csv";
			LOGS_FULLPATH = OUTPUT_DIR + "/logs.txt";
		}

		if (useStorageLive)
			EVMAbstractState.setUseStorageLive();

		// Creating json output notes
		JSONObject jsonOptions = new JSONObject();
		jsonOptions.put("address", addressSC);
		jsonOptions.put("dump-CFG", dumpCFG);
		jsonOptions.put("dump-analysis", dumpAnalysis);
		jsonOptions.put("dump-statistics", dumpStatistics);
		jsonOptions.put("download-bytecode", downloadBytecode);
		jsonOptions.put("use-storage-live", useStorageLive);
		jsonOptions.put("filepath", filepath);
		jsonOptions.put("stack-size", AbstractStack.getStackLimit());
		jsonOptions.put("stack-set-size", AbstractStackSet.getStackSetLimit());
		jsonOptions.put("benchmark", benchmark);
		jsonOptions.put("cores", CORES);
		jsonOptions.put("dump-report", dumpReport);
		jsonOptions.put("output-directory", OUTPUT_DIR);

		// Run benchmark case
		if (benchmark != null) {
			Files.createDirectories(Paths.get(OUTPUT_DIR));
			SMARTCONTRACTS_FULLPATH = benchmark;
			try {
				runBenchmark(jsonOptions);
			} catch (FileNotFoundException e) {
				log.error("File {} not found.", benchmark);
			}
			return;
		}

		// Error case
		if (addressSC == null && filepath == null) {
			log.error("Address or filepath required.");
			formatter.printHelp("help", options);
			System.exit(1);
		}

		// Single analysis case
		OUTPUT_DIR += "/" + addressSC;
		Files.createDirectories(Paths.get(OUTPUT_DIR));
		jsonOptions.put("output-directory", OUTPUT_DIR);

		if (outputDir == null)
			outputDir = OUTPUT_DIR + "/" + addressSC + "_REPORT";

		STATISTICS_FULLPATH = OUTPUT_DIR + "/" + addressSC + "_STATISTICS" + ".csv";
		FAILURE_FULLPATH = OUTPUT_DIR + "/" + addressSC + "_FAILURE" + ".csv";

		String BYTECODE_FULLPATH;
		if (filepath == null) {
			BYTECODE_FULLPATH = OUTPUT_DIR + "/" + addressSC + ".sol";
			EVMFrontend.parseContractFromEtherscan(addressSC, BYTECODE_FULLPATH);
		} else {
			BYTECODE_FULLPATH = filepath + "opcodes";
			String bytecode = new String(Files.readAllBytes(Paths.get(filepath)));
			EVMFrontend.opcodesFromBytecode(bytecode, BYTECODE_FULLPATH);
		}

		Program program = EVMFrontend.generateCfgFromFile(BYTECODE_FULLPATH);

		long start = System.currentTimeMillis();
		long finish;

		LiSAConfiguration conf = new LiSAConfiguration();
		conf.serializeInputs = dumpCFG;
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new EVMAbstractState(addressSC),
				new TypeEnvironment<>(new InferredTypes()));
		conf.jsonOutput = dumpReport;
		conf.workdir = outputDir + "/" + addressSC;
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		JumpSolver checker = new JumpSolver();
		conf.semanticChecks.add(checker);
		conf.callGraph = new RTACallGraph();
		conf.serializeResults = false;
		conf.optimize = false;
		conf.useWideningPoints = false;
		if (dumpAnalysis != null) {
			if (dumpAnalysis.equals("dot"))
				conf.analysisGraphs = GraphType.DOT;
			else if (dumpAnalysis.equals("html"))
				conf.analysisGraphs = GraphType.HTML_WITH_SUBNODES;
		}

		try {
			LiSA lisa = new LiSA(conf);
			lisa.run(program);

			// Print the results
			finish = System.currentTimeMillis();

			MyLogger result = EVMLiSA.dumpStatistics(checker)
					.address(addressSC)
					.time(finish - start)
					.timeLostToGetStorage(MyCache.getInstance().getTimeLostToGetStorage(addressSC))
					.buildJson(jsonOptions)
					.build();

			if (dumpStatistics) {
				toFile(STATISTICS_FULLPATH, result.toString());
				log.info("Statistics successfully written in {}.", STATISTICS_FULLPATH);
			}

			System.err.println(result.getJson());

		} catch (Throwable e) {
			finish = System.currentTimeMillis();

			String msg = MyLogger.newLogger()
					.address(addressSC)
					.notes("failure: " + e + " - details: " + e.getMessage())
					.time(finish - start)
					.timeLostToGetStorage(MyCache.getInstance().getTimeLostToGetStorage(addressSC))
					.buildJson(jsonOptions)
					.build().toString();

			log.error(msg);

			if (dumpStatistics) {
				toFile(FAILURE_FULLPATH, msg);
				log.info("Failures successfully written in {}.", FAILURE_FULLPATH);
			}
		}
	}

	private MyLogger newAnalysis(String CONTRACT_ADDR, JSONObject jsonOptions) throws Exception {

		String BYTECODE_FULLPATH = OUTPUT_DIR + "/benchmark/" + CONTRACT_ADDR + "/" + CONTRACT_ADDR
				+ ".sol";

		// Directory setup and bytecode retrieval
		Files.createDirectories(Paths.get(OUTPUT_DIR + "/" + "benchmark/" + CONTRACT_ADDR));

		// If the file does not exist, we will do an API request to Etherscan
		File file = new File(BYTECODE_FULLPATH);
		if (!file.exists() || REGENERATE) {
			numberOfAPIEtherscanRequest++;

			if (numberOfAPIEtherscanRequest % 5 == 0) {
				try {
					// I can do max 5 API request in 1 sec to Etherscan.io
					Thread.sleep(1000);
				} catch (InterruptedException e) {
					log.error("error: {}", e.getMessage());
				}
			}

			if (EVMFrontend.parseContractFromEtherscan(CONTRACT_ADDR, BYTECODE_FULLPATH))
				numberOfAPIEtherscanRequestOnSuccess++;
		}

		// Configuration and test run
		Program program = EVMFrontend.generateCfgFromFile(BYTECODE_FULLPATH);

		long start = System.currentTimeMillis();

		LiSAConfiguration conf = new LiSAConfiguration();
		conf.serializeInputs = false;
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new EVMAbstractState(CONTRACT_ADDR),
				new TypeEnvironment<>(new InferredTypes()));
		conf.jsonOutput = false;
		conf.workdir = OUTPUT_DIR + "/benchmark/" + CONTRACT_ADDR;
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		JumpSolver checker = new JumpSolver();
		conf.semanticChecks.add(checker);
		conf.callGraph = new RTACallGraph();
		conf.serializeResults = false;
		conf.optimize = false;

		LiSA lisa = new LiSA(conf);
		lisa.run(program);

		// Print the results
		long finish = System.currentTimeMillis();

		return EVMLiSA.dumpStatistics(checker)
				.address(CONTRACT_ADDR)
				.time(finish - start)
				.timeLostToGetStorage(MyCache.getInstance().getTimeLostToGetStorage(CONTRACT_ADDR))
				.buildJson(jsonOptions)
				.build();
	}

	/**
	 * Runs the benchmark for analyzing smart contracts.
	 *
	 * @throws Exception if an error occurs during the benchmark execution.
	 */
	private void runBenchmark(JSONObject jsonOptions) throws Exception {
		List<String> smartContracts = readSmartContractsFromFile(SMARTCONTRACTS_FULLPATH);
		List<String> smartContractsTerminatedSuccessfully = new ArrayList<>();
		List<String> smartContractsFailed = new ArrayList<>();

		Runnable runnableHandler = new RunnableHandler(smartContracts, smartContractsTerminatedSuccessfully,
				smartContractsFailed, jsonOptions);

		synchronized (EVMLiSA.class) {
			Thread handler = new Thread(runnableHandler);
			handler.start();

			long timeToWait;

			timeToWait = 1000 * 60 * 60 * 24; // 1 day

			String msg = "Started at " + now() + ".\n";
			msg += "Number of cores: " + CORES + " (parallel analysis).\n";
			msg += "Number of analyses: " + smartContracts.size() + ".\n";
			msg += "\n"; // Blank line

			msg += "Stack size = " + AbstractStack.getStackLimit() + ".\n";
			msg += "Stack set size = " + AbstractStackSet.getStackSetLimit() + ".\n";
			msg += "\n"; // Blank line

			msg += "Heap size: " + new Converter().getSize(Runtime.getRuntime().totalMemory()) + ".\n";
			msg += "Heap Max size: " + new Converter().getSize(Runtime.getRuntime().maxMemory()) + ".\n";
			msg += "\n"; // Blank line

			log.info(msg);
			toFile(LOGS_FULLPATH, msg);

			EVMLiSA.class.wait(timeToWait);
		}

		for (String smartContract : smartContracts) {
			if (!smartContractsTerminatedSuccessfully.contains(smartContract) &&
					!smartContractsFailed.contains(smartContract)) {
				String msg = MyLogger.newLogger()
						.address(smartContract)
						.notes("Killed: timeout.")
						.build().toString();
				toFile(FAILURE_FULLPATH, msg);
			}
		}

		// Print statistics to standard output and log file
		String msg = "Total analysis: " + smartContracts.size() + ", " +
				"successfully: " + smartContractsTerminatedSuccessfully.size() + ", " +
				"failed: " + (smartContracts.size() - smartContractsTerminatedSuccessfully.size()) + ".";

		log.info(msg);
		toFile(LOGS_FULLPATH, msg);

		log.info("Statistics successfully written in {}.", STATISTICS_FULLPATH);
		log.info("Logs successfully written in {}.", LOGS_FULLPATH);
	}

	private class RunnableHandler implements Runnable {

		private int analysesTerminated;
		private int analysesFailed;
		private final Object mutex = new Object();
		private int threadsStarted;

		private final List<String> smartContracts;
		private final List<String> smartContractsTerminatedSuccessfully;
		private final List<String> smartContractsFailed;

		private final JSONObject jsonOptions;

		public RunnableHandler(List<String> smartContracts, List<String> smartContractsTerminatedSuccessfully,
				List<String> smartContractsFailed, JSONObject jsonOptions) {
			this.smartContracts = smartContracts;
			this.smartContractsTerminatedSuccessfully = smartContractsTerminatedSuccessfully;
			this.smartContractsFailed = smartContractsFailed;
			this.threadsStarted = 0;
			this.analysesTerminated = 0;
			this.analysesFailed = 0;
			this.jsonOptions = jsonOptions;
		}

		@Override
		public void run() {
			for (String address : smartContracts) {

				synchronized (mutex) {
					// We optimize parallelism by running n analyzes at a
					// time with n = CORES
					while ((threadsStarted - analysesTerminated) > CORES) {
						try {
							mutex.wait();
						} catch (InterruptedException e) {
							log.error("error: {}", e.getMessage());
						}
					}
				}

				Runnable worker = () -> {
					try {
						MyLogger myStats = newAnalysis(address, jsonOptions);

						synchronized (mutex) {
							analysesTerminated++;
							smartContractsTerminatedSuccessfully.add(address);

							if (myStats.jumpSize() == 0)
								toFile(STATISTICSZEROJUMP_FULLPATH, myStats.toString());
							else
								toFile(STATISTICS_FULLPATH, myStats.toString());

							toFile(LOGS_FULLPATH, buildMessage("SUCCESS", address, smartContracts.size(),
									smartContractsTerminatedSuccessfully.size(), analysesTerminated,
									analysesFailed, threadsStarted));

							mutex.notifyAll();
						}

					} catch (Throwable e) {
						synchronized (mutex) {
							analysesTerminated++;
							analysesFailed++;
							smartContractsFailed.add(address);

							String msg = MyLogger.newLogger()
									.address(address)
									.notes("failure: " + e + " - details: " + e.getMessage())
									.build().toString();

							log.error(msg);
							toFile(FAILURE_FULLPATH, msg);

							toFile(LOGS_FULLPATH, buildMessage("FAILURE", address, smartContracts.size(),
									smartContractsTerminatedSuccessfully.size(), analysesTerminated,
									analysesFailed, threadsStarted));

							mutex.notifyAll();
						}
					}
				};

				new Thread(worker).start();
				threadsStarted++;

				Runtime.getRuntime().gc(); // Force Java Garbage Collection
			}

			try {
				synchronized (mutex) {
					while (analysesTerminated < smartContracts.size()) {
						mutex.wait();
					}
				}

			} catch (InterruptedException e) {
				log.error("error: {}", e.getMessage());
			}

			synchronized (EVMLiSA.class) {
				EVMLiSA.class.notifyAll(); // All tests are finished
			}

		}
	}

	/**
	 * Calculates and prints statistics about the control flow graph (CFG) of
	 * the provided EVMCFG object.
	 *
	 * @param checker The control flow graph (CFG) of the Ethereum Virtual
	 *                    Machine (EVM) bytecode.
	 * 
	 * @return A Triple containing the counts of precisely resolved jumps, sound
	 *             resolved jumps, and unreachable jumps.
	 */
	public static MyLogger dumpStatistics(JumpSolver checker) {
		EVMCFG cfg = checker.getComputedCFG();

		log.info("### Calculating statistics ###");

		Set<Statement> unreachableJumpNodes = checker.getUnreachableJumps();

		int resolvedJumps = 0;
		int definitelyUnreachable = 0;
		int maybeUnreachable = 0;
		int unsoundJumps = 0;
		int maybeUnsoundJumps = checker.getMaybeUnsoundJumps().size();

		boolean allJumpAreSound = true;

		if (cfg.getEntrypoints().stream().findAny().isEmpty()) {
			log.warn("There are no entrypoints.");
			return null;
		}

		Statement entryPoint = cfg.getEntrypoints().stream().findAny().get();
		Set<Statement> pushedJumps = cfg.getAllPushedJumps();

		for (Statement jumpNode : cfg.getAllJumps()) {
			if (pushedJumps.contains(jumpNode))
				continue;
			boolean reachableFrom = cfg.reachableFrom(entryPoint, jumpNode);
			Set<StackElement> topStackValuesPerJump = checker.getTopStackValuesPerJump(jumpNode);
			if (topStackValuesPerJump == null || !reachableFrom)
				continue;
			else if (topStackValuesPerJump.contains(StackElement.NUMERIC_TOP)) {
				allJumpAreSound = false;
				break;
			}
		}

		// we are safe supposing that we have a single entry point
		for (Statement jumpNode : cfg.getAllJumps()) {
			if ((jumpNode instanceof Jump) || (jumpNode instanceof Jumpi)) {
				boolean reachableFrom = cfg.reachableFrom(entryPoint, jumpNode);
				Set<StackElement> topStackValuesPerJump = checker.getTopStackValuesPerJump(jumpNode);

				if (pushedJumps.contains(jumpNode))
					resolvedJumps++;
				else if (reachableFrom && unreachableJumpNodes.contains(jumpNode))
					definitelyUnreachable++;
				else if (!reachableFrom) {
					if (allJumpAreSound)
						definitelyUnreachable++;
					else
						maybeUnreachable++;
				} else if (topStackValuesPerJump == null) {
					// If all stacks are bottom, then we have a
					// maybeFakeMissedJump
					definitelyUnreachable++;
				} else if (!topStackValuesPerJump.contains(StackElement.NUMERIC_TOP)) {
					// If the elements at the top of the stacks are all
					// different from NUMERIC_TOP, then we are sure that it
					// is definitelyFakeMissedJumps
					resolvedJumps++;
				} else {
					unsoundJumps++;
					log.error("{} not solved", jumpNode);
					log.error("getTopStackValuesPerJump: {}", topStackValuesPerJump);
				}
			}
		}

		log.info("Total opcodes: {}", cfg.getOpcodeCount());
		log.info("Total jumps: {}", cfg.getAllJumps().size());
		log.info("Resolved jumps: {}", resolvedJumps);
		log.info("Definitely unreachable jumps: {}", definitelyUnreachable);
		log.info("Maybe unreachable jumps: {}", maybeUnreachable);
		log.info("Unsound jumps: {}", unsoundJumps);
		log.info("Maybe unsound jumps: {}", maybeUnsoundJumps);

		return MyLogger.newLogger()
				.opcodes(cfg.getOpcodeCount())
				.jumps(cfg.getAllJumps().size())
				.preciselyResolvedJumps(resolvedJumps)
				.definitelyUnreachableJumps(definitelyUnreachable)
				.maybeUnreachableJumps(maybeUnreachable)
				.unsoundJumps(unsoundJumps)
				.maybeUnsoundJumps(maybeUnsoundJumps);
	}

	/**
	 * Cleans up the directory used for bytecode benchmark outputs.
	 */
	public void clean() {
		Path path = Paths.get("evm-outputs/benchmark");

		if (Files.exists(path))
			try {
				Files.walkFileTree(path, new SimpleFileVisitor<Path>() {
					@Override
					public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
						Files.delete(file);
						return FileVisitResult.CONTINUE;
					}

					@Override
					public FileVisitResult postVisitDirectory(Path dir, IOException exc) throws IOException {
						Files.delete(dir);
						return FileVisitResult.CONTINUE;
					}
				});
			} catch (IOException e) {
				log.error("error: {}", e.getMessage());
			}

		File f = new File(STATISTICS_FULLPATH);
		if (f.delete())
			log.info("{} deleted.", STATISTICS_FULLPATH);

		f = new File(LOGS_FULLPATH);
		if (f.delete())
			log.info("{} deleted.", LOGS_FULLPATH);

		f = new File(STATISTICSZEROJUMP_FULLPATH);
		if (f.delete())
			log.info("{} deleted.", STATISTICSZEROJUMP_FULLPATH);

		f = new File(FAILURE_FULLPATH);
		if (f.delete())
			log.info("{} deleted.", FAILURE_FULLPATH);
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

	public static void toFile(String FILE_PATH, String stats) {
		if (FILE_PATH == null || stats == null)
			throw new NullPointerException("(void EVMLiSA.toFile) FILE_PATH or stats null");

		synchronized (EVMLiSA.class) {
			try {
				File idea = new File(FILE_PATH);
				if (!idea.exists()) {
					FileWriter myWriter = new FileWriter(idea, true);

					String init = "Smart Contract, Total Opcodes, Total Jumps, Solved Jumps, Definitely unreachable jumps, Maybe unreachable jumps, Total solved Jumps, "
							+ "Unsound jumps, Maybe unsound jumps, % Total Solved, Time (millis), Time lost to get Storage, Actual time, Notes \n";

					myWriter.write(init + stats);
					myWriter.close();

				} else {
					FileWriter myWriter = new FileWriter(idea, true);
					myWriter.write(stats);
					myWriter.close();
				}

			} catch (IOException e) {
				log.error("An error occurred in {}", FILE_PATH);
			}
		}
	}

	/**
	 * Constructs a log message providing information about the analysis status.
	 *
	 * @param type                                     The type of analysis
	 *                                                     (e.g., "SUCCESS",
	 *                                                     "FAILURE").
	 * @param address                                  The address of the
	 *                                                     analyzed smart
	 *                                                     contract.
	 * @param smartContractsSize                       The total number of smart
	 *                                                     contracts to be
	 *                                                     analyzed.
	 * @param smartContractsTerminatedSuccessfullySize The number of smart
	 *                                                     contracts
	 *                                                     successfully
	 *                                                     terminated.
	 * @param analysesTerminated                       The total number of
	 *                                                     analyses terminated.
	 * @param analysesFailed                           The total number of
	 *                                                     failed analyses.
	 * @param threadsStarted                           The total number of
	 *                                                     threads started for
	 *                                                     the analysis.
	 * 
	 * @return The constructed log message.
	 */
	private String buildMessage(String type, String address, int smartContractsSize,
			int smartContractsTerminatedSuccessfullySize, int analysesTerminated,
			int analysesFailed, int threadsStarted) {
		return "[" + now() + " - " + Thread.currentThread().getName() + "] \t [" + type + "] "
				+ address + ", " +
				"analyses ended: " + (smartContractsTerminatedSuccessfullySize + analysesFailed) + ", " +
				"analyses remaining: " + (smartContractsSize - analysesTerminated) + ", " +
				"analyses not started yet: "
				+ ((smartContractsSize - analysesTerminated)
						- (threadsStarted - smartContractsTerminatedSuccessfullySize) + analysesFailed)
				+ ", " +
				"analysis in progress (active threads): "
				+ (threadsStarted - smartContractsTerminatedSuccessfullySize - analysesFailed) + " \n";
	}

	/**
	 * Retrieves the current timestamp formatted according to the DATE_FORMAT
	 * constant.
	 *
	 * @return A string representation of the current timestamp.
	 */
	private String now() {
		return DATE_FORMAT.format(System.currentTimeMillis());
	}

	/**
	 * Saves smart contracts bytecode from Etherscan.
	 * <p>
	 * This method reads a list of smart contract addresses from a file, then
	 * for each address, it retrieves the bytecode of the corresponding smart
	 * contract from Etherscan.io and saves it to a file. The method also limits
	 * the API requests to Etherscan.io to a maximum of 5 per second.
	 * </p>
	 *
	 * @throws Exception if an error occurs during the process.
	 */
	private void saveSmartContractsFromEtherscan() throws Exception {
		List<String> smartContracts = readSmartContractsFromFile(SMARTCONTRACTS_FULLPATH);

		for (int i = 0; i < smartContracts.size(); i++) {
			String address = smartContracts.get(i);

			String BYTECODE_FULLPATH = OUTPUT_DIR + "/bytecode/" + address + "/" + address
					+ ".sol";

			if (i % 5 == 0) {
				try {
					// I can do max 5 API request in 1 sec to Etherscan.io
					Thread.sleep(1000);
				} catch (InterruptedException e) {
					log.error("e: {}", e.getMessage());
				}
			}

			// Directory setup and bytecode retrieval
			try {
				Files.createDirectories(Paths.get(OUTPUT_DIR + "/" + "benchmark/" + address));

				// If the file does not exist, we will do an API request to
				// Etherscan
				File file = new File(BYTECODE_FULLPATH);
				if (!file.exists()) {
					numberOfAPIEtherscanRequest++;
					if (EVMFrontend.parseContractFromEtherscan(address, BYTECODE_FULLPATH))
						numberOfAPIEtherscanRequestOnSuccess++;

					log.info("Downloading {}, remaining: {}.", address,
							(smartContracts.size() - numberOfAPIEtherscanRequest));
				}
			} catch (Exception e) {
				continue;
			}
		}

		log.info("Downloaded {} smart contract.", numberOfAPIEtherscanRequestOnSuccess);
	}

	public static class Converter {
		long kilo = 1024;
		long mega = kilo * kilo;
		long giga = mega * kilo;
		long tera = giga * kilo;

		public String getSize(long size) {
			double kb = (double) size / kilo;
			double mb = kb / kilo;
			double gb = mb / kilo;
			double tb = gb / kilo;
			if (size < kilo) {
				return size + " Bytes";
			} else if (size < mega) {
				return String.format("%.2f", kb) + " KB";
			} else if (size < giga) {
				return String.format("%.2f", mb) + " MB";
			} else if (size < tera) {
				return String.format("%.2f", gb) + " GB";
			} else {
				return String.format("%.2f", tb) + " TB";
			}
		}
	}
}
