package it.unipr.analysis.contract;

import it.unipr.analysis.*;
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
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class EventsExitPointsComputer implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(EventsExitPointsComputer.class);

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		boolean isLog = (node instanceof Log1) || (node instanceof Log2) || (node instanceof Log3)
				|| (node instanceof Log4);

		if (isLog) {
			EVMCFG cfg = ((EVMCFG) graph);
			Statement logStatement = node;

			for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, EVMAbstractState,
					TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
				AnalysisState<SimpleAbstractState<MonolithicHeap, EVMAbstractState,
						TypeEnvironment<InferredTypes>>> analysisResult = null;

				try {
					analysisResult = result.getAnalysisStateBefore(logStatement);
				} catch (SemanticException e1) {
					log.error("(EventsExitPointsComputer): {}", e1.getMessage());
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
					checkForEventSignature(node, valueState.getStacks());
				}
			}

		}

		return true;
	}

	/**
	 * Extracts and stores event signatures from the EVM stack based on LOG
	 * instructions. Depending on the LOG opcode type (LOG1, LOG2, LOG3, LOG4),
	 * it retrieves the corresponding topics from the stack and stores their
	 * first 4 bytes as event exit points.
	 *
	 * @param node   The statement representing the LOG instruction.
	 * @param stacks The abstract stack set containing stack states to analyze.
	 */
	private void checkForEventSignature(Statement node, AbstractStackSet stacks) {
		for (AbstractStack originalStack : stacks) {
			AbstractStack stack = originalStack.clone();

			stack.pop(); // offset
			stack.pop(); // size

			if (node instanceof Log1) {
				StackElement topic = stack.pop();
				MyCache.getInstance().addEventExitPoint(node, toHexFirst4Bytes(topic));
			} else if (node instanceof Log2) {
				StackElement topic1 = stack.pop();
				StackElement topic2 = stack.pop();
				MyCache.getInstance().addEventExitPoint(node, toHexFirst4Bytes(topic1));
				MyCache.getInstance().addEventExitPoint(node, toHexFirst4Bytes(topic2));
			} else if (node instanceof Log3) {
				StackElement topic1 = stack.pop();
				StackElement topic2 = stack.pop();
				StackElement topic3 = stack.pop();
				MyCache.getInstance().addEventExitPoint(node, toHexFirst4Bytes(topic1));
				MyCache.getInstance().addEventExitPoint(node, toHexFirst4Bytes(topic2));
				MyCache.getInstance().addEventExitPoint(node, toHexFirst4Bytes(topic3));
			} else if (node instanceof Log4) {
				StackElement topic1 = stack.pop();
				StackElement topic2 = stack.pop();
				StackElement topic3 = stack.pop();
				StackElement topic4 = stack.pop();
				MyCache.getInstance().addEventExitPoint(node, toHexFirst4Bytes(topic1));
				MyCache.getInstance().addEventExitPoint(node, toHexFirst4Bytes(topic2));
				MyCache.getInstance().addEventExitPoint(node, toHexFirst4Bytes(topic3));
				MyCache.getInstance().addEventExitPoint(node, toHexFirst4Bytes(topic4));
			}
		}
	}

	/**
	 * Converts a stack element to its hexadecimal representation and returns
	 * only the first 4 bytes. If the value represents a special case (e.g.,
	 * bottom, top, topNumeric), it returns a corresponding string.
	 *
	 * @param value The stack element to convert.
	 *
	 * @return A lowercase hexadecimal string of the first 4 bytes or a special
	 *             identifier if applicable.
	 */
	public static String toHexFirst4Bytes(StackElement value) {
		if (value.isBottom())
			return "bottom";
		if (value.isTopNotJumpdest())
			return "topNotJumpdest";
		if (value.isTopNumeric())
			return "topNumeric";
		if (value.isTop())
			return "top";

		StringBuilder hex = new StringBuilder(toHex(value));
		while (hex.length() < 8)
			hex.insert(0, "0");
		return hex.toString().toLowerCase().substring(0, 8);
	}

	/**
	 * Converts a stack element's numeric value to its full hexadecimal
	 * representation.
	 *
	 * @param value The stack element to convert.
	 *
	 * @return A hexadecimal string representing the numeric value of the stack
	 *             element.
	 */
	public static String toHex(StackElement value) {
		return it.unipr.analysis.Number.toBigInteger(value.getNumber()).toString(16);
	}
}