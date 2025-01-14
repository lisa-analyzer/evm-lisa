package it.unipr.checker;

import static org.reflections.Reflections.log;

import it.unipr.analysis.MyCache;
import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.*;
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

public class TimestampDependencyChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(ReentrancyChecker.class);

	@Override
	public void beforeExecution(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool) {
		// TODO Auto-generated method stub
		SemanticCheck.super.beforeExecution(tool);
	}

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		if (node instanceof Timestamp || node instanceof Blockhash ||
				node instanceof Difficulty || node instanceof Balance) {
			EVMCFG cfg = ((EVMCFG) graph);
			/*
			 * Set<Statement> sha3 = cfg.getAllSha3(); // Returns a set of all
			 * the SHA3 statements in the CFG Set<Statement> sstore =
			 * cfg.getAllSstore(); // Returns a set of all the SSTORE statements
			 * in the CFG Set<Statement> jump = cfg.getAllJump(); // Returns a
			 * set of all the JUMP statements in the CFG Set<Statement> jumpI =
			 * cfg.getAllJumpI(); // Returns a set of all the JUMPI statements
			 * in the CFG
			 */

			// Combine all sink
			Set<Statement> sinks = new HashSet<>();
			sinks.addAll(cfg.getAllSha3());
			sinks.addAll(cfg.getAllSstore());
			sinks.addAll(cfg.getAllJump());
			sinks.addAll(cfg.getAllJumpI());

			Statement source = node; // Timestamp, Blockhash, Difficulty,
										// Balance

			for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
					TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
				AnalysisState<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
						TypeEnvironment<InferredTypes>>> analysisResult = null;

				for (Statement sink : sinks) {
					try {
						analysisResult = result.getAnalysisStateBefore(sink);
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
						if (sink instanceof Sha3) {
							if (checkTaintForSha3(taintedStack, source, sink))
								checkForTimestampDependency(source, sink, tool, cfg);
						} else if (sink instanceof Sstore) {
							if (checkTaintForSstore(taintedStack, source, sink))
								checkForTimestampDependency(source, sink, tool, cfg);
						} else if (sink instanceof Jump) {
							if (checkTaintForJump(taintedStack, source, sink))
								checkForTimestampDependency(source, sink, tool, cfg);
						} else if (sink instanceof Jumpi) {
							if (checkTaintForJumpI(taintedStack, source, sink))
								checkForTimestampDependency(source, sink, tool, cfg);
						}
					}

				}
			}

		}
		return true;
	}

	@Override
	public void afterExecution(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool) {
		// TODO Auto-generated method stub
		SemanticCheck.super.afterExecution(tool);
	}

	/**********/

	// 2 pop(), 1 push() // TODO: check push() case
	private boolean checkTaintForSha3(TaintAbstractDomain taintedStack, Statement source, Statement sink) {
		TaintElement firstStackElement = taintedStack.getFirstElement();
		TaintElement secondStackElement = taintedStack.getSecondElement();
		if (secondStackElement.isBottom() || secondStackElement.isBottom())
			return false;
		else if (firstStackElement.isTaint() || secondStackElement.isTaint())
			return true;
		return false;
	}

	// 2 pop()
	private boolean checkTaintForSstore(TaintAbstractDomain taintedStack, Statement source, Statement sink) {
		TaintElement firstStackElement = taintedStack.getFirstElement();
		TaintElement secondStackElement = taintedStack.getSecondElement();
		if (secondStackElement.isBottom())
			return false;
		else if (firstStackElement.isTaint() || secondStackElement.isTaint())
			return true;
		return false;
	}

	// 2 pop()
	private boolean checkTaintForJump(TaintAbstractDomain taintedStack, Statement source, Statement sink) {
		TaintElement firstStackElement = taintedStack.getFirstElement();

		if (firstStackElement.isBottom())
			return false;
		else if (firstStackElement.isTaint())
			return true;
		return false;
	}

	// 2 pop()
	private boolean checkTaintForJumpI(TaintAbstractDomain taintedStack, Statement source, Statement sink) {
		TaintElement firstStackElement = taintedStack.getFirstElement();
		TaintElement secondStackElement = taintedStack.getSecondElement();
		if (secondStackElement.isBottom())
			return false;
		else if (firstStackElement.isTaint() || secondStackElement.isTaint())
			return true;
		return false;
	}

	/**********/

	private void checkForTimestampDependency(Statement source, Statement sink, CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
			EVMCFG cfg) {
		if (cfg.reachableFrom(source, sink)) {
			ProgramCounterLocation jumploc = (ProgramCounterLocation) sink.getLocation();

			log.debug("Timestamp attack at {} at line no. {} coming from line {}", jumploc.getPc(),
					jumploc.getSourceCodeLine(),
					((ProgramCounterLocation) source.getLocation()).getSourceCodeLine());

			String warn = "Timestamp attack at " + ((ProgramCounterLocation) source.getLocation()).getSourceCodeLine();
			tool.warn(warn);
			MyCache.getInstance().addTxOriginWarning(cfg.hashCode(), warn);
		}
	}

}
