package it.unipr.analysis.cron;

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

import org.apache.commons.lang3.tuple.Triple;
import org.junit.Before;
import org.junit.Test;

import it.unipr.analysis.EVMAbstractState;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Jump;
import it.unipr.cfg.Jumpi;
import it.unipr.checker.JumpChecker;
import it.unipr.frontend.EVMFrontend;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.conf.LiSAConfiguration.GraphType;
import it.unive.lisa.interprocedural.ModularWorstCaseAnalysis;
import it.unive.lisa.interprocedural.callgraph.RTACallGraph;
import it.unive.lisa.program.cfg.statement.Statement;

public class EVMBytecodeTest extends EVMBytecodeAnalysisExecutor {

	// Choose whether to generate the CFG or not
	private final static boolean GENERATE_CFG = true;

	// Append statistics in file
	private final static boolean APPEND = true;
	
	// Regenerates the smart contracts source code in the case
	private final static boolean REGENERATE = false;

	// Path
	private final String STATISTICS_FULLPATH = ACTUAL_RESULTS_DIR + "/statistics.csv";
	private final String STATISTICSZEROJUMP_FULLPATH = ACTUAL_RESULTS_DIR + "/statisticsZeroJumps.csv";
	private final String FAILURE_FULLPATH = ACTUAL_RESULTS_DIR + "/failure.csv";
	private final String LOGS_FULLPATH = ACTUAL_RESULTS_DIR + "/logs.txt";
	private final String SMARTCONTRACTS_FULLPATH = "benchmark/EtherScan1000.txt";

	// Statistics
	private int numberOfAPIEtherscanRequest = 0;
	private int numberOfAPIEtherscanRequestOnSuccess = 0;
	private static SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("YYYY-MM-dd HH:mm:ss,SSS");
	private final int CORES = Runtime.getRuntime().availableProcessors();
	private long startOfExecutionTime = 0;

	@Test
	public void testSCFromEtherscan() throws Exception {
		String SC_ADDRESS = "0x40f941E48A552bF496B154Af6bf55725f18D77c3";
		toFileStatistics(newAnalysis(SC_ADDRESS).toString());
	}

	public static void main(String[] args) throws Exception {
		new EVMBytecodeTest().testEVMBytecodeAnalysisMultiThread();
//		new EVMBytecodeTest().saveSmartContractsFromEtherscan(); // Save sc from etherscan
	}

