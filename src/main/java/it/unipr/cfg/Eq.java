package it.unipr.cfg;

import it.unipr.analysis.operator.EqOperator;
import it.unive.lisa.analysis.AbstractState;
import it.unive.lisa.analysis.AnalysisState;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.StatementStore;
import it.unive.lisa.interprocedural.InterproceduralAnalysis;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;
import it.unive.lisa.program.cfg.edge.Edge;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.type.Untyped;
import it.unive.lisa.util.datastructures.graph.GraphVisitor;

/**
 * Eq opcode of the program to analyze.
 */
public class Eq extends Statement {

	/**
	 * Builds a Eq opcode happening at the given source location.
	 * 
	 * @param cfg      the cfg that this statement belongs to
	 * @param location the location where this statement is defined within the
	 *                     program
	 */
	public Eq(CFG cfg, CodeLocation location) {
		super(cfg, location);
	}

	@Override
	public <V> boolean accept(GraphVisitor<CFG, Statement, Edge, V> visitor, V tool) {
		return visitor.visit(tool, getCFG(), this);
	}

	@Override
	public String toString() {
		return "EQ";
	}

	@Override
	public <A extends AbstractState<A>> AnalysisState<A> forwardSemantics(AnalysisState<A> entryState,
			InterproceduralAnalysis<A> interprocedural, StatementStore<A> expressions) throws SemanticException {

		return entryState.smallStepSemantics(
				new it.unive.lisa.symbolic.value.UnaryExpression(Untyped.INSTANCE, DummyConstant.INSTANCE,
						EqOperator.INSTANCE, getLocation()),
				this);
	}

	@Override
	protected int compareSameClass(Statement o) {
		// we cannot have more than one statement on the same code location
		return 0;
	}
}