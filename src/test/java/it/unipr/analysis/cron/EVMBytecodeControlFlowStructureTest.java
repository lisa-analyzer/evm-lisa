package it.unipr.analysis.cron;

import it.unipr.analysis.EVMAbsDomain;
import it.unipr.checker.JumpChecker;
import it.unive.lisa.AnalysisSetupException;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.conf.LiSAConfiguration.GraphType;
import it.unive.lisa.interprocedural.ModularWorstCaseAnalysis;
import it.unive.lisa.interprocedural.callgraph.RTACallGraph;
import java.io.IOException;
import org.junit.Test;

/**
 * JUnit tests for the various control flow structures of the EVM bytecode, such
 * as if, if-else, while, etc. Operations with orphan jumps, marked as NPBJ (No
 * Push Before Jump), are also tested in specific test cases.
 */
public class EVMBytecodeControlFlowStructureTest extends EVMBytecodeAnalysisExecutor {
	private static final boolean GENERATE_CFG_FOR_ALL_TESTS = false;

	/**
	 * Helper method to create a {@link CronConfiguration} object for the test
	 * cases.
	 * 
	 * @param testDir     the directory where the test case is stored.
	 * @param programFile the name of the test case file.
	 * @param generateCfg a flag to enable/disable the generation of the CFG
	 *                        file (in DOT format). This flag will be ignored if
	 *                        {@link #GENERATE_CFG_FOR_ALL_TESTS} is set to
	 *                        {@code true}.
	 * 
	 * @return a {@link CronConfiguration} to be performed on the test case.
	 */
	private static CronConfiguration createConfiguration(String testDir, String programFile, boolean generateCfg) {
		if (GENERATE_CFG_FOR_ALL_TESTS) {
			generateCfg = true;
		}

		CronConfiguration conf = new CronConfiguration();
		conf.testDir = testDir;
		conf.programFile = programFile;
		conf.serializeResults = true;
		if (generateCfg) {
			conf.analysisGraphs = GraphType.DOT;
		}
		conf.abstractState = new SimpleAbstractState<MonolithicHeap, EVMAbsDomain, TypeEnvironment<InferredTypes>>(
				new MonolithicHeap(), new EVMAbsDomain(),
				new TypeEnvironment<>(new InferredTypes()));
		conf.callGraph = new RTACallGraph();
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		conf.semanticChecks.add(new JumpChecker());

		return conf;
	}

	@Test
	public void testIf() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/if", "if_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testIfElse() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/if_else", "if_else_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testWhile() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/while", "while_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testIfElseNPBJ() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/if_else_npbj", "if_else_npbj_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testWhileNPBJ() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/while_npbj", "while_npbj_eth.sol", false);
		perform(conf);
	}

	/**
	 * Testcase for a real contract: 0x0000000000bda2152794ac8c76b2dc86cba57cad
	 * - Number of opcodes: 32 - Expected solved jumps %: 100%
	 */
	@Test
	public void testRealContract() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/0x0000000000bda2152794ac8c76b2dc86cba57cad",
				"0x0000000000bda2152794ac8c76b2dc86cba57cad.sol", false);
		perform(conf);
	}

	@Test
	public void testMstore() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/mstore", "mstore_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testMstore8() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/mstore8", "mstore8_eth.sol", false);
		perform(conf);
	}

}