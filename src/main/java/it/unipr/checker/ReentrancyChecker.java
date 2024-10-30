package it.unipr.checker;

import it.unipr.analysis.EVMAbstractState;
import it.unipr.cfg.Call;
import it.unipr.cfg.EVMCFG;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.checks.semantic.CheckToolWithAnalysisResults;
import it.unive.lisa.checks.semantic.SemanticCheck;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.statement.Statement;

public class ReentrancyChecker
		implements SemanticCheck<SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>,
				MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>> {

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>,
					MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>> tool,
			CFG graph, Statement node) {

		if (node instanceof Call) {
			EVMCFG cfg = ((EVMCFG) graph);
			// found paths to SSTORE
		}

		return true;
	}
}
