package it.unipr.analysis.cron.checker;

import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.MyCache;
import it.unipr.analysis.taint.TxOriginAbstractDomain;
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
import it.unive.lisa.interprocedural.ModularWorstCaseAnalysis;
import it.unive.lisa.interprocedural.callgraph.RTACallGraph;
import it.unive.lisa.program.Program;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.Test;

public class SolidiFITxOriginTruth {
	private static final Logger log = LogManager.getLogger(SolidiFITxOriginTruth.class);

	private ConcurrentMap<Integer, Integer> _resultsBuggy = new ConcurrentHashMap<>();
	private ConcurrentMap<Integer, Integer> _resultsVanilla = new ConcurrentHashMap<>();
	private ConcurrentMap<Integer, Integer> _solidifi = new ConcurrentHashMap<>();

	@Test
	public void testSolidiFITxOriginTruth() throws Exception {
		setSolidifiMap();
		int cores = Runtime.getRuntime().availableProcessors() / 4 * 3;
		ExecutorService executor = Executors.newFixedThreadPool(cores > 0 ? cores : 1);

		Path solidifiBuggyBytecodesDirPath = Paths
				.get("evm-testcases", "ground-truth", "solidifi", "tx-origin-truth", "bytecode");
		String SOLIDIFI_BUGGY_BYTECODES_DIR = solidifiBuggyBytecodesDirPath.toString();
		List<String> bytecodes = getFileNamesInDirectory(SOLIDIFI_BUGGY_BYTECODES_DIR);

		// Run the benchmark on Buggy contracts
		for (String bytecodeFileName : bytecodes) {
			executor.submit(() -> {
				try {
					String bytecodeFullPath = solidifiBuggyBytecodesDirPath.resolve(bytecodeFileName).toString();

					String bytecode = new String(Files.readAllBytes(Paths.get(bytecodeFullPath)));
					if (bytecode.startsWith("0x"))
						EVMFrontend.opcodesFromBytecode(bytecode, bytecodeFullPath);

					Program program = EVMFrontend.generateCfgFromFile(bytecodeFullPath);

					LiSAConfiguration conf = new LiSAConfiguration();
					conf.serializeInputs = false;
					conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new EVMAbstractState(null),
							new TypeEnvironment<>(new InferredTypes()));
					conf.jsonOutput = false;
					conf.workdir = SOLIDIFI_BUGGY_BYTECODES_DIR;
					conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
					JumpSolver checker = new JumpSolver();
					conf.semanticChecks.add(checker);
					conf.callGraph = new RTACallGraph();
					conf.serializeResults = false;
					conf.optimize = false;

					LiSA lisa = new LiSA(conf);
					lisa.run(program);

					conf.semanticChecks.clear();
					conf.semanticChecks.add(new TxOriginChecker());
					conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new TxOriginAbstractDomain(),
							new TypeEnvironment<>(new InferredTypes()));
					lisa.run(program);

					Integer key = Integer.parseInt(bytecodeFileName.split("\\.")[0]);
					int value = MyCache.getInstance().getTxOriginWarnings(checker.getComputedCFG().hashCode());

					_resultsBuggy.put(key, value);
				} catch (Exception e) {
					log.error("Error processing bytecode {}: {}", bytecodeFileName, e.getMessage(), e);
				}
			});
		}

		Path solidifiVanillaBytecodesDirPath = Paths
				.get("evm-testcases", "ground-truth", "solidifi", "vanilla", "bytecode");
		String SOLIDIFI_VANILLA_BYTECODES_DIR = solidifiVanillaBytecodesDirPath.toString();
		bytecodes = getFileNamesInDirectory(SOLIDIFI_VANILLA_BYTECODES_DIR);

		// Run the benchmark on Vanilla contracts
		for (String bytecodeFileName : bytecodes) {
			executor.submit(() -> {
				try {
					String bytecodeFullPath = solidifiVanillaBytecodesDirPath.resolve(bytecodeFileName).toString();

					String bytecode = new String(Files.readAllBytes(Paths.get(bytecodeFullPath)));
					if (bytecode.startsWith("0x"))
						EVMFrontend.opcodesFromBytecode(bytecode, bytecodeFullPath);

					Program program = EVMFrontend.generateCfgFromFile(bytecodeFullPath);

					LiSAConfiguration conf = new LiSAConfiguration();
					conf.serializeInputs = false;
					conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new EVMAbstractState(null),
							new TypeEnvironment<>(new InferredTypes()));
					conf.jsonOutput = false;
					conf.workdir = SOLIDIFI_VANILLA_BYTECODES_DIR;
					conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
					JumpSolver checker = new JumpSolver();
					conf.semanticChecks.add(checker);
					conf.callGraph = new RTACallGraph();
					conf.serializeResults = false;
					conf.optimize = false;

					LiSA lisa = new LiSA(conf);
					lisa.run(program);

					conf.semanticChecks.clear();
					conf.semanticChecks.add(new TxOriginChecker());
					conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new TxOriginAbstractDomain(),
							new TypeEnvironment<>(new InferredTypes()));
					lisa.run(program);

					Integer key = Integer.parseInt(bytecodeFileName.split("\\.")[0]);
					int value = MyCache.getInstance().getTxOriginWarnings(checker.getComputedCFG().hashCode());

					_resultsVanilla.put(key, value);
				} catch (Exception e) {
					log.error("Error processing bytecode {}: {}", bytecodeFileName, e.getMessage(), e);
				}
			});
		}

		// Shutdown the executor and wait for completion
		executor.shutdown();
		if (!executor.awaitTermination(1, TimeUnit.HOURS)) {
			log.error("Timeout reached while waiting for thread pool to terminate.");
			executor.shutdownNow();
		}

		log.info("Results buggy: {}", _resultsBuggy);
		log.info("Results vanilla: {}", _resultsVanilla);

		boolean soundness = true;
		for (Integer key : _resultsBuggy.keySet()) {
			int value = _resultsBuggy.get(key) - _resultsVanilla.get(key);
			int valueSolidifi = _solidifi.get(key);

			if (value == valueSolidifi)
				continue;
			else if (value < valueSolidifi) {
				log.error("Unsound on {}.sol, {} false negative", key, valueSolidifi - value);
				soundness = false;
			} else {
				log.warn("{} false positive on {}.sol", value - valueSolidifi, key);
			}
		}
		assert soundness;
	}

	public static List<String> getFileNamesInDirectory(String directoryPath) {
		List<String> fileNames = new ArrayList<>();
		File directory = new File(directoryPath);

		if (directory.isDirectory()) {
			File[] files = directory.listFiles();

			if (files != null)
				for (File file : files)
					if (file.isFile())
						fileNames.add(file.getName());
		} else {
			log.warn("Path {} is not a directory.", directoryPath);
		}

		return fileNames;
	}

	private void setSolidifiMap() {
		_solidifi.put(1, 18);
		_solidifi.put(2, 20);
		_solidifi.put(3, 21);
		_solidifi.put(4, 18);
		_solidifi.put(5, 31);
		_solidifi.put(6, 30);
		_solidifi.put(7, 31);
		_solidifi.put(8, 31);
		_solidifi.put(9, 24);
		_solidifi.put(10, 8);
		_solidifi.put(11, 30);
		_solidifi.put(12, 28);
		_solidifi.put(13, 17);
		_solidifi.put(14, 22);
		_solidifi.put(15, 17);
		_solidifi.put(16, 40);
		_solidifi.put(17, 30);
		_solidifi.put(18, 39);
		_solidifi.put(19, 28);
		_solidifi.put(20, 29);
		_solidifi.put(21, 23);
		_solidifi.put(22, 29);
		_solidifi.put(23, 26);
		_solidifi.put(24, 40);
		_solidifi.put(25, 21);
		_solidifi.put(26, 23);
		_solidifi.put(27, 40);
		_solidifi.put(28, 29);
		_solidifi.put(29, 16);
		_solidifi.put(30, 40);
		_solidifi.put(31, 15);
		_solidifi.put(32, 21);
		_solidifi.put(33, 22);
		_solidifi.put(34, 36);
		_solidifi.put(35, 34);
		_solidifi.put(36, 29);
		_solidifi.put(37, 34);
		_solidifi.put(38, 29);
		_solidifi.put(39, 11);
		_solidifi.put(40, 24);
		_solidifi.put(41, 17);
		_solidifi.put(42, 22);
		_solidifi.put(43, 29);
		_solidifi.put(44, 30);
		_solidifi.put(45, 28);
		_solidifi.put(46, 7);
		_solidifi.put(47, 40);
		_solidifi.put(48, 31); 
		_solidifi.put(49, 11);
		_solidifi.put(50, 25);
	}
}
