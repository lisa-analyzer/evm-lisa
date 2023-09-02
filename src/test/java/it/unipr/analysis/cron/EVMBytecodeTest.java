package it.unipr.analysis.cron;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

import org.junit.Test;

import it.unipr.analysis.SymbolicStack;
import it.unipr.cfg.EVMCFG;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.conf.LiSAConfiguration.GraphType;
import it.unive.lisa.interprocedural.callgraph.RTACallGraph;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unipr.checker.JumpChecker;
import it.unipr.frontend.EVMFrontend;
import it.unive.lisa.interprocedural.ModularWorstCaseAnalysis;

public class EVMBytecodeTest extends EVMBytecodeAnalysisExecutor {
	/*
	 * Some examples of contract addresses:
	 * a. SafeMath: 	     0x7de33b2672efb11fde366dae96bd63b985bce186
	 * b. ZipmexTokenP.:     0xaa602de53347579f86b996d2add74bb6f79462b2
	 * c. ltdFDTfactory:     0xf155152d838b7a023317ad8c1e8c02aab7e8f2a2
	 * d. Dividend: 	     0xdb6f50cf0c521a98b6852839aa5cbea4e2430052
	 * e. DharmaKeyR.: 	     0x0000000000bda2152794ac8c76b2dc86cba57cad
	 * f. DharmaT.R.: 	     0x8b028e2fad2dc99999fb784ca9d7267981c90b4d
	 * g. AltesF.G.: 	     0x8313675d1405f3f7aee3da9d63e0bf5c30c75832
	 * h. SMRT16Ext: 	     0xdabb0c3f9a190b6fe4df6cb412ba66c3dd3e2ad1
	 * i. FlashFloss:	     0xfd4085e56a96787fb7acd9b49510f874c3d4afcb
	 * j. FoxInvSplit:	     0xd69015163e250a70ee4a607812afda5372132cc4
	 * k. BCN20:		     0x1964f2f3ce45ac518b18ef4aa4265f8aadcef4ae
	 * l. OneSplit:		     0x3a2d9db352580eb50018fc86eae32e19070a9982
	 * m. EthexLoto:	     0x0e26b2dc8ef577baf50891eac94f0def59b5da16
	 * n. ManagedAccount:    0x0f4f45f2edba03d4590bd27cf4fd62e91a2a2d6a
	 * o. ERC20Salary:	     0xcc2ba2eac448d60e0f943ebe378f409cb7d1b58a
	 */
	private final static String CONTRACT_ADDR = "0x679131f591b4f369acb8cd8c51e68596806c3916";

	// Contract bytecode output directory
	private final static String BYTECODE_DIR = "bytecodeBenchmark/" + CONTRACT_ADDR;
	private final static String BYTECODE_FILENAME = CONTRACT_ADDR + ".sol";
	private final static String BYTECODE_FULLPATH = EXPECTED_RESULTS_DIR + "/" + BYTECODE_DIR + "/" + BYTECODE_FILENAME;

	// Choose whether to generate the CFG or not
	private final static boolean GENERATE_CFG = true;

	@Test
	public void testEVMBytecodeAnalysis() throws Exception {
		// Directory setup and bytecode retrieval
		Files.createDirectories(Paths.get(EXPECTED_RESULTS_DIR + "/" + BYTECODE_DIR));
		EVMFrontend.parseContractFromEtherscan(CONTRACT_ADDR, BYTECODE_FULLPATH);
		
		// Config and test run
		CronConfiguration conf = new CronConfiguration();
		conf.serializeResults = true;
		conf.abstractState = new SimpleAbstractState<MonolithicHeap, SymbolicStack, TypeEnvironment<InferredTypes>>(
				new MonolithicHeap(), new SymbolicStack(),
				new TypeEnvironment<>(new InferredTypes()));
		conf.testDir = BYTECODE_DIR;
		conf.callGraph = new RTACallGraph();
		JumpChecker checker = new JumpChecker();
		conf.semanticChecks.add(checker);
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		conf.serializeInputs = true;
		if (GENERATE_CFG) {
			conf.analysisGraphs = GraphType.DOT;
		}
		conf.programFile = BYTECODE_FILENAME;
		perform(conf);

		// Print the results
		int totalJumps = getTotalJumpsFromFile(BYTECODE_FULLPATH);
		System.err.println("##############");
		try {
			System.err.println("Percentage of solved jumps: " + checker.getSolvedJumps() * 100 / (totalJumps - checker.getUnreachableJumps()) + "%");
		} catch (ArithmeticException e) {
			System.err.println("Percentage of solved jumps: 0%");
		}
		System.err.println("Total jumps: " + totalJumps);
		System.err.println("Solved jumps: " + checker.getSolvedJumps());
		System.err.println("Unsolved jumps: " + checker.getUnsolvedJumps());
		System.err.println("Unreachable jumps: " + checker.getUnreachableJumps());
		System.err.println("##############");
	}

	private static int getTotalJumpsFromFile(String filename) {
		int totalJumps = 0;
		try {
			for (CFG c : EVMFrontend.generateCfgFromFile(filename).getAllCFGs()) {
				totalJumps = ((EVMCFG) c).getAllJumps().size();
			}
		} catch (IOException e) {
			System.err.println("Incorrect contract filename");
		}
		return totalJumps;
	}
}