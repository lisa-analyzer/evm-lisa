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
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * The TimeSynchronizationChecker class implements a semantic check that
 * analyzes the control flow graph (CFG) of a program and identifies potential
 * time synchronization vulnerabilities. This checker inspects log-based
 * statements within the program's CFG and evaluates the taint analysis results,
 * such as the symbolic stack entries, to detect risky operations involving
 * tainted data. When a vulnerability is detected, it logs warnings regarding
 * the specific program counter and source code location where the issue is
 * found.
 */
public class TimeSynchronizationChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(TimeSynchronizationChecker.class);

	/**
	 * Visits a specific statement in the control flow graph (CFG) and performs
	 * an analysis to detect possible issues related to time synchronization by
	 * evaluating the taint status of the symbolic stack.
	 *
	 * @param tool  the analysis tool containing results for abstract states and
	 *                  analysis computations
	 * @param graph the control flow graph (CFG) where the statement belongs
	 * @param node  the specific statement node to be analyzed
	 * 
	 * @return true if the statement is successfully visited and analyzed
	 */
	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		if (node instanceof Log) {
			EVMCFG cfg = ((EVMCFG) graph);

			for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
					TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
				AnalysisState<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
						TypeEnvironment<InferredTypes>>> analysisResult = null;

				try {
					analysisResult = result.getAnalysisStateBefore(node);
				} catch (SemanticException e1) {
					log.error("(TimeSynchronizationChecker): {}", e1.getMessage());
				}

				// Retrieve the symbolic stack from the analysis result
				TaintAbstractDomain taintedStack = analysisResult.getState().getValueState();

//				ProgramCounterLocation nodeLocation = (ProgramCounterLocation) node.getLocation();
//				log.debug("[{}] {} at pc {}, line {}", cfg.hashCode(), node, nodeLocation.getPc(),
//						nodeLocation.getSourceCodeLine());
//				log.debug("Tainted stack: {}", taintedStack.toString());

				if (taintedStack.isBottom())
					// Nothing to do
					continue;
				else {
					if (node instanceof Log0)
						if (isTaintedOrTop(taintedStack.getElementAtPosition(1),
								taintedStack.getElementAtPosition(2)))
							checkForTimeSynchronization(node, tool, cfg);
					if (node instanceof Log1)
						if (isTaintedOrTop(taintedStack.getElementAtPosition(1),
								taintedStack.getElementAtPosition(2),
								taintedStack.getElementAtPosition(3)))
							checkForTimeSynchronization(node, tool, cfg);
					if (node instanceof Log2)
						if (isTaintedOrTop(taintedStack.getElementAtPosition(1),
								taintedStack.getElementAtPosition(2),
								taintedStack.getElementAtPosition(3),
								taintedStack.getElementAtPosition(4)))
							checkForTimeSynchronization(node, tool, cfg);
					if (node instanceof Log3)
						if (isTaintedOrTop(taintedStack.getElementAtPosition(1),
								taintedStack.getElementAtPosition(2),
								taintedStack.getElementAtPosition(3),
								taintedStack.getElementAtPosition(4),
								taintedStack.getElementAtPosition(5)))
							checkForTimeSynchronization(node, tool, cfg);
					if (node instanceof Log4)
						if (isTaintedOrTop(taintedStack.getElementAtPosition(1),
								taintedStack.getElementAtPosition(2),
								taintedStack.getElementAtPosition(3),
								taintedStack.getElementAtPosition(4),
								taintedStack.getElementAtPosition(5),
								taintedStack.getElementAtPosition(6)))
							checkForTimeSynchronization(node, tool, cfg);
				}
			}
		}

		return true;
	}

	/**
	 * Checks whether any of the provided {@link TaintElement} instances is either in
	 * the "taint" state or the "top" state.
	 *
	 * @param elements the array of {@link TaintElement} instances to be checked
	 * @return true if at least one of the provided {@link TaintElement} instances
	 *         is either tainted or top, false otherwise
	 */
	private boolean isTaintedOrTop(TaintElement... elements) {
		for (TaintElement element : elements) {
			if (element.isTaint() || element.isTop())
				return true;
		}
		return false;
	}

	private void checkForTimeSynchronization(Statement node, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg) {

		ProgramCounterLocation nodeLocation = (ProgramCounterLocation) node.getLocation();

		String warn = "Time Synchronization vulnerability at pc " + nodeLocation.getPc() + " at line "
				+ nodeLocation.getSourceCodeLine();
		MyCache.getInstance().addTimeSynchronizationWarning(cfg.hashCode(), warn);
		log.warn(warn);
		tool.warn(warn);
	}
}