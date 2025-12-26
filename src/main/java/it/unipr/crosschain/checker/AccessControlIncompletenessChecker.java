package it.unipr.crosschain.checker;

import it.unipr.analysis.contract.Signature;
import it.unipr.analysis.contract.SmartContract;
import it.unipr.cfg.*;
import it.unipr.crosschain.taint.RelationalTaintAbstractDomain;
import it.unipr.crosschain.taint.RelationalTaintElement;
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
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
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
		SemanticCheck<
				SimpleAbstractState<MonolithicHeap, RelationalTaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(AccessControlIncompletenessChecker.class);

	private Set<Statement> taintedJumpi = new HashSet<>();
	private Map<Statement, Set<Integer>> jumpiProgramPoints = new HashMap<>();
	private SmartContract contract;
	private final Set<String> stateMutabilityForbidden = Set.of("view", "pure");

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
					SimpleAbstractState<MonolithicHeap, RelationalTaintAbstractDomain,
							TypeEnvironment<InferredTypes>>> tool,
			CFG graph) {

		EVMCFG cfg = ((EVMCFG) graph);

		for (Statement node : cfg.getNodes())
			if (node instanceof Jumpi)
				for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, RelationalTaintAbstractDomain,
						TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {

					AnalysisState<SimpleAbstractState<MonolithicHeap, RelationalTaintAbstractDomain,
							TypeEnvironment<InferredTypes>>> analysisResult = null;

					try {
						analysisResult = result.getAnalysisStateBefore(node);
					} catch (SemanticException e1) {
						log.error("(AccessControlIncompletenessChecker): {}", e1.getMessage());
						continue;
					}

					RelationalTaintAbstractDomain taintedStack = analysisResult.getState().getValueState();

					if (taintedStack.isBottom() || taintedStack.isTop())
						continue;

					RelationalTaintElement elem1 = taintedStack.getElementAtPosition(1);
					RelationalTaintElement elem2 = taintedStack.getElementAtPosition(2);

					if (RelationalTaintElement.isAtLeastOneTainted(elem1, elem2)) {
						taintedJumpi.add(node);
						// Track program points sanitized by this specific Jumpi
						Set<Integer> jumpiPps = new HashSet<>();
						if (elem1.isTaint()) {
							log.debug("[SANITIZER] Tainted Jumpi at pc {} - elem1 sanitizes program points: {}",
									((ProgramCounterLocation) node.getLocation()).getPc(),
									elem1.getProgramPoints());
							jumpiPps.addAll(elem1.getProgramPoints());
						}
						if (elem2.isTaint()) {
							log.debug("[SANITIZER] Tainted Jumpi at pc {} - elem2 sanitizes program points: {}",
									((ProgramCounterLocation) node.getLocation()).getPc(),
									elem2.getProgramPoints());
							jumpiPps.addAll(elem2.getProgramPoints());
						}
						jumpiProgramPoints.put(node, jumpiPps);
					}
				}
		return true;
	}

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, RelationalTaintAbstractDomain,
							TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		if (isSink(node)) {
			EVMCFG cfg = ((EVMCFG) graph);

			for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, RelationalTaintAbstractDomain,
					TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
				AnalysisState<SimpleAbstractState<MonolithicHeap, RelationalTaintAbstractDomain,
						TypeEnvironment<InferredTypes>>> analysisResult = null;

				try {
					analysisResult = result.getAnalysisStateBefore(node);
				} catch (SemanticException e1) {
					log.error("(AccessControlIncompletenessChecker): {}", e1.getMessage());
				}

				// Retrieve the symbolic stack from the analysis result
				RelationalTaintAbstractDomain taintedStack = analysisResult.getState().getValueState();

				if (taintedStack.isBottom() || taintedStack.isTop())
					// Nothing to do
					continue;

				int numArgs = getNumberOfArgs(node);
				boolean isAtLeastOneTainted = false;

				for (int argIndex = 1; argIndex <= numArgs; argIndex++) {
					isAtLeastOneTainted |= RelationalTaintElement.isAtLeastOneTainted(
							taintedStack.getElementAtPosition(argIndex));
				}

				if (isAtLeastOneTainted)
					checkForAccessControlIncompleteness(tool, cfg, node);
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
			SimpleAbstractState<MonolithicHeap, RelationalTaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg,
			Statement sink) {

		Set<Statement> sources = cfg.getAllStatementsByClass(
				Calldataload.class,
				Calldatacopy.class,
				Caller.class,
				Origin.class,
				Callvalue.class,
				Calldatasize.class);

		for (Statement source : sources) {
			// Check if source can reach sink
			if (cfg.reachableFromWithoutStatements(source, sink, new HashSet<>())) {
				int sourcePC = ((ProgramCounterLocation) source.getLocation()).getPc();

				// Get all tainted jumpi on the path from source to sink
				Set<Statement> jumpiBetweenSourceAndSink = cfg.getStatementsInAPathWithTypes(source, sink, Jumpi.class);

				// Check if at least one jumpi sanitizes this source's program
				// point
				boolean isSanitized = false;
				for (Statement jumpi : jumpiBetweenSourceAndSink) {
					Set<Integer> sanitizedPps = jumpiProgramPoints.get(jumpi);
					if (sanitizedPps == null)
						continue;
					if (sanitizedPps.contains(sourcePC)) {
						isSanitized = true;
						break;
					}
				}

				// If not sanitized by any jumpi on the path, it's a
				// vulnerability
				if (!isSanitized) {
					reportVulnerability(tool, cfg, source, sink);
				}
			}
		}
	}

	/**
	 * Reports a vulnerability found by the checker.
	 *
	 * @param tool   the analysis tool to report warnings on
	 * @param cfg    the CFG under inspection
	 * @param source the untrusted source statement
	 * @param sink   the sensitive sink statement
	 */
	private void reportVulnerability(CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, RelationalTaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg,
			Statement source,
			Statement sink) {
		String functionSignatureByStatement = contract.getFunctionSignatureByStatement(source);

		// It means that this vulnerability is inside a private function
		if (functionSignatureByStatement.equals("no-function-found"))
			return;

		Signature signature = contract.getFunctionSignatureByString(functionSignatureByStatement);
		if (signature == null)
			return;
		if (stateMutabilityForbidden.contains(signature.getStateMutability()))
			return;

		if (signature.isProtected()) {
			log.warn(
					"[POSSIBLE] Access Control Incompleteness vulnerability at pc {} (line {}) coming from pc {} (line {}).",
					((ProgramCounterLocation) sink.getLocation()).getPc(),
					((ProgramCounterLocation) sink.getLocation()).getSourceCodeLine(),
					((ProgramCounterLocation) source.getLocation()).getPc(),
					((ProgramCounterLocation) source.getLocation()).getSourceCodeLine());
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
