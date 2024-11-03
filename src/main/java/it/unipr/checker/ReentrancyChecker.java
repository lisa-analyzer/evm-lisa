package it.unipr.checker;

import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.UniquePairCollector;
import it.unipr.cfg.Call;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Sstore;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.checks.semantic.CheckToolWithAnalysisResults;
import it.unive.lisa.checks.semantic.SemanticCheck;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.statement.Statement;
import java.util.Set;
import java.util.stream.Collectors;
import org.apache.commons.lang3.tuple.ImmutablePair;

public class ReentrancyChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> {
	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		if (node instanceof Call) {
			EVMCFG cfg = ((EVMCFG) graph);

			Set<Statement> ns = cfg.getNodes().stream()
					.filter(n -> n instanceof Sstore)
					.collect(Collectors.toSet());

			for (Statement stmt : ns)
				if (cfg.reachableFrom(node, stmt)) {

					tool.warn("Reentrancy attack from " + node.getLocation() + " to " + stmt.getLocation());
					UniquePairCollector.getInstance().add(new ImmutablePair<>(node.getLocation(), stmt.getLocation()));
				}

		}
		return true;
	}
}