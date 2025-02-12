package it.unipr.checker;

import it.unipr.analysis.AbstractStack;
import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.cfg.Calldataload;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.ProgramCounterLocation;
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

public class CallDataLoadChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(CallDataLoadChecker.class);

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		if (node instanceof Calldataload) {
			EVMCFG cfg = ((EVMCFG) graph);
			Statement callDataLoad = node;

			for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, EVMAbstractState,
					TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
				AnalysisState<SimpleAbstractState<MonolithicHeap, EVMAbstractState,
						TypeEnvironment<InferredTypes>>> analysisResult = null;

				try {
					analysisResult = result.getAnalysisStateBefore(callDataLoad);
				} catch (SemanticException e1) {
					log.error("(CallDataLoadChecker): {}", e1.getMessage());
				}

				// Retrieve the symbolic stack from the analysis result
				EVMAbstractState valueState = analysisResult.getState().getValueState();

				// If the value state is bottom, the jump is definitely
				// unreachable
				if (valueState.isBottom())
					// Nothing to do
					continue;
				else if (valueState.isTop())
					continue;
				else {
					for (AbstractStack stack : valueState.getStacks()) {
						log.debug(stack);
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