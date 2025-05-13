package it.unipr.analysis.cron;

import it.unipr.EVMLiSA;
import it.unipr.utils.JSONManager;
import it.unipr.utils.StandardStatisticsObject;

import static org.junit.Assert.assertFalse;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Set;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.Ignore;
import org.junit.Test;

/*
 * ground-truth-stats/ground-truth-data.csv FILE MUST BE UPDATED WHEN A NEW
 * VERSION OF THE TRUTH DATASET IS CHOSEN.
 */
public class EVMBytecodeGroundTruth {
	private static final Logger log = LogManager.getLogger(EVMBytecodeGroundTruth.class);

	private final Path WORKING_DIRECTORY_PATH = Paths.get("evm-testcases", "ground-truth", "50-ground-truth");
	private final Path GROUND_TRUTH_FILE_PATH = WORKING_DIRECTORY_PATH.resolve("ground-truth-data.json");
	private final Path SMARTCONTRACTS_FULLPATH = Paths.get("benchmark", "50-ground-truth.txt");
	private final Path RUN_RESULTS = WORKING_DIRECTORY_PATH.resolve("set-of-contracts").resolve("results.json");

	private void setupAndRun() {
		EVMLiSA.setWorkingDirectory(WORKING_DIRECTORY_PATH);
		EVMLiSA.setCores(Runtime.getRuntime().availableProcessors() / 4 * 3);
		EVMLiSA.setTestMode();
		EVMLiSA.analyzeSetOfContracts(SMARTCONTRACTS_FULLPATH);
	}

	@Test
	@Ignore
	public void regenerateGroundTruth() throws Exception {
		setupAndRun();

		Files.copy(RUN_RESULTS, GROUND_TRUTH_FILE_PATH, StandardCopyOption.REPLACE_EXISTING);
	}

	@Test
	public void testGroundTruth() throws Exception {
		setupAndRun();

		boolean changed = false;
		Set<StandardStatisticsObject> groundTruthData = JSONManager.readStatsFromJSON(GROUND_TRUTH_FILE_PATH);
		Set<StandardStatisticsObject> newData = JSONManager.readStatsFromJSON(RUN_RESULTS);

		log.info("Ground truth size: {}", groundTruthData.size());
		log.info("New data size: {}", newData.size());

		assert groundTruthData.size() == newData.size();

		for (StandardStatisticsObject groundTruthStats : groundTruthData) {
			for (StandardStatisticsObject newStats : newData) {
				if (groundTruthStats.getAddress().equals(newStats.getAddress())
						&& !groundTruthStats.equals(newStats)) {

					if (!changed)
						System.err.println("\n*******************************************\n");

					changed = true;
					System.err.printf("%s\n", groundTruthStats.getAddress());

					if (groundTruthStats.getResolvedJumps() != newStats.getResolvedJumps()) {
						System.err.println("\tSolved Jumps");
						System.err.printf("\t\tTruth: %s, New: %s\n", groundTruthStats.getResolvedJumps(),
								newStats.getResolvedJumps());
					}
					if (groundTruthStats.getDefinitelyUnreachableJumps() != newStats.getDefinitelyUnreachableJumps()) {
						System.err.println("\tDefinitely Unreachable Jumps");
						System.err.printf("\t\tTruth: %s, New: %s\n", groundTruthStats.getDefinitelyUnreachableJumps(),
								newStats.getDefinitelyUnreachableJumps());
					}
					if (groundTruthStats.getMaybeUnreachableJumps() != newStats.getMaybeUnreachableJumps()) {
						System.err.println("\tMaybe Unreachable Jumps");
						System.err.printf("\t\tTruth: %s, New: %s\n", groundTruthStats.getMaybeUnreachableJumps(),
								newStats.getMaybeUnreachableJumps());
					}
					if (groundTruthStats.getUnsoundJumps() != newStats.getUnsoundJumps()) {
						System.err.println("\tUnsolved Jumps");
						System.err.printf("\t\tTruth: %s, New: %s\n", groundTruthStats.getUnsoundJumps(),
								newStats.getUnsoundJumps());
					}
					if (groundTruthStats.getMaybeUnsoundJumps() != newStats.getMaybeUnsoundJumps()) {
						System.err.println("\tMaybe Unsound Jumps");
						System.err.printf("\t\tTruth: %s, New: %s\n", groundTruthStats.getMaybeUnsoundJumps(),
								newStats.getMaybeUnsoundJumps());
					}
					newData.remove(newStats);
					break;
				}
			}
		}

		assertFalse(changed);
	}
}