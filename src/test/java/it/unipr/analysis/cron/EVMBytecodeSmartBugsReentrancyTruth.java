package it.unipr.analysis.cron;

import static it.unipr.frontend.EVMFrontend.opcodesFromBytecode;

import it.unipr.analysis.*;
import it.unipr.checker.JumpSolver;
import it.unipr.checker.ReentrancyChecker;
import it.unipr.frontend.EVMFrontend;
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
import java.nio.file.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.Test;

public class EVMBytecodeSmartBugsReentrancyTruth {
	private static final Logger log = LogManager.getLogger(EVMBytecodeSmartBugsReentrancyTruth.class);

	private Map<Integer, Integer> _results = new HashMap<>();

	@Test
	public void testSmartBugsReentrancyTruth() throws Exception {
		String SMARTBUGS_BYTECODE_PATH = "evm-testcases/ground-truth/test-reentrancy-smartbugs-truth/bytecode/";
		String SMARTBUGS_OPCODES_PATH = "evm-testcases/ground-truth/test-reentrancy-smartbugs-truth/opcodes/";

		EVMFrontend.setUseCreationCode();

		List<String> bytecodes = getFileNamesInDirectory(SMARTBUGS_BYTECODE_PATH);

		// Run the benchmark
		for (String bytecodeFileName : bytecodes) {

			String bytecodeFullPath = SMARTBUGS_BYTECODE_PATH + bytecodeFileName;
			String bytecode = Files.readString(Paths.get(bytecodeFullPath));
			String opcodeFullPath = SMARTBUGS_OPCODES_PATH + bytecodeFileName;

			opcodesFromBytecode(bytecode, opcodeFullPath);

			Program program = EVMFrontend.generateCfgFromFile(opcodeFullPath);

			LiSAConfiguration conf = new LiSAConfiguration();
			conf.serializeInputs = false;
			conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new EVMAbstractState(null),
					new TypeEnvironment<>(new InferredTypes()));
			conf.jsonOutput = false;
			conf.workdir = SMARTBUGS_BYTECODE_PATH;
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
			int value = UniqueItemCollector.getInstance().size();

			int tmp = 0;
			if (_results.containsKey(key))
				tmp = _results.get(key);
			_results.put(key, value + tmp);

			UniqueItemCollector.getInstance().clear();

			Runtime.getRuntime().gc(); // Force Java Garbage Collection
		}

		log.info("Results: {}", _results);
		// Check the results
		for (Integer key : _results.keySet()) {
			int value = _results.get(key);
			if (value == 1)
				continue;
			else if (value == 0) {
				log.error("Unsound on {}.sol", key);
				assert false;
			} else {
				log.warn("{} false positive on {}.sol", value - 1, key);
			}
		}

	}

	public static List<String> getFileNamesInDirectory(String directoryPath) {
		List<String> fileNames = new ArrayList<>();
		File directory = new File(directoryPath);

		// Controlla se il percorso specificato è una directory
		if (directory.isDirectory()) {
			// Ottieni tutti i file e cartelle nella directory
			File[] files = directory.listFiles();

			if (files != null) {
				// Aggiungi solo i nomi dei file alla lista
				for (File file : files) {
					if (file.isFile()) {
						fileNames.add(file.getName());
					}
				}
			}
		} else {
			System.out.println("Il percorso specificato non è una directory.");
		}

		return fileNames;
	}
}
