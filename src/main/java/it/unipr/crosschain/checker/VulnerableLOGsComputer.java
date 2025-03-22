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

public class VulnerableLOGsComputer implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(VulnerableLOGsComputer.class);

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		if (node instanceof Log
				|| node instanceof Calldataload) {

			EVMCFG cfg = ((EVMCFG) graph);

			for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
					TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
				AnalysisState<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
						TypeEnvironment<InferredTypes>>> analysisResult = null;

				try {
					analysisResult = result.getAnalysisStateBefore(node);
				} catch (SemanticException e1) {
					log.error("(VulnerableLOGsComputer): {}", e1.getMessage());
				}

				// Retrieve the symbolic stack from the analysis result
				TaintAbstractDomain taintedStack = analysisResult.getState().getValueState();

				if (taintedStack.isBottom())
					// Nothing to do
					continue;
				else {
					if (node instanceof Log0)
						if (isTaintedOrTop(taintedStack.getElementAtPosition(1),
								taintedStack.getElementAtPosition(2)))
							addVulnerableLOG(node);
					if (node instanceof Log1)
						if (isTaintedOrTop(taintedStack.getElementAtPosition(1),
								taintedStack.getElementAtPosition(2),
								taintedStack.getElementAtPosition(3)))
							addVulnerableLOG(node);
					if (node instanceof Log2)
						if (isTaintedOrTop(taintedStack.getElementAtPosition(1),
								taintedStack.getElementAtPosition(2),
								taintedStack.getElementAtPosition(3),
								taintedStack.getElementAtPosition(4)))
							addVulnerableLOG(node);
					if (node instanceof Log3)
						if (isTaintedOrTop(taintedStack.getElementAtPosition(1),
								taintedStack.getElementAtPosition(2),
								taintedStack.getElementAtPosition(3),
								taintedStack.getElementAtPosition(4),
								taintedStack.getElementAtPosition(5)))
							addVulnerableLOG(node);
					if (node instanceof Log4)
						if (isTaintedOrTop(taintedStack.getElementAtPosition(1),
								taintedStack.getElementAtPosition(2),
								taintedStack.getElementAtPosition(3),
								taintedStack.getElementAtPosition(4),
								taintedStack.getElementAtPosition(5),
								taintedStack.getElementAtPosition(6)))
							addVulnerableLOG(node);
				}
			}
		}

		return true;
	}

	/**
	 * Checks whether any of the provided {@link TaintElement} instances is
	 * either in the "taint" state or the "top" state.
	 *
	 * @param elements the array of {@link TaintElement} instances to be checked
	 * 
	 * @return true if at least one of the provided {@link TaintElement}
	 *             instances is either tainted or top, false otherwise
	 */
	private boolean isTaintedOrTop(TaintElement... elements) {
		for (TaintElement element : elements) {
			if (element.isTaint() || element.isTop())
				return true;
		}
		return false;
	}

	/**
	 * Adds a vulnerable log statement to the time synchronization checker and
	 * logs a warning message indicating the potential vulnerability.
	 *
	 * @param node the statement node considered potentially vulnerable and to
	 *                 be added for time synchronization checking
	 */
	private void addVulnerableLOG(Statement node) {
		MyCache.getInstance().addVulnerableLogStatementForTimeSynchronizationChecker(node);

		ProgramCounterLocation nodeLocation = (ProgramCounterLocation) node.getLocation();
		log.warn("(Time Synchronization vulnerability) LOG possibly vulnerable at pc {} at line {}.",
				nodeLocation.getPc(), nodeLocation.getSourceCodeLine());
	}
}