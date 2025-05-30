package it.unipr.analysis.cron.checker;

import it.unipr.analysis.AbstractStack;
import it.unipr.analysis.AbstractStackSet;
import it.unipr.analysis.EVMAbstractState;
import it.unipr.checker.JumpSolver;
import it.unipr.checker.ReentrancyChecker;
import it.unipr.frontend.EVMFrontend;
import it.unipr.utils.MyCache;
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
import org.junit.Ignore;

public class SmartBugsReentrancyTruth {
	private static final Logger log = LogManager.getLogger(SmartBugsReentrancyTruth.class);

	private ConcurrentMap<Integer, Integer> _results = new ConcurrentHashMap<>();

	@Ignore
	public void testSmartBugsReentrancyTruth() throws Exception {
		AbstractStack.setStackLimit(64);
		AbstractStackSet.setStackSetSize(16);
		JumpSolver.setLinkUnsoundJumpsToAllJumpdest();

		Path smartbugsBytecodesDirPath = Paths
				.get("evm-testcases", "ground-truth", "test-reentrancy-smartbugs-truth", "bytecode");
		String SMARTBUGS_BYTECODES_DIR = smartbugsBytecodesDirPath.toString();

		List<String> bytecodes = getFileNamesInDirectory(SMARTBUGS_BYTECODES_DIR);

		int cores = Runtime.getRuntime().availableProcessors() / 3 * 2;
		ExecutorService executor = Executors.newFixedThreadPool(cores > 0 ? cores : 1);

		// Run the benchmark in parallel
		for (String bytecodeFileName : bytecodes) {
			executor.submit(() -> {
				try {
					String bytecodeFullPath = smartbugsBytecodesDirPath.resolve(bytecodeFileName).toString();

					String bytecode = new String(Files.readAllBytes(Paths.get(bytecodeFullPath)));
					if (bytecode.startsWith("0x"))
						EVMFrontend.opcodesFromBytecode(bytecode, bytecodeFullPath);

					Program program = EVMFrontend.generateCfgFromFile(bytecodeFullPath);

					LiSAConfiguration conf = new LiSAConfiguration();
					conf.serializeInputs = false;
					conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new EVMAbstractState(null),
							new TypeEnvironment<>(new InferredTypes()));
					conf.jsonOutput = false;
					conf.workdir = SMARTBUGS_BYTECODES_DIR;
					conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
					JumpSolver checker = new JumpSolver();
					conf.semanticChecks.add(checker);
					conf.callGraph = new RTACallGraph();
					conf.serializeResults = false;
					conf.optimize = false;

					LiSA lisa = new LiSA(conf);
					lisa.run(program);

					conf.semanticChecks.clear();
					conf.semanticChecks.add(new ReentrancyChecker());
					lisa.run(program);

					Integer key = Integer.parseInt(bytecodeFileName.split("_")[0]);
					int value = MyCache.getInstance().getReentrancyWarnings(checker.getComputedCFG().hashCode());

					_results.merge(key, value, Integer::sum);
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

		log.info("Results: {}", _results);

		boolean sound = true;

		// Check the results
		for (Integer key : _results.keySet()) {
			int value = _results.get(key);
			if (value == 1) {
				continue;
			} else if (value == 0) {
				log.error("Unsound on {}.sol", key);
				sound = false;
			} else {
				log.warn("{} false positive on {}.sol", value - 1, key);
			}
		}
		assert sound;
	}

	public static List<String> getFileNamesInDirectory(String directoryPath) {
		List<String> fileNames = new ArrayList<>();
		File directory = new File(directoryPath);

		if (directory.isDirectory()) {
			File[] files = directory.listFiles();

			if (files != null) {
				for (File file : files) {
					if (file.isFile()) {
						fileNames.add(file.getName());
					}
				}
			}
		} else {
			log.warn("Path {} is not a directory.", directoryPath);
		}

		return fileNames;
	}
}
