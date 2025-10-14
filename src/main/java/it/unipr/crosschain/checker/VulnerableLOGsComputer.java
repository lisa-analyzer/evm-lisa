package it.unipr.crosschain.checker;

import it.unipr.analysis.contract.Signature;
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

public class VulnerableLOGsComputer implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(VulnerableLOGsComputer.class);
	private Set<Statement> eventsExitpoints;

	public VulnerableLOGsComputer(Set<Signature> events) {
		this.eventsExitpoints = new HashSet<>();
		for (Signature event : events)
			eventsExitpoints.addAll(event.getExitPoints());
	}

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		if (eventsExitpoints.contains(node)) {
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

				if (taintedStack.isBottom() || taintedStack.isTop())
					// Nothing to do
					continue;

				int numArgs = getNumberOfArgs(node);
				boolean isAtLeastOneTainted = false;

				for (int argIndex = 1; argIndex <= numArgs; argIndex++)
					isAtLeastOneTainted |= TaintElement.isAtLeastOneTainted(
							taintedStack.getElementAtPosition(argIndex));

				if (isAtLeastOneTainted)
					addVulnerableLOG(node);
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

	/**
	 * Adds a vulnerable log statement to the time synchronization checker and
	 * logs a warning message indicating the potential vulnerability.
	 *
	 * @param node the statement node considered potentially vulnerable and to
	 *                 be added for time synchronization checking
	 */
	private void addVulnerableLOG(Statement node) {
		MyCache.getInstance().addVulnerableLogStatementForLocalDependencyChecker(node);

		ProgramCounterLocation nodeLocation = (ProgramCounterLocation) node.getLocation();
		log.warn("(Local Dependency Checker) Event possibly vulnerable at pc {} (line {}) (cfg={}).",
				nodeLocation.getPc(),
				nodeLocation.getSourceCodeLine(),
				node.getCFG().hashCode());
	}
}