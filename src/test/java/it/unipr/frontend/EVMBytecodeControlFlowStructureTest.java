package it.unipr.frontend;

import java.io.IOException;

import org.junit.Test;

import it.unipr.analysis.SymbolicStack;
import it.unive.lisa.AnalysisSetupException;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.conf.LiSAConfiguration.GraphType;
import it.unive.lisa.interprocedural.ModularWorstCaseAnalysis;
import it.unive.lisa.interprocedural.callgraph.RTACallGraph;

public class EVMBytecodeControlFlowStructureTest extends EVMBytecodeAnalysisExecutor{

	
	@Test
	public void testIf() throws AnalysisSetupException, IOException {
		CronConfiguration conf = new CronConfiguration();
		conf.serializeResults = true;
		conf.abstractState = new SimpleAbstractState<MonolithicHeap, SymbolicStack, TypeEnvironment<InferredTypes>>(new MonolithicHeap(), new SymbolicStack(),
				new TypeEnvironment<>(new InferredTypes()));
		conf.testDir = "cfs/if";
		conf.callGraph = new RTACallGraph();
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		conf.programFile = "if_eth.sol";
		perform(conf);
	}
	
	@Test
	public void testWhile() throws AnalysisSetupException, IOException {
		CronConfiguration conf = new CronConfiguration();
		conf.serializeResults = true;
		conf.abstractState = new SimpleAbstractState<MonolithicHeap, SymbolicStack, TypeEnvironment<InferredTypes>>(new MonolithicHeap(), new SymbolicStack(),
				new TypeEnvironment<>(new InferredTypes()));
		conf.callGraph = new RTACallGraph();
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		conf.testDir = "cfs/while";
		conf.serializeInputs = true;
		conf.analysisGraphs = GraphType.DOT;
		conf.programFile = "while_eth.sol";
		perform(conf);
	}
}
