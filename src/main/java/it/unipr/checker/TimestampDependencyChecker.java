package it.unipr.checker;

import java.util.Set;

import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.cfg.Balance;
import it.unipr.cfg.Blockhash;
import it.unipr.cfg.Difficulty;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Timestamp;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.checks.semantic.CheckToolWithAnalysisResults;
import it.unive.lisa.checks.semantic.SemanticCheck;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.statement.Statement;

public class TimestampDependencyChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	@Override
	public void beforeExecution(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool) {
		// TODO Auto-generated method stub
		SemanticCheck.super.beforeExecution(tool);
	}

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {
		
		if (node instanceof Timestamp || node instanceof Blockhash || node instanceof Difficulty || node instanceof Balance) {
			EVMCFG cfg = ((EVMCFG) graph);
			Set<Statement> nsh = cfg.getAllSha3();
			Set<Statement> ns = cfg.getAllSstore();
			// The function cfg.getAllJumps() returns all jumps, whether being jump or jumpi
			// if you want to separete the jumps, a different function need to be done
			Set<Statement> nj = cfg.getAllJumps();
			
			
		}
		
		
		
		
		return SemanticCheck.super.visit(tool, graph, node);
	}

	@Override
	public void afterExecution(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool) {
		// TODO Auto-generated method stub
		SemanticCheck.super.afterExecution(tool);
	}

}
