package it.unipr.analysis.cron;

import java.io.IOException;

import org.junit.Test;

import it.unipr.analysis.taint.TaintAbstractStack;
import it.unipr.checker.JumpSolver;
import it.unive.lisa.AnalysisSetupException;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.conf.LiSAConfiguration.GraphType;
import it.unive.lisa.interprocedural.ModularWorstCaseAnalysis;
import it.unive.lisa.interprocedural.callgraph.RTACallGraph;

/**
 * JUnit tests for the various control flow structures of the EVM bytecode, such
 * as if, if-else, while, etc. Operations with orphan jumps, marked as NPBJ (No
 * Push Before Jump), are also tested in specific test cases.
 */
public class EVMTaintAbstractSemantics extends EVMBytecodeAnalysisExecutor {
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
		conf.abstractState = new SimpleAbstractState<MonolithicHeap, TaintAbstractStack, TypeEnvironment<InferredTypes>>(
				new MonolithicHeap(), new TaintAbstractStack(),
				new TypeEnvironment<>(new InferredTypes()));
		conf.callGraph = new RTACallGraph();
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
//		conf.semanticChecks.add(new JumpSolver());
		conf.useWideningPoints = false;

		return conf;
	}

	@Test
	public void testTaint01() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint", "example", "example.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint02() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint", "example02", "example02.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint03() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint", "example03", "example03.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint04() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint", "example04", "example04.sol", false);
		perform(conf);
	}

	@Test
	public void testTaint05() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint", "example05", "example05.sol", false);
		perform(conf);
	}
}