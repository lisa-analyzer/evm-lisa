package it.unipr.checker;

import it.unipr.analysis.MyCache;
import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Jump;
import it.unipr.cfg.Jumpi;
import it.unipr.cfg.ProgramCounterLocation;
import it.unipr.cfg.Sha3;
import it.unipr.cfg.Sstore;
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

public class TimestampDependencyChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(TimestampDependencyChecker.class);

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		EVMCFG cfg = ((EVMCFG) graph);

		if (node instanceof Jump || node instanceof Jumpi || node instanceof Sstore || node instanceof Sha3)
			for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
					TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
				AnalysisState<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
						TypeEnvironment<InferredTypes>>> analysisResult = null;

				try {
					analysisResult = result.getAnalysisStateBefore(node);
				} catch (SemanticException e1) {
					log.error("(TimestampDependencyChecker): {}", e1.getMessage());
				}

				// Retrieve the symbolic stack from the analysis result
				TaintAbstractDomain taintedStack = analysisResult.getState().getValueState();

				// If the stack is bottom, the jump is definitely
				// unreachable
				if (taintedStack.isBottom())
					// Nothing to do
					continue;
				else {
					if (node instanceof Sha3 || node instanceof Sstore || node instanceof Jumpi) {
						if (checkTaintTwoPops(taintedStack))
							raiseWarning(node, tool, cfg);
					} else if (node instanceof Jump) {
						if (checkTaintOnePop(taintedStack))
							raiseWarning(node, tool, cfg);
					}
				}

			}

		return true;
	}

	// 2 pop()
	private boolean checkTaintTwoPops(TaintAbstractDomain taintedStack) {
		TaintElement firstStackElement = taintedStack.getFirstElement();
		TaintElement secondStackElement = taintedStack.getSecondElement();
		if (secondStackElement.isBottom() || secondStackElement.isBottom())
			return false;
		else if (firstStackElement.isTaint() || secondStackElement.isTaint())
			return true;
		return false;
	}

	// 1 pop()
	private boolean checkTaintOnePop(TaintAbstractDomain taintedStack) {
		TaintElement firstStackElement = taintedStack.getFirstElement();

		if (firstStackElement.isBottom())
			return false;
		else if (firstStackElement.isTaint())
			return true;
		return false;
	}

	private void raiseWarning(Statement sink, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg) {
		ProgramCounterLocation sinkLoc = (ProgramCounterLocation) sink.getLocation();

		log.debug("Timestamp attack at {} at line no. {}", sinkLoc.getPc(),
				sinkLoc.getSourceCodeLine());

		String warn = "Timestamp attack at " + ((ProgramCounterLocation) sink.getLocation()).getSourceCodeLine();
		tool.warn(warn);
		MyCache.getInstance().addTimestampDependencyWarning(cfg.hashCode(), warn);
	}
}
