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

	@Override
	public int hashCode() {
		return getSource().hashCode() + getSource().getCFG().hashCode()
				+ getDestination().hashCode() + getDestination().getCFG().hashCode();
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (!(obj instanceof CrossChainEdge))
			return false;
		CrossChainEdge other = (CrossChainEdge) obj;
		return (getSource() != null ? getSource().equals(other.getSource()) : other.getSource() == null)
				&& (getDestination() != null ? getDestination().equals(other.getDestination())
						: other.getDestination() == null)
				&& (getSource().getCFG() != null ? getSource().getCFG().equals(other.getSource().getCFG())
						: other.getSource().getCFG() == null)
				&& (getDestination().getCFG() != null
						? getDestination().getCFG().equals(other.getDestination().getCFG())
						: other.getDestination().getCFG() == null)
				&& (getSource().getCFG().equals(getDestination().getCFG()));
	}

}