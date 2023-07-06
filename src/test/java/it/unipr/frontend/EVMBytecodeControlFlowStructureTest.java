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

	private final static boolean GENERATE_CFG = true;

	// Test for /evm-testcases/cfs/if/if_eth.sol
	@Test
	public void testIf() throws AnalysisSetupException, IOException {
		CronConfiguration conf = new CronConfiguration();
		conf.serializeResults = true;
		conf.abstractState = new SimpleAbstractState<MonolithicHeap, SymbolicStack, TypeEnvironment<InferredTypes>>(new MonolithicHeap(), new SymbolicStack(),
				new TypeEnvironment<>(new InferredTypes()));
		conf.testDir = "cfs/if";
		conf.callGraph = new RTACallGraph();
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		if (GENERATE_CFG) {
			conf.analysisGraphs = GraphType.DOT;
		}
		conf.programFile = "if_eth.sol";
		perform(conf);
	}
	
	// Test for /evm-testcases/cfs/if_else/if_else_eth.sol
	@Test
	public void testIfElse() throws AnalysisSetupException, IOException {
		CronConfiguration conf = new CronConfiguration();
		conf.serializeResults = true;
		conf.abstractState = new SimpleAbstractState<MonolithicHeap, SymbolicStack, TypeEnvironment<InferredTypes>>(new MonolithicHeap(), new SymbolicStack(),
				new TypeEnvironment<>(new InferredTypes()));
		conf.testDir = "cfs/if_else";
		conf.callGraph = new RTACallGraph();
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		if (GENERATE_CFG) {
			conf.analysisGraphs = GraphType.DOT;
		}
		conf.programFile = "if_else_eth.sol";
		perform(conf);
	}
	
	
	// Test for /evm-testcases/cfs/while/while_eth.sol
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
		if (GENERATE_CFG) {
			conf.analysisGraphs = GraphType.DOT;
		}
		conf.programFile = "while_eth.sol";
		perform(conf);
	}
}