package it.unipr.crosschain.checker;

import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.ProgramCounterLocation;
import it.unipr.cfg.Sstore;
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
import java.util.Set;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * This checker detects cases where a contract updates its state using values
 * returned from external calls (CALL, DELEGATECALL, STATICCALL) without proper
 * validation.
 * <p>
 * <b>Purpose:</b>
 * </p>
 * <ul>
 * <li>Identifies operations where state updates (SSTORE) are influenced by
 * external contract calls.</li>
 * <li>Ensures that state updates do not depend on unverified external
 * data.</li>
 * <li>Prevents potential security vulnerabilities due to unchecked state
 * modifications.</li>
 * </ul>
 * <p>
 * <b>Analysis Process:</b>
 * </p>
 * <ul>
 * <li>Uses taint analysis to track the propagation of values from external
 * calls.</li>
 * <li>Marks CALL, DELEGATECALL, and STATICCALL as taint sources.</li>
 * <li>Marks SSTORE as a sink where state is modified.</li>
 * <li>If a tainted value reaches SSTORE without encountering a validation step
 * (JUMPI), the contract is vulnerable.</li>
 * </ul>
 *
 * @see UncheckedStateUpdateAbstractDomain
 */
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
					TaintElement firstStackElement = taintedStack.getFirstElement();
					TaintElement secondStackElement = taintedStack.getSecondElement();
					if (secondStackElement.isBottom())
						// Nothing to do
						continue;
					else {
						// Checks if either first or second element in the
						// stack is tainted
						if (firstStackElement.isTaint() || secondStackElement.isTaint()) {
							checkForUncheckedStateUpdate(sstore, tool, cfg);
						}
					}
				}
			}
		}

		return true;
	}

	private void checkForUncheckedStateUpdate(Statement sstore, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg) {

		Set<Statement> jumps = cfg.getAllJumpI();
		Set<Statement> calls = cfg.getAllCall();

		for (Statement call : calls) {
			if (cfg.reachableFrom(call, sstore)) {
				if (!cfg.reachableFromCrossing(call, sstore, jumps)) {

					ProgramCounterLocation sstoreLocation = (ProgramCounterLocation) sstore.getLocation();

					log.warn("Unchecked State Update vulnerability at {} at line no. {} coming from line {}",
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
}
