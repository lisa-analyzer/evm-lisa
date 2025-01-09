package it.unipr.cfg;

import it.unipr.analysis.operator.PcOperator;
import it.unive.lisa.analysis.AbstractState;
import it.unive.lisa.analysis.AnalysisState;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.StatementStore;
import it.unive.lisa.interprocedural.InterproceduralAnalysis;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;
import it.unive.lisa.program.cfg.edge.Edge;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Constant;
import it.unive.lisa.type.Untyped;
import it.unive.lisa.util.datastructures.graph.GraphVisitor;

/**
 * Pc opcode of the program to analyze.
 */
public class Pc extends Statement {

	/**
	 * Builds a Pc opcode happening at the given source location.
	 * 
	 * @param cfg      the cfg that this statement belongs to
	 * @param location the location where this statement is defined within the
	 *                     program
	 */
	public Pc(CFG cfg, CodeLocation location) {
		super(cfg, location);
	}

	@Override
	public <V> boolean accept(GraphVisitor<CFG, Statement, Edge, V> visitor, V tool) {
		return visitor.visit(tool, getCFG(), this);
	}

	@Override
	public String toString() {
		return "PC";
	}

	public <A extends AbstractState<A>> AnalysisState<A> forwardSemantics(AnalysisState<A> entryState,
			InterproceduralAnalysis<A> interprocedural, StatementStore<A> expressions) throws SemanticException {

		// we can safely suppose that there exists just one node incoming to
		// this node
		Statement incomingNode = getCFG().getIngoingEdges(this).stream().map(t -> t.getSource()).findAny().get();

		Constant pc = new Constant(Untyped.INSTANCE, ((ProgramCounterLocation) incomingNode.getLocation()).getPc(),
				getLocation());
		return entryState.smallStepSemantics(new it.unive.lisa.symbolic.value.UnaryExpression(Untyped.INSTANCE, pc,
				PcOperator.INSTANCE, getLocation()), this);
	}

	@Override
	protected int compareSameClass(Statement o) {
		// TODO Auto-generated method stub
		return 0;
	}
}