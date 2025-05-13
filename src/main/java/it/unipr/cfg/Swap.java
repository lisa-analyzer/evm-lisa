package it.unipr.cfg;

import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;
import it.unive.lisa.program.cfg.edge.Edge;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.util.datastructures.graph.GraphVisitor;

/**
 * Swap opcode of the program to analyze.
 */
public abstract class Swap extends Statement {

	/**
	 * Builds a Swap opcode happening at the given source location.
	 * 
	 * @param cfg      the cfg that this statement belongs to
	 * @param location the location where this statement is defined within the
	 *                     program
	 */
	protected Swap(CFG cfg, CodeLocation location) {
		super(cfg, location);
	}

	@Override
	public <V> boolean accept(GraphVisitor<CFG, Statement, Edge, V> visitor, V tool) {
		return visitor.visit(tool, getCFG(), this);
	}

	@Override
	protected int compareSameClass(Statement o) {
		// we cannot have more than one statement on the same code location
		return 0;
	}
}