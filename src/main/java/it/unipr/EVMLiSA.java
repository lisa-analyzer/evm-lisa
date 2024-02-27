package it.unipr;

import it.unipr.analysis.AbstractStack;
import it.unipr.analysis.AbstractStackSet;
import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.MyLogger;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Jump;
import it.unipr.cfg.Jumpi;
import it.unipr.checker.JumpSolver;
import it.unipr.frontend.EVMFrontend;
import it.unive.lisa.AnalysisException;
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
import org.apache.commons.lang3.tuple.Triple;

public class EVMLiSA {
	private String OUTPUT_DIR = "execution/results";

	// Path
	private String STATISTICS_FULLPATH = OUTPUT_DIR + "/statistics.csv";
	private String STATISTICSZEROJUMP_FULLPATH = OUTPUT_DIR + "/statisticsZeroJumps.csv";
	private String FAILURE_FULLPATH = OUTPUT_DIR + "/failure.csv";
	private String LOGS_FULLPATH = OUTPUT_DIR + "/logs.txt";
	private String SMARTCONTRACTS_FULLPATH = "";

	// Statistics
	private int numberOfAPIEtherscanRequest = 0;
	private int numberOfAPIEtherscanRequestOnSuccess = 0;
	private static SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("YYYY-MM-dd HH:mm:ss,SSS");
	private int CORES;
	private long startOfExecutionTime = 0;
	private String init = "Smart Contract, Total Opcodes, Total Jumps, Solved Jumps, Definitely unreachable jumps, Maybe unreachable jumps, Total solved Jumps, Not solved jumps, Unsound jumps, % Total Solved, Time (millis), Notes \n";

	/**
	 * Generates a control flow graph (represented as a LiSA {@code Program})
	 * from a EVM bytecode smart contract and runs the analysis on it.
	 * 
	 * @param args
	 * 
	 * @throws AnalysisException
	 * @throws IOException
	 */
	public static void main(String[] args) throws AnalysisException, IOException, Exception {
		new EVMLiSA().go(args);
	}

	private void go(String[] args) throws Exception {
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
		options.addOption(dumpStatisticsOption);
		Option dumpCFGOption = Option.builder("c")
				.longOpt("dump-cfg")
				.desc("dump the CFG")
				.required(false)
				.hasArg(false)
				.build();
		options.addOption(dumpCFGOption);

		CommandLineParser parser = new DefaultParser();
		HelpFormatter formatter = new HelpFormatter();
		CommandLine cmd = null;

		try {
			cmd = parser.parse(options, args);
		} catch (ParseException e) {
			System.out.println(e.getMessage());
			formatter.printHelp("help", options);

			System.exit(1);
		}

		String addressSC = cmd.getOptionValue("address");
		String outputDir = cmd.getOptionValue("output");
		Boolean dumpCFG = cmd.hasOption("dumpcfg");
		String dumpAnalysis = cmd.getOptionValue("dump-analysis");
		boolean dumpStatistics = cmd.hasOption("dump-stats");
		String filepath = cmd.getOptionValue("filepath");
		String stackSize = cmd.getOptionValue("stack-size");
		String stackSetSize = cmd.getOptionValue("stack-set-size");
		String benchmark = cmd.getOptionValue("benchmark");
		String coresOpt = cmd.getOptionValue("cores");

		// --cores
		if (coresOpt != null && Integer.parseInt(coresOpt) > 0)
			CORES = Integer.parseInt(coresOpt);
		else
			CORES = 1;

		// --stack-size & --stack-set-size
		try {
			if (stackSize != null && Integer.parseInt(stackSize) > 0)
				AbstractStack.setStackLimit(Integer.parseInt(stackSize));

			if (stackSetSize != null && Integer.parseInt(stackSetSize) > 0)
				AbstractStackSet.setStackSetSize(Integer.parseInt(stackSetSize));

		} catch (NumberFormatException e) {
			System.out.println("Size must be an integer");
			formatter.printHelp("help", options);

			System.exit(1);
		}

		// --output
		if (outputDir != null) {
			OUTPUT_DIR = outputDir;
			STATISTICS_FULLPATH = OUTPUT_DIR + "/statistics.csv";
			STATISTICSZEROJUMP_FULLPATH = OUTPUT_DIR + "/statisticsZeroJumps.csv";
			FAILURE_FULLPATH = OUTPUT_DIR + "/failure.csv";
			LOGS_FULLPATH = OUTPUT_DIR + "/logs.txt";
		}

		// --benchmark
		if (benchmark != null) {
			Files.createDirectories(Paths.get(OUTPUT_DIR));
			SMARTCONTRACTS_FULLPATH = benchmark;
			try {
				runBenchmark();
			} catch (FileNotFoundException e) {
				System.err.println("File " + benchmark + " not found.");
			}
			return;
		}

		if (addressSC == null && filepath == null) {
			// Error: no address and no filepath
			System.out.println("Address or filepath required");
			formatter.printHelp("help", options);
			System.exit(1);
		}

		OUTPUT_DIR += addressSC + "/";
		Files.createDirectories(Paths.get(OUTPUT_DIR));

		if (outputDir == null)
			outputDir = OUTPUT_DIR + "/" + addressSC + "_REPORT";

		STATISTICS_FULLPATH = OUTPUT_DIR + addressSC + "_STATISTICS" + ".csv";
		FAILURE_FULLPATH = OUTPUT_DIR + addressSC + "_FAILURE" + ".csv";

		String BYTECODE_FULLPATH = "";
		if (filepath == null) {
			BYTECODE_FULLPATH = OUTPUT_DIR + addressSC + ".sol";
			EVMFrontend.parseContractFromEtherscan(addressSC, BYTECODE_FULLPATH);
		} else
			BYTECODE_FULLPATH = filepath;

		Program program = EVMFrontend.generateCfgFromFile(BYTECODE_FULLPATH);

		long start = System.currentTimeMillis();
		long finish;

		LiSAConfiguration conf = new LiSAConfiguration();
		conf.serializeInputs = dumpCFG;
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new EVMAbstractState(),
				new TypeEnvironment<>(new InferredTypes()));
		conf.jsonOutput = false;
		conf.workdir = outputDir;
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		JumpSolver checker = new JumpSolver();
		conf.semanticChecks.add(checker);
		conf.callGraph = new RTACallGraph();
		conf.serializeResults = false;
		conf.optimize = false;

