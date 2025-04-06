package it.unipr.analysis.cron;

import it.unipr.EVMLiSA;
import it.unipr.analysis.contract.SmartContract;
import it.unipr.crosschain.Bridge;
import it.unipr.crosschain.xEVMLiSA;
import it.unipr.utils.EVMLiSAExecutor;
import it.unipr.utils.MyCache;
import it.unipr.utils.VulnerabilitiesObject;
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
import java.util.concurrent.TimeUnit;
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

		try {
			new SmartaxeBenchmark().runBenchmarkWithTimeSynchronizationChecker();
		} catch (Exception e) {
			e.printStackTrace();
			EVMLiSAExecutor.shutdown();
		}

		log.debug("Cache used {} times.", MyCache.getTimesUsed());
		EVMLiSAExecutor.shutdown();
	}

	private void runBenchmarkWithIntraCrossChainCheckers() {
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

		List<CompletableFuture<Void>> completablesFutures = new ArrayList<>();
		List<Future<?>> futures = new ArrayList<>();

		// Submit tasks: build the CFG for each contract and run intra cross
		// chain checkers
		for (Bridge bridge : bridges)
			for (SmartContract contract : bridge)
				completablesFutures.add(EVMLiSAExecutor.runAsync(
						() -> EVMLiSA.buildCFG(contract),
						Set.of(
								() -> xEVMLiSA.runUncheckedExternalInfluenceChecker(contract),
								() -> xEVMLiSA.runUncheckedStateUpdateChecker(contract),
								() -> xEVMLiSA.runMissingEventNotificationChecker(contract))));
		EVMLiSAExecutor.awaitCompletionCompletableFutures(completablesFutures, 8, TimeUnit.HOURS); // barrier

		// Submit tasks: build the xCFG for each bridge
		for (Bridge bridge : bridges)
			futures.add(EVMLiSAExecutor.submit(() -> {
				bridge.buildPartialXCFG();
				bridge.addEdges(
						xEVMLiSA.getCrossChainEdgesUsingEventsAndFunctionsEntrypoint(bridge));
			}));
		EVMLiSAExecutor.awaitCompletionFutures(futures, 8, TimeUnit.HOURS); // barrier

		// Submit tasks: run intra cross chain checkers using xCFG
		for (Bridge bridge : bridges)
			for (SmartContract contract : bridge) {
				futures.add(EVMLiSAExecutor.submit(() -> xEVMLiSA.runEventOrderChecker(bridge, contract)));
				futures.add(
						EVMLiSAExecutor.submit(() -> xEVMLiSA.runSemanticIntegrityViolationChecker(bridge, contract)));
			}
		EVMLiSAExecutor.awaitCompletionFutures(futures, 8, TimeUnit.HOURS); // barrier

		// Saving results
		JSONArray bridgesVulnerabilities = new JSONArray();
		for (Bridge bridge : bridges) {
			JSONObject bridgeVulnerabilities = new JSONObject();
			bridgeVulnerabilities.put("name", bridge.getName());
			bridgeVulnerabilities.put("vulnerabilities", bridge.vulnerabilitiesToJson());
			bridgesVulnerabilities.put(bridgeVulnerabilities);

			try {
				System.err.println(bridgeVulnerabilities.toString(4));

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
			System.err.println(bridgesVulnerabilities.toString(4));

			Path resultFilePath = workingDirectory.resolve("benchmark_results.json");
			Files.writeString(resultFilePath, bridgesVulnerabilities.toString(4));

			log.info("Results saved in: {}/benchmark_results.json", workingDirectory);
		} catch (IOException e) {
			log.error("An error occurred while saving the benchmark results: {}", e.getMessage());
		}
	}

	private void runBenchmarkWithTimeSynchronizationChecker() {
		workingDirectory = workingDirectory.resolve("dataset");
		Path datasetPath = Paths.get("scripts", "python", "benchmark-checkers", "cross-chain", "smartaxe",
				"manually-labeled");
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

		// Info prints
		log.info("Number of bridges to be analyzed: {}.", bridges.size());
		int numberOfContract = 0;
		for (Bridge bridge : bridges)
			numberOfContract += bridge.getSmartContracts().size();
		log.info("Number of contracts to be analyzed: {}.", numberOfContract);

		List<CompletableFuture<Void>> completablesFutures = new ArrayList<>();
		List<Future<?>> futures = new ArrayList<>();

		// Submit tasks: build the CFG for each contract in bridges and compute
		// the vulnerable logs
		for (Bridge bridge : bridges)
			for (SmartContract contract : bridge)
				completablesFutures.add(EVMLiSAExecutor.runAsync(
						() -> EVMLiSA.buildCFG(contract),
						Set.of(
								() -> xEVMLiSA.computeVulnerablesLOGsForTimeSynchronizationChecker(contract))));
		EVMLiSAExecutor.awaitCompletionCompletableFutures(completablesFutures, 10, TimeUnit.HOURS); // barrier

		// Submit tasks: build the xCFG for each bridge and compute the tainted
		// call data
		for (Bridge bridge : bridges)
			completablesFutures.add(EVMLiSAExecutor.runAsync(
					() -> {
						bridge.buildPartialXCFG();
						bridge.addEdges(
								xEVMLiSA.getCrossChainEdgesUsingEventsAndFunctionsEntrypoint(bridge));
					},
					Set.of(
							() -> xEVMLiSA.computeTaintedCallDataForTimeSynchronizationChecker(bridge))));
		EVMLiSAExecutor.awaitCompletionCompletableFutures(completablesFutures, 24, TimeUnit.HOURS); // barrier

		// Submit tasks: run time synchronization checker for each contract in
		// bridges
		for (Bridge bridge : bridges)
			for (SmartContract contract : bridge)
				futures.add(EVMLiSAExecutor.submit(() -> xEVMLiSA.runTimeSynchronizationChecker(contract)));
		EVMLiSAExecutor.awaitCompletionFutures(futures, 10, TimeUnit.HOURS);

		// Saving results
		JSONArray bridgesVulnerabilities = new JSONArray();
		for (Bridge bridge : bridges) {
			bridge.setVulnerabilities(
					VulnerabilitiesObject.newVulnerabilitiesObject()
							.timeSynchronization(MyCache.getInstance().getTimeSynchronizationWarnings())
							.build());

			JSONObject bridgeVulnerabilities = new JSONObject();
			bridgeVulnerabilities.put("name", bridge.getName());
			bridgeVulnerabilities.put("number_of_contracts", bridge.getSmartContracts().size());
			bridgeVulnerabilities.put("vulnerabilities", bridge.getVulnerabilities().toJson());
			bridgesVulnerabilities.put(bridgeVulnerabilities);

			try {
				System.err.println(bridgeVulnerabilities.toString(4));

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
			System.err.println(bridgesVulnerabilities.toString(4));

			Path resultFilePath = workingDirectory.resolve("benchmark_results.json");
			Files.writeString(resultFilePath, bridgesVulnerabilities.toString(4));

			log.info("Results saved in: {}/benchmark_results.json", workingDirectory);
		} catch (IOException e) {
			log.error("An error occurred while saving the benchmark results: {}", e.getMessage());
		}
	}
}
