package it.unipr.crosschain.edges;

import it.unive.lisa.program.cfg.edge.SequentialEdge;
import it.unive.lisa.program.cfg.statement.Statement;

public class CrossChainEdge extends SequentialEdge {
	/**
	 * Builds an "empty" cross chain edge, meaning that it does not have
	 * endpoints.
	 */
	public CrossChainEdge() {
		super();
	}

	/**
	 * Builds the cross chain edge.
	 *
	 * @param source      the source statement
	 * @param destination the destination statement
	 */
	public CrossChainEdge(
			Statement source,
			Statement destination) {
		super(source, destination);
	}
}