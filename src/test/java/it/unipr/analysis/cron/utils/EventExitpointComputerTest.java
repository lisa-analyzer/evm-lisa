package it.unipr.analysis.cron.utils;

import it.unipr.EVMLiSA;
import it.unipr.analysis.contract.Signature;
import it.unipr.analysis.contract.SmartContract;
import it.unipr.crosschain.Bridge;
import it.unipr.crosschain.xEVMLiSA;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.Test;

public class EventExitpointComputerTest {
	private static final Logger log = LogManager.getLogger(EventExitpointComputerTest.class);

	private static final Path outputDirPath = Paths.get("evm-outputs", "event-exitpoint-computer");

	@Test
	public void test01() {
		Path bytecodePath = Paths.get("evm-testcases", "event-exitpoint-computer", "Thorchain", "bytecode");
		Path abiPath = Paths.get("evm-testcases", "event-exitpoint-computer", "Thorchain", "abi");

		Map<String, Integer> gt = new HashMap<>();
		gt.put("2_1-2da466a7", 1);
		gt.put("1_3-8be0079c", 2);
		gt.put("3_1-2da466a7", 1);
		gt.put("4_1-2da466a7", 1);
		gt.put("5_1-643e927b", 1);
		gt.put("5_1-89d500b0", 1);

		EVMLiSA.setWorkingDirectory(outputDirPath.resolve("Thorchain"));
		EVMLiSA.setStackLimit(32);
		EVMLiSA.setStackSetSize(8);

		Bridge bridge = new Bridge(bytecodePath, abiPath);
		xEVMLiSA.analyzeBridge(bridge);

		boolean changed = true;
		for (SmartContract contract : bridge) {
			for (Signature event : contract.getEventsSignature()) {
				String key = contract.getName() + "-" + event.getSelector();

				if (gt.containsKey(key)) {
					log.debug("[{}] Expected {}, found {}", key, gt.get(key), event.getExitPoints().size());
					changed &= gt.get(key) == event.getExitPoints().size();
				} else {
					log.debug("[{}] Expected 0, found {}", key, event.getExitPoints().size());
					changed &= event.getExitPoints().isEmpty();
				}
			}
		}
		assert changed;
	}

}
