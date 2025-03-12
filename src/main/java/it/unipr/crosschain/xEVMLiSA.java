package it.unipr.crosschain;

import it.unipr.EVMLiSA;
import it.unipr.analysis.contract.Signature;
import it.unipr.analysis.contract.SmartContract;
import it.unipr.cfg.ProgramCounterLocation;
import it.unipr.crosschain.edges.ConservativeCrossChainEdge;
import it.unipr.crosschain.edges.CrossChainEdge;
import it.unipr.utils.MyCache;
import it.unive.lisa.program.cfg.edge.Edge;
import it.unive.lisa.program.cfg.statement.Statement;
import java.nio.file.Path;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class xEVMLiSA {
	private static final Logger log = LogManager.getLogger(xEVMLiSA.class);
	private static boolean CONSERVATIVE_LINK = false;

	public static void runAnalysis(Path bytecodeDirectoryPath, Path abiDirectoryPath) {
		Bridge bridge = new Bridge(bytecodeDirectoryPath, abiDirectoryPath);
		analyzeBridge(bridge);
	}

	public static void analyzeBridge(Bridge bridge) {
		EVMLiSA.setLinkUnsoundJumpsToAllJumpdest();
		EVMLiSA.setCores(
				Runtime.getRuntime().availableProcessors() / 4 * 3);
		EVMLiSA.analyzeSetOfContracts(bridge.getSmartContracts());
		bridge.buildPartialXCFG();
		bridge.addEdges(
				// getCrossChainEdgesUsingEventsAndFunctionsEntrypoint(bridge)
				getCrossChainEdgesUsingEventsEntrypoint(bridge) // SmartAxe
																// solution
		);

		// log.debug("Bridge after analysis \n {}", bridge);
	}

	/**
	 * Gets cross-chain edges by linking events exit points to function entry
	 * points in different contracts.
	 *
	 * @return A list of added cross-chain edges.
	 */
	private static Set<Edge> getCrossChainEdgesUsingEventsAndFunctionsEntrypoint(Bridge bridge) {
		Set<Edge> crossChainEdges = new HashSet<>();

		log.info("Computing cross chain edges");
		log.info("Functions count: {}", bridge.getFunctions().size());
		log.info("Events count: {}", bridge.getEvents().size());
		log.info("Log count: {}", bridge.getXCFG().getAllLogX().size());

		boolean match = false;

		for (Statement logStatement : bridge.getXCFG().getAllLogX()) {

			Set<String> selectorsInLOG = MyCache.getInstance().getEventExitPoints(logStatement);
			match = false;

			if (selectorsInLOG.isEmpty())
				continue;

			for (String selector : selectorsInLOG) {
				for (Signature event : bridge.getEvents()) {
					if (selector.equals(event.getSelector())) {
						for (Signature function : bridge.getFunctions()) {
							if (event.getName().equalsIgnoreCase(function.getName())) {
								match = true;
								crossChainEdges.addAll(
										addCrossChainEdges(event.getEntryPoints(), function.getEntryPoints()));
								log.debug(
										"Perfect match! Event: {}/{} from LOG source-code line: {}, to Function: {}/{}",
										event.getName(), event.getParamCount(),
										((ProgramCounterLocation) logStatement.getLocation()).getSourceCodeLine(),
										function.getName(), function.getParamCount());
							}
						}
					}
				}
			}

			if (!match && CONSERVATIVE_LINK) {
				// We link this event to all functions entry points
				for (Signature function : bridge.getFunctions())
					crossChainEdges.addAll(addConservativeCrossChainEdges(Collections.singleton(logStatement),
							function.getEntryPoints()));

				log.warn("No match! LOG at source-code line {} conservative linked to {} functions",
						((ProgramCounterLocation) logStatement.getLocation()).getSourceCodeLine(),
						bridge.getFunctions().size());
			}
		}

		log.debug("Added {} cross chain edges using events exit points and functions entry points",
				crossChainEdges.size());
		log.info("Cross chain edges computed");

		return crossChainEdges;
	}

	/**
	 * Gets cross-chain edges by linking emitting blocks to information blocks
	 * in different contracts (SmartAxe solution).
	 *
	 * @return A list of added cross-chain edges.
	 */
	private static Set<Edge> getCrossChainEdgesUsingEventsEntrypoint(Bridge bridge) {
		Set<Statement> emittingBlocks = new HashSet<>();
		Set<Statement> informationBlocks = new HashSet<>();

		for (SmartContract contract : bridge) {
			for (Signature signature : EventKnowledge.getEmittingBlocksSignature(contract.getEventsSignature()))
				emittingBlocks.addAll(signature.getEntryPoints());

			for (Signature signature : EventKnowledge.getInformationBlocksSignature(contract.getEventsSignature()))
				informationBlocks.addAll(signature.getEntryPoints());
		}

		Set<Edge> crossChainEdges = new HashSet<>(addCrossChainEdges(emittingBlocks, informationBlocks));

		log.debug("Added {} cross chain edges using events entrypoint", crossChainEdges.size());
		return crossChainEdges;
	}

	/**
	 * Creates cross-chain edges between a set of source statements and a set of
	 * target statements.
	 *
	 * @param sources The set of source statements.
	 * @param targets The set of target statements.
	 *
	 * @return A set of cross-chain edges connecting the given sources to the
	 *             targets.
	 */
	private static Set<Edge> addCrossChainEdges(Set<Statement> sources, Set<Statement> targets) {
		Set<Edge> edges = new HashSet<>();

		for (Statement source : sources)
			for (Statement target : targets)
				edges.add(new CrossChainEdge(source, target));

		return edges;
	}

	/**
	 * Creates conservative cross-chain edges between a set of source statements
	 * and a set of target statements.
	 *
	 * @param sources The set of source statements.
	 * @param targets The set of target statements.
	 *
	 * @return A set of conservative cross-chain edges connecting the given
	 *             sources to the targets.
	 */
	private static Set<Edge> addConservativeCrossChainEdges(Set<Statement> sources, Set<Statement> targets) {
		Set<Edge> edges = new HashSet<>();

		for (Statement source : sources)
			for (Statement target : targets)
				edges.add(new ConservativeCrossChainEdge(source, target));

		return edges;
	}

}
