package it.unipr;

import it.unipr.analysis.contract.SmartContract;
import it.unipr.crosschain.xEVMLiSA;
import it.unipr.utils.EVMLiSAExecutor;
import it.unipr.utils.MyCache;
import it.unipr.utils.MyTimestampUtil;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.stream.Stream;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;

/**
 * Benchmark for cross-chain smart contracts in the "real" dataset.
 *
 * <p>Scans {@code datasets/cross-chain/smartaxe/real/} for per-address
 * subdirectories produced by
 * {@code scripts/cross-chain-analysis/download_and_compile_real.py} (which
 * downloads the verified source code, follows proxies to their implementation,
 * compiles locally with the exact {@code solc} version, and decorates the ABI
 * with modifiers from the AST). For each {@code <address>/} directory it loads
 * the locally compiled {@code bytecode/<address>.bytecode} and
 * {@code abi/<address>.abi} via
 * {@link SmartContract#SmartContract(Path, Path)} (no Etherscan call), builds
 * the CFG, and runs the Access Control Incompleteness checker.
 */
public class CrossChainRealBenchmark {

	private static final Logger log = LogManager.getLogger(CrossChainRealBenchmark.class);

	private static final String DATASET_SUBDIR = "real";

	private static Path workingDirectory = Path.of("outputs", MyTimestampUtil.getCurrentTimestamp(),
			"crosschain-real-benchmark");

	public static void main(String[] args) {
		EVMLiSA.setWorkingDirectory(workingDirectory);
		EVMLiSA.setLinkUnsoundJumpsToAllJumpdest();
		EVMLiSAExecutor.setCoresAvailable(Runtime.getRuntime().availableProcessors() / 3);

		log.info("Cores available: {}", EVMLiSAExecutor.getCoresAvailable());

		try {
			new CrossChainRealBenchmark().runBenchmark();
		} catch (Exception e) {
			e.printStackTrace();
		}

		log.debug("Cache used {} times.", MyCache.getTimesUsed());
		System.exit(0);
	}

	private void runBenchmark() {
		Path datasetPath = Paths.get("datasets", "cross-chain", "smartaxe", DATASET_SUBDIR);
		List<SmartContract> contracts = loadContracts(datasetPath);

		log.info("Number of contracts to be analyzed: {}.", contracts.size());

		List<Future<?>> futures = new ArrayList<>();

		/* Phase 1: build CFG for each contract */
		for (SmartContract contract : contracts)
			futures.add(EVMLiSAExecutor.submit(CrossChainRealBenchmark.class, () -> {
				try {
					EVMLiSA.buildCFG(contract);
				} catch (Exception e) {
					log.error("Error building CFG for {}: {}", contract.getName(), e.getMessage());
				}
			}));
		EVMLiSAExecutor.awaitCompletionFutures(futures, 11, TimeUnit.HOURS); // barrier

		futures.clear();

		/* Phase 2: run Access Control Incompleteness checker */
		for (SmartContract contract : contracts)
			futures.add(EVMLiSAExecutor.submit(CrossChainRealBenchmark.class, () -> {
				try {
					xEVMLiSA.runAccessControlIncompleteness(contract);
				} catch (Exception e) {
					log.error("Error during Access Control Incompleteness for {}: {}", contract.getName(),
							e.getMessage());
				}
			}));
		EVMLiSAExecutor.awaitCompletionFutures(futures, 12, TimeUnit.HOURS); // barrier

		/* Save results */
		saveResults(contracts);
		saveVulnerabilitiesPerFunction(contracts);
		EVMLiSAExecutor.shutdown(CrossChainRealBenchmark.class);
	}

