package it.unipr.cfg.push;

import it.unipr.analysis.PushOperator;
import it.unipr.cfg.HexDecimalLiteral;
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
import it.unive.lisa.program.cfg.statement.Expression;
import it.unive.lisa.program.cfg.statement.UnaryExpression;
import it.unive.lisa.symbolic.SymbolicExpression;

public abstract class Push extends UnaryExpression {

	protected Push(CFG cfg, CodeLocation location, String constructName,
			Expression subExpression) {
		super(cfg, location, constructName, subExpression);
	}

	@Override
	protected <A extends AbstractState<A, H, V, T>,
			H extends HeapDomain<H>,
			V extends ValueDomain<V>,
			T extends TypeDomain<T>> AnalysisState<A, H, V, T> unarySemantics(
					InterproceduralAnalysis<A, H, V, T> interprocedural, AnalysisState<A, H, V, T> state,
					SymbolicExpression expr, StatementStore<A, H, V, T> expressions) throws SemanticException {
		return state.smallStepSemantics(new it.unive.lisa.symbolic.value.UnaryExpression(getStaticType(), expr,
				PushOperator.INSTANCE, getLocation()), this);
	}

	public int getInt() {
		String hexadecimal = ((HexDecimalLiteral) getSubExpression()).getValue().substring(2);
		return Integer.parseInt(hexadecimal, 16);
	}
}
