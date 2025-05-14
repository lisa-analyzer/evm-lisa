package it.unipr.analysis.cron;

import it.unipr.EVMLiSA;
import it.unipr.utils.EVMLiSAExecutor;
import it.unipr.utils.JSONManager;
import it.unipr.utils.PaperStatisticsObject;
import it.unipr.utils.StandardStatisticsObject;
import it.unipr.utils.StatisticsObject;

import static org.junit.Assert.assertFalse;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Set;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.AfterClass;
import org.junit.Ignore;
import org.junit.Test;

/*
 * ground-truth-stats/ground-truth-data.csv FILE MUST BE UPDATED WHEN A NEW
 * VERSION OF THE TRUTH DATASET IS CHOSEN.
 */
public class EVMBytecodeGroundTruth {
	private static final Logger log = LogManager.getLogger(EVMBytecodeGroundTruth.class);

	private final Path WORKING_DIRECTORY_PATH = Paths.get("evm-testcases", "ground-truth", "50-ground-truth");
	private final Path SMARTCONTRACTS_FULLPATH = Paths.get("benchmark", "50-ground-truth.txt");
	private final Path RUN_RESULTS = WORKING_DIRECTORY_PATH.resolve("set-of-contracts").resolve("results.json");
	private Path GROUND_TRUTH_FILE_PATH;

	@AfterClass
	public static void cleanUp() {
		EVMLiSAExecutor.shutdown();
	}

	private void setupAndRun() {
		if (EVMLiSA.isInPaperMode())
			GROUND_TRUTH_FILE_PATH = WORKING_DIRECTORY_PATH.resolve("ground-truth-data-paper-mode.json");
		else
			GROUND_TRUTH_FILE_PATH = WORKING_DIRECTORY_PATH.resolve("ground-truth-data.json");
		EVMLiSA.setWorkingDirectory(WORKING_DIRECTORY_PATH);
		EVMLiSA.setCores(Runtime.getRuntime().availableProcessors() / 4 * 3);
		EVMLiSA.setTestMode();
		EVMLiSA.analyzeSetOfContracts(SMARTCONTRACTS_FULLPATH, false);
	}

	@Test
	@Ignore
	public void regenerateGroundTruth() throws Exception {
		EVMLiSA.disablePaperMode();
		setupAndRun();

		Files.copy(RUN_RESULTS, GROUND_TRUTH_FILE_PATH, StandardCopyOption.REPLACE_EXISTING);
	}

	@Test
	public void testGroundTruth() throws Exception {
		EVMLiSA.disablePaperMode();
		setupAndRun();

		boolean changed = false;
		Set<StatisticsObject<?>> groundTruthData = JSONManager.readStatsFromJSON(GROUND_TRUTH_FILE_PATH);
		Set<StatisticsObject<?>> newData = JSONManager.readStatsFromJSON(RUN_RESULTS);

		log.info("Ground truth size: {}", groundTruthData.size());
		log.info("New data size: {}", newData.size());

		assert groundTruthData.size() == newData.size();

		for (StatisticsObject<?> truthStats : groundTruthData) {
			StandardStatisticsObject groundTruthStats = (StandardStatisticsObject) truthStats;
			for (StatisticsObject<?> stats : newData) {
				StandardStatisticsObject newStats = (StandardStatisticsObject) stats;
				if (groundTruthStats.getAddress().equals(newStats.getAddress())
						&& !groundTruthStats.equals(newStats)) {

					if (!changed)
						log.error("\n*******************************************\n");

					changed = true;
					log.error("{}\n", groundTruthStats.getAddress());

					if (groundTruthStats.getResolvedJumps() != newStats.getResolvedJumps()) {
						log.error("\tSolved Jumps");
						log.error("\t\tTruth: {}, New: {}\n", groundTruthStats.getResolvedJumps(),
								newStats.getResolvedJumps());
					}
					if (groundTruthStats.getDefinitelyUnreachableJumps() != newStats.getDefinitelyUnreachableJumps()) {
						log.error("\tDefinitely Unreachable Jumps");
						log.error("\t\tTruth: {}, New: {}\n", groundTruthStats.getDefinitelyUnreachableJumps(),
								newStats.getDefinitelyUnreachableJumps());
					}
					if (groundTruthStats.getMaybeUnreachableJumps() != newStats.getMaybeUnreachableJumps()) {
						log.error("\tMaybe Unreachable Jumps");
						log.error("\t\tTruth: {}, New: {}\n", groundTruthStats.getMaybeUnreachableJumps(),
								newStats.getMaybeUnreachableJumps());
					}
					if (groundTruthStats.getUnsoundJumps() != newStats.getUnsoundJumps()) {
						log.error("\tUnsolved Jumps");
						log.error("\t\tTruth: {}, New: {}\n", groundTruthStats.getUnsoundJumps(),
								newStats.getUnsoundJumps());
					}
					if (groundTruthStats.getMaybeUnsoundJumps() != newStats.getMaybeUnsoundJumps()) {
						log.error("\tMaybe Unsound Jumps");
						log.error("\t\tTruth: {}, New: {}\n", groundTruthStats.getMaybeUnsoundJumps(),
								newStats.getMaybeUnsoundJumps());
					}
					newData.remove(newStats);
					break;
				}
			}
		}

		assertFalse(changed);
	}

