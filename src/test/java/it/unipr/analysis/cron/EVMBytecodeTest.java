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
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;
import java.util.Date;

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
	private final static boolean GENERATE_CFG = false;

	// Append statistics in file
	private final static boolean APPEND = true;

	private final String STATISTICS_FULLPATH = ACTUAL_RESULTS_DIR + "/statistics.csv";
	private final String LOGS_FULLPATH = ACTUAL_RESULTS_DIR + "/logs.txt";
	private final String SMARTCONTRACTS_FULLPATH = "benchmark/EtherScan1000.txt";

	// Statistics
	private int numberOfAPIEtherscanRequest = 0;
	private int numberOfAPIEtherscanRequestOnSuccess = 0;
	
	private final int CORES = Runtime.getRuntime().availableProcessors();
	
	private double sumSolvedJumpPercent = 0;

	@Test
	public void testSCFromEtherscan() throws Exception {
		String SC_ADDRESS = "0x22895ba3ee81ab5f12753bd13b52858f8857d518";
		toFileStatistics(newAnalysis(SC_ADDRESS));
	}

	public static void main(String[] args) throws Exception {
		new EVMBytecodeTest().testEVMBytecodeAnalysisMultiThread();
//		new EVMBytecodeTest().saveSmartContractsFromEtherscan(); // Save sc from etherscan
	}
	
	@Test
	public void testEVMBytecodeAnalysisMultiThread() throws Exception {
		clean();
		Object guardia = new Object();

		List<String> smartContracts = readSmartContractsFromFile();
		List<String> smartContractsTerminated = new ArrayList<String>();

		Thread[] threads = new Thread[smartContracts.size()];

		Runnable runnableHandler = new Runnable() {
			private int counter = 0;
			private Object mutex = new Object();
			int threadsStarted = 0;

			@Override
			public void run() {
				
				for (int i = 0; i < smartContracts.size(); i++) {
					String address = smartContracts.get(i);
					
					synchronized (mutex) {
						// We optimize parallelism by running n analyzes at a time with n = CORES
						while ((threadsStarted - smartContractsTerminated.size()) > CORES) {
							try {
								mutex.wait();
							} catch (InterruptedException e) {
								e.printStackTrace();
							}
						}
					}

					Runnable runnable = () -> {
						String myStats = "";

						try {

							myStats = newAnalysis(address);

							synchronized (mutex) {
								toFileStatistics(myStats);
								smartContractsTerminated.add(address);
								counter++;
								
								String msg = "SC: " + address + " finished at " + new Date() + ", " + 
										"ended: " + smartContractsTerminated.size() + ", " +
										"in progress: " + (smartContracts.size() - counter) + ", " +
										"active threads: " + (threadsStarted - smartContractsTerminated.size()) + ", " +
										"not started yet: " + ((smartContracts.size() - counter) - (threadsStarted - smartContractsTerminated.size())) + " \n";
								
								System.out.println(msg);
								toFileLogs(msg);

								mutex.notifyAll();
							}

						} catch (Exception e) {
							synchronized (mutex) {
								String msg = MyLogger.newLogger()
										.address(address)
										.notes("failure: " + e)
										.build().toString();
								toFileStatistics(msg);

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
						while (counter < smartContracts.size()) {
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
			
			String msg = "[TIMER] Setted: " + timeToWait + " millis " + 
					"(" + minutes + " minutes and " + seconds + " seconds) \n";
			msg += "Finish expected at " + new Date((new Date().getTime() + timeToWait)) + " \n";
			
			System.out.println(msg);
			toFileLogs(msg);
			toFileLogs("Number of cores: " + CORES + " \n");
			
			guardia.wait(timeToWait);

			for (int i = 0; i < smartContracts.size(); i++)
				threads[i].interrupt();
		}

		for (int i = 0; i < smartContracts.size(); i++) {
			if (!smartContractsTerminated.contains(smartContracts.get(i))) {
				String msg = MyLogger.newLogger()
						.address(smartContracts.get(i))
						.notes("Killed: timeout")
						.build().toString();
				toFileStatistics(msg);
			}
		}
		
		// TODO not working
		String msg = MyLogger.newLogger()
				.address("Total")
				.solvedJumpsPercent(((double) sumSolvedJumpPercent / smartContractsTerminated.size()))
				.build().toString();
//		toFileStatistics(msg);
//		System.out.println(msg);

		// Print statistics to standard output and log file		
		msg = "Total analysis: " + smartContracts.size() + ", " + 
				"succesfully: " + smartContractsTerminated.size() + ", " +
				"failed: " + (smartContracts.size() - smartContractsTerminated.size()) + " \n";
		
		System.out.println(msg);
		toFileLogs(msg);
		
		msg = "API Etherscan Request: " + numberOfAPIEtherscanRequest + ", " + 
				"succesfully: " + numberOfAPIEtherscanRequestOnSuccess + " \n";
		
		System.out.println(msg);
		toFileLogs(msg);

		System.out.println("Stats successfully written in " + STATISTICS_FULLPATH);
		
		return;
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
		File f2 = new File(LOGS_FULLPATH);
		f2.delete();
	}

	private String newAnalysis(String CONTRACT_ADDR) throws Exception {
		long start = System.currentTimeMillis();

		String BYTECODE_FULLPATH = EXPECTED_RESULTS_DIR + "/bytecodeBenchmark/" + CONTRACT_ADDR + "/" + CONTRACT_ADDR
				+ ".sol";

		// Directory setup and bytecode retrieval
		Files.createDirectories(Paths.get(EXPECTED_RESULTS_DIR + "/" + "bytecodeBenchmark/" + CONTRACT_ADDR));

		// If the file does not exists, we will do an API request to Etherscan
		File file = new File(BYTECODE_FULLPATH);
		if (!file.exists()) {
			numberOfAPIEtherscanRequest++;
			
			if(numberOfAPIEtherscanRequest % 5 == 0) {
				try {
					Thread.sleep(1001); // I can do max 5 API
										// request in 1 sec to
										// Etherscan.io
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
			}
			
			if (EVMFrontend.parseContractFromEtherscan(CONTRACT_ADDR, BYTECODE_FULLPATH))
				numberOfAPIEtherscanRequestOnSuccess++;
		}
		
		// Config and test run
		CronConfiguration conf = new CronConfiguration();
		conf.serializeResults = true;
		conf.abstractState = new SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>(
				new MonolithicHeap(), new EVMAbstractState(),
				new TypeEnvironment<>(new InferredTypes()));
		conf.testDir = "bytecodeBenchmark/" + CONTRACT_ADDR;
		conf.callGraph = new RTACallGraph();
		JumpChecker checker = new JumpChecker();
		conf.semanticChecks.add(checker);
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		conf.serializeInputs = true;
		if (GENERATE_CFG) {
			conf.analysisGraphs = GraphType.HTML_WITH_SUBNODES;
		}
		conf.programFile = CONTRACT_ADDR + ".sol";
		perform(conf);

		// Print the results
		EVMCFG baseCfg = checker.getComputedCFG();

		Triple<Integer, Integer, Integer> pair = dumpStatistics(baseCfg);
		long finish = System.currentTimeMillis();

		String stats = MyLogger.newLogger()
				.address(CONTRACT_ADDR)
				.opcodes(baseCfg.getNodesCount())
				.jumps(baseCfg.getAllJumps().size())
				.preciselyResolvedJumps(pair.getLeft())
				.soundResolvedJumps(pair.getMiddle())
				.unreachableJumps(pair.getRight())
				.time(finish - start)
				.build().toString();
		
		sumSolvedJumpPercent += ((double) (pair.getLeft() + pair.getMiddle() + pair.getRight()) / baseCfg.getAllJumps().size());
		
		return stats;
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

	private Triple<Integer, Integer, Integer> dumpStatistics(EVMCFG cfg) {
		System.err.println("##############");
		System.err.println("Total opcodes: " + cfg.getNodesCount());
		System.err.println("Total jumps: " + cfg.getAllJumps().size());

		int preciselyResolvedJumps = 0;
		int soundResolvedJumps = 0;
		int unreachableJumps = 0;
		
		// we are safe supposing that we have a single entry point
		Statement entryPoint = cfg.getEntrypoints().stream().findAny().get();
		for (Statement jumpNode : cfg.getAllJumps())
			if (jumpNode instanceof Jump) {
				if (!cfg.reachableFrom(entryPoint, jumpNode))
					unreachableJumps++;
				else if (cfg.getOutgoingEdges(jumpNode).size() == 1)
					preciselyResolvedJumps++;
				else if (cfg.getOutgoingEdges(jumpNode).size() > 1)
					soundResolvedJumps++;
			} else if (jumpNode instanceof Jumpi) {
				if (!cfg.reachableFrom(entryPoint, jumpNode))
					unreachableJumps++;
				else if (cfg.getOutgoingEdges(jumpNode).size() == 2)
					preciselyResolvedJumps++;
				else if (cfg.getOutgoingEdges(jumpNode).size() > 2)
					soundResolvedJumps++;
			}

		System.err.println("Precisely solved jumps: " + preciselyResolvedJumps);
		System.err.println("Sound solved jumps: " + soundResolvedJumps);
		System.err.println("Unreachable jumps: " + unreachableJumps);
		System.err.println("##############");

		return Triple.of(preciselyResolvedJumps, soundResolvedJumps ,unreachableJumps);
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
	 * Saves smart contracts bytecode from Etherscan.
	 * <p>
	 * This method reads a list of smart contract addresses from a file, then for each address,
	 * it retrieves the bytecode of the corresponding smart contract from Etherscan.io and saves it to a file.
	 * The method also limits the API requests to Etherscan.io to a maximum of 5 per second.
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
	
				// If the file does not exists, we will do an API request to Etherscan
				File file = new File(BYTECODE_FULLPATH);
				if (!file.exists()) {
					numberOfAPIEtherscanRequest++;
					if (EVMFrontend.parseContractFromEtherscan(address, BYTECODE_FULLPATH))
						numberOfAPIEtherscanRequestOnSuccess++;
					
					System.out.printf("Downloading %s, remaining: %s \n", address, (smartContracts.size() - numberOfAPIEtherscanRequest));
				}
			} catch (Exception e) {
				continue;
			}
		}
	}

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
				if(solvedJumpsPercent == 0)
					this.solvedJumpsPercent = ((double) (preciselyResolvedJumps + soundResolvedJumps + unreachableJumps) / jumps);
				this.preciselySolvedJumpsPercent = ((double) (preciselyResolvedJumps) / jumps);
			} else {
				if(solvedJumpsPercent == 0)
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
