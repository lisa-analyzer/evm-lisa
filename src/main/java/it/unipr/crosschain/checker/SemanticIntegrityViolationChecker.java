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

public class SemanticIntegrityViolationChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(SemanticIntegrityViolationChecker.class);

	private final Set<Statement> taintedJumpi = new HashSet<>();

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
					taintedJumpi.add(node);
				}
		return true;
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
					log.error("(SemanticIntegrityViolationChecker): {}", e1.getMessage());
				}

				TaintAbstractDomain taintedStack = analysisResult.getState().getValueState();

				if (taintedStack.isBottom())
					// Nothing to do
					continue;
				else if (node instanceof Log0) {
					// Checks if either first or second element in the
					// stack is tainted
					if (TaintElement.isAtLeastOneTainted(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2))) {
						raiseDefiniteSemanticIntegrityViolation(node, tool, cfg);
					} else if (TaintElement.isAtLeastOneTop(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2))) {
						raisePossibleSemanticIntegrityViolation(node, tool, cfg);
					}
				} else if (node instanceof Log1) {
					if (TaintElement.isAtLeastOneTainted(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2),
							taintedStack.getElementAtPosition(3))) {
						raiseDefiniteSemanticIntegrityViolation(node, tool, cfg);
					} else if (TaintElement.isAtLeastOneTop(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2),
							taintedStack.getElementAtPosition(3))) {
						raisePossibleSemanticIntegrityViolation(node, tool, cfg);
					}
				} else if (node instanceof Log2) {
					if (TaintElement.isAtLeastOneTainted(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2),
							taintedStack.getElementAtPosition(3),
							taintedStack.getElementAtPosition(4))) {
						raiseDefiniteSemanticIntegrityViolation(node, tool, cfg);
					} else if (TaintElement.isAtLeastOneTop(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2),
							taintedStack.getElementAtPosition(3),
							taintedStack.getElementAtPosition(4))) {
						raisePossibleSemanticIntegrityViolation(node, tool, cfg);
					}
				} else if (node instanceof Log3) {
					if (TaintElement.isAtLeastOneTainted(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2),
							taintedStack.getElementAtPosition(3),
							taintedStack.getElementAtPosition(4),
							taintedStack.getElementAtPosition(5))) {
						raiseDefiniteSemanticIntegrityViolation(node, tool, cfg);
					} else if (TaintElement.isAtLeastOneTop(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2),
							taintedStack.getElementAtPosition(3),
							taintedStack.getElementAtPosition(4),
							taintedStack.getElementAtPosition(5))) {
						raisePossibleSemanticIntegrityViolation(node, tool, cfg);
					}
				} else if (node instanceof Log4) {
					if (TaintElement.isAtLeastOneTainted(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2),
							taintedStack.getElementAtPosition(3),
							taintedStack.getElementAtPosition(4),
							taintedStack.getElementAtPosition(5),
							taintedStack.getElementAtPosition(6))) {
						raiseDefiniteSemanticIntegrityViolation(node, tool, cfg);
					} else if (TaintElement.isAtLeastOneTop(
							taintedStack.getElementAtPosition(1),
							taintedStack.getElementAtPosition(2),
							taintedStack.getElementAtPosition(3),
							taintedStack.getElementAtPosition(4),
							taintedStack.getElementAtPosition(5),
							taintedStack.getElementAtPosition(6))) {
						raisePossibleSemanticIntegrityViolation(node, tool, cfg);
					}
				}
			}
		}
		return true;
	}

	private void raiseDefiniteSemanticIntegrityViolation(Statement logx, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg) {
		Set<Statement> externalDatas = cfg.getExternalData();

		for (Statement data : externalDatas) {
			if (cfg.reachableFromWithoutStatements(data, logx, taintedJumpi)) {

				ProgramCounterLocation logxLocation = (ProgramCounterLocation) logx.getLocation();

				log.warn("[DEFINITE] Semantic integrity violation at pc {} at line {} coming from line {}.",
						logxLocation.getPc(),
						logxLocation.getSourceCodeLine(),
						((ProgramCounterLocation) data.getLocation()).getSourceCodeLine());

				String warn = "[DEFINITE] Semantic Integrity Violation vulnerability at "
						+ ((ProgramCounterLocation) data.getLocation()).getSourceCodeLine();
				tool.warn(warn);
				MyCache.getInstance().addSemanticIntegrityViolationWarning(cfg.hashCode(), warn);
			}
		}
	}

	private void raisePossibleSemanticIntegrityViolation(Statement logx, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg) {
		Set<Statement> externalDatas = cfg.getExternalData();

		for (Statement data : externalDatas) {
			if (cfg.reachableFromWithoutStatements(data, logx, taintedJumpi)) {

				ProgramCounterLocation logxLocation = (ProgramCounterLocation) logx.getLocation();

				log.warn("[POSSIBLE] Semantic integrity violation at pc {} at line {} coming from line {}.",
						logxLocation.getPc(),
						logxLocation.getSourceCodeLine(),
						((ProgramCounterLocation) data.getLocation()).getSourceCodeLine());

				String warn = "[POSSIBLE] Semantic integrity violation vulnerability at "
						+ ((ProgramCounterLocation) data.getLocation()).getSourceCodeLine();
				tool.warn(warn);
				MyCache.getInstance().addPossibleSemanticIntegrityViolationWarning(cfg.hashCode(), warn);
			}
		}
	}
}
