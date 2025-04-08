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
import java.util.HashSet;
import java.util.Set;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * This checker detects cases where a smart contract updates its state based on
 * external inputs without proper validation. In particular, it tracks tainted
 * values derived from external sources (e.g., CALLDATALOAD, CALLDATACOPY) and
 * monitors if these unvalidated values influence state modifications (via
 * SSTORE) or are passed to event emission functions. Analysis process:
 * <ul>
 * <li>Identifies JUMPI nodes where tainted values (from external inputs) are
 * present.</li>
 * <li>For each state update (e.g., SSTORE), it checks whether the tainted
 * values have been propagated without a proper validation step (such as a
 * conditional jump via JUMPI).</li>
 * <li>Raises a definite violation if the tainted value is confirmed, or a
 * possible violation if the value remains ambiguous (e.g., marked as TOP).</li>
 * </ul>
 *
 * @see TaintAbstractDomain
 */
public class UncheckedExternalInfluenceChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(UncheckedExternalInfluenceChecker.class);

	private Set<Statement> taintedJumpi = new HashSet<>();
	private SmartContract contract;

	public UncheckedExternalInfluenceChecker(SmartContract contract) {
		this.contract = contract;
	}

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

	/**
	 * Visits a given log node in the CFG and determines whether it is affected
	 * by an unchecked external influence
	 *
	 * @param tool  the analysis tool providing semantic check results
	 * @param graph the control-flow graph (CFG) of the smart contract
	 * @param node  the node to analyze
	 * 
	 * @return always returns true after processing the node
	 */
	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		if (node instanceof Sstore) {
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
						checkForUncheckedExternalInfluence(node, tool, cfg);
					} else if (TaintElement.isAtLeastOneTop(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2))) {
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

				String functionSignatureByStatement = contract.getFunctionSignatureByStatement(data);
				// It means that this vulnerability is inside a private function
				if (functionSignatureByStatement.equals("no-function-found"))
					continue;

				ProgramCounterLocation sstoreLocation = (ProgramCounterLocation) sstore.getLocation();

				log.warn(
						"[DEFINITE] Unchecked External Influence vulnerability at pc {}  (line {}) coming from pc {} (line {}).",
						sstoreLocation.getPc(),
						sstoreLocation.getSourceCodeLine(),
						((ProgramCounterLocation) data.getLocation()).getPc(),
						((ProgramCounterLocation) data.getLocation()).getSourceCodeLine());

				String warn = "[DEFINITE] Unchecked External Influence vulnerability at "
						+ ((ProgramCounterLocation) data.getLocation()).getSourceCodeLine();
				tool.warn(warn);
				MyCache.getInstance().addUncheckedExternalInfluenceWarning(cfg.hashCode(), warn);

				warn = "[DEFINITE] Unchecked External Influence vulnerability in " + contract.getName() + " at " + functionSignatureByStatement;
				MyCache.getInstance().addOlli(cfg.hashCode(), warn);
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
						"[POSSIBLE] Unchecked External Influence vulnerability at pc {} (line {}) coming from pc {} (line {}).",
						sstoreLocation.getPc(),
						sstoreLocation.getSourceCodeLine(),
						((ProgramCounterLocation) data.getLocation()).getPc(),
						((ProgramCounterLocation) data.getLocation()).getSourceCodeLine());

				String warn = "[POSSIBLE] Unchecked External Influence vulnerability at "
						+ ((ProgramCounterLocation) data.getLocation()).getSourceCodeLine();
				tool.warn(warn);
				MyCache.getInstance().addPossibleUncheckedExternalInfluenceWarning(cfg.hashCode(), warn);

//				warn = "[POSSIBLE] Unchecked External Influence vulnerability in " + contract.getName() + " at " + contract.getFunctionSignatureByStatement(data);
//				MyCache.getInstance().addOlli(cfg.hashCode(), warn);
			}
		}
	}
}