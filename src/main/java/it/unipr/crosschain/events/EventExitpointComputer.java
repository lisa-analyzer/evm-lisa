package it.unipr.crosschain.events;

import it.unipr.analysis.AbstractStack;
import it.unipr.analysis.AbstractStackSet;
import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.StackElement;
import it.unipr.analysis.contract.Signature;
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
import java.util.Set;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class EventExitpointComputer implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(EventExitpointComputer.class);
	private final Set<Signature> eventsSignature;

	public EventExitpointComputer(Set<Signature> eventsSignature) {
		this.eventsSignature = eventsSignature;
	}

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> tool,
			CFG graph,
			Statement node) {

		if (!(node instanceof Log))
			return true;
		if (node instanceof Log0)
			return true; // Log0 has no topics, not used with events

		for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, EVMAbstractState,
				TypeEnvironment<InferredTypes>>> result : tool.getResultOf(graph)) {
			AnalysisState<SimpleAbstractState<MonolithicHeap, EVMAbstractState,
					TypeEnvironment<InferredTypes>>> analysisResult = null;

			try {
				analysisResult = result.getAnalysisStateBefore(node);
			} catch (SemanticException e1) {
				log.error("(EventExitpointComputer): {}", e1.getMessage());
			}

			// Retrieve the symbolic stack from the analysis result
			EVMAbstractState valueState = analysisResult.getState().getValueState();

			if (valueState.isBottom() || valueState.isTop())
				continue;

			AbstractStackSet stacks = valueState.getStacks();
			for (AbstractStack stack : stacks) {
				int numTopics = getNumberOfTopics(node);

				for (int topicIndex = 0; topicIndex < numTopics; topicIndex++) {
					StackElement topic = stack.getElementAtPosition(3 + topicIndex);

					for (Signature event : eventsSignature)
						if (checkTopicMatchesEvent(topic, event, node))
							break;
				}
			}
		}

		return true;
	}

	/**
	 * Determines the number of topics based on the type of Log statement. In
	 * EVM, Log0 has no topics, Log1 has 1 topic, Log2 has 2 topics, etc.
	 *
	 * @param node the Log statement node
	 *
	 * @return the number of topics for the given Log statement (0-4)
	 */
	private int getNumberOfTopics(Statement node) {
		if (node instanceof Log1)
			return 1;
		if (node instanceof Log2)
			return 2;
		if (node instanceof Log3)
			return 3;
		if (node instanceof Log4)
			return 4;
		return 0;
	}

	/**
	 * Checks if a topic from the stack matches an event signature selector. If
	 * a match is found, the statement is added as an exit point for the event.
	 *
	 * @param topic the stack element representing the topic to check
	 * @param event the event signature to match against
	 * @param node  the Log statement node where the topic was found
	 *
	 * @return true if the topic matches the event selector, false otherwise
	 */
	private boolean checkTopicMatchesEvent(StackElement topic, Signature event, Statement node) {
		if (topic.toHexString().toLowerCase().startsWith(event.getSelector().toLowerCase())) {
			event.addExitPoint(node);
			log.info("Found event exitpoint for {}", event.getSelector());
			return true;
		}
		return false;
	}
}
