package it.unipr.analysis.cron;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.Test;

import it.unipr.EVMLiSA;
import it.unipr.analysis.AbstractStack;
import it.unipr.analysis.AbstractStackSet;
import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.MyCache;
import it.unipr.analysis.MyLogger;
import it.unipr.checker.JumpSolver;
import it.unipr.frontend.EVMFrontend;
import it.unive.lisa.LiSA;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.conf.LiSAConfiguration;
import it.unive.lisa.interprocedural.ModularWorstCaseAnalysis;
import it.unive.lisa.interprocedural.callgraph.RTACallGraph;
import it.unive.lisa.program.Program;

/*
 * ground-truth-stats/ground-truth-data.csv FILE MUST BE UPDATED WHEN A NEW
 * VERSION OF THE TRUTH DATASET IS CHOSEN.
 */
public class EVMBytecodeGroundTruth {
	private static final Logger log = LogManager.getLogger(EVMBytecodeGroundTruth.class);

	@Test
	public void testGroundTruth() throws Exception {
		String GROUND_TRUTH_FILE_PATH = "evm-testcases/ground-truth/ground-truth-data.csv";
		String RESULT_EXEC_DIR_PATH = "evm-testcases/ground-truth/test-ground-truth-results";
		String RESULT_EXEC_FILE_PATH = RESULT_EXEC_DIR_PATH + "/statistics.csv";
		String SMARTCONTRACTS_FULLPATH = "benchmark/50-ground-truth.txt";
		AbstractStack.setStackLimit(32);
		AbstractStackSet.setStackSetSize(8);
		boolean changed = false;

		if (new File(RESULT_EXEC_FILE_PATH).delete())
			log.warn("File deleted {}", RESULT_EXEC_FILE_PATH);

		List<String> smartContracts = EVMLiSA.readSmartContractsFromFile(SMARTCONTRACTS_FULLPATH);

		ExecutorService executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());

		for (String address : smartContracts) {
			executor.submit(() -> {
				try {
					MyLogger myStats = newAnalysis(address, RESULT_EXEC_DIR_PATH);

					if (myStats.jumpSize() != 0) {
						synchronized (RESULT_EXEC_FILE_PATH) {
							EVMLiSA.toFile(RESULT_EXEC_FILE_PATH, myStats.toString());
						}
					}
				} catch (Exception e) {
					log.error("Error processing contract {}: {}", address, e.getMessage(), e);
				}
			});
		}

		// Shutdown the executor and wait for completion
		executor.shutdown();
		if (!executor.awaitTermination(1, TimeUnit.HOURS)) {
			log.error("Timeout reached while waiting for thread pool to terminate.");
			executor.shutdownNow();
		}

		List<SmartContractData> smartContractList = readStatsFromCSV(RESULT_EXEC_FILE_PATH);
		List<SmartContractData> smartContractGroundTruthList = readStatsFromCSV(GROUND_TRUTH_FILE_PATH);
		long smartContractGroundTruthListTime = 0;
		long smartContractListTime = 0;

		assert smartContractList.size() == smartContractGroundTruthList.size();

		for (SmartContractData truthSC : smartContractGroundTruthList) {
			for (SmartContractData newSC : smartContractList) {

				if (truthSC.getAddress().equals(newSC.getAddress())) {

					smartContractGroundTruthListTime += truthSC.getTimeMillis();
					smartContractListTime += newSC.getTimeMillis();

					if (!truthSC.equals(newSC)) {
						if (!changed)
							System.err.println("\n*******************************************\n");

						changed = true;
						System.err.printf("%s\n", truthSC.getAddress());

						if (truthSC.getSolvedJumps() != newSC.getSolvedJumps()) {
							System.err.println("\tSolved Jumps");
							System.err.printf("\t\tTruth: %s, New: %s\n", truthSC.getSolvedJumps(),
									newSC.getSolvedJumps());
						}
						if (truthSC.getDefinitelyUnreachableJumps() != newSC.getDefinitelyUnreachableJumps()) {
							System.err.println("\tDefinitely Unreachable Jumps");
							System.err.printf("\t\tTruth: %s, New: %s\n", truthSC.getDefinitelyUnreachableJumps(),
									newSC.getDefinitelyUnreachableJumps());
						}
						if (truthSC.getMaybeUnreachableJumps() != newSC.getMaybeUnreachableJumps()) {
							System.err.println("\tMaybe Unreachable Jumps");
							System.err.printf("\t\tTruth: %s, New: %s\n", truthSC.getMaybeUnreachableJumps(),
									newSC.getMaybeUnreachableJumps());
						}
						if (truthSC.getUnsoundJumps() != newSC.getUnsoundJumps()) {
							System.err.println("\tUnsolved Jumps");
							System.err.printf("\t\tTruth: %s, New: %s\n", truthSC.getUnsoundJumps(),
									newSC.getUnsoundJumps());
						}
						if (truthSC.getMaybeUnsoundJumps() != newSC.getMaybeUnsoundJumps()) {
							System.err.println("\tMaybe Unsound Jumps");
							System.err.printf("\t\tTruth: %s, New: %s\n", truthSC.getMaybeUnsoundJumps(),
									newSC.getMaybeUnsoundJumps());
						}
					}

					smartContractList.remove(newSC);
					break;
				}
			}
		}
		assert !changed;