	@Test
	public void testEVMBytecodeAnalysisMultiThread() throws Exception {
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
								
								if(myStats.jumpSize() == 0)
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

			int millisPerSmartContract = 25000;
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

	private MyLogger newAnalysis(String CONTRACT_ADDR) throws Exception {
		long start = System.currentTimeMillis();

		String BYTECODE_FULLPATH = EXPECTED_RESULTS_DIR + "/bytecodeBenchmark/" + CONTRACT_ADDR + "/" + CONTRACT_ADDR
				+ ".sol";

		// Directory setup and bytecode retrieval
		Files.createDirectories(Paths.get(EXPECTED_RESULTS_DIR + "/" + "bytecodeBenchmark/" + CONTRACT_ADDR));

		// If the file does not exists, we will do an API request to Etherscan
		File file = new File(BYTECODE_FULLPATH);
		if (!file.exists() || REGENERATE) {
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
		CronConfiguration conf = new CronConfiguration();
		conf.serializeResults = false;
		conf.abstractState = new SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>(
				new MonolithicHeap(), new EVMAbstractState(),
				new TypeEnvironment<>(new InferredTypes()));
		conf.testDir = "bytecodeBenchmark/" + CONTRACT_ADDR;
		conf.callGraph = new RTACallGraph();
		JumpChecker checker = new JumpChecker();
		conf.semanticChecks.add(checker);
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		conf.serializeInputs = false;

		if (GENERATE_CFG) {
			conf.analysisGraphs = GraphType.DOT;
		}
		conf.programFile = CONTRACT_ADDR + ".sol";
		perform(conf);

		// Print the results
		EVMCFG baseCfg = checker.getComputedCFG();

		Triple<Integer, Integer, Integer> pair = dumpStatistics(checker);
		long finish = System.currentTimeMillis();

		return MyLogger.newLogger()
				.address(CONTRACT_ADDR)
				.opcodes(baseCfg.getNodesCount())
				.jumps(baseCfg.getAllJumps().size())
				.preciselyResolvedJumps(pair.getLeft())
				.soundResolvedJumps(pair.getMiddle())
				.unreachableJumps(pair.getRight())
				.time(finish - start)
				.build();
	}
	
	/**
	 * Cleans up the directory used for bytecode benchmark outputs.
	 */
	@Before
	public void clean() {
		Path path = Paths.get("evm-outputs/bytecodeBenchmark");

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
			e.printStackTrace();
		}

		return smartContractsRead;
	}

	/**
	 * Calculates and prints statistics about the control flow graph (CFG) of the provided EVMCFG object.
	 *
	 * @param checker The control flow graph (CFG) of the Ethereum Virtual Machine (EVM) bytecode.
	 * @return A Triple containing the counts of precisely resolved jumps, sound resolved jumps, and unreachable jumps.
	 */
	private Triple<Integer, Integer, Integer> dumpStatistics(JumpChecker checker) {
		EVMCFG cfg = checker.getComputedCFG();
		Set<Statement> unreachableJumpNodes = checker.getUnreachableJumps();
		int preciselyResolvedJumps = 0;
		int soundResolvedJumps = 0;
		int unreachableJumps = 0;

		// we are safe supposing that we have a single entry point
		Statement entryPoint = cfg.getEntrypoints().stream().findAny().get();
		for (Statement jumpNode : cfg.getAllJumps())
			if (jumpNode instanceof Jump) {
				if (cfg.getOutgoingEdges(jumpNode).size() == 1)
					preciselyResolvedJumps++;
				else if (cfg.getOutgoingEdges(jumpNode).size() > 1)
					soundResolvedJumps++;
				else if (!cfg.reachableFrom(entryPoint, jumpNode) || unreachableJumpNodes.contains(jumpNode))
					unreachableJumps++;
			} else if (jumpNode instanceof Jumpi) {
				if (cfg.getOutgoingEdges(jumpNode).size() == 2)
					preciselyResolvedJumps++;
				else if (cfg.getOutgoingEdges(jumpNode).size() > 2)
					soundResolvedJumps++;
				else if (!cfg.reachableFrom(entryPoint, jumpNode)|| unreachableJumpNodes.contains(jumpNode))
					unreachableJumps++;
			}

		System.err.println("##############");
		System.err.println("Total opcodes: " + cfg.getNodesCount());
		System.err.println("Total jumps: " + cfg.getAllJumps().size());
		System.err.println("Precisely solved jumps: " + preciselyResolvedJumps);
		System.err.println("Sound solved jumps: " + soundResolvedJumps);
		System.err.println("Unreachable jumps: " + unreachableJumps);
		System.err.println("##############");

		return Triple.of(preciselyResolvedJumps, soundResolvedJumps, unreachableJumps);
	}

	/**
	 * Writes the given statistics to a file.
	 *
	 * @param stats The statistics to be written to the file.
	 */
	private void toFileStatistics(String stats) {
		synchronized (STATISTICS_FULLPATH) {
			String init = "Smart Contract, Total Opcodes, Total Jumps, Precisely solved Jumps, Sound solved Jumps, Unreachable Jumps, Total solved Jumps, % Precisely Solved, % Total Solved, Time (millis), Thread, Notes \n";
			try {
				File idea = new File(STATISTICS_FULLPATH);
				if (!idea.exists()) {
					FileWriter myWriter = new FileWriter(idea, APPEND);
					myWriter.write(init + stats);
					myWriter.close();

				} else {
					FileWriter myWriter = new FileWriter(idea, APPEND);
					myWriter.write(stats);
					myWriter.close();
				}

			} catch (IOException e) {
				System.err.println("An error occurred.");
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
			String init = "Smart Contract, Total Opcodes, Total Jumps, Precisely solved Jumps, Sound solved Jumps, Unreachable Jumps, Total solved Jumps, % Precisely Solved, % Total Solved, Time (millis), Thread, Notes \n";
			try {
				File idea = new File(STATISTICSZEROJUMP_FULLPATH);
				if (!idea.exists()) {
					FileWriter myWriter = new FileWriter(idea, APPEND);
					myWriter.write(init + stats);
					myWriter.close();

				} else {
					FileWriter myWriter = new FileWriter(idea, APPEND);
					myWriter.write(stats);
					myWriter.close();
				}

			} catch (IOException e) {
				System.err.println("An error occurred.");
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
			String init = "Smart Contract, Total Opcodes, Total Jumps, Precisely solved Jumps, Sound solved Jumps, Unreachable Jumps, Total solved Jumps, % Precisely Solved, % Total Solved, Time (millis), Thread, Notes \n";
			try {
				File idea = new File(FAILURE_FULLPATH);
				if (!idea.exists()) {
					FileWriter myWriter = new FileWriter(idea, APPEND);
					myWriter.write(init + stats);
					myWriter.close();

				} else {
					FileWriter myWriter = new FileWriter(idea, APPEND);
					myWriter.write(stats);
					myWriter.close();
				}

			} catch (IOException e) {
				System.err.println("An error occurred.");
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

				FileWriter myWriter = new FileWriter(idea, APPEND);
				myWriter.write(msg);
				myWriter.close();

			} catch (IOException e) {
				System.err.println("An error occurred.");
				e.printStackTrace();
			}
		}
	}
	
	/**
	 * Constructs a log message providing information about the analysis status.
	 *
	 * @param type                                The type of analysis (e.g., "SUCCESS", "FAILURE").
	 * @param address                             The address of the analyzed smart contract.
	 * @param smartContractsSize                  The total number of smart contracts to be analyzed.
	 * @param smartContractsTerminatedSuccesfullySize The number of smart contracts successfully terminated.
	 * @param analysesTerminated                  The total number of analyses terminated.
	 * @param analysesFailed                      The total number of failed analyses.
	 * @param threadsStarted                      The total number of threads started for the analysis.
	 * @return                                    The constructed log message.
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
						- (threadsStarted - smartContractsTerminatedSuccesfullySize) + analysesFailed) + ", " +
				"analysis in progress (active threads): "
				+ (threadsStarted - smartContractsTerminatedSuccesfullySize - analysesFailed) + " \n";
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
		List<String> smartContracts = readSmartContractsFromFile();

		for (int i = 0; i < smartContracts.size(); i++) {
			String address = smartContracts.get(i);

			String BYTECODE_FULLPATH = EXPECTED_RESULTS_DIR + "/bytecodeBenchmark/" + address + "/" + address
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
				Files.createDirectories(Paths.get(EXPECTED_RESULTS_DIR + "/" + "bytecodeBenchmark/" + address));

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
	
	/**
	 * Retrieves the current timestamp formatted according to the DATE_FORMAT constant.
	 *
	 * @return A string representation of the current timestamp.
	 */
	private String now() {
		return DATE_FORMAT.format(System.currentTimeMillis());
	}

	/**
	 * Represents a logger object for recording statistical data related to Ethereum smart contracts.
	 */
	private static class MyLogger {
		private static String divider = ", ";
		private String address;
		private int opcodes;
		private int jumps;
		private int preciselyResolvedJumps;
		private int soundResolvedJumps;
		private int unreachableJumps;
		private int totalResolvedJumps;
		private double preciselySolvedJumpsPercent;
		private double solvedJumpsPercent;
		private long time;
		private String notes;
		private String currentThread;

		private MyLogger() {
			this.address = null;
			this.opcodes = 0;
			this.jumps = 0;
			this.preciselyResolvedJumps = 0;
			this.soundResolvedJumps = 0;
			this.unreachableJumps = 0;
			this.solvedJumpsPercent = 0;
			this.time = 0;
			this.notes = "";
			this.currentThread = null;
		}

		private MyLogger(String address, int opcodes, int jumps, int preciselyResolvedJumps, int soundResolvedJumps,
				int unreachableJumps, int totalResolvedJumps, double solvedJumpsPercent, long time, String notes) {
			this.address = address;
			this.opcodes = opcodes;
			this.jumps = jumps;
			this.preciselyResolvedJumps = preciselyResolvedJumps;
			this.soundResolvedJumps = soundResolvedJumps;
			this.unreachableJumps = unreachableJumps;
			if (jumps != 0) {
				if (solvedJumpsPercent == 0)
					this.solvedJumpsPercent = ((double) (preciselyResolvedJumps + soundResolvedJumps + unreachableJumps)
							/ jumps);
				this.preciselySolvedJumpsPercent = ((double) (preciselyResolvedJumps) / jumps);
			} else {
				if (solvedJumpsPercent == 0)
					this.solvedJumpsPercent = -1;
				this.preciselySolvedJumpsPercent = -1;
			}
			this.totalResolvedJumps = preciselyResolvedJumps + soundResolvedJumps;
			this.notes = notes;
			this.time = time;
			this.currentThread = Thread.currentThread().getName();
		}

		public static MyLogger newLogger() {
			return new MyLogger();
		}

		public MyLogger address(String address) {
			this.address = address;
			return this;
		}

		public MyLogger opcodes(int opcodes) {
			this.opcodes = opcodes;
			return this;
		}

		public MyLogger jumps(int jumps) {
			this.jumps = jumps;
			return this;
		}

		public MyLogger preciselyResolvedJumps(int preciselyResolvedJumps) {
			this.preciselyResolvedJumps = preciselyResolvedJumps;
			return this;
		}

		public MyLogger soundResolvedJumps(int soundResolvedJumps) {
			this.soundResolvedJumps = soundResolvedJumps;
			return this;
		}

		public MyLogger unreachableJumps(int unreachableJumps) {
			this.unreachableJumps = unreachableJumps;
			return this;
		}

		public MyLogger solvedJumpsPercent(double solvedJumpsPercent) {
			this.solvedJumpsPercent = solvedJumpsPercent;
			return this;
		}

		public MyLogger time(long time) {
			this.time = time;
			return this;
		}

		public MyLogger notes(String notes) {
			this.notes = notes;
			return this;
		}

		public MyLogger build() {
			return new MyLogger(address, opcodes, jumps, preciselyResolvedJumps, soundResolvedJumps,
					unreachableJumps, totalResolvedJumps, solvedJumpsPercent, time, notes);
		}
		
		public int jumpSize() { 
			return jumps; 
		}

		@Override
		public String toString() {
			return address + divider +
					opcodes + divider +
					jumps + divider +
					preciselyResolvedJumps + divider +
					soundResolvedJumps + divider +
					unreachableJumps + divider +
					totalResolvedJumps + divider +
					preciselySolvedJumpsPercent + divider +
					solvedJumpsPercent + divider +
					time + divider +
					currentThread + divider +
					notes + " \n";
		}
	}
}
