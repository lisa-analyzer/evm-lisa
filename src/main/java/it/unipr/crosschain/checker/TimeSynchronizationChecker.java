package it.unipr.crosschain.checker;

import it.unipr.analysis.contract.SmartContract;
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
	private final SmartContract contract;

	public TimeSynchronizationChecker(SmartContract contract) {
		this.contract = contract;
	}

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
					if (TaintElement.isAtLeastOneTainted(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2))) {
						throwVulnerability(node, tool, cfg);
					} else if (TaintElement.isAtLeastOneTop(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2))) {
						throwPossibleVulnerability(node, tool, cfg);
					}
				}
			}
		}

		return true;
	}

	/**
	 * Identifies and reports a Time Synchronization vulnerability within a
	 * control flow graph (CFG). This method analyzes the reachability of
	 * certain statements and logs warnings if potential vulnerabilities are
	 * detected. The warnings are logged, stored in a cache, and reported to the
	 * provided analysis tool.
	 *
	 * @param jumpi The statement being analyzed for reachability and
	 *                  vulnerability. It represents a conditional jump in the
	 *                  control flow.
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

					String functionSignatureByStatement = contract.getFunctionSignatureByStatement(jumpi);
					// It means that this vulnerability is inside a private
					// function
					if (functionSignatureByStatement.equals("no-function-found"))
						continue;

					ProgramCounterLocation nodeLocation = (ProgramCounterLocation) jumpi.getLocation();

					log.warn(
							"[DEFINITE] Time Synchronization vulnerability at pc {} (line {}) (cfg={}), coming from pc {} (line {}) (cfg={})",
							nodeLocation.getPc(),
							nodeLocation.getSourceCodeLine(),
							cfg.hashCode(),
							((ProgramCounterLocation) logVulnerable.getLocation()).getPc(),
							((ProgramCounterLocation) logVulnerable.getLocation()).getSourceCodeLine(),
							logVulnerable.getCFG().hashCode());

					String warn = "[DEFINITE] Time Synchronization vulnerability at pc "
							+ ((ProgramCounterLocation) logVulnerable.getLocation()).getPc()
							+ " (cfg=" + logVulnerable.getCFG().hashCode() + ")";
					MyCache.getInstance().addTimeSynchronizationWarning(contract.getCFG().hashCode(), warn);
					tool.warn(warn);

					warn = "[DEFINITE] Time Synchronization vulnerability in " + contract.getName() + " at "
							+ functionSignatureByStatement;
					MyCache.getInstance().addOlli(cfg.hashCode(), warn);
				}
			}
		}
	}

	private void throwPossibleVulnerability(Statement jumpi, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg) {

		for (Statement externalData : cfg.getExternalData()) {
			if (cfg.reachableFrom(externalData, jumpi)) {
				for (Statement logVulnerable : MyCache.getInstance()
						.getKeysContainingValueInLinkFromLogToCallDataLoad(externalData)) {
					ProgramCounterLocation nodeLocation = (ProgramCounterLocation) jumpi.getLocation();

					log.warn(
							"[POSSIBLE] Time Synchronization vulnerability at pc {} (line {}) (cfg={}), coming from pc {} (line {}) (cfg={})",
							nodeLocation.getPc(),
							nodeLocation.getSourceCodeLine(),
							cfg.hashCode(),
							((ProgramCounterLocation) logVulnerable.getLocation()).getPc(),
							((ProgramCounterLocation) logVulnerable.getLocation()).getSourceCodeLine(),
							logVulnerable.getCFG().hashCode());

					String warn = "[POSSIBLE] Time Synchronization vulnerability at pc "
							+ ((ProgramCounterLocation) logVulnerable.getLocation()).getPc()
							+ " (cfg=" + logVulnerable.getCFG().hashCode() + ")";
					MyCache.getInstance().addPossibleTimeSynchronizationWarning(contract.getCFG().hashCode(), warn);
					tool.warn(warn);

//					warn = "[POSSIBLE] Time Synchronization vulnerability in " + contract.getName() + " at " + contract.getFunctionSignatureByStatement(jumpi);
//					MyCache.getInstance().addOlli(cfg.hashCode(), warn);
				}
			}
		}
	}
}