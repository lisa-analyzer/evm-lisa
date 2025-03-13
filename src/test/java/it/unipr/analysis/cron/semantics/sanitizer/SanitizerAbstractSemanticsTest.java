package it.unipr.analysis.cron.semantics.sanitizer;

import it.unipr.analysis.cron.CronConfiguration;
import it.unipr.analysis.cron.EVMBytecodeAnalysisExecutor;
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
public class SanitizerAbstractSemanticsTest extends EVMBytecodeAnalysisExecutor {
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
						new MonolithicHeap(), new SanitizerAbstractDomain(),
						new TypeEnvironment<>(new InferredTypes()));
		conf.callGraph = new RTACallGraph();
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		conf.useWideningPoints = false;
		return conf;
	}

	@Test
	public void testSanitizer01() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testSanitizer", "test1", "test1.opcode", false);
		perform(conf);
	}

	@Test
	public void testSanitizer02() throws AnalysisSetupException, IOException {
		CronConfiguration conf = createConfiguration("taint/testSanitizer", "test2", "test2.opcode", false);
		perform(conf);
	}
}