		if (smartContractGroundTruthListTime != 0) {
			float percentageChange = ((smartContractListTime - smartContractGroundTruthListTime)
					/ (float) smartContractGroundTruthListTime) * 100;

			System.err.println("\n");
			System.err.println("GroundTruth Time: " + (smartContractGroundTruthListTime / (float) 1000) + " seconds");
			System.err.println("New Execution Time: " + (smartContractListTime / (float) 1000) + " seconds");

			if (percentageChange > 0) {
				System.err.println("Time lost: " + percentageChange + "%");
			} else {
				System.err.println("Time gained: " + Math.abs(percentageChange) + "%");
			}
		} else {
			System.err.println("Cannot calculate percentage change, ground truth time is zero.");
		}
	}

	private MyLogger newAnalysis(String CONTRACT_ADDR, String RESULT_EXEC_DIR_PATH) throws Exception {
		String BYTECODE_DIR = RESULT_EXEC_DIR_PATH + "/benchmark/" + CONTRACT_ADDR;
		String BYTECODE_FULLPATH = BYTECODE_DIR + "/" + CONTRACT_ADDR + ".sol";

		// Directory setup and bytecode retrieval
		Files.createDirectories(Paths.get(RESULT_EXEC_DIR_PATH + "/" + "benchmark/" + CONTRACT_ADDR));

		// If the file does not exist, we will do an API request to Etherscan
		File file = new File(BYTECODE_FULLPATH);
		if (!file.exists()) {
			String bytecode = EVMFrontend.parseContractFromEtherscan(CONTRACT_ADDR);
			EVMFrontend.opcodesFromBytecode(bytecode, BYTECODE_FULLPATH);
		}

		// Configuration and test run
		Program program = EVMFrontend.generateCfgFromFile(BYTECODE_FULLPATH);

		long start = System.currentTimeMillis();

		LiSAConfiguration conf = new LiSAConfiguration();
		conf.serializeInputs = false;
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new EVMAbstractState(CONTRACT_ADDR),
				new TypeEnvironment<>(new InferredTypes()));
		conf.jsonOutput = false;
		conf.workdir = BYTECODE_DIR;
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

		return EVMLiSA.dumpStatistics(checker, new HashSet<>())
				.address(CONTRACT_ADDR)
				.time(finish - start)
				.timeLostToGetStorage(MyCache.getInstance().getTimeLostToGetStorage(CONTRACT_ADDR))
				.build();
	}

	/**
	 * Reads data from a CSV file and populates a list of
	 * {@link SmartContractData} objects.
	 *
	 * @param csvPath the path to the CSV file containing the smart contract
	 *                    statistics
	 * 
	 * @return a {@code List<SmartContractData>} containing the data read from
	 *             the CSV file
	 * 
	 * @throws NullPointerException if {@code csvPath} is {@code null} The CSV
	 *                                  file is expected to have the following
	 *                                  columns: Smart Contract, Total Opcodes,
	 *                                  Total Jumps, Solved Jumps, Definitely
	 *                                  unreachable jumps, Maybe unreachable
	 *                                  jumps, Total solved Jumps, Unsound
	 *                                  jumps, Maybe unsound jumps, % Total
	 *                                  Solved, Time (millis), Time lost to get
	 *                                  Storage, Actual time, Notes. Each line
	 *                                  after the header represents one smart
	 *                                  contract data entry, and the method
	 *                                  converts each line into a
	 *                                  {@link SmartContractData} object and
	 *                                  adds it to the list. If an
	 *                                  {@link IOException} occurs during
	 *                                  reading, the exception's stack trace
	 *                                  will be printed.
	 */
	private List<SmartContractData> readStatsFromCSV(String csvPath) {
		if (csvPath == null)
			throw new NullPointerException("csvPath is null");

		List<SmartContractData> smartContractList = new ArrayList<>();
		String line;
		String csvSeparator = ",";

		try (BufferedReader br = new BufferedReader(new FileReader(csvPath))) {
			line = br.readLine(); // Skip the header

			while ((line = br.readLine()) != null) {
				String[] values = line.split(csvSeparator);
				smartContractList.add(new SmartContractData(values));
			}
		} catch (IOException e) {
			System.err.println("private List<SmartContractData> readStatsFromCSV(String csvPath): " + e.getMessage());
		}

		return smartContractList;
	}

	/**
	 * Represents data related to a smart contract, including various statistics
	 * about opcodes, jumps, and execution times. This class provides methods to
	 * access individual data points and constructs objects from an array of
	 * values typically read from a CSV file.
	 */
	private class SmartContractData {
		private final String _address;
		private final int _totalOpcodes;
		private final int _totalJumps;
		private final int _solvedJumps;
		private final int _definitelyUnreachableJumps;
		private final int _maybeUnreachableJumps;
		private final int _totalSolvedJumps;
		private final int _unsoundJumps;
		private final int _maybeUnsoundJumps;
		private final double _percentageTotalSolved;
		private final long _timeMillis;
		private final long _timeLostToGetStorage;
		private final long _actualTime;
		private final String _notes;

		public SmartContractData(String[] values) {
			if (values == null)
				throw new NullPointerException("String[] values == null");
			this._address = values[0].trim();
			this._totalOpcodes = Integer.parseInt(values[1].trim());
			this._totalJumps = Integer.parseInt(values[2].trim());
			this._solvedJumps = Integer.parseInt(values[3].trim());
			this._definitelyUnreachableJumps = Integer.parseInt(values[4].trim());
			this._maybeUnreachableJumps = Integer.parseInt(values[5].trim());
			this._totalSolvedJumps = Integer.parseInt(values[6].trim());
			this._unsoundJumps = Integer.parseInt(values[7].trim());
			this._maybeUnsoundJumps = Integer.parseInt(values[8].trim());
			this._percentageTotalSolved = Double.parseDouble(values[9].trim());
			this._timeMillis = Long.parseLong(values[10].trim());
			this._timeLostToGetStorage = Long.parseLong(values[11].trim());
			this._actualTime = Long.parseLong(values[12].trim());
			this._notes = values[13].trim();
		}

		public String getAddress() {
			return _address;
		}

		public int getTotalOpcodes() {
			return _totalOpcodes;
		}

		public int getTotalJumps() {
			return _totalJumps;
		}

		public int getSolvedJumps() {
			return _solvedJumps;
		}

		public int getDefinitelyUnreachableJumps() {
			return _definitelyUnreachableJumps;
		}

		public int getMaybeUnreachableJumps() {
			return _maybeUnreachableJumps;
		}

		public int getTotalSolvedJumps() {
			return _totalSolvedJumps;
		}

		public int getUnsoundJumps() {
			return _unsoundJumps;
		}

		public int getMaybeUnsoundJumps() {
			return _maybeUnsoundJumps;
		}

		public double getPercentageTotalSolved() {
			return _percentageTotalSolved;
		}

		public long getTimeMillis() {
			return _timeMillis;
		}

		public long getTimeLostToGetStorage() {
			return _timeLostToGetStorage;
		}

		public long getActualTime() {
			return _actualTime;
		}

		public String getNotes() {
			return _notes;
		}

		public void print() {
			System.out.println("Address: " + _address);
			System.out.println("Total Opcodes: " + _totalOpcodes);
			System.out.println("Total Jumps: " + _totalJumps);
			System.out.println("Solved Jumps: " + _solvedJumps);
			System.out.println("Definitely Unreachable Jumps: " + _definitelyUnreachableJumps);
			System.out.println("Maybe Unreachable Jumps: " + _maybeUnreachableJumps);
			System.out.println("Total Solved Jumps: " + _totalSolvedJumps);
			System.out.println("Unsound Jumps: " + _unsoundJumps);
			System.out.println("Maybe Unsound Jumps: " + _maybeUnsoundJumps);
			System.out.println("Percentage of Total Solved: " + _percentageTotalSolved);
			System.out.println("Time (Millis): " + _timeMillis);
			System.out.println("Time Lost to Get Storage: " + _timeLostToGetStorage);
			System.out.println("Actual Time: " + _actualTime);
			System.out.println("Notes: " + _notes);
			System.out.println("-------------------------------");
		}

		@Override
		public boolean equals(Object obj) {
			if (obj == null)
				return false;
			if (!(obj instanceof SmartContractData))
				return false;

			SmartContractData other = (SmartContractData) obj;

			return this._address.equals(other.getAddress()) &&
					this._solvedJumps == other.getSolvedJumps() &&
					this._definitelyUnreachableJumps == other.getDefinitelyUnreachableJumps() &&
					this._maybeUnreachableJumps == other.getMaybeUnreachableJumps() &&
					this._unsoundJumps == other.getUnsoundJumps() &&
					this._maybeUnsoundJumps == other.getMaybeUnsoundJumps();
		}
	}

	/**
	 * Deletes all files and subdirectories within the specified directory, and
	 * then deletes the directory itself.
	 *
	 * @param pathDir the path of the directory to be cleared If the directory
	 *                    exists, this method uses
	 *                    {@link java.nio.file.Files#walkFileTree} to
	 *                    recursively visit all files and subdirectories,
	 *                    deleting each one. If the directory or any of its
	 *                    contents cannot be deleted, an error message is
	 *                    printed to {@code System.err}.
	 */
	private void clearDirectory(String pathDir) {
		if (pathDir == null)
			return;
		Path path = Paths.get(pathDir);

		if (Files.exists(path)) {
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

				System.out.println("Directory " + pathDir + " deleted.");
			} catch (IOException e) {
				System.err.println("Error deleting " + pathDir + ": " + e);
			}
		}
	}
}