	@Test
	@Ignore
	public void regenerateGroundTruthPaperMode() throws Exception {
		EVMLiSA.setPaperMode();
		setupAndRun();

		Files.copy(RUN_RESULTS, GROUND_TRUTH_FILE_PATH, StandardCopyOption.REPLACE_EXISTING);
	}

	@Test
	public void testGroundTruthPaperMode() throws Exception {
		EVMLiSA.setPaperMode();
		setupAndRun();

		boolean changed = false;
		Set<StatisticsObject<?>> groundTruthData = JSONManager.readStatsFromJSON(GROUND_TRUTH_FILE_PATH);
		Set<StatisticsObject<?>> newData = JSONManager.readStatsFromJSON(RUN_RESULTS);

		log.info("Ground truth size: {}", groundTruthData.size());
		log.info("New data size: {}", newData.size());

		assert groundTruthData.size() == newData.size();

		for (StatisticsObject<?> truthStats : groundTruthData) {
			PaperStatisticsObject groundTruthStats = (PaperStatisticsObject) truthStats;
			for (StatisticsObject<?> stats : newData) {
				PaperStatisticsObject newStats = (PaperStatisticsObject) stats;
				if (groundTruthStats.getAddress().equals(newStats.getAddress())
						&& !groundTruthStats.equals(newStats)) {

					if (!changed)
						log.error("\n*******************************************\n");

					changed = true;
					log.error("{}\n", groundTruthStats.getAddress());

					if (groundTruthStats.getResolved() != newStats.getResolved()) {
						log.error("\tSolved Jumps");
						log.error("\t\tTruth: {}, New: {}\n", groundTruthStats.getResolved(),
								newStats.getResolved());
					}
					if (groundTruthStats.getUnreachable() != newStats.getUnreachable()) {
						log.error("\tUnreachable Jumps");
						log.error("\t\tTruth: {}, New: {}\n", groundTruthStats.getUnreachable(),
								newStats.getUnreachable());
					}
					if (groundTruthStats.getErroneous() != newStats.getErroneous()) {
						log.error("\tErroneous Jumps");
						log.error("\t\tTruth: {}, New: {}\n", groundTruthStats.getErroneous(),
								newStats.getErroneous());
					}
					if (groundTruthStats.getUnknown() != newStats.getUnknown()) {
						log.error("\tUnknown Jumps");
						log.error("\t\tTruth: {}, New: {}\n", groundTruthStats.getUnknown(),
								newStats.getUnknown());
					}
					newData.remove(newStats);
					break;
				}
			}
		}

		assertFalse(changed);
	}
}