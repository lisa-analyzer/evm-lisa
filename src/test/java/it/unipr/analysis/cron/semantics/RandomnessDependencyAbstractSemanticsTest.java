package it.unipr.analysis.cron.semantics;

import it.unipr.analysis.cron.CronConfiguration;
import it.unipr.analysis.cron.EVMBytecodeAnalysisExecutor;
import it.unipr.analysis.taint.RandomnessDependencyAbstractDomain;
import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unive.lisa.AnalysisSetupException;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.conf.LiSAConfiguration;
import it.unive.lisa.interprocedural.ModularWorstCaseAnalysis;
import it.unive.lisa.interprocedural.callgraph.RTACallGraph;
import java.io.IOException;
import org.junit.Test;

/**
 * JUnit tests for the various control flow structures of the EVM bytecode, such
 * as if, if-else, while, etc. Operations with orphan jumps, marked as NPBJ (No
 * Push Before Jump), are also tested in specific test cases.
 */
public class RandomnessDependencyAbstractSemanticsTest extends EVMBytecodeAnalysisExecutor {
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
			conf.analysisGraphs = LiSAConfiguration.GraphType.DOT;
		}
		conf.abstractState = new SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
				TypeEnvironment<InferredTypes>>(
						new MonolithicHeap(), new RandomnessDependencyAbstractDomain(),
						new TypeEnvironment<>(new InferredTypes()));
		conf.callGraph = new RTACallGraph();
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		conf.useWideningPoints = false;
		return conf;
	}

	@Test
	public void testTimestampDependency01() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example", "example.sol", false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency02() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example02", "example02.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency03() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example03", "example03.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency04() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example04", "example05.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency05() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example05", "example06.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency06() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example06", "example07.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency07() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example07", "example08.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency08() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example08", "example09.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency09() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example09", "example10.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency10() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example10", "example11.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency11() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example11", "example12.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency12() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example12", "example13.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency13() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example13", "example14.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency14() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example14", "example15.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency15() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example15", "example16.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency16() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example16", "example17.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency17() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example17", "example18.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency18() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example18", "example19.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency19() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example19", "example20.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency20() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example20", "example21.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency21() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example21", "example22.sol",
				false);
		perform(conf);
	}

	@Test
	public void testTimestampDependency22() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testTimestampDependency", "example22", "example23.sol",
				false);
		perform(conf);
	}

}