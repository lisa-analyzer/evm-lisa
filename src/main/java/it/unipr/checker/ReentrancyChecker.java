package it.unipr.checker;

import it.unipr.analysis.AbstractStack;
import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.StackElement;
import it.unipr.cfg.Call;
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

public class ReentrancyChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(ReentrancyChecker.class);

	private static boolean isEnabled = false;

	public static void enableChecker() {
		isEnabled = true;
	}

	public static void disableChecker() {
		isEnabled = false;
	}

	public static boolean isEnabled() {
		return isEnabled;
	}

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		if (node instanceof Call) {
			EVMCFG cfg = ((EVMCFG) graph);
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
					checkForReentrancy(call, tool, cfg);
				else {
					for (AbstractStack stack : valueState.getStacks()) {
						StackElement sndElem = stack.getSecondElement();
						if (sndElem.isTop() || sndElem.isTopNotJumpdest())
							checkForReentrancy(call, tool, cfg);
					}
				}
			}
		}

		return true;
	}

	/**
	 * Checks for potential reentrancy vulnerabilities in the contract by
	 * analyzing the flow from a CALL instruction to the furthest reachable
	 * SSTORE instructions. If multiple SSTORE instructions are found, it
	 * verifies if they are sequentially reachable from each other to determine
	 * the furthest modification to the contract's state.
	 *
	 * @param call The CALL instruction being analyzed.
	 * @param tool The analysis tool used to track and report vulnerabilities.
	 * @param cfg  The control flow graph of the contract being analyzed.
	 */
	private void checkForReentrancy(Statement call, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> tool, EVMCFG cfg) {

		Set<Statement> otherSstores = cfg.getFurthestSstores(call);

		if (otherSstores.isEmpty())
			return;

		for (Statement ss1 : otherSstores) {
			ProgramCounterLocation sstoreLoc = (ProgramCounterLocation) ss1.getLocation();

			for (Statement ss2 : otherSstores)
				if (!ss2.equals(ss1) && cfg.reachableFromSequentially(ss1, ss2))
					sstoreLoc = (ProgramCounterLocation) ss2.getLocation();

			log.debug("Reentrancy attack at {} at line no. {} coming from line {}", sstoreLoc.getPc(),
					sstoreLoc.getSourceCodeLine(), ((ProgramCounterLocation) call.getLocation()).getSourceCodeLine());
			String warn = "Reentrancy attack at " + sstoreLoc.getPc();
			tool.warn(warn);
			MyCache.getInstance().addReentrancyWarning(cfg.hashCode(), warn);
		}
	}
}