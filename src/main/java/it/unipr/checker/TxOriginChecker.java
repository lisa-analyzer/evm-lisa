package it.unipr.checker;

import it.unipr.analysis.MyCache;
import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Origin;
import it.unipr.cfg.ProgramCounterLocation;
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

public class TxOriginChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(TxOriginChecker.class);

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		if (node instanceof Origin) {
			EVMCFG cfg = ((EVMCFG) graph);
			Set<Statement> jumps = cfg.getAllJumpI();
			Statement origin = node;

			for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
					TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
				AnalysisState<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
						TypeEnvironment<InferredTypes>>> analysisResult = null;

				for (Statement jump : jumps) {
					try {
						analysisResult = result.getAnalysisStateBefore(jump);
					} catch (SemanticException e1) {
						log.error("(TxOriginChecker): {}", e1.getMessage());
					}

					// Retrieve the symbolic stack from the analysis result
					TaintAbstractDomain taintedStack = analysisResult.getState().getValueState();

					// If the stack is bottom, the jump is definitely
					// unreachable
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
								checkForTxOrigin(origin, jump, tool, cfg);
							}
						}
					}
				}
			}

		}

		return true;
	}

	private void checkForTxOrigin(Statement origin, Statement jump, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg) {
		if (cfg.reachableFrom(origin, jump)) {
			ProgramCounterLocation jumploc = (ProgramCounterLocation) jump.getLocation();

			log.debug("Tx. Origin attack at {} at line no. {} coming from line {}", jumploc.getPc(),
					jumploc.getSourceCodeLine(),
					((ProgramCounterLocation) origin.getLocation()).getSourceCodeLine());

			String warn = "TxOrigin attack at " + ((ProgramCounterLocation) origin.getLocation()).getSourceCodeLine();
			tool.warn(warn);
			MyCache.getInstance().addTxOriginWarning(cfg.hashCode(), warn);
		}
	}
}