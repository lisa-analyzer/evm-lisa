package it.unipr.crosschain.checker;

import it.unipr.analysis.contract.Signature;
import it.unipr.analysis.contract.SmartContract;
import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.*;
import it.unipr.utils.CustomPolicy;
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

public class LocalDependencyChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(LocalDependencyChecker.class);

	private final SmartContract contract;
	private final CustomPolicy policy;

	/**
	 * Builds the checker for the given contract.
	 *
	 * @param contract the contract under analysis
	 */
	public LocalDependencyChecker(SmartContract contract, CustomPolicy policy) {
		this.contract = contract;
		this.policy = policy;
	}

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
					log.error("(LocalDependencyChecker): {}", e1.getMessage());
				}

				// Retrieve the symbolic stack from the analysis result
				TaintAbstractDomain taintedStack = analysisResult.getState().getValueState();

				if (taintedStack.isBottom() || taintedStack.isTop())
					// Nothing to do
					continue;

				int numArgs = getNumberOfArgs(node);
				boolean isAtLeastOneTainted = false;
				boolean isAtLeastOneTop = false;

				for (int argIndex = 1; argIndex <= numArgs; argIndex++) {
					isAtLeastOneTainted |= TaintElement.isAtLeastOneTainted(
							taintedStack.getElementAtPosition(argIndex));
					isAtLeastOneTop |= TaintElement.isAtLeastOneTop(
							taintedStack.getElementAtPosition(argIndex));
				}

				if (isAtLeastOneTainted)
					checkForLocalDependency(tool, node, false);
				else if (isAtLeastOneTop)
					checkForLocalDependency(tool, node, true);
			}
		}

		return true;
	}

	/**
	 * Computes the number of arguments consumed from the stack by the provided
	 * EVM instruction.
	 *
	 * @param node the statement to inspect
	 *
	 * @return the amount of stack elements consumed by {@code node}
	 */
	private int getNumberOfArgs(Statement node) {
		if (node instanceof Log1)
			return 3;
		if (node instanceof Log2)
			return 4;
		if (node instanceof Log3)
			return 5;
		if (node instanceof Log4)
			return 6;
		return 0;
	}

	private void checkForLocalDependency(CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			Statement sink, boolean isTop) {
		for (Signature events : contract.getEventsSignature()) {
			for (String eventsName : policy.getKnownEvents()) {

				if (!eventsName.equalsIgnoreCase(events.getName()))
					continue;

				for (Statement eventExitpoint : events.getExitPoints()) {
					if (sink.equals(eventExitpoint)) {
						ProgramCounterLocation sinkLocation = (ProgramCounterLocation) sink.getLocation();
						if (!isTop) {
							log.warn(
									"[DEFINITE] Local Dependency warning at pc {} (line {})",
									sinkLocation.getPc(),
									sinkLocation.getSourceCodeLine());

							String warn = "[DEFINITE] Local Dependency warning at pc "
									+ sinkLocation.getPc();
							tool.warn(warn);
							MyCache.getInstance().addLocalDependencyWarning(contract.getCFG().hashCode(), warn);
						} else {
							log.warn(
									"[POSSIBLE] Local Dependency warning at pc {} (line {})",
									sinkLocation.getPc(),
									sinkLocation.getSourceCodeLine());

							String warn = "[POSSIBLE] Local Dependency warning at pc "
									+ sinkLocation.getPc();
							tool.warn(warn);
							MyCache.getInstance().addLocalDependencyWarning(contract.getCFG().hashCode(), warn);
						}
					}
				}
			}
		}
	}

}
