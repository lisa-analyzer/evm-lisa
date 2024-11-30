package it.unipr;

import it.unipr.analysis.*;
import it.unipr.cfg.*;
import it.unipr.checker.JumpSolver;
import it.unipr.checker.ReentrancyChecker;
import it.unipr.checker.TxOriginChecker;
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
import it.unive.lisa.program.cfg.edge.SequentialEdge;
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
import java.util.HashSet;
import java.util.List;
import java.util.Scanner;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
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

	// Path
	private Path _outputDirPath = Paths.get("execution", "results");
	private String OUTPUT_DIR = _outputDirPath.toString();

	private String STATISTICS_FULLPATH = Paths.get("execution", "results").toString();
	private String STATISTICSZEROJUMP_FULLPATH = _outputDirPath.resolve("statisticsZeroJumps.csv").toString();
	private String FAILURE_FULLPATH = _outputDirPath.resolve("failure.csv").toString();
	private String LOGS_FULLPATH = _outputDirPath.resolve("logs.txt").toString();
	private static String SMARTCONTRACTS_FULLPATH = Paths.get("").toString();

	// Statistics
	private int numberOfAPIEtherscanRequest = 0;
	private int numberOfAPIEtherscanRequestOnSuccess = 0;
	private static final SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss,SSS");
	private int CORES;

	// Configuration
	private static final boolean REGENERATE = false;
	private static boolean ENABLE_REENTRANCY_CHECKER = false;
	private static boolean ENABLE_TXORIGIN_CHECKER = false;

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
		Options options = getOptions();
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
		boolean serializeInputs = cmd.hasOption("serialize-inputs");
		boolean dumpHTML = cmd.hasOption("html");
		boolean dumpDot = cmd.hasOption("dot");
		boolean dumpStatistics = cmd.hasOption("dump-stats");
		boolean downloadBytecode = cmd.hasOption("download-bytecode");
		boolean useStorageLive = cmd.hasOption("use-live-storage");
		String filepath = cmd.getOptionValue("filepath-bytecode");
		String stackSize = cmd.getOptionValue("stack-size");
		String stackSetSize = cmd.getOptionValue("stack-set-size");
		String benchmark = cmd.getOptionValue("benchmark");
		String coresOpt = cmd.getOptionValue("cores");
		boolean dumpReport = cmd.hasOption("dump-report");
		boolean useCreationCode = cmd.hasOption("creation-code");
		ENABLE_REENTRANCY_CHECKER = cmd.hasOption("checker-reentrancy");
		ENABLE_TXORIGIN_CHECKER = cmd.hasOption("checker-txorigin");
		boolean linkUnsoundJumpsToAllJumpdestOption = cmd.hasOption("link-unsound-jumps-to-all-jumpdest");
		String mnemonicInputFile = cmd.getOptionValue("filepath-mnemonic");

		// Download bytecode case
		if (downloadBytecode && benchmark != null) {
			SMARTCONTRACTS_FULLPATH = Paths.get(benchmark).toString();
			OUTPUT_DIR = Paths.get("download").toString();
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
			_outputDirPath = Paths.get(outputDir);
			OUTPUT_DIR = _outputDirPath.toString();
			STATISTICS_FULLPATH = _outputDirPath
					.resolve("statistics.csv")
					.toString();
			STATISTICSZEROJUMP_FULLPATH = _outputDirPath
					.resolve("statisticsZeroJumps.csv")
					.toString();
			FAILURE_FULLPATH = _outputDirPath
					.resolve("failure.csv")
					.toString();
			LOGS_FULLPATH = _outputDirPath
					.resolve("logs.txt")
					.toString();
		}

		if (useStorageLive && addressSC == null && benchmark == null) {
			log.warn("Address must be set if live storage option is activated.");
			log.warn("Live storage option deactivated.");
			useStorageLive = false;
		}

		if (useStorageLive)
			EVMAbstractState.setUseStorageLive();
		if (useCreationCode)
			EVMFrontend.setUseCreationCode();
		if (linkUnsoundJumpsToAllJumpdestOption)
			JumpSolver.setLinkUnsoundJumpsToAllJumpdest();

		// Creating json output notes
		JSONObject jsonOptions = new JSONObject();
		jsonOptions.put("address", addressSC);
		jsonOptions.put("serialize-inputs", serializeInputs);
		jsonOptions.put("dump-html", dumpHTML);
		jsonOptions.put("dump-dot", dumpDot);
		jsonOptions.put("dump-statistics", dumpStatistics);
		jsonOptions.put("download-bytecode", downloadBytecode);
		jsonOptions.put("use-storage-live", useStorageLive);
		jsonOptions.put("use-creation-code", useCreationCode);
		if (filepath != null)
			jsonOptions.put("input-filepath", filepath);
		else
			jsonOptions.put("input-filepath", mnemonicInputFile);
		jsonOptions.put("stack-size", AbstractStack.getStackLimit());
		jsonOptions.put("stack-set-size", AbstractStackSet.getStackSetLimit());
		jsonOptions.put("benchmark", benchmark);
		jsonOptions.put("cores", CORES);
		jsonOptions.put("dump-report", dumpReport);
		jsonOptions.put("output-directory", OUTPUT_DIR);
		jsonOptions.put("link-unsound-jumps-to-all-jumpdest", JumpSolver.getLinkUnsoundJumpsToAllJumpdest());

		// Run benchmark case
		if (benchmark != null) {
			SimpleDateFormat DATE_FORMAT_BENCHMARK = new SimpleDateFormat("yyyy-MM-dd-HH-mm-ss");
			String timestamp = DATE_FORMAT_BENCHMARK.format(System.currentTimeMillis());
			int ss = AbstractStack.getStackLimit();
			int sss = AbstractStackSet.getStackSetLimit();
			String postFix = timestamp + "-" + ss + "-" + sss;

			Files.createDirectories(_outputDirPath.resolve("benchmark"));
			SMARTCONTRACTS_FULLPATH = Paths.get(benchmark).toString();
			STATISTICS_FULLPATH = _outputDirPath
					.resolve("benchmark").resolve("statistics-" + postFix + ".csv")
					.toString();
			STATISTICSZEROJUMP_FULLPATH = _outputDirPath
					.resolve("benchmark")
					.resolve("statisticsZeroJumps-" + postFix + ".csv")
					.toString();
			FAILURE_FULLPATH = _outputDirPath
					.resolve("benchmark")
					.resolve("failure-" + postFix + ".csv")
					.toString();
			LOGS_FULLPATH = _outputDirPath
					.resolve("benchmark")
					.resolve("logs-" + postFix + ".txt")
					.toString();

			try {
				runBenchmark(jsonOptions);
			} catch (FileNotFoundException e) {
				log.error("File {} not found.", benchmark);
			}
			return;
		}

		// Error case
		if (addressSC == null && filepath == null && mnemonicInputFile == null) {
			log.error("Address or filepath required.");
			formatter.printHelp("help", options);
			System.exit(1);
		}

		// Single analysis case
		if (addressSC == null)
			addressSC = "no-address-" + System.currentTimeMillis();

		_outputDirPath = _outputDirPath.resolve(addressSC);
		OUTPUT_DIR = _outputDirPath.toString();

		Files.createDirectories(_outputDirPath);
		jsonOptions.put("output-directory", OUTPUT_DIR);

		if (outputDir == null)
			outputDir = OUTPUT_DIR;

		String workDir = Paths.get(outputDir).resolve(addressSC).toString();
		STATISTICS_FULLPATH = _outputDirPath.resolve(addressSC + "_STATISTICS.csv").toString();
		FAILURE_FULLPATH = _outputDirPath.resolve(addressSC + "_FAILURE.csv").toString();

		String BYTECODE_FULLPATH = mnemonicInputFile;
		if (mnemonicInputFile == null) {
			BYTECODE_FULLPATH = _outputDirPath.resolve(addressSC + ".opcode").toString();
			String bytecode;
			if (filepath == null) {
				bytecode = EVMFrontend.parseContractFromEtherscan(addressSC);
			} else {
				bytecode = new String(Files.readAllBytes(Paths.get(filepath)));
			}
			if (useCreationCode) {
				jsonOptions.put("bytecode", bytecode);
			} else if (bytecode != null) {
				// runtime code case
				jsonOptions.put("bytecode", bytecode.substring(0, bytecode.indexOf("fe")));
			}

			EVMFrontend.opcodesFromBytecode(bytecode, BYTECODE_FULLPATH);
		}

		Program program = EVMFrontend.generateCfgFromFile(BYTECODE_FULLPATH);

		long start = System.currentTimeMillis();
		long finish;

		LiSAConfiguration conf = new LiSAConfiguration();
		conf.serializeInputs = serializeInputs;
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new EVMAbstractState(addressSC),
				new TypeEnvironment<>(new InferredTypes()));
		conf.jsonOutput = dumpReport;
		conf.workdir = workDir;
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		JumpSolver checker = new JumpSolver();
		conf.semanticChecks.add(checker);
		conf.callGraph = new RTACallGraph();
		conf.serializeResults = false;
		conf.optimize = false;
		conf.useWideningPoints = false;
		if (dumpHTML)
			conf.analysisGraphs = GraphType.HTML_WITH_SUBNODES;
		else if (dumpDot)
			conf.analysisGraphs = GraphType.DOT;

		try {
			LiSA lisa = new LiSA(conf);
			lisa.run(program);
			Set<Statement> soundlySolved = getSoundlySolvedJumps(checker, lisa, program);

			// Print the results
			finish = System.currentTimeMillis();

			checkers(conf, lisa, program, checker, jsonOptions);

			MyLogger result = EVMLiSA.dumpStatistics(checker, soundlySolved)
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

	/**
	 * Performs a new analysis for a given smart contract. This method retrieves
	 * the bytecode (via API requests to Etherscan.io if necessary), generates
	 * the Control Flow Graph (CFG), configures the analysis parameters,
	 * executes the analysis, and collects the results.
	 *
	 * @param CONTRACT_ADDR the address of the smart contract to analyze.
	 * @param jsonOptions   a {@link JSONObject} containing configuration
	 *                          options and parameters for the analysis. The
	 *                          options may be updated during the analysis.
	 * 
	 * @return a {@link MyLogger} instance containing detailed statistics,
	 *             warnings, and execution logs for the analysis.
	 * 
	 * @throws Exception if any error occurs during directory setup, bytecode
	 *                       retrieval, CFG generation, or analysis execution.
	 */
	private MyLogger newAnalysis(String CONTRACT_ADDR, JSONObject jsonOptions) throws Exception {
		Path bytecodeWorkDir = Paths.get(OUTPUT_DIR, "benchmark", "bytecode", CONTRACT_ADDR);
		String BYTECODE_WORKDIR = bytecodeWorkDir.toString();

		Path bytecodeFullPath = bytecodeWorkDir.resolve(CONTRACT_ADDR + ".opcode");
		String BYTECODE_FULLPATH = bytecodeFullPath.toString();

		// Directory setup and bytecode retrieval
		Files.createDirectories(bytecodeWorkDir);

		// If the file does not exist, we will do an API request to Etherscan
		synchronized (EVMLiSA.class) {
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

				String bytecode = EVMFrontend.parseContractFromEtherscan(CONTRACT_ADDR);
				if (EVMFrontend.opcodesFromBytecode(bytecode, BYTECODE_FULLPATH))
					numberOfAPIEtherscanRequestOnSuccess++;
			}
		}

		// Configuration and test run
		Program program = EVMFrontend.generateCfgFromFile(BYTECODE_FULLPATH);

		long start = System.currentTimeMillis();

		LiSAConfiguration conf = new LiSAConfiguration();
		conf.serializeInputs = false;
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new EVMAbstractState(CONTRACT_ADDR),
				new TypeEnvironment<>(new InferredTypes()));
		conf.jsonOutput = false;
		conf.workdir = BYTECODE_WORKDIR;
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		JumpSolver checker = new JumpSolver();
		conf.semanticChecks.add(checker);
		conf.callGraph = new RTACallGraph();
		conf.serializeResults = false;
		conf.optimize = false;

		LiSA lisa = new LiSA(conf);
		lisa.run(program);

		Set<Statement> soundlySolved = getSoundlySolvedJumps(checker, lisa, program);

		long finish = System.currentTimeMillis();

		checkers(conf, lisa, program, checker, jsonOptions);

		return EVMLiSA.dumpStatistics(checker, soundlySolved)
				.address(CONTRACT_ADDR)
				.time(finish - start)
				.timeLostToGetStorage(MyCache.getInstance().getTimeLostToGetStorage(CONTRACT_ADDR))
				.buildJson(jsonOptions)
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
	Set<Statement> getSoundlySolvedJumps(JumpSolver checker, LiSA lisa, Program program) {
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
	 * Executes the specified semantic checkers on the provided program and
	 * configuration, updating the JSON options with warnings generated by the
	 * analysis. This method dynamically adds and runs semantic checks based on
	 * the enabled configuration flags.
	 *
	 * @param conf        the {@link LiSAConfiguration} used for static analysis
	 * @param lisa        the {@link LiSA} instance performing the analysis
	 * @param program     the {@link Program} representing the analyzed code
	 * @param checker     the {@link JumpSolver} providing CFG information for
	 *                        the analysis
	 * @param jsonOptions the {@link JSONObject} where the results of the
	 *                        analysis are stored
	 */
	void checkers(LiSAConfiguration conf, LiSA lisa, Program program, JumpSolver checker, JSONObject jsonOptions) {
		if (ENABLE_REENTRANCY_CHECKER) {
			// Clear existing checks and add the ReentrancyChecker
			conf.semanticChecks.clear();
			conf.semanticChecks.add(new ReentrancyChecker());
			lisa.run(program);

			// Store re-entrancy warnings in the JSON options
			jsonOptions.put("re-entrancy-warning",
					MyCache.getInstance().getReentrancyWarnings(checker.getComputedCFG().hashCode()));
		}

		if (ENABLE_TXORIGIN_CHECKER) {
			// Clear existing checks and add the TxOriginChecker
			conf.semanticChecks.clear();
			conf.semanticChecks.add(new TxOriginChecker());
			lisa.run(program);

			// Store tx-origin warnings in the JSON options
			jsonOptions.put("tx-origin-warning",
					MyCache.getInstance().getTxOriginWarnings(checker.getComputedCFG().hashCode()));
		}
	}

	/**
	 * Executes the benchmark for a set of smart contracts. This method handles
	 * the parallel execution of analyses on the smart contracts, collects the
	 * results, and logs relevant information, including statistics and
	 * execution logs.
	 *
	 * @param jsonOptions a {@link JSONObject} containing configuration options
	 *                        and parameters for the benchmark execution.
	 * 
	 * @throws Exception if an error occurs during the benchmark execution or
	 *                       analysis.
	 */
	private void runBenchmark(JSONObject jsonOptions) throws Exception {
		List<String> smartContracts = readSmartContractsFromFile(SMARTCONTRACTS_FULLPATH);
		List<String> smartContractsTerminatedSuccessfully = new ArrayList<>();
		List<String> smartContractsFailed = new ArrayList<>();

		synchronized (EVMLiSA.class) {
			long timeToWait = 1000 * 60 * 60 * 5; // 5 hours

			String msg = "Start: " + now() + ".\n";
			msg += "Cores: " + CORES + " (parallel analysis).\n";
			msg += "Analysis: " + smartContracts.size() + ".\n";
			msg += "Stack size = " + AbstractStack.getStackLimit() + ".\n";
			msg += "Stack set size = " + AbstractStackSet.getStackSetLimit() + ".\n";
			msg += "Heap size: " + new Converter().getSize(Runtime.getRuntime().totalMemory()) + ".\n";
			msg += "Heap Max size: " + new Converter().getSize(Runtime.getRuntime().maxMemory()) + ".\n\n";

			log.info(msg);
			toFile(LOGS_FULLPATH, msg);

			Runnable runnableHandler = new RunnableHandler(smartContracts, smartContractsTerminatedSuccessfully,
					smartContractsFailed, jsonOptions);
			Thread handler = new Thread(runnableHandler);
			handler.start();

			EVMLiSA.class.wait(timeToWait);
		}

		String msg = "End: " + now() + ".\n";
		msg += "Analysis: " + smartContracts.size() + ".\n";
		msg += "Successfully: " + smartContractsTerminatedSuccessfully.size() + ".\n";
		msg += "Failed: " + (smartContracts.size() - smartContractsTerminatedSuccessfully.size()) + ".\n";

		log.info(msg);
		toFile(LOGS_FULLPATH, msg);

		log.info("Statistics successfully written in {}.", STATISTICS_FULLPATH);
		log.info("Logs successfully written in {}.", LOGS_FULLPATH);
	}

	private class RunnableHandler implements Runnable {
		private final List<String> smartContracts;
		private final List<String> smartContractsTerminatedSuccessfully;
		private final List<String> smartContractsFailed;
		private final JSONObject jsonOptions;

		public RunnableHandler(List<String> smartContracts, List<String> smartContractsTerminatedSuccessfully,
				List<String> smartContractsFailed, JSONObject jsonOptions) {
			this.smartContracts = smartContracts;
			this.smartContractsTerminatedSuccessfully = smartContractsTerminatedSuccessfully;
			this.smartContractsFailed = smartContractsFailed;
			this.jsonOptions = jsonOptions;
		}

		@Override
		public void run() {
			ExecutorService executor = Executors.newFixedThreadPool(CORES);

			for (String address : smartContracts) {
				executor.submit(() -> {
					try {
						MyLogger myStats = newAnalysis(address, jsonOptions);

						synchronized (smartContractsTerminatedSuccessfully) {
							smartContractsTerminatedSuccessfully.add(address);

							if (myStats.jumpSize() == 0)
								toFile(STATISTICSZEROJUMP_FULLPATH, myStats.toString());
							else
								toFile(STATISTICS_FULLPATH, myStats.toString());

							toFile(LOGS_FULLPATH, buildMessage("SUCCESS", address, smartContracts.size(),
									smartContractsTerminatedSuccessfully.size(),
									smartContractsTerminatedSuccessfully.size(),
									smartContractsFailed.size()));
						}
					} catch (Throwable e) {
						synchronized (smartContractsFailed) {
							smartContractsFailed.add(address);

							String msg = MyLogger.newLogger()
									.address(address)
									.notes("failure: " + e + " - details: " + e.getMessage())
									.build().toString();

							log.error(msg);
							toFile(FAILURE_FULLPATH, msg);

							toFile(LOGS_FULLPATH, buildMessage("FAILURE", address, smartContracts.size(),
									smartContractsTerminatedSuccessfully.size(),
									smartContractsTerminatedSuccessfully.size(),
									smartContractsFailed.size()));
						}
					}
				});
			}

			executor.shutdown();
			try {
				if (!executor.awaitTermination(1, TimeUnit.HOURS)) {
					executor.shutdownNow();
					log.error("Timeout while waiting for tasks to complete");
				}
			} catch (InterruptedException e) {
				log.error("Execution interrupted: {}", e.getMessage());
				executor.shutdownNow();
			}

			synchronized (EVMLiSA.class) {
				EVMLiSA.class.notifyAll(); // All tests are finished
			}
		}
	}

	/**
	 * Dumps statistics related to jump resolution within a CFG (Control Flow
	 * Graph). This method calculates and logs various statistics, such as
	 * resolved jumps, unreachable jumps, unsound jumps, and more, based on the
	 * analysis performed by the {@link JumpSolver}.
	 *
	 * @param checker       the {@link JumpSolver} instance used to analyze the
	 *                          CFG and compute jump-related information.
	 * @param soundlySolved a set of {@link Statement} objects representing
	 *                          jumps that were soundly solved in the CFG.
	 * 
	 * @return a {@link MyLogger} instance containing the computed statistics
	 *             for logging or further analysis; returns {@code null} if no
	 *             entry points are found in the CFG.
	 */
	public static MyLogger dumpStatistics(JumpSolver checker, Set<Statement> soundlySolved) {
		EVMCFG cfg = checker.getComputedCFG();

		log.info("### Calculating statistics ###");

		Set<Statement> unreachableJumpNodes = checker.getUnreachableJumps();

		int resolvedJumps = 0;
		int definitelyUnreachable = 0;
		int maybeUnreachable = 0;
		int unsoundJumps = 0;
		int maybeUnsoundJumps = 0; // checker.getMaybeUnsoundJumps().size();

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

				if (topStackValuesPerJump != null && topStackValuesPerJump.contains(StackElement.NUMERIC_TOP)) {
					allJumpAreSound = false;
					break;
				}
			}

		// we are safe supposing that we have a single entry point
		for (Statement jumpNode : cfg.getAllJumps()) {
			if ((jumpNode instanceof Jump) || (jumpNode instanceof Jumpi)) {
				boolean reachableFrom;
				int key = cfg.hashCode() + entryPoint.hashCode() + jumpNode.hashCode();

				if (MyCache.getInstance().existsInReachableFrom(key)) {
					reachableFrom = MyCache.getInstance().isReachableFrom(key); // Caching
					log.debug("Value cached");
				} else {
					reachableFrom = cfg.reachableFrom(entryPoint, jumpNode);
					MyCache.getInstance().addReachableFrom(key, reachableFrom);
				}

				Set<StackElement> topStackValuesPerJump = checker.getTopStackValuesPerJump(jumpNode);

				if (pushedJumps.contains(jumpNode)) {
					resolvedJumps++;
					continue;
				}
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
				if (!topStackValuesPerJump.contains(StackElement.NUMERIC_TOP)) {
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
		Path path = Paths.get("evm-outputs", "benchmark");

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
				log.error("(dumpStatistics): {}", e.getMessage());
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

	public static String readFileAsString(String filePath) {
		try {
			Path path = Paths.get(filePath);
			return Files.readString(path);
		} catch (IOException e) {
			log.error("(readFileAsString): {}", e.getMessage());
			return null;
		}
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
	 * 
	 * @return The constructed log message.
	 */
	private String buildMessage(String type, String address, int smartContractsSize,
			int smartContractsTerminatedSuccessfullySize, int analysesTerminated,
			int analysesFailed) {
		return "[" + now() + " - " + Thread.currentThread().getName() + "] \t [" + type + "] "
				+ address + ", " +
				"ended: " + (smartContractsTerminatedSuccessfullySize + analysesFailed) + ", " +
				"remaining: " + (smartContractsSize - analysesTerminated) + " \n";
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

			String BYTECODE_FULLPATH = Paths
					.get(OUTPUT_DIR, "bytecode", address, address + ".sol")
					.toString();

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
				Files.createDirectories(Paths.get(OUTPUT_DIR, "benchmark", address));

				// If the file does not exist, we will do an API request to
				// Etherscan
				File file = new File(BYTECODE_FULLPATH);
				if (!file.exists()) {
					numberOfAPIEtherscanRequest++;

					String bytecode = EVMFrontend.parseContractFromEtherscan(address);
					if (EVMFrontend.opcodesFromBytecode(bytecode, BYTECODE_FULLPATH))
						numberOfAPIEtherscanRequestOnSuccess++;

					log.info("Downloading {}, remaining: {}.", address,
							(smartContracts.size() - numberOfAPIEtherscanRequest));
				}
			} catch (Exception e) {
				log.warn("Bytecode not downloaded: {}, cause: {}", address, e.getMessage());
			}
		}

		log.info("Downloaded {} smart contract.", numberOfAPIEtherscanRequestOnSuccess);
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

		Option outputOption = Option.builder("o")
				.longOpt("output")
				.desc("Output directory path.")
				.required(false)
				.hasArg(true)
				.build();

		Option filePathOption = Option.builder("f")
				.longOpt("filepath-bytecode")
				.desc("Filepath of the bytecode file.")
				.required(false)
				.hasArg(true)
				.build();

		Option filePathMnemonicOption = Option.builder()
				.longOpt("filepath-mnemonic")
				.desc("Filepath of the mnemonic file.")
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

		Option benchmarkOption = Option.builder("b")
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

		// Boolean parameters
		Option dumpStatisticsOption = Option.builder()
				.longOpt("dump-stats")
				.desc("Dump statistics.")
				.required(false)
				.hasArg(false)
				.build();

		Option dumpHtmlOption = Option.builder()
				.longOpt("html")
				.desc("Export a graphic HTML report.")
				.required(false)
				.hasArg(false)
				.build();

		Option dumpDotOption = Option.builder()
				.longOpt("dot")
				.desc("Export a dot-notation file.")
				.required(false)
				.hasArg(false)
				.build();

		Option serializeInputsOption = Option.builder()
				.longOpt("serialize-inputs")
				.desc("Serialize inputs.")
				.required(false)
				.hasArg(false)
				.build();

		Option downloadBytecodeOption = Option.builder()
				.longOpt("download-bytecode")
				.desc("Download the bytecode.")
				.required(false)
				.hasArg(false)
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

		Option dumpAnalysisReport = Option.builder()
				.longOpt("dump-report")
				.desc("Dump analysis report.")
				.required(false)
				.hasArg(false)
				.build();

		Option useCreationCodeOption = Option.builder()
				.longOpt("creation-code")
				.desc("Parse bytecode as creation code (instead of runtime code).")
				.required(false)
				.hasArg(false)
				.build();

		Option enableReentrancyCheckerOption = Option.builder()
				.longOpt("checker-reentrancy")
				.desc("Enable re-entrancy checker.")
				.required(false)
				.hasArg(false)
				.build();

		Option enableTxOriginCheckerOption = Option.builder()
				.longOpt("checker-txorigin")
				.desc("Enable tx-origin checker.")
				.required(false)
				.hasArg(false)
				.build();

		options.addOption(addressOption);
		options.addOption(outputOption);
		options.addOption(filePathOption);
		options.addOption(filePathMnemonicOption);
		options.addOption(stackSizeOption);
		options.addOption(stackSetSizeOption);
		options.addOption(benchmarkOption);
		options.addOption(coresOption);

		options.addOption(dumpStatisticsOption);
		options.addOption(serializeInputsOption);
		options.addOption(downloadBytecodeOption);
		options.addOption(useStorageLiveOption);
		options.addOption(linkUnsoundJumpsToAllJumpdestOption);
		options.addOption(dumpAnalysisReport);
		options.addOption(useCreationCodeOption);
		options.addOption(dumpHtmlOption);
		options.addOption(dumpDotOption);
		options.addOption(enableReentrancyCheckerOption);
		options.addOption(enableTxOriginCheckerOption);

		return options;
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
