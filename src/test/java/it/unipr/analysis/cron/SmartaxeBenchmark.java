package it.unipr.analysis.cron;

import it.unipr.EVMLiSA;
import it.unipr.analysis.contract.SmartContract;
import it.unipr.crosschain.Bridge;
import it.unipr.crosschain.xEVMLiSA;
import it.unipr.utils.EVMLiSAExecutor;
import it.unipr.utils.MyCache;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Future;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;

public class SmartaxeBenchmark {
	private static final Logger log = LogManager.getLogger(SmartaxeBenchmark.class);
	private static Path workingDirectory = Paths.get("execution", "smartaxe-benchmark");

	public static void main(String[] args) {
		EVMLiSA.setWorkingDirectory(workingDirectory);
		EVMLiSA.setLinkUnsoundJumpsToAllJumpdest();
		EVMLiSAExecutor.setCoresAvailable(Runtime.getRuntime().availableProcessors() - 1);

		log.info("Cores available: {}", EVMLiSAExecutor.getCoresAvailable());

		new SmartaxeBenchmark().runBenchmarkOnManuallyLabeled();

		log.debug("Cache used {} times.", MyCache.getTimesUsed());
		EVMLiSAExecutor.shutdown();
	}

	private void runBenchmarkOnManuallyLabeled() {
		workingDirectory = workingDirectory.resolve("manually-labeled");
		Path datasetPath = Paths.get("scripts", "python", "benchmark-checkers", "cross-chain", "smartaxe",
				"manually-labeled");
		Set<Bridge> bridges = new HashSet<>();

		// Building bridges
		try {
			for (Path dir : Files.newDirectoryStream(datasetPath)) {
				if (Files.isDirectory(dir)) {
					Path bytecodeDirectoryPath = dir.resolve("bytecode");
					Path abiDirectoryPath = dir.resolve("abi");
					String name = dir.getFileName().toString();

					EVMLiSA.setWorkingDirectory(workingDirectory.resolve(name));
					bridges.add(new Bridge(bytecodeDirectoryPath, abiDirectoryPath, name));
				}
			}
		} catch (IOException e) {
			log.error("An error occurred while listing directories: {}", e.getMessage());
		}

		// Info prints
		log.info("Number of bridges to be analyzed: {}.", bridges.size());
		int numberOfContract = 0;
		for (Bridge bridge : bridges)
			numberOfContract += bridge.getSmartContracts().size();
		log.info("Number of contracts to be analyzed: {}.", numberOfContract);

		// Submit tasks
		List<CompletableFuture<Void>> futures = new ArrayList<>();
		for (Bridge bridge : bridges) {
			for (SmartContract contract : bridge) {
				futures.add(EVMLiSAExecutor.runAsync(
						() -> EVMLiSA.buildCFG(contract),
						Set.of(
								() -> EVMLiSA.runReentrancyChecker(contract),
								() -> EVMLiSA.runTxOriginChecker(contract),
								() -> EVMLiSA.runRandomnessDependencyChecker(contract),
								() -> xEVMLiSA.runEventOrderChecker(contract),
								() -> xEVMLiSA.runUncheckedExternalInfluenceChecker(contract),
								() -> xEVMLiSA.runUncheckedStateUpdateChecker(contract),
								() -> xEVMLiSA.runSemanticIntegrityViolationChecker(contract))));
			}
		}
		EVMLiSAExecutor.awaitCompletionCompletableFutures(futures); // barrier

		// Save results
		JSONArray bridgesVulnerabilities = new JSONArray();
		for (Bridge bridge : bridges) {
			JSONObject bridgeVulnerabilities = new JSONObject();
			bridgeVulnerabilities.put("name", bridge.getName());
			bridgeVulnerabilities.put("vulnerabilities", bridge.vulnerabilitiesToJson());
			bridgesVulnerabilities.put(bridgeVulnerabilities);

			try {
				Path resultFilePath = workingDirectory
						.resolve(Path.of(bridge.getName(), "vulnerabilities_results.json"));
				Files.writeString(resultFilePath, bridgeVulnerabilities.toString(4));
				log.info("Vulnerabilities of {} saved in: {}.", bridge.getName(), resultFilePath);
			} catch (IOException e) {
				log.error("An error occurred while saving vulnerabilities results of {}: {}", bridge.getName(),
						e.getMessage());
			}
		}

		try {
			Path resultFilePath = workingDirectory.resolve("benchmark_results.json");
			Files.writeString(resultFilePath, bridgesVulnerabilities.toString(4));

			log.info("Results saved in: {}/benchmark_results.json", workingDirectory);
		} catch (IOException e) {
			log.error("An error occurred while saving the benchmark results: {}", e.getMessage());
		}
	}

	private void runBenchmarkOnDataset() {
		workingDirectory = workingDirectory.resolve("dataset");
		Path datasetPath = Paths.get("scripts", "python", "benchmark-checkers", "cross-chain", "smartaxe",
				"dataset");
		Set<Bridge> bridges = new HashSet<>();

		try {
			for (Path dir : Files.newDirectoryStream(datasetPath)) {
				if (Files.isDirectory(dir)) {
					Path bytecodeDirectoryPath = dir.resolve("bytecode");
					Path abiDirectoryPath = dir.resolve("abi");
					String name = dir.getFileName().toString();

					EVMLiSA.setWorkingDirectory(workingDirectory.resolve(name));
					bridges.add(new Bridge(bytecodeDirectoryPath, abiDirectoryPath, name));
				}
			}
		} catch (IOException e) {
			log.error("An error occurred while listing directories: {}", e.getMessage());
		}

		log.info("Number of bridges to be analyzed: {}.", bridges.size());

		int counter = 0;
		JSONArray bridgesVulnerabilities = new JSONArray();

		for (Bridge bridge : bridges) {
			log.info("[IN] Analyzing bridge {} with {} contracts.",
					bridge.getName(), bridge.getSmartContracts().size());

			List<Future<?>> futures = new ArrayList<>();
			for (SmartContract contract : bridge)
				futures.add(EVMLiSAExecutor.submit(() -> EVMLiSA.buildCFG(contract)));
			EVMLiSAExecutor.awaitCompletionFutures(futures);

			xEVMLiSA.runInterCrossChainCheckers(bridge);

			JSONObject bridgeVulnerabilities = new JSONObject();
			bridgeVulnerabilities.put("name", bridge.getName());
			bridgeVulnerabilities.put("vulnerabilities", bridge.getVulnerabilities().toJson());
			bridgesVulnerabilities.put(bridgeVulnerabilities);

			log.info("[OUT] Bridge analyzed {}.", bridge.getName());
			log.info("Analyzed {}/{} bridges.", ++counter, bridges.size());

			try {
				Path resultFilePath = workingDirectory
						.resolve(Path.of(bridge.getName(), "vulnerabilities_results.json"));
				Files.writeString(resultFilePath, bridgeVulnerabilities.toString(4));
				log.info("Vulnerabilities of {} saved in: {}.", bridge.getName(), resultFilePath);
			} catch (IOException e) {
				log.error("An error occurred while saving vulnerabilities results of {}: {}", bridge.getName(),
						e.getMessage());
			}
		}

		try {
			Path resultFilePath = workingDirectory.resolve("benchmark_results.json");
			Files.writeString(resultFilePath, bridgesVulnerabilities.toString(4));

			log.info("Results saved in: {}/benchmark_results.json", workingDirectory);
		} catch (IOException e) {
			log.error("An error occurred while saving the benchmark results: {}", e.getMessage());
		}
	}

}
