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
import java.util.HashSet;
import java.util.Set;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * This checker identifies instances where a smart contract updates its state
 * based on values obtained from external calls (e.g., CALL, DELEGATECALL,
 * STATICCALL) without proper validation. Analysis process:
 * <ul>
 * <li>Monitors SSTORE instructions and retrieves the symbolic stack preceding
 * them to detect whether external inputs have tainted critical stack
 * positions.</li>
 * <li>Checks if the relevant stack elements are tainted or remain at a TOP
 * value, which may indicate an unchecked state update.</li>
 * <li>If a tainted value is detected, the checker verifies reachability from
 * external calls to the SSTORE, and raises a definite or possible vulnerability
 * warning accordingly.</li>
 * </ul>
 *
 * @see TaintAbstractDomain
 */
public class UncheckedStateUpdateChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(UncheckedStateUpdateChecker.class);

	private Set<Statement> taintedJumpi = new HashSet<>();

	/**
	 * Visits all nodes in the CFG and records any JUMPI nodes that have tainted
	 * stack values.
	 *
	 * @param tool  the analysis tool providing semantic check results
	 * @param graph the control-flow graph (CFG) of the smart contract
	 *
	 * @return always returns true after processing all nodes
	 */
	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			CFG graph) {

		EVMCFG cfg = ((EVMCFG) graph);

		for (Statement node : cfg.getNodes())
			if (node instanceof Jumpi)
				for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
						TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {

					AnalysisState<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
							TypeEnvironment<InferredTypes>>> analysisResult = null;

					try {
						analysisResult = result.getAnalysisStateBefore(node);
					} catch (SemanticException e1) {
						log.error("(SemanticIntegrityViolationChecker): {}", e1.getMessage());
					}

					TaintAbstractDomain taintedStack = analysisResult.getState().getValueState();

					if (taintedStack.isBottom())
						// Nothing to do
						continue;

					if (TaintElement.isAtLeastOneTainted(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2)))
						taintedJumpi.add(node);
				}
		return true;
	}

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
					if (TaintElement.isAtLeastOneTainted(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2))) {
						checkForUncheckedStateUpdate(sstore, tool, cfg);
					} else if (TaintElement.isAtLeastOneTop(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2))) {
						checkForPossibleUncheckedStateUpdate(sstore, tool, cfg);
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
			if (cfg.reachableFromWithoutStatements(call, sstore, taintedJumpi)) {

				ProgramCounterLocation sstoreLocation = (ProgramCounterLocation) sstore.getLocation();

				log.warn(
						"[DEFINITE] Unchecked State Update vulnerability at pc {} (line {}) coming from pc {} (line {}).",
						sstoreLocation.getPc(),
						sstoreLocation.getSourceCodeLine(),
						((ProgramCounterLocation) call.getLocation()).getPc(),
						((ProgramCounterLocation) call.getLocation()).getSourceCodeLine());

				String warn = "[DEFINITE] Unchecked State Update vulnerability at "
						+ ((ProgramCounterLocation) call.getLocation()).getSourceCodeLine();
				tool.warn(warn);
				MyCache.getInstance().addUncheckedStateUpdateWarning(cfg.hashCode(), warn);
			}
		}
	}

	private void checkForPossibleUncheckedStateUpdate(Statement sstore, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg) {

		Set<Statement> calls = cfg.getAllCall();

		for (Statement call : calls) {
			if (cfg.reachableFromWithoutStatements(call, sstore, taintedJumpi)) {

				ProgramCounterLocation sstoreLocation = (ProgramCounterLocation) sstore.getLocation();

				log.warn(
						"[POSSIBLE] Unchecked State Update vulnerability at pc {} (line {}) coming from pc {} (line {}).",
						sstoreLocation.getPc(),
						sstoreLocation.getSourceCodeLine(),
						((ProgramCounterLocation) call.getLocation()).getPc(),
						((ProgramCounterLocation) call.getLocation()).getSourceCodeLine());

				String warn = "[POSSIBLE] Unchecked State Update vulnerability at "
						+ ((ProgramCounterLocation) call.getLocation()).getSourceCodeLine();
				tool.warn(warn);
				MyCache.getInstance().addPossibleUncheckedStateUpdateWarning(cfg.hashCode(), warn);
			}
		}
	}
}
