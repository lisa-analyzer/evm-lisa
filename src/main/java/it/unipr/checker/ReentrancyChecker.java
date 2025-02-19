package it.unipr.checker;

import java.util.Set;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import it.unipr.analysis.AbstractStack;
import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.MyCache;
import it.unipr.analysis.StackElement;
import it.unipr.cfg.Call;
import it.unipr.cfg.EVMCFG;
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

public class ReentrancyChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(ReentrancyChecker.class);

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		if (node instanceof Call) {
			EVMCFG cfg = ((EVMCFG) graph);
			Set<Statement> ns = cfg.getAllSstore();
			Statement call = node; // Renaming

			for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, EVMAbstractState,
					TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
				AnalysisState<SimpleAbstractState<MonolithicHeap, EVMAbstractState,
						TypeEnvironment<InferredTypes>>> analysisResult = null;

				try {
					analysisResult = result.getAnalysisStateBefore(call);
				} catch (SemanticException e1) {
					log.error("(ReentrancyChecker): {}", e1.getMessage());
				}

				// Retrieve the symbolic stack from the analysis result
				EVMAbstractState valueState = analysisResult.getState().getValueState();

				// If the value state is bottom, the jump is definitely
				// unreachable
				if (valueState.isBottom())
					// Nothing to do
					continue;
				else if (valueState.isTop())
					for (Statement sstore : ns)
						checkForReentrancy(call, sstore, tool, ns, cfg);
				else {
					for (AbstractStack stack : valueState.getStacks()) {
						StackElement sndElem = stack.getSecondElement();

						if (sndElem.isTop() || sndElem.isTopNotJumpdest())
							for (Statement sstore : ns)
								checkForReentrancy(call, sstore, tool, ns, cfg);
					}
				}
			}
		}

		return true;
	}

	private void checkForReentrancy(Statement call, Statement sstore, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> tool,
			Set<Statement> ns, EVMCFG cfg) {

		ProgramCounterLocation sstoreLoc = (ProgramCounterLocation) sstore.getLocation();

		if (cfg.reachableFrom(call, sstore)) {
			for (Statement otherSstore : ns)
				if (!otherSstore.equals(sstore))
					if (cfg.reachableFromSequentially(sstore, otherSstore))
						sstoreLoc = (ProgramCounterLocation) otherSstore.getLocation();

			log.debug("Reentrancy attack at {} at line no. {} coming from line {}", sstoreLoc.getPc(),
					sstoreLoc.getSourceCodeLine(), ((ProgramCounterLocation) call.getLocation()).getSourceCodeLine());
			String warn = "Reentrancy attack at " + sstoreLoc.getPc();
			tool.warn(warn);
			MyCache.getInstance().addReentrancyWarning(cfg.hashCode(), warn);
		}
	}
}