	/**
	 * Scans the dataset directory for per-address subdirectories (named
	 * {@code 0x...}) and loads one {@link SmartContract} per address from its
	 * locally compiled {@code bytecode/<address>.bytecode} and
	 * {@code abi/<address>.abi}. Directories missing either artifact are
	 * skipped (e.g. unverified sources that failed to compile).
	 *
	 * @param datasetPath path to {@code datasets/cross-chain/smartaxe/real/}
	 * @return list of loaded contracts
	 */
	private List<SmartContract> loadContracts(Path datasetPath) {
		List<SmartContract> contracts = new ArrayList<>();

		try (Stream<Path> dirs = Files.list(datasetPath)) {
			dirs.filter(Files::isDirectory)
					.filter(p -> p.getFileName().toString().startsWith("0x"))
					.sorted()
					.forEach(dir -> {
						String address = dir.getFileName().toString();
						Path bytecodePath = dir.resolve("bytecode").resolve(address + ".bytecode");
						Path abiPath = dir.resolve("abi").resolve(address + ".abi");

						if (!Files.exists(bytecodePath) || !Files.exists(abiPath)) {
							log.warn("Skipping {}: missing compiled bytecode or ABI.", address);
							return;
						}

						log.info("Loading contract: {}", address);
						try {
							contracts.add(new SmartContract(bytecodePath, abiPath));
						} catch (Exception e) {
							log.error("Failed to load contract {}: {}", address, e.getMessage());
						}
					});
		} catch (IOException e) {
			log.error("Failed to list dataset directory {}: {}", datasetPath, e.getMessage());
		}

		return contracts;
	}

	/**
	 * Serializes per-function vulnerability data for every contract and writes
	 * {@code benchmark_results_function.json} to the working directory.
	 *
	 * <p>For each contract the CFG hashcode is used as the cache key to look up
	 * the warnings populated by the checker. The contract address is used as
	 * the identifier (no source-code name mapping is available for this dataset).
	 *
	 * @param contracts analyzed contracts
	 */
	private void saveVulnerabilitiesPerFunction(List<SmartContract> contracts) {
		try {
			JSONArray results = new JSONArray();

			for (SmartContract contract : contracts) {
				JSONObject contractJson = new JSONObject();
				contractJson.put("address", contract.getName());
				contractJson.put("execution-time", contract.getExecutionTime());

				try {
					contractJson.put("vulnerabilities",
							MyCache.getInstance().getVulnerabilityPerFunction(
									contract.getCFG().hashCode()));
				} catch (Exception e) {
					log.error("Failed to retrieve per-function vulnerabilities for {}: {}",
							contract.getName(), e.getMessage());
					contractJson.put("vulnerabilities", new JSONArray());
				}

				results.put(contractJson);
			}

			System.err.println(results.toString(4));

			Path resultFilePath = workingDirectory.resolve("benchmark_results_function.json");
			Files.createDirectories(workingDirectory);
			Files.writeString(resultFilePath, results.toString(4));

			log.info("Per-function results saved in: {}", resultFilePath);
		} catch (IOException e) {
			log.error("Failed to save per-function benchmark results: {}", e.getMessage());
		}
	}

	/**
	 * Serializes per-contract analysis results and writes an aggregate
	 * {@code benchmark_results.json} to the working directory.
	 *
	 * @param contracts analyzed contracts
	 */
	private void saveResults(List<SmartContract> contracts) {
		JSONArray results = new JSONArray();

		for (SmartContract contract : contracts) {
			JSONObject contractJson = new JSONObject();
			contractJson.put("address", contract.getName());
			contractJson.put("execution-time", contract.getExecutionTime());

			try {
				contractJson.put("vulnerabilities", contract.getVulnerabilities().toJson());
			} catch (Exception e) {
				log.error("Failed to retrieve vulnerabilities for {}: {}", contract.getName(), e.getMessage());
				contractJson.put("vulnerabilities", JSONObject.NULL);
			}

			results.put(contractJson);
		}

		try {
			System.err.println(results.toString(4));

			Path resultFilePath = workingDirectory.resolve("benchmark_results.json");
			Files.createDirectories(workingDirectory);
			Files.writeString(resultFilePath, results.toString(4));

			log.info("Results saved in: {}", resultFilePath);
		} catch (IOException e) {
			log.error("Failed to save benchmark results: {}", e.getMessage());
		}
	}
}
