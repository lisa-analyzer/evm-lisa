package it.unipr.checker;

import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Jumpi;
import it.unipr.cfg.ProgramCounterLocation;
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
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class TxOriginChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(TxOriginChecker.class);

	private static boolean isEnabled = false;

	public static void enableChecker() {
		isEnabled = true;
	}

	public static void disableChecker() {
		isEnabled = false;
	}

	public static boolean isEnabled() {
		return isEnabled;
	}

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		if (node instanceof Jumpi) {
			EVMCFG cfg = (EVMCFG) graph;

			for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
					TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
				AnalysisState<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
						TypeEnvironment<InferredTypes>>> analysisResult = null;

				try {
					analysisResult = result.getAnalysisStateBefore(node);
				} catch (SemanticException e1) {
					log.error("(TxOriginChecker): {}", e1.getMessage());
				}

				// Retrieve the symbolic stack from the analysis result
				TaintAbstractDomain stack = analysisResult.getState().getValueState();

				// If the stack is bottom, the node is definitely
				// unreachable
				if (stack.isBottom())
					// Nothing to do
					continue;
				else {
					TaintElement firstElem = stack.getFirstElement();
					TaintElement secondElem = stack.getSecondElement();
					if (firstElem.isBottom() || secondElem.isBottom())
						// Nothing to do
						continue;
					else {
						// Checks if either first or second element in the
						// stack is tainted
						if (firstElem.isTaint() || secondElem.isTaint()) {
							ProgramCounterLocation jumploc = (ProgramCounterLocation) node.getLocation();

							log.warn("Tx. Origin attack at {} at line no. {}", jumploc.getPc(),
									jumploc.getSourceCodeLine());

							String warn = "TxOrigin attack at "
									+ ((ProgramCounterLocation) node.getLocation()).getSourceCodeLine();
							tool.warn(warn);
							MyCache.getInstance().addTxOriginWarning(cfg.hashCode(), warn);
						}
					}
				}
			}
		}

		return true;
	}
}