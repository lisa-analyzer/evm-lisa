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
import java.util.*;
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

		log.info("Cores available: {}", EVMLiSAExecutor.getCoresAvailable());

		try {
			new SmartaxeBenchmark().runBenchmark();
		} catch (Exception e) {
			e.printStackTrace();
		}

		log.debug("Cache used {} times.", MyCache.getTimesUsed());
		System.exit(0);
	}

	private void runBenchmark() {
		workingDirectory = workingDirectory.resolve("manually-labeled");
		Path datasetPath = Paths.get("scripts", "python", "benchmark-checkers", "cross-chain", "smartaxe",
				"manually-labeled");
		Set<Bridge> bridges = new HashSet<>();

		/* Initialize bridges */
		try {
			for (Path dir : Files.newDirectoryStream(datasetPath)) {
				if (Files.isDirectory(dir)) {
					Path bytecodeDirectoryPath = dir.resolve("bytecode");
					Path abiDirectoryPath = dir.resolve("abi");
					String name = dir.getFileName().toString();

					EVMLiSA.setWorkingDirectory(workingDirectory.resolve(name));
					bridges.add(new Bridge(bytecodeDirectoryPath, abiDirectoryPath, null, name));
				}
			}
		} catch (IOException e) {
			log.error("An error occurred while listing directories: {}", e.getMessage());
		}

		/* Info prints */
		log.info("Number of bridges to be analyzed: {}.", bridges.size());
		int numberOfContract = 0;
		for (Bridge bridge : bridges)
			numberOfContract += bridge.getSmartContracts().size();
		log.info("Number of contracts to be analyzed: {}.", numberOfContract);

		List<Future<?>> futures = new ArrayList<>();

		/* Submit tasks: build the CFG for each contract */
		for (Bridge bridge : bridges)
			for (SmartContract contract : bridge)
				futures.add(EVMLiSAExecutor.submit(SmartaxeBenchmark.class, () -> EVMLiSA.buildCFG(contract)));
		EVMLiSAExecutor.awaitCompletionFutures(futures, 12, TimeUnit.HOURS); // barrier

		/*
		 * Submit tasks: build the xCFG for each bridge and compute vulnerable
		 * LOGs for Local Dependency
		 */
		for (Bridge bridge : bridges) {
			futures.add(EVMLiSAExecutor.submit(SmartaxeBenchmark.class, () -> {
				bridge.buildPartialXCFG();
				bridge.addEdges(
						xEVMLiSA.getCrossChainEdgesUsingEventsAndFunctionsEntrypoint(bridge));
			}));
			for (SmartContract contract : bridge)
				futures.add(
						EVMLiSAExecutor
								.submit(SmartaxeBenchmark.class,
										() -> xEVMLiSA.computeVulnerablesLOGsForLocalDependencyChecker(contract)));
		}
		EVMLiSAExecutor.awaitCompletionFutures(futures, 12, TimeUnit.HOURS); // barrier

		/* Submit tasks: compute tainted call data for Local Dependency */
		for (Bridge bridge : bridges)
			for (SmartContract contract : bridge)
				futures.add(EVMLiSAExecutor
						.submit(SmartaxeBenchmark.class,
								() -> xEVMLiSA.computeTaintedCallDataForLocalDependencyChecker(contract)));
		EVMLiSAExecutor.awaitCompletionFutures(futures, 12, TimeUnit.HOURS); // barrier

		/* Submit tasks: run cross chain checkers using xCFG */
		for (Bridge bridge : bridges)
			for (SmartContract contract : bridge) {
				futures.add(EVMLiSAExecutor.submit(SmartaxeBenchmark.class,
						() -> xEVMLiSA.runEventOrderChecker(bridge, contract)));
				futures.add(EVMLiSAExecutor.submit(SmartaxeBenchmark.class,
						() -> xEVMLiSA.runAccessControlIncompleteness(contract)));
				futures.add(EVMLiSAExecutor.submit(SmartaxeBenchmark.class,
						() -> xEVMLiSA.runMissingEventNotificationChecker(contract, bridge.getPolicy())));
				futures.add(EVMLiSAExecutor.submit(SmartaxeBenchmark.class,
						() -> xEVMLiSA.runLocalDependencyChecker(contract)));
			}
		EVMLiSAExecutor.awaitCompletionFutures(futures, 18, TimeUnit.HOURS); // barrier

		/* Saving results */
		saveVulnerabilities(bridges);
		saveVulnerabilitiesPerFunction(bridges, datasetPath);
		EVMLiSAExecutor.shutdown(SmartaxeBenchmark.class);
	}

	private void saveVulnerabilities(Set<Bridge> bridges) {
		JSONArray bridgesVulnerabilities = new JSONArray();
		for (Bridge bridge : bridges) {
			JSONObject bridgeVulnerabilities = new JSONObject();
			bridgeVulnerabilities.put("name", bridge.getName());
			bridgeVulnerabilities.put("number_of_contracts", bridge.getSmartContracts().size());
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

	private void saveVulnerabilitiesPerFunction(Set<Bridge> bridges, Path datasetPath) {
		try {
			JSONArray results = new JSONArray();
			for (Bridge bridge : bridges) {
				Map<String, Integer> map = readJsonToMap(
						datasetPath.resolve(bridge.getName()).resolve("match-file-index.json"));

				JSONObject json = new JSONObject();
				log.info("Bridge {}", bridge.getName());
				json.put("bridge", bridge.getName());

				JSONArray contracts = new JSONArray();

				for (SmartContract contract : bridge) {
					JSONObject contractJson = new JSONObject();
					contractJson.put("bytecode-name",
							contract.getName());
					contractJson.put("source-code-name",
							getMatchingKey(
									contract.getName(),
									map));
					contractJson.put("vulnerabilities",
							MyCache.getInstance().getVulnerabilityPerFunction(
									contract.getCFG().hashCode()));
					contracts.put(contractJson);
				}
				json.put("contracts", contracts);
				results.put(json);
			}

			System.err.println(results.toString(4));

			Path resultFilePath = workingDirectory.resolve("benchmark_results_function.json");
			Files.writeString(resultFilePath, results.toString(4));

			log.info("Results saved in: {}/benchmark_results_function.json", workingDirectory);

		} catch (Exception e) {
			log.error("An error occurred while saving the benchmark_results_functions: {}", e.getMessage());
		}
	}

	/**
	 * Reads a JSON file and returns its contents as a map where keys are
	 * strings and values are integers.
	 *
	 * @param jsonPath the path to the JSON file
	 *
	 * @return a Map containing the JSON key-value pairs
	 *
	 * @throws IOException if an I/O error occurs reading from the file or a
	 *                         malformed or unmappable byte sequence is read
	 */
	public static Map<String, Integer> readJsonToMap(Path jsonPath) throws IOException {
		String content = Files.readString(jsonPath);
		JSONObject jsonObject = new JSONObject(content);
		Map<String, Integer> resultMap = new HashMap<>();

		for (String key : jsonObject.keySet()) {
			resultMap.put(key, jsonObject.getInt(key));
		}

		return resultMap;
	}

	/**
	 * Given a string in the format "number_other", this method extracts the
	 * number before the underscore, converts it to an integer, and checks if
	 * this integer is present as a value in the provided map. If a matching
	 * entry is found, the method returns the corresponding key.
	 *
	 * @param input the input string in the format "number_other"
	 * @param map   the map with keys of type String and values of type Integer
	 *
	 * @return the key from the map whose value equals the extracted number, or
	 *             null if no match is found
	 *
	 * @throws NumberFormatException if the number cannot be parsed from the
	 *                                   input string
	 */
	public static String getMatchingKey(String input, Map<String, Integer> map) {
		// Extract the substring before the underscore
		String numberStr = input.split("_")[0];
		// Convert the extracted string to an integer
		int number = Integer.parseInt(numberStr);

		// Iterate over the map entries to find a key with a matching value
		for (Map.Entry<String, Integer> entry : map.entrySet()) {
			if (entry.getValue() == number) {
				return entry.getKey();
			}
		}

		// Return null if no matching value is found in the map
		return null;
	}
}
