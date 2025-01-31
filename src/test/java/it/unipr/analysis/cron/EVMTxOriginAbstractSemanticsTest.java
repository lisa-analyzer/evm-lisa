package it.unipr.analysis.cron;

import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TxOriginAbstractDomain;
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
public class EVMTxOriginAbstractSemanticsTest extends EVMBytecodeAnalysisExecutor {
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
		conf.abstractState = new SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
				TypeEnvironment<InferredTypes>>(
						new MonolithicHeap(), new TxOriginAbstractDomain(),
						new TypeEnvironment<>(new InferredTypes()));
		conf.callGraph = new RTACallGraph();
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
//		conf.semanticChecks.add(new JumpSolver());
		conf.useWideningPoints = false;

		return conf;
	}

	@Test
	public void testTaint01() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example", "example.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint02() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example02", "example02.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint03() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example03", "example03.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint04() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example04", "example04.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint05() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example05", "example05.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint06() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example06", "example06.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint07() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example07", "example07.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint08() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example08", "example08.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint09() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example09", "example09.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint10() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example10", "example10.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint11() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example11", "example11.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint12() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example12", "example12.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint13() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example13", "example13.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint14() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example14", "example14.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint15() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example15", "example15.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint16() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example16", "example16.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint17() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example17", "example17.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint18() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTxOrigin", "example18", "example18.sol", false);
		perform(conf);
	}
}