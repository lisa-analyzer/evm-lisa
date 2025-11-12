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
 * Semantic checker that detects missing access control guards by combining a
 * taint analysis with control-flow reachability information. The checker looks
 * for sensitive sink instructions that can be reached from untrusted sources
 * without passing through any guarded conditional jumps.
 */
public class AccessControlIncompletenessChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(AccessControlIncompletenessChecker.class);

	private Set<Statement> taintedJumpi = new HashSet<>();
	private SmartContract contract;

	/**
	 * Builds the checker for the given contract.
	 *
	 * @param contract the contract under analysis
	 */
	public AccessControlIncompletenessChecker(SmartContract contract) {
		this.contract = contract;
	}

	/**
	 * Determines whether the given statement is sink.
	 *
	 * @param stmt the statement to check
	 *
	 * @return {@code true} if the statement is sink, {@code false} otherwise.
	 */
	public boolean isSink(Statement stmt) {
		return stmt instanceof Call
				|| stmt instanceof Callcode
				|| stmt instanceof Staticcall
				|| stmt instanceof Delegatecall
				|| stmt instanceof Sstore
				|| stmt instanceof Balance;
	}

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
						log.error("(AccessControlIncompletenessChecker): {}", e1.getMessage());
					}

					TaintAbstractDomain taintedStack = analysisResult.getState().getValueState();

					if (taintedStack.isBottom() || taintedStack.isTop())
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

		if (isSink(node)) {
			EVMCFG cfg = ((EVMCFG) graph);

			for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
					TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
				AnalysisState<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
						TypeEnvironment<InferredTypes>>> analysisResult = null;

				try {
					analysisResult = result.getAnalysisStateBefore(node);
				} catch (SemanticException e1) {
					log.error("(AccessControlIncompletenessChecker): {}", e1.getMessage());
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
					checkForAccessControlIncompleteness(tool, cfg, node, false);
				else if (isAtLeastOneTop)
					checkForAccessControlIncompleteness(tool, cfg, node, true);
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
		if (node instanceof Call || node instanceof Callcode)
			return 7;
		if (node instanceof Staticcall || node instanceof Delegatecall)
			return 6;
		if (node instanceof Sstore)
			return 2;
		if (node instanceof Balance)
			return 1;
		return 0;
	}

	/**
	 * Verifies whether a tainted source can reach an unguarded sink without
	 * being protected by a conditional jump and, if so, records the
	 * vulnerability.
	 *
	 * @param tool the analysis tool to report warnings on
	 * @param cfg  the CFG under inspection
	 * @param sink the sink statement that manipulates sensitive state
	 */
	private void checkForAccessControlIncompleteness(CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool, EVMCFG cfg,
			Statement sink, boolean isTop) {

		Set<Statement> sources = cfg.getAllStatementsByClass(
				Calldataload.class,
				Calldatacopy.class,
				Caller.class,
				Origin.class,
				Callvalue.class,
				Calldatasize.class);

		for (Statement source : sources) {
			if (cfg.reachableFromWithoutStatements(source, sink, taintedJumpi)) {
				String functionSignatureByStatement = contract.getFunctionSignatureByStatement(source);

				// It means that this vulnerability is inside a private function
				if (functionSignatureByStatement.equals("no-function-found"))
					continue;

				if (isTop) {
//					log.warn(
//							"[POSSIBLE] Access Control Incompleteness vulnerability at pc {} (line {}) coming from pc {} (line {}).",
//							((ProgramCounterLocation) sink.getLocation()).getPc(),
//							((ProgramCounterLocation) sink.getLocation()).getSourceCodeLine(),
//							((ProgramCounterLocation) source.getLocation()).getPc(),
//							((ProgramCounterLocation) source.getLocation()).getSourceCodeLine());

					String warn = "[POSSIBLE] Access Control Incompleteness vulnerability at "
							+ ((ProgramCounterLocation) sink.getLocation()).getSourceCodeLine();
					tool.warn(warn);
					MyCache.getInstance().addPossibleAccessControlIncompletenessWarning(cfg.hashCode(), warn);

//					warn = "[POSSIBLE] Access Control Incompleteness vulnerability in " + contract.getName() + " at "
//							+ functionSignatureByStatement
//							+ " (pc: " + ((ProgramCounterLocation) sink.getLocation()).getPc() + ", "
//							+ "line: " + ((ProgramCounterLocation) sink.getLocation()).getSourceCodeLine() + ")";
//					MyCache.getInstance().addVulnerabilityPerFunction(cfg.hashCode(), warn);
				} else {
					log.warn(
							"[DEFINITE] Access Control Incompleteness vulnerability at pc {} (line {}) coming from pc {} (line {}).",
							((ProgramCounterLocation) sink.getLocation()).getPc(),
							((ProgramCounterLocation) sink.getLocation()).getSourceCodeLine(),
							((ProgramCounterLocation) source.getLocation()).getPc(),
							((ProgramCounterLocation) source.getLocation()).getSourceCodeLine());

					String warn = "[DEFINITE] Access Control Incompleteness vulnerability at "
							+ ((ProgramCounterLocation) sink.getLocation()).getSourceCodeLine();
					tool.warn(warn);
					MyCache.getInstance().addAccessControlIncompletenessWarning(cfg.hashCode(), warn);

					warn = "[DEFINITE] Access Control Incompleteness vulnerability in " + contract.getName() + " at "
							+ functionSignatureByStatement
							+ " (pc: " + ((ProgramCounterLocation) sink.getLocation()).getPc() + ", "
							+ "line: " + ((ProgramCounterLocation) sink.getLocation()).getSourceCodeLine() + ")";
					MyCache.getInstance().addVulnerabilityPerFunction(cfg.hashCode(), warn);
				}
			}
		}
	}

}
