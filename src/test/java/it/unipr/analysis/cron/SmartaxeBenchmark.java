package it.unipr.analysis.cron;

import it.unipr.EVMLiSA;
import it.unipr.crosschain.Bridge;
import it.unipr.crosschain.xEVMLiSA;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashSet;
import java.util.Set;

import it.unipr.utils.MyCache;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;

public class SmartaxeBenchmark {
	private static final Logger log = LogManager.getLogger(SmartaxeBenchmark.class);
	private static final Path workingDirectory = Paths.get("execution", "smartaxe-benchmark");

	public static void main(String[] args) {
		EVMLiSA.setWorkingDirectory(workingDirectory);
		EVMLiSA.setLinkUnsoundJumpsToAllJumpdest();
		EVMLiSA.setCores(Runtime.getRuntime().availableProcessors() - 1);
        EVMLiSA.enableReentrancyChecker();
        EVMLiSA.enableRandomnessDependencyChecker();
        EVMLiSA.enableTxOriginChecker();

		new SmartaxeBenchmark().runBenchmarkManuallyLabeled();

		log.debug("Cache used {} times.", MyCache.getTimesUsed());
	}

	private void runBenchmarkManuallyLabeled() {
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

		log.info("Number of bridges to be analyzed: {}.", bridges.size());

		int counter = 0;
		JSONArray bridgesVulnerabilities = new JSONArray();

		for (Bridge bridge : bridges) {
			xEVMLiSA.analyzeBridge(bridge);
			xEVMLiSA.runIntraCrossChainCheckers(bridge);

			JSONObject bridgeVulnerabilities = new JSONObject();
			bridgeVulnerabilities.put("name", bridge.getName());
			bridgeVulnerabilities.put("vulnerabilities", bridge.vulnerabilitiesToJson());
			bridgesVulnerabilities.put(bridgeVulnerabilities);

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
