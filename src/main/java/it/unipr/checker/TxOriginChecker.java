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
				TaintAbstractDomain taintedStack = analysisResult.getState().getValueState();

				// If the stack is bottom, the node is definitely
				// unreachable
				if (taintedStack.isBottom())
					// Nothing to do
					continue;
				else {
					if (taintedStack.getElementAtPosition(1).isBottom()
							|| taintedStack.getElementAtPosition(2).isBottom())
						// Nothing to do
						continue;
					else {
						if (TaintElement.isAtLeastOneTainted(taintedStack.getElementAtPosition(1),
								taintedStack.getElementAtPosition(2)))
							raiseWarning(node, tool, cfg);
						else if (TaintElement.isAtLeastOneTop(taintedStack.getElementAtPosition(1),
								taintedStack.getElementAtPosition(2)))
							raisePossibleWarning(node, tool, cfg);
					}
				}
			}
		}

		return true;
	}

	private void raiseWarning(Statement node, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg) {

		ProgramCounterLocation nodeLocation = (ProgramCounterLocation) node.getLocation();

		log.warn("Tx. Origin attack at pc {} (line {}).", nodeLocation.getPc(),
				nodeLocation.getSourceCodeLine());

		String warn = "TxOrigin attack at "
				+ ((ProgramCounterLocation) node.getLocation()).getSourceCodeLine();
		tool.warn(warn);
		MyCache.getInstance().addTxOriginWarning(cfg.hashCode(), warn);
	}

	private void raisePossibleWarning(Statement node, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg) {

		ProgramCounterLocation nodeLocation = (ProgramCounterLocation) node.getLocation();

		log.warn("Tx. Origin attack (possible) at pc {} (line {}).", nodeLocation.getPc(),
				nodeLocation.getSourceCodeLine());

		String warn = "TxOrigin attack (possible) at "
				+ ((ProgramCounterLocation) node.getLocation()).getSourceCodeLine();
		tool.warn(warn);
		MyCache.getInstance().addPossibleTxOriginWarning(cfg.hashCode(), warn);
	}
}