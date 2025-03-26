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
 * This checker detects instances where a smart contract updates its state based
 * on external inputs (such as msg.sender or function parameters) without proper
 * validation.
 * <p>
 * <b>Analysis Method:</b>
 * </p>
 * <ul>
 * <li>Uses <b>Taint Analysis</b> similar to the EventOrderChecker case 2.</li>
 * <li><b>Sources:</b> msg.sender, function parameters.</li>
 * <li><b>Sink:</b> SSTORE.</li>
 * <li>If a tainted value reaches an SSTORE without passing through a control
 * JUMPI, the contract is vulnerable.</li>
 * </ul>
 * <p>
 * <b>Detection Logic:</b>
 * </p>
 * <ul>
 * <li>Iterates over the program's statements and identifies SSTORE
 * operations.</li>
 * <li>Retrieves the symbolic execution stack to check if the stored value is
 * tainted.</li>
 * <li>If tainted, verifies whether it was properly validated via a conditional
 * JUMPI before reaching SSTORE.</li>
 * <li>If no validation is detected, logs the vulnerability and adds it to the
 * cache.</li>
 * </ul>
 * <p>
 * <b>Potential Security Issue:</b>
 * </p>
 * <ul>
 * <li>Contracts that fail to verify external input sources before modifying
 * their state are susceptible to malicious manipulation.</li>
 * </ul>
 */
public class UncheckedExternalInfluenceChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(UncheckedExternalInfluenceChecker.class);

	private Set<Statement> taintedJumpi = new HashSet<>();

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		if (node instanceof Sstore || node instanceof Jumpi) {
			EVMCFG cfg = ((EVMCFG) graph);

			for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
					TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
				AnalysisState<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
						TypeEnvironment<InferredTypes>>> analysisResult = null;

				try {
					analysisResult = result.getAnalysisStateBefore(node);
				} catch (SemanticException e1) {
					log.error("(UncheckedExternalInfluenceChecker): {}", e1.getMessage());
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

						if (node instanceof Jumpi) {
							taintedJumpi.add(node);
							return true;
						}
						checkForUncheckedExternalInfluence(node, tool, cfg);

					} else if (TaintElement.isAtLeastOneTop(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2))) {

						if (node instanceof Jumpi) {
							taintedJumpi.add(node);
							return true;
						}
						checkForPossibleUncheckedExternalInfluence(node, tool, cfg);
					}

				}
			}
		}

		return true;
	}

	/**
	 * Performs the actual vulnerability check by analyzing whether tainted data
	 * from external sources reaches an SSTORE without passing through a JUMPI
	 * validation. If such a case is detected, logs a warning and adds it to the
	 * cache.
	 *
	 * @param sstore The SSTORE instruction being analyzed.
	 * @param tool   The analysis tool containing the program's state.
	 * @param cfg    The EVM control flow graph of the smart contract.
	 */
	private void checkForUncheckedExternalInfluence(Statement sstore, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg) {

		Set<Statement> externalDatas = cfg.getExternalData();

		for (Statement data : externalDatas) {
			if (cfg.reachableFromWithoutStatements(data, sstore, taintedJumpi)) {

				ProgramCounterLocation sstoreLocation = (ProgramCounterLocation) sstore.getLocation();

				log.warn("Unchecked External Influence vulnerability at pc {}  (line {}) coming from line {}.",
						sstoreLocation.getPc(),
						sstoreLocation.getSourceCodeLine(),
						((ProgramCounterLocation) data.getLocation()).getSourceCodeLine());

				String warn = "Unchecked External Influence vulnerability at "
						+ ((ProgramCounterLocation) data.getLocation()).getSourceCodeLine();
				tool.warn(warn);
				MyCache.getInstance().addUncheckedExternalInfluenceWarning(cfg.hashCode(), warn);
			}
		}
	}

	private void checkForPossibleUncheckedExternalInfluence(Statement sstore, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg) {

		Set<Statement> externalDatas = cfg.getExternalData();

		for (Statement data : externalDatas) {
			if (cfg.reachableFromWithoutStatements(data, sstore, taintedJumpi)) {

				ProgramCounterLocation sstoreLocation = (ProgramCounterLocation) sstore.getLocation();

				log.warn(
						"Unchecked External Influence vulnerability (possible) at pc {} (line {}) coming from line {}.",
						sstoreLocation.getPc(),
						sstoreLocation.getSourceCodeLine(),
						((ProgramCounterLocation) data.getLocation()).getSourceCodeLine());

				String warn = "Unchecked External Influence vulnerability (possible) at "
						+ ((ProgramCounterLocation) data.getLocation()).getSourceCodeLine();
				tool.warn(warn);
				MyCache.getInstance().addPossibleUncheckedExternalInfluenceWarning(cfg.hashCode(), warn);
			}
		}
	}
}