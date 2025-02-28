package it.unipr.analysis.cron;

import it.unipr.EVMLiSA;
import it.unipr.utils.JSONManager;
import it.unipr.utils.StatisticsObject;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Set;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.Test;

/*
 * ground-truth-stats/ground-truth-data.csv FILE MUST BE UPDATED WHEN A NEW
 * VERSION OF THE TRUTH DATASET IS CHOSEN.
 */
public class EVMBytecodeGroundTruth {
	private static final Logger log = LogManager.getLogger(EVMBytecodeGroundTruth.class);

	@Test
	public void testGroundTruth() throws Exception {
		Path WORKING_DIRECTORY_PATH = Paths.get("evm-testcases", "ground-truth", "50-ground-truth");
		Path GROUND_TRUTH_FILE_PATH = WORKING_DIRECTORY_PATH.resolve("ground-truth-data.json");
		Path SMARTCONTRACTS_FULLPATH = Paths.get("benchmark", "50-ground-truth.txt");

		boolean changed = false;
		EVMLiSA.setStackLimit(32);
		EVMLiSA.setStackSetSize(8);
		EVMLiSA.setWorkingDirectory(WORKING_DIRECTORY_PATH);
		EVMLiSA.setCores(4);
		EVMLiSA.setLinkUnsoundJumpsToAllJumpdest();
		EVMLiSA.analyzeSetOfContracts(SMARTCONTRACTS_FULLPATH);

		Set<StatisticsObject> groundTruthData = JSONManager.readStatsFromJSON(GROUND_TRUTH_FILE_PATH);
		Set<StatisticsObject> newData = JSONManager.readStatsFromJSON(
				WORKING_DIRECTORY_PATH.resolve("set-of-contracts").resolve("results.json"));

		log.info("Ground truth size: {}", groundTruthData.size());
		log.info("New data size: {}", newData.size());

		assert groundTruthData.size() == newData.size();

		for (StatisticsObject groundTruthStats : groundTruthData) {
			for (StatisticsObject newStats : newData) {
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

		assert !changed;
	}
}