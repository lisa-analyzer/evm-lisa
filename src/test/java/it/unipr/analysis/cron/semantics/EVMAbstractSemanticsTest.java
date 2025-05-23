package it.unipr.analysis.cron.semantics;

import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.cron.CronConfiguration;
import it.unipr.analysis.cron.EVMBytecodeAnalysisExecutor;
import it.unipr.checker.JumpSolver;
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
public class EVMAbstractSemanticsTest extends EVMBytecodeAnalysisExecutor {
	private static final boolean GENERATE_CFG_FOR_ALL_TESTS = false;

	private static final String FAKE_ADDRESS = "0x000000000000000";

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
	private static CronConfiguration createConfiguration(String testDir, String subDir, String programFile,
			boolean generateCfg) {
		if (GENERATE_CFG_FOR_ALL_TESTS) {
			generateCfg = true;
		}

		CronConfiguration conf = new CronConfiguration();
		conf.testDir = testDir;
		conf.testSubDir = subDir;
		conf.programFile = programFile;
		conf.serializeResults = true;
		if (generateCfg) {
			conf.analysisGraphs = GraphType.DOT;
		}
		conf.abstractState = new SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>(
				new MonolithicHeap(), new EVMAbstractState(FAKE_ADDRESS),
				new TypeEnvironment<>(new InferredTypes()));
		conf.callGraph = new RTACallGraph();
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		conf.semanticChecks.add(new JumpSolver());
		conf.useWideningPoints = false;
		return conf;
	}

	@Test
	public void testIf() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "if", "if_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testIfElse() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "if_else", "if_else_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testWhile() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "while", "while_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testIfElseNPBJ() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "if_else_npbj", "if_else_npbj_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testWhileNPBJ() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "while_npbj", "while_npbj_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testMstore() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "mstore", "mstore_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testMstore2() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "mstore2", "mstore_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testMstore3() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "mstore3", "mstore_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testMstore8() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "mstore8", "mstore8_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testLT() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "lt", "lt_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testSgt() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "sgt", "sgt_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testSlt() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "slt", "slt_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testKeccak256() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "keccak256", "keccak.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testAnd() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "and", "and_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testOr() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "or", "or_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testXor() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "xor", "xor_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testNot() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "not", "not_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testShl() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "shl", "shl_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testShr() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "shr", "shr_eth.sol", false);
		perform(conf);
	}

	@Test
	public void testShr2() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "shr2", "shr_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testSar() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "sar", "sar_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testDiv() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "div", "div_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testSdiv() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "sdiv", "sdiv_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testMod() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "mod", "mod_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testSmod() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "smod", "smod_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testAddmod() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "addmod", "addmod_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testMulmod() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "mulmod", "mulmod_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testShl2() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "shl2", "shl.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testAdd() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "add", "add_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testSub() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "sub", "sub_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testByte() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "byte", "byte_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 */
	@Test
	public void testSloadSstore() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "sload_sstore", "sload_sstore.sol", false);
		perform(conf);
	}

	/**
	 * The final memory must be
	 * 000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F
	 */
	@Test
	public void testMcopy() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "mcopy", "mcopy.sol", false);
		perform(conf);
	}

	/**
	 * The final memory must be TOP
	 */
	@Test
	public void testMcopyTopNotJumpdest() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "mcopy_topnotjumpdest", "mcopy.sol", false);
		perform(conf);
	}

	/**
	 * The final memory must be TOP
	 */
	@Test
	public void testMcopyTop() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "mcopy_top", "mcopy.sol", false);
		perform(conf);
	}

	@Test
	public void testBlobs() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "blob", "blob.sol", false);
		perform(conf);
	}

	@Test
	public void testTransient() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs", "transient", "transient.sol", false);
		perform(conf);
	}
}