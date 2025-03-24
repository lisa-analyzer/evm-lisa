package it.unipr.crosschain.checker;

import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.*;
import it.unipr.utils.MyCache;
import it.unive.lisa.analysis.AnalysisState;
import it.unive.lisa.analysis.AnalyzedCFG;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.checks.semantic.CheckToolWithAnalysisResults;
import it.unive.lisa.checks.semantic.SemanticCheck;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.statement.Statement;
import java.util.Collections;
import java.util.Set;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class UncheckedStateUpdateChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(UncheckedStateUpdateChecker.class);

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		if (node instanceof Sstore) {
			EVMCFG cfg = ((EVMCFG) graph);
			Statement sstore = node;

			for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
					TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
				AnalysisState<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
						TypeEnvironment<InferredTypes>>> analysisResult = null;

				try {
					analysisResult = result.getAnalysisStateBefore(sstore);
				} catch (SemanticException e1) {
					log.error("(UncheckedStateUpdateChecker): {}", e1.getMessage());
				}

				// Retrieve the symbolic stack from the analysis result
				TaintAbstractDomain taintedStack = analysisResult.getState().getValueState();

				if (taintedStack.isBottom())
					// Nothing to do
					continue;
				else {

					// Checks if either first or second element in the
					// stack is tainted
					if (TaintElement.isTaintedOrTop(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2))) {
						checkForUncheckedStateUpdate(sstore, tool, cfg);
					}

				}
			}
		}

		return true;
	}

	private void checkForUncheckedStateUpdate(Statement sstore, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg) {

		Set<Statement> calls = cfg.getAllCall();

		for (Statement call : calls) {
			if (cfg.reachableFromWithoutTypes(call, sstore, Collections.singleton(Jumpi.class))) {

				ProgramCounterLocation sstoreLocation = (ProgramCounterLocation) sstore.getLocation();

				log.warn("Unchecked State Update vulnerability at pc {} at line {} coming from line {}.",
						sstoreLocation.getPc(),
						sstoreLocation.getSourceCodeLine(),
						((ProgramCounterLocation) call.getLocation()).getSourceCodeLine());

				String warn = "Unchecked State Update vulnerability at "
						+ ((ProgramCounterLocation) call.getLocation()).getSourceCodeLine();
				tool.warn(warn);
				MyCache.getInstance().addUncheckedStateUpdateWarning(cfg.hashCode(), warn);
			}
		}
	}
}
