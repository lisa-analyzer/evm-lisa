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
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.statement.Statement;

public class EVMBytecodeTest extends EVMBytecodeAnalysisExecutor {

	// Choose whether to generate the CFG or not
	private final static boolean GENERATE_CFG = false;

	// Append statistics in file
	private final static boolean APPEND = true;

	private final String STATISTICS = ACTUAL_RESULTS_DIR + "/statistics.xls";
	private final String SMARTCONTRACTS_FULLPATH = "benchmark/smartContracts.txt";
//	private final String SMARTCONTRACTS_FULLPATH = "benchmark/failed.txt";
//	private final String SMARTCONTRACTS_FULLPATH = "benchmark/failed-small.txt";

	// Statistics
	private int numberOfAPIEtherscanRequest = 0;
	private int numberOfAPIEtherscanRequestOnSuccess = 0;

	public void testSCFromEtherscan() throws Exception {
		String SC_ADDRESS = "0x000000000d38df53b45c5733c7b34000de0bdf52";
		toFile(newAnalysis(SC_ADDRESS));
	}
	
	@Test
	public void testEVMBytecodeAnalysisMultiThread() throws Exception {
		Object guardia = new Object();

		List<String> smartContracts = readSmartContractsFromFile();
		List<String> smartContractsTerminated = new ArrayList<String>();

		Thread[] threads = new Thread[smartContracts.size()];

		Runnable runnableHandler = new Runnable() {
			private int counter = 0;
			private Object mutex = new Object();

			@Override
			public void run() {
				synchronized (mutex) {
					for (int i = 0; i < smartContracts.size(); i++) {
						String address = smartContracts.get(i);

						if (i % 4 == 0) {
							try {
								Thread.sleep(1001); // I can do max 5 API
													// request in 1 sec to
													// Etherscan.io
							} catch (InterruptedException e) {
								e.printStackTrace();
							}
						}

						Runnable runnable = () -> {
							String myStats = "";

							try {

								myStats = newAnalysis(address);

								synchronized (mutex) {
									toFile(myStats);
									smartContractsTerminated.add(address);
									counter++;

									System.out.printf("SC: %s, SC ended: %s, in progress: %s \n", smartContracts.size(),
											smartContractsTerminated.size(), (smartContracts.size() - counter));

									mutex.notifyAll();
								}

							} catch (Exception e) {
								synchronized (mutex) {
									String msg = MyLogger.newLogger()
											.address(address)
											.notes("failure: " + e)
											.build().toString();
									toFile(msg);

									mutex.notifyAll();
								}
							}
						};

						threads[i] = new Thread(runnable);
						threads[i].start();
					}

					try {
						while (counter < smartContracts.size()) {
							mutex.wait();
						}

					} catch (InterruptedException e) {
						e.printStackTrace();
					}

					synchronized (guardia) {
						guardia.notifyAll(); // All tests are finished
					}

				}

			} // ! run()
		}; // ! Runnable

		synchronized (guardia) {
			Thread handler = new Thread(runnableHandler);
			handler.start();

			int millisPerSmartContract = 2000;
			int extra = 60000;
			long blocks = smartContracts.size() / 5 * 250;
			long timeToWait = smartContracts.size() * millisPerSmartContract + extra + blocks;
			
			// Statistics
			long minutes = (timeToWait / 1000) / 60;
			long seconds = (timeToWait / 1000) % 60;			
			System.out.printf("[TIMER] Setted: %s millis = %s minutes and %s seconds \n", timeToWait, minutes,
					seconds);
			
//			guardia.wait(timeToWait);
			guardia.wait(10 * 60 * 1000);

			for (int i = 0; i < smartContracts.size(); i++)
				threads[i].interrupt();
		}

		for (int i = 0; i < smartContracts.size(); i++) {
			if (!smartContractsTerminated.contains(smartContracts.get(i))) {
				String msg = MyLogger.newLogger()
						.address(smartContracts.get(i))
						.notes("Killed: timeout")
						.build().toString();
				toFile(msg);
			}
		}

		// Print statistics to standard output
		System.out.printf("Total analysis: %s, succesfully: %s, failed: %s \n", smartContracts.size(),
				smartContractsTerminated.size(), (smartContracts.size() - smartContractsTerminated.size()));
		System.out.printf("API Etherscan Request: %s, succesfully: %s \n", numberOfAPIEtherscanRequest,
				numberOfAPIEtherscanRequestOnSuccess);

		// Save statistics to file
		toFile(MyLogger.newLogger()
				.address("Total analysis: " + smartContracts.size() +
						" - succesfully: " + smartContractsTerminated.size() +
						" - failed: " + (smartContracts.size() - smartContractsTerminated.size()))
				.build().toString());

		toFile(MyLogger.newLogger()
				.address("API Etherscan Request: " + numberOfAPIEtherscanRequest +
						" - succesfully: " + numberOfAPIEtherscanRequestOnSuccess)
				.build().toString());

		System.out.println("Stats successfully written in " + STATISTICS);
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
		
		File f = new File(STATISTICS);
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
	 * Writes the given statistics to a file.
	 *
	 * @param stats The statistics to be written to the file.
	 */
	private void toFile(String stats) {
		synchronized (STATISTICS) {
			String init = "Smart Contract, Total Opcodes, Total Jumps, Solved Jumps, % Solved, Time (millis), Thread, Notes \n";
			try {
				File idea = new File(STATISTICS);
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

		int solvedJumps = dumpStatistics(baseCfg);
		long finish = System.currentTimeMillis();

		String stats = MyLogger.newLogger()
				.address(CONTRACT_ADDR)
				.opcodes(baseCfg.getNodesCount())
				.jumps(baseCfg.getAllJumps().size())
				.jumpsSolved(solvedJumps)
				.time(finish - start)
				.build().toString();

		return stats;
	}

	private static CFG getCFGFromFile(String filename) {
		CFG cfg = null;
		try {
			for (CFG c : EVMFrontend.generateCfgFromFile(filename).getAllCFGs()) {
				cfg = c;
			}
		} catch (IOException e) {
			System.err.println("Incorrect contract filename");
		}
		return cfg;
	}

	private int dumpStatistics(EVMCFG cfg) {
		System.err.println("##############");
		System.err.println("Total opcodes: " + cfg.getNodesCount());
		System.err.println("Total jumps: " + cfg.getAllJumps().size());

		int solvedJumps = 0;
		for (Statement st : cfg.getNodes())
			if (st instanceof Jump && cfg.getOutgoingEdges(st).size() == 1)
				solvedJumps++;
			else if (st instanceof Jumpi && cfg.getOutgoingEdges(st).size() == 2)
				solvedJumps++;
		
		System.err.println("Solved jumps: " + solvedJumps);
		System.err.println("##############");

		return solvedJumps;
	}

	private static class MyLogger {
		private static String divider = ", ";
		private String address;
		private int opcodes;
		private int jumps;
		private int jumpsSolved;
		private double solvedJumpsPercent;
		private long time;
		private String notes;
		private String currentThread;

		private MyLogger() {
			this.address = null;
			this.opcodes = 0;
			this.jumps = 0;
			this.jumpsSolved = 0;
			this.solvedJumpsPercent = 0;
			this.time = 0;
			this.notes = "";
			this.currentThread = null;
		}

		private MyLogger(String address, int opcodes, int jumps, int jumpsSolved, long time, String notes) {
			this.address = address;
			this.opcodes = opcodes;
			this.jumps = jumps;
			this.jumpsSolved = jumpsSolved;

			if (jumps != 0) {
				this.solvedJumpsPercent = ((double) jumpsSolved / jumps);
			} else {
				this.solvedJumpsPercent = -1;
			}
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

		public MyLogger jumpsSolved(int jumpsSolved) {
			this.jumpsSolved = jumpsSolved;
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
			return new MyLogger(address, opcodes, jumps, jumpsSolved, time, notes);
		}

		@Override
		public String toString() {
			return address + divider +
					opcodes + divider +
					jumps + divider +
					jumpsSolved + divider +
					solvedJumpsPercent + divider +
					time + divider +
					currentThread + divider +
					notes + " \n";
		}
	}

}
