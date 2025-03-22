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

public class TimeSynchronizationChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(TimeSynchronizationChecker.class);

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		if (node instanceof Jumpi) {

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

				if (taintedStack.isBottom())
					// Nothing to do
					continue;
				else {
					if (isTaintedOrTop(taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2)))
						throwVulnerability(node, tool, cfg);
				}
			}
		}

		return true;
	}

	/**
	 * Checks whether any of the provided {@link TaintElement} instances is
	 * either tainted or at the top of the lattice hierarchy.
	 *
	 * @param elements an array of {@link TaintElement} instances to check
	 * 
	 * @return {@code true} if at least one element in the input array is
	 *             tainted or top, {@code false} otherwise
	 */
	private boolean isTaintedOrTop(TaintElement... elements) {
		for (TaintElement element : elements) {
			if (element.isTaint() || element.isTop())
				return true;
		}
		return false;
	}

	/**
	 * Identifies and reports a Time Synchronization vulnerability within a
	 * control flow graph (CFG). This method analyzes the reachability of
	 * certain statements and logs warnings if potential vulnerabilities are
	 * detected. The warnings are logged, stored in a cache, and reported to the
	 * provided analysis tool.
	 *
	 * @param jumpi The statement being analyzed for reachability and
	 *                  vulnerability. Typically represents a conditional jump
	 *                  in the control flow.
	 * @param tool  The analysis tool containing results of the analysis and
	 *                  methods for reporting warnings about identified
	 *                  vulnerabilities.
	 * @param cfg   The control flow graph representing the structure of the
	 *                  program being analyzed. Used to derive external data and
	 *                  verify reachability between statements.
	 */
	private void throwVulnerability(Statement jumpi, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg) {

		for (Statement externalData : cfg.getExternalData()) {
			if (cfg.reachableFrom(externalData, jumpi)) {
				for (Statement logVulnerable : MyCache.getInstance()
						.getKeysContainingValueInLinkFromLogToCallDataLoad(externalData)) {
					ProgramCounterLocation nodeLocation = (ProgramCounterLocation) jumpi.getLocation();

					log.warn(
							"Time Synchronization vulnerability at pc {} (line {}) (cfg={}), coming from pc {} (cfg={})",
							nodeLocation.getPc(),
							nodeLocation.getSourceCodeLine(),
							cfg.hashCode(),
							((ProgramCounterLocation) logVulnerable.getLocation()).getSourceCodeLine(),
							logVulnerable.getCFG().hashCode());

					String warn = "Time Synchronization vulnerability at pc "
							+ ((ProgramCounterLocation) logVulnerable.getLocation()).getSourceCodeLine()
							+ " (cfg=" + logVulnerable.getCFG().hashCode() + ")";
					MyCache.getInstance().addTimeSynchronizationWarning(warn);
					tool.warn(warn);
				}
			}
		}
	}
}