package it.unipr.crosschain.edges;

import it.unive.lisa.program.cfg.statement.Statement;

public class ConservativeCrossChainEdge extends CrossChainEdge {
	/**
	 * Builds an "empty" conservative cross chain edge, meaning that it does not
	 * have endpoints.
	 */
	public ConservativeCrossChainEdge() {
		super();
	}

	/**
	 * Builds the conservative cross chain edge.
	 *
	 * @param source      the source statement
	 * @param destination the destination statement
	 */
	public ConservativeCrossChainEdge(
			Statement source,
			Statement destination) {
		super(source, destination);
	}
}