		if (dumpAnalysis != null) {
			if (dumpAnalysis.equals("dot"))
				conf.analysisGraphs = GraphType.DOT;
			else if (dumpAnalysis.equals("html"))
				conf.analysisGraphs = GraphType.HTML_WITH_SUBNODES;
		}

		try {
			LiSA lisa = new LiSA(conf);
			lisa.run(program);

			EVMCFG baseCfg = checker.getComputedCFG();

			Triple<Integer, Integer, Triple<Integer, Integer, Integer>> pair;

			pair = dumpStatistics(checker);

			finish = System.currentTimeMillis();

			String msg2 = "\nResults \n" +
					"Address: " + addressSC + "\n" +
					"Opcodes: " + baseCfg.getOpcodeCount() + "\n" +
					"Jumps: " + baseCfg.getAllJumps().size() + "\n" +
					"PreciselyResolvedJumps: " + pair.getLeft() + "\n" +
					"SoundResolvedJumps: " + pair.getMiddle() + "\n" +
					"DefinitelyUnreachableJumps: " + pair.getRight().getLeft() + "\n" +
					"MaybeUnreachableJumps: " + pair.getRight().getMiddle() + "\n" +
					"NotUnreachableJumps: " + pair.getRight().getRight() + "\n" +
					"Time (in millis): " + (finish - start) + "\n";

			System.out.println(msg2);

			if (dumpStatistics) {
				String msg = MyLogger.newLogger()
						.address(addressSC)
						.opcodes(baseCfg.getOpcodeCount())
						.jumps(baseCfg.getAllJumps().size())
						.preciselyResolvedJumps(pair.getLeft())
						.soundResolvedJumps(pair.getMiddle())
						.definitelyUnreachableJumps(pair.getRight().getLeft())
						.maybeUnreachableJumps(pair.getRight().getMiddle())
						.notSolvedJumps(pair.getRight().getRight())
						.unsoundJumps(checker.getUnsoundJumps().size())
						.time(finish - start)
						.notes("Stack.size: " + AbstractStack.getStackLimit() + " Stack-set.size: "
								+ AbstractStackSet.getStackSetLimit())
						.build().toString();

				toFileStatistics(msg);
				System.out.println("Statistics successfully written in " + STATISTICS_FULLPATH);
			}

		} catch (Throwable e) {
			finish = System.currentTimeMillis();

			String msg = MyLogger.newLogger()
					.address(addressSC)
					.notes("failure: " + e + " - details: " + e.getMessage())
					.time(finish - start)
					.build().toString();

			System.err.println(msg);

			if (dumpStatistics) {
				toFileFailure(msg);
				System.out.println("Failures successfully written in " + FAILURE_FULLPATH);
			}
		}
	}

	private MyLogger newAnalysis(String CONTRACT_ADDR) throws Exception {

		String BYTECODE_FULLPATH = OUTPUT_DIR + "/benchmark/" + CONTRACT_ADDR + "/" + CONTRACT_ADDR
				+ ".sol";

		// Directory setup and bytecode retrieval
		Files.createDirectories(Paths.get(OUTPUT_DIR + "/" + "benchmark/" + CONTRACT_ADDR));

		// If the file does not exists, we will do an API request to Etherscan
		File file = new File(BYTECODE_FULLPATH);
		if (!file.exists()) {
			numberOfAPIEtherscanRequest++;

			if (numberOfAPIEtherscanRequest % 5 == 0) {
				try {
					Thread.sleep(1001); // I can do max 5 API request in 1 sec
										// to Etherscan.io
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
			}

			if (EVMFrontend.parseContractFromEtherscan(CONTRACT_ADDR, BYTECODE_FULLPATH))
				numberOfAPIEtherscanRequestOnSuccess++;
		}

		// Config and test run
		Program program = EVMFrontend.generateCfgFromFile(BYTECODE_FULLPATH);

		long start = System.currentTimeMillis();

		LiSAConfiguration conf = new LiSAConfiguration();
		conf.serializeInputs = false;
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new EVMAbstractState(),
				new TypeEnvironment<>(new InferredTypes()));
		conf.jsonOutput = true;
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
		EVMCFG baseCfg = checker.getComputedCFG();

		Triple<Integer, Integer, Triple<Integer, Integer, Integer>> pair = EVMLiSA.dumpStatistics(checker);
		long finish = System.currentTimeMillis();

		return MyLogger.newLogger()
				.address(CONTRACT_ADDR)
				.opcodes(baseCfg.getNodesCount())
				.jumps(baseCfg.getAllJumps().size())
				.preciselyResolvedJumps(pair.getLeft())
				.soundResolvedJumps(pair.getMiddle())
				.definitelyUnreachableJumps(pair.getRight().getLeft())
				.maybeUnreachableJumps(pair.getRight().getMiddle())
				.notSolvedJumps(pair.getRight().getRight())
				.unsoundJumps(checker.getUnsoundJumps().size())
				.time(finish - start)
				.notes("Stack.size: " + AbstractStack.getStackLimit() + " Stack-set.size: "
						+ AbstractStackSet.getStackSetLimit())
				.build();
	}

	private void runBenchmark() throws Exception {
		clean();
		startOfExecutionTime = System.currentTimeMillis();
		Object guardia = new Object();

		List<String> smartContracts = readSmartContractsFromFile();
		List<String> smartContractsTerminatedSuccesfully = new ArrayList<String>();
		List<String> smartContractsFailed = new ArrayList<String>();

		Thread[] threads = new Thread[smartContracts.size()];

		Runnable runnableHandler = new Runnable() {
			private int analysesTerminated = 0;
			private int analysesFailed = 0;
			private Object mutex = new Object();
			int threadsStarted = 0;

			@Override
			public void run() {

				for (int i = 0; i < smartContracts.size(); i++) {
					String address = smartContracts.get(i);

					synchronized (mutex) {
						// We optimize parallelism by running n analyzes at a
						// time with n = CORES
						while ((threadsStarted - analysesTerminated) > CORES) {
							try {
								mutex.wait();
							} catch (InterruptedException e) {
								e.printStackTrace();
							}
						}
					}

					Runnable runnable = () -> {
						try {

							MyLogger myStats = newAnalysis(address);

							synchronized (mutex) {
								analysesTerminated++;
								smartContractsTerminatedSuccesfully.add(address);

								if (myStats.jumpSize() == 0)
									toFileStatisticsWithZeroJumps(myStats.toString());
								else
									toFileStatistics(myStats.toString());

								String msg = buildMessage("SUCCESS", address, smartContracts.size(),
										smartContractsTerminatedSuccesfully.size(), analysesTerminated,
										analysesFailed, threadsStarted);

								System.out.println(msg);
								toFileLogs(msg);

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

								System.err.println(msg);
								toFileFailure(msg);

								msg = buildMessage("FAILURE", address, smartContracts.size(),
										smartContractsTerminatedSuccesfully.size(), analysesTerminated,
										analysesFailed, threadsStarted);

								System.out.println(msg);
								toFileLogs(msg);

								mutex.notifyAll();
							}
						}
					};

					threads[i] = new Thread(runnable);
					threads[i].start();
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
					e.printStackTrace();
				}

				synchronized (guardia) {
					guardia.notifyAll(); // All tests are finished
				}

			} // ! run()
		}; // ! Runnable

		synchronized (guardia) {
			Thread handler = new Thread(runnableHandler);
			handler.start();

			int millisPerSmartContract = 25000 * 10;
			int extra = 120000;
			long blocks = smartContracts.size() / CORES * 20000;
			long timeToWait = smartContracts.size() * millisPerSmartContract + extra + blocks;

			// Statistics
			long minutes = (timeToWait / 1000) / 60;
			long seconds = (timeToWait / 1000) % 60;

			String msg = "Timeout setted: " + timeToWait + " millis " +
					"(" + minutes + " minutes and " + seconds + " seconds) \n";
			msg += "Started at " + now() + " \n";
			msg += "Finish (brute) expected at " + DATE_FORMAT.format(System.currentTimeMillis() + timeToWait) + " \n";
			msg += "Number of cores: " + CORES + " \n";
			msg += "Number of analyses: " + smartContracts.size() + " \n";
			msg += "\n"; // Blank line

			msg += "Stack size = " + AbstractStack.getStackLimit() + "\n";
			msg += "Stack set size = " + AbstractStackSet.getStackSetLimit() + "\n";
			msg += "\n"; // Blank line

			msg += "Heap size: " + new Converter().getSize(Runtime.getRuntime().totalMemory()) + "\n";
			msg += "Heap Max size: " + new Converter().getSize(Runtime.getRuntime().maxMemory()) + "\n";
			msg += "\n"; // Blank line

			System.out.println(msg);
			toFileLogs(msg);

			guardia.wait(timeToWait);

			for (int i = 0; i < smartContracts.size(); i++)
				threads[i].interrupt();
		}

		for (int i = 0; i < smartContracts.size(); i++) {
			if (!smartContractsTerminatedSuccesfully.contains(smartContracts.get(i)) &&
					!smartContractsFailed.contains(smartContracts.get(i))) {
				String msg = MyLogger.newLogger()
						.address(smartContracts.get(i))
						.notes("Killed: timeout")
						.build().toString();
				toFileFailure(msg);
			}
		}

		// Print statistics to standard output and log file
		long executionTime = System.currentTimeMillis() - startOfExecutionTime;
		String msg = "";
		msg += "\n"; // Blank line

		msg += "Total analysis: " + smartContracts.size() + ", " +
				"succesfully: " + smartContractsTerminatedSuccesfully.size() + ", " +
				"failed: " + (smartContracts.size() - smartContractsTerminatedSuccesfully.size()) + " \n";

		msg += "API Etherscan Request: " + numberOfAPIEtherscanRequest + ", " +
				"succesfully: " + numberOfAPIEtherscanRequestOnSuccess + " \n" +
				"Total duration: " + ((executionTime / 1000) / 60) + " minutes and " + ((executionTime / 1000) % 60)
				+ " seconds \n";

		System.out.println(msg);
		toFileLogs(msg);

		System.out.println("Statistics successfully written in " + STATISTICS_FULLPATH);
		System.out.println("Logs successfully written in " + LOGS_FULLPATH);
		System.out.println("Statistics with zero jumps successfully written in " + STATISTICSZEROJUMP_FULLPATH);
		System.out.println("Failures successfully written in " + FAILURE_FULLPATH);

		return;
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
	public static Triple<Integer, Integer, Triple<Integer, Integer, Integer>> dumpStatistics(JumpSolver checker) {
		EVMCFG cfg = checker.getComputedCFG();
		Set<Statement> unreachableJumpNodes = checker.getUnreachableJumps();
		int preciselyResolvedJumps = 0;
		int soundResolvedJumps = 0;

		int definitelyUnreachable = 0;
		int maybeUnreachable = 0;
		int notSolvedJumps = 0;

		// we are safe supposing that we have a single entry point
		Statement entryPoint = cfg.getEntrypoints().stream().findAny().get();
		for (Statement jumpNode : cfg.getAllJumps())
			if (jumpNode instanceof Jump) {
				if (cfg.getOutgoingEdges(jumpNode).size() == 1)
					preciselyResolvedJumps++;
				else if (cfg.getOutgoingEdges(jumpNode).size() > 1)
					soundResolvedJumps++;
				else if (cfg.reachableFrom(entryPoint, jumpNode) && unreachableJumpNodes.contains(jumpNode))
					definitelyUnreachable++;
				else if (!cfg.reachableFrom(entryPoint, jumpNode))
					maybeUnreachable++;
				else
					notSolvedJumps++;
			} else if (jumpNode instanceof Jumpi) {
				if (cfg.getOutgoingEdges(jumpNode).size() == 2)
					preciselyResolvedJumps++;
				else if (cfg.getOutgoingEdges(jumpNode).size() > 2)
					soundResolvedJumps++;
				else if (cfg.reachableFrom(entryPoint, jumpNode) && unreachableJumpNodes.contains(jumpNode))
					definitelyUnreachable++;
				else if (!cfg.reachableFrom(entryPoint, jumpNode))
					maybeUnreachable++;
				else
					notSolvedJumps++;
			}

		System.err.println("##############");
		System.err.println("Total opcodes: " + cfg.getOpcodeCount());
		System.err.println("Total jumps: " + cfg.getAllJumps().size());
		System.err.println("Precisely solved jumps: " + preciselyResolvedJumps);
		System.err.println("Sound solved jumps: " + soundResolvedJumps);
		System.err.println("Definitely unreachable jumps: " + definitelyUnreachable);
		System.err.println("Maybe unreachable jumps: " + maybeUnreachable);
		System.err.println("Not solved jumps: " + notSolvedJumps);
		System.err.println("Unsound jumps: " + checker.getUnsoundJumps().size());
		System.err.println("##############");

		return Triple.of(preciselyResolvedJumps, soundResolvedJumps,
				Triple.of(definitelyUnreachable, maybeUnreachable, notSolvedJumps));
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
				e.printStackTrace();
			}

		File f = new File(STATISTICS_FULLPATH);
		f.delete();
		f = new File(LOGS_FULLPATH);
		f.delete();
		f = new File(STATISTICSZEROJUMP_FULLPATH);
		f.delete();
		f = new File(FAILURE_FULLPATH);
		f.delete();
	}

	/**
	 * Reads smart contracts from a file and returns a list of strings.
	 *
	 * @return A list of strings containing the smart contracts read from the
	 *             file.
	 * 
	 * @throws Exception If an error occurs while reading the file.
	 */
	public ArrayList<String> readSmartContractsFromFile() throws Exception {
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
			System.err.println("[ERROR] " + SMARTCONTRACTS_FULLPATH + " not found");
			throw e;
		}

		return smartContractsRead;
	}

	/**
	 * Writes the given statistics to a file.
	 *
	 * @param stats The statistics to be written to the file.
	 */
	private void toFileStatistics(String stats) {
		synchronized (STATISTICS_FULLPATH) {
			try {
				File idea = new File(STATISTICS_FULLPATH);
				if (!idea.exists()) {
					FileWriter myWriter = new FileWriter(idea, true);
					myWriter.write(init + stats);
					myWriter.close();

				} else {
					FileWriter myWriter = new FileWriter(idea, true);
					myWriter.write(stats);
					myWriter.close();
				}

			} catch (IOException e) {
				System.err.println("An error occurred. (toFileStatistics)");
				e.printStackTrace();
			}
		}
	}

	/**
	 * Writes the given statistics to a file.
	 *
	 * @param stats The statistics to be written to the file.
	 */
	private void toFileStatisticsWithZeroJumps(String stats) {
		synchronized (STATISTICSZEROJUMP_FULLPATH) {
			try {
				File idea = new File(STATISTICSZEROJUMP_FULLPATH);
				if (!idea.exists()) {
					FileWriter myWriter = new FileWriter(idea, true);
					myWriter.write(init + stats);
					myWriter.close();

				} else {
					FileWriter myWriter = new FileWriter(idea, true);
					myWriter.write(stats);
					myWriter.close();
				}

			} catch (IOException e) {
				System.err.println("An error occurred. (toFileStatisticsWithZeroJumps)");
				e.printStackTrace();
			}
		}
	}

	/**
	 * Writes the given failures to a file.
	 *
	 * @param stats The failures to be written to the file.
	 */
	private void toFileFailure(String stats) {
		synchronized (FAILURE_FULLPATH) {
			try {
				File idea = new File(FAILURE_FULLPATH);
				if (!idea.exists()) {
					FileWriter myWriter = new FileWriter(idea, true);
					myWriter.write(init + stats);
					myWriter.close();

				} else {
					FileWriter myWriter = new FileWriter(idea, true);
					myWriter.write(stats);
					myWriter.close();
				}

			} catch (IOException e) {
				System.err.println("An error occurred. (toFileFailure)");
				e.printStackTrace();
			}
		}
	}

	/**
	 * Writes the given message to a file.
	 *
	 * @param msg The logs to be written to the file.
	 */
	private void toFileLogs(String msg) {
		synchronized (LOGS_FULLPATH) {
			try {
				File idea = new File(LOGS_FULLPATH);

				FileWriter myWriter = new FileWriter(idea, true);
				myWriter.write(msg);
				myWriter.close();

			} catch (IOException e) {
				System.err.println("An error occurred. (toFileLogs)");
				e.printStackTrace();
			}
		}
	}

	/**
	 * Constructs a log message providing information about the analysis status.
	 *
	 * @param type                                    The type of analysis
	 *                                                    (e.g., "SUCCESS",
	 *                                                    "FAILURE").
	 * @param address                                 The address of the
	 *                                                    analyzed smart
	 *                                                    contract.
	 * @param smartContractsSize                      The total number of smart
	 *                                                    contracts to be
	 *                                                    analyzed.
	 * @param smartContractsTerminatedSuccesfullySize The number of smart
	 *                                                    contracts successfully
	 *                                                    terminated.
	 * @param analysesTerminated                      The total number of
	 *                                                    analyses terminated.
	 * @param analysesFailed                          The total number of failed
	 *                                                    analyses.
	 * @param threadsStarted                          The total number of
	 *                                                    threads started for
	 *                                                    the analysis.
	 * 
	 * @return The constructed log message.
	 */
	private String buildMessage(String type, String address, int smartContractsSize,
			int smartContractsTerminatedSuccesfullySize, int analysesTerminated,
			int analysesFailed, int threadsStarted) {
		return "[" + now() + " - " + Thread.currentThread().getName() + "] \t [" + type + "] "
				+ address + ", " +
				"analyses ended: " + (smartContractsTerminatedSuccesfullySize + analysesFailed) + ", " +
				"analyses remaining: " + (smartContractsSize - analysesTerminated) + ", " +
				"analyses not started yet: "
				+ ((smartContractsSize - analysesTerminated)
						- (threadsStarted - smartContractsTerminatedSuccesfullySize) + analysesFailed)
				+ ", " +
				"analysis in progress (active threads): "
				+ (threadsStarted - smartContractsTerminatedSuccesfullySize - analysesFailed) + " \n";
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
	@SuppressWarnings("unused")
	private void saveSmartContractsFromEtherscan() throws Exception {
		List<String> smartContracts = readSmartContractsFromFile();

		for (int i = 0; i < smartContracts.size(); i++) {
			String address = smartContracts.get(i);

			String BYTECODE_FULLPATH = OUTPUT_DIR + "/benchmark/" + address + "/" + address
					+ ".sol";

			if (i % 5 == 0) {
				try {
					Thread.sleep(1001); // I can do max 5 API
										// request in 1 sec to
										// Etherscan.io
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
			}

			// Directory setup and bytecode retrieval
			try {
				Files.createDirectories(Paths.get(OUTPUT_DIR + "/" + "benchmark/" + address));

				// If the file does not exists, we will do an API request to
				// Etherscan
				File file = new File(BYTECODE_FULLPATH);
				if (!file.exists()) {
					numberOfAPIEtherscanRequest++;
					if (EVMFrontend.parseContractFromEtherscan(address, BYTECODE_FULLPATH))
						numberOfAPIEtherscanRequestOnSuccess++;

					System.out.printf("Downloading %s, remaining: %s \n", address,
							(smartContracts.size() - numberOfAPIEtherscanRequest));
				}
			} catch (Exception e) {
				continue;
			}
		}
	}

	public class Converter {
		long kilo = 1024;
		long mega = kilo * kilo;
		long giga = mega * kilo;
		long tera = giga * kilo;

		public String getSize(long size) {
			String s = "";
			double kb = (double) size / kilo;
			double mb = kb / kilo;
			double gb = mb / kilo;
			double tb = gb / kilo;
			if (size < kilo) {
				s = size + " Bytes";
			} else if (size >= kilo && size < mega) {
				s = String.format("%.2f", kb) + " KB";
			} else if (size >= mega && size < giga) {
				s = String.format("%.2f", mb) + " MB";
			} else if (size >= giga && size < tera) {
				s = String.format("%.2f", gb) + " GB";
			} else if (size >= tera) {
				s = String.format("%.2f", tb) + " TB";
			}
			return s;
		}
	}

}
