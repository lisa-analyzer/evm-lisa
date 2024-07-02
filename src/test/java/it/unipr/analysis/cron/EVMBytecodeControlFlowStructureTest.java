package it.unipr.analysis.cron;

import it.unipr.analysis.EVMAbstractState;
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
public class EVMBytecodeControlFlowStructureTest extends EVMBytecodeAnalysisExecutor {
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
		conf.abstractState = new SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>(
				new MonolithicHeap(), new EVMAbstractState(FAKE_ADDRESS),
				new TypeEnvironment<>(new InferredTypes()));
		conf.callGraph = new RTACallGraph();
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		conf.semanticChecks.add(new JumpSolver());

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

	@Test
	public void testLT() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/lt", "lt_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 * 
	 * @throws AnalysisSetupException
	 * @throws IOException
	 */
	@Test
	public void testAnd() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/and", "and_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 * 
	 * @throws AnalysisSetupException
	 * @throws IOException
	 */
	@Test
	public void testOr() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/or", "or_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 * 
	 * @throws AnalysisSetupException
	 * @throws IOException
	 */
	@Test
	public void testXor() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/xor", "xor_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 * 
	 * @throws AnalysisSetupException
	 * @throws IOException
	 */
	@Test
	public void testNot() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/not", "not_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 * 
	 * @throws AnalysisSetupException
	 * @throws IOException
	 */
	@Test
	public void testShl() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/shl", "shl_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 * 
	 * @throws AnalysisSetupException
	 * @throws IOException
	 */
	@Test
	public void testShr() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/shr", "shr_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 * 
	 * @throws AnalysisSetupException
	 * @throws IOException
	 */
	@Test
	public void testSar() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/sar", "sar_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 * 
	 * @throws AnalysisSetupException
	 * @throws IOException
	 */
	@Test
	public void testDiv() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/div", "div_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 * 
	 * @throws AnalysisSetupException
	 * @throws IOException
	 */
	@Test
	public void testSdiv() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/sdiv", "sdiv_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 * 
	 * @throws AnalysisSetupException
	 * @throws IOException
	 */
	@Test
	public void testMod() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/mod", "mod_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 * 
	 * @throws AnalysisSetupException
	 * @throws IOException
	 */
	@Test
	public void testSmod() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/smod", "smod_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 * 
	 * @throws AnalysisSetupException
	 * @throws IOException
	 */
	@Test
	public void testAddmod() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/addmod", "addmod_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 * 
	 * @throws AnalysisSetupException
	 * @throws IOException
	 */
	@Test
	public void testMulmod() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/mulmod", "mulmod_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 * 
	 * @throws AnalysisSetupException
	 * @throws IOException
	 */
	@Test
	public void testAdd() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/add", "add_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 * 
	 * @throws AnalysisSetupException
	 * @throws IOException
	 */
	@Test
	public void testSub() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/sub", "sub_eth.sol", false);
		perform(conf);
	}

	/**
	 * All the items in the final stack must be 1
	 * 
	 * @throws AnalysisSetupException
	 * @throws IOException
	 */
	@Test
	public void testByte() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/byte", "byte_eth.sol", false);
		perform(conf);
	}
	
	/**
	 * All the items in the final stack must be 1
	 * 
	 * @throws AnalysisSetupException
	 * @throws IOException
	 */
	@Test
	public void testSloadSstore() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("cfs/sload_sstore", "sload_sstore.sol", false);
		perform(conf);
	}

}