package it.unipr.cfg;

import it.unipr.analysis.AbstractStack;
import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.StackElement;
import it.unipr.analysis.operator.JumpiOperator;
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
import java.util.HashSet;
import java.util.Set;
import org.apache.commons.lang3.tuple.Pair;

/**
 * Jumpi opcode of the program to analyze.
 */
public class Jumpi extends Statement {

	/**
	 * Builds a Jumpi opcode happening at the given source location.
	 * 
	 * @param cfg      the cfg that this statement belongs to
	 * @param location the location where this statement is defined within the
	 *                     program
	 */
	public Jumpi(CFG cfg, CodeLocation location) {
		super(cfg, location);
	}

	@Override
	public <V> boolean accept(GraphVisitor<CFG, Statement, Edge, V> visitor, V tool) {
		return visitor.visit(tool, getCFG(), this);
	}

	@Override
	public String toString() {
		return "JUMPI";
	}

	public <A extends AbstractState<A>> AnalysisState<A> forwardSemantics(AnalysisState<A> entryState,
			InterproceduralAnalysis<A> interprocedural, StatementStore<A> expressions) throws SemanticException {

		EVMAbstractState valueState = entryState.getState().getDomainInstance(EVMAbstractState.class);

		// Split here
		Set<AbstractStack> trueStacks = new HashSet<>();
		Set<AbstractStack> falseStacks = new HashSet<>();
		if (!valueState.isBottom() && !valueState.isTop()) {
			for (AbstractStack st : valueState.getStacks()) {
				AbstractStack result = st.clone();
				result.pop();
				StackElement condition = result.pop();
				if (condition.isDefinitelyTrue())
					trueStacks.add(result);
				else if (condition.isDefinitelyFalse())
					falseStacks.add(result);
				else if (condition.isUnknown()) {
					trueStacks.add(result);
					falseStacks.add(result);
				}
			}
		}

		Constant c = new Constant(Untyped.INSTANCE, Pair.of(trueStacks, falseStacks), getLocation());
		return entryState.smallStepSemantics(new it.unive.lisa.symbolic.value.UnaryExpression(Untyped.INSTANCE, c,
				JumpiOperator.INSTANCE, getLocation()), this);
	}

	@Override
	protected int compareSameClass(Statement o) {
		// TODO Auto-generated method stub
		return 0;
	}
}