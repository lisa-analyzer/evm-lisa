package it.unipr.cfg;

import it.unipr.analysis.AbstractStack;
import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.StackElement;
import it.unipr.analysis.operator.JumpiOperator;
import it.unive.lisa.analysis.AbstractState;
import it.unive.lisa.analysis.AnalysisState;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.StatementStore;
import it.unive.lisa.analysis.heap.HeapDomain;
import it.unive.lisa.analysis.value.TypeDomain;
import it.unive.lisa.analysis.value.ValueDomain;
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
	public int setOffset(int offset) {
		return this.offset = offset;
	}

	@Override
	public <V> boolean accept(GraphVisitor<CFG, Statement, Edge, V> visitor, V tool) {
		return visitor.visit(tool, getCFG(), this);
	}

	@Override
	public String toString() {
		return "JUMPI";
	}

	@Override
	public <A extends AbstractState<A, H, V, T>,
			H extends HeapDomain<H>,
			V extends ValueDomain<V>,
			T extends TypeDomain<T>> AnalysisState<A, H, V, T> semantics(
					AnalysisState<A, H, V, T> entryState, InterproceduralAnalysis<A, H, V, T> interprocedural,
					StatementStore<A, H, V, T> expressions) throws SemanticException {
		EVMAbstractState valueState = entryState.getDomainInstance(EVMAbstractState.class);

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

		Constant dummy = new Constant(Untyped.INSTANCE, Pair.of(trueStacks, falseStacks), getLocation());
		return entryState.smallStepSemantics(new it.unive.lisa.symbolic.value.UnaryExpression(Untyped.INSTANCE, dummy,
				JumpiOperator.INSTANCE, getLocation()), this);
	}
}