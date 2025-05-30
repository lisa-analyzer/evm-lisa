package it.unipr.checker;

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
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class RandomnessDependencyChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(RandomnessDependencyChecker.class);

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

		EVMCFG cfg = ((EVMCFG) graph);

		if (node instanceof Jump || node instanceof Jumpi || node instanceof Sstore
				|| node instanceof Sha3 || node instanceof Return)
			for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
					TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
				AnalysisState<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
						TypeEnvironment<InferredTypes>>> analysisResult = null;

				try {
					analysisResult = result.getAnalysisStateBefore(node);
				} catch (SemanticException e1) {
					log.error("(RandomnessDependencyChecker): {}", e1.getMessage());
				}

				// Retrieve the symbolic stack from the analysis result
				TaintAbstractDomain taintedStack = analysisResult.getState().getValueState();

				// If the stack is bottom, the jump is definitely
				// unreachable
				if (taintedStack.isBottom())
					// Nothing to do
					continue;
				else {
					if (node instanceof Sha3
							|| node instanceof Sstore
							|| node instanceof Jumpi
							|| node instanceof Return) {

						if (TaintElement.isAtLeastOneTainted(taintedStack.getElementAtPosition(1),
								taintedStack.getElementAtPosition(2)))
							raiseWarning(node, tool, cfg);
						else if (TaintElement.isAtLeastOneTop(taintedStack.getElementAtPosition(1),
								taintedStack.getElementAtPosition(2)))
							raisePossibleWarning(node, tool, cfg);

					} else if (node instanceof Jump) {

						if (TaintElement.isAtLeastOneTainted(taintedStack.getElementAtPosition(1)))
							raiseWarning(node, tool, cfg);
						else if (TaintElement.isAtLeastOneTop(taintedStack.getElementAtPosition(1)))
							raisePossibleWarning(node, tool, cfg);

					}
				}
			}

		return true;
	}

	/**
	 * Raises a warning indicating a randomness dependency vulnerability in the
	 * analyzed program.
	 *
	 * @param sink the statement causing the warning
	 * @param tool the analysis tool and results used for the check
	 * @param cfg  the control flow graph where the warning is identified
	 */
	private void raiseWarning(Statement sink, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg) {
		ProgramCounterLocation sinkLoc = (ProgramCounterLocation) sink.getLocation();

		log.warn("[DEFINITE] Randomness dependency vulnerability at pc {} (line {}).",
				sinkLoc.getPc(),
				sinkLoc.getSourceCodeLine());

		String warn = "[DEFINITE] Randomness dependency vulnerability at pc "
				+ ((ProgramCounterLocation) sink.getLocation()).getSourceCodeLine();
		tool.warn(warn);
		MyCache.getInstance().addRandomnessDependencyWarning(cfg.hashCode(), warn);
	}

	/**
	 * Logs a possible randomness dependency vulnerability warning and updates
	 * the tool and cache with the detected issue.
	 *
	 * @param sink the statement where the potential vulnerability is detected
	 * @param tool the analysis tool containing the current state and analysis
	 *                 results
	 * @param cfg  the control flow graph associated with the statement
	 */
	private void raisePossibleWarning(Statement sink, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg) {
		ProgramCounterLocation sinkLoc = (ProgramCounterLocation) sink.getLocation();

		log.warn("[POSSIBLE] Randomness dependency vulnerability at pc {} (line {}).",
				sinkLoc.getPc(),
				sinkLoc.getSourceCodeLine());

		String warn = "[POSSIBLE] Randomness dependency vulnerability at pc "
				+ ((ProgramCounterLocation) sink.getLocation()).getSourceCodeLine();
		tool.warn(warn);
		MyCache.getInstance().addPossibleRandomnessDependencyWarning(cfg.hashCode(), warn);
	}
}
