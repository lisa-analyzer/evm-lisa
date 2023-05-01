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
import it.unive.lisa.program.cfg.statement.evaluation.EvaluationOrder;
import it.unive.lisa.program.cfg.statement.evaluation.LeftToRightEvaluation;
import it.unive.lisa.symbolic.SymbolicExpression;
import it.unive.lisa.type.Untyped;
import java.math.BigInteger;

/**
 * A Push opcode with a single sub-expression.
 */
public abstract class Push extends UnaryExpression {

	/**
	 * Builds the Push opcode, happening at the given location in the program.
	 * The static type of this expression is {@link Untyped}. The
	 * {@link EvaluationOrder} is {@link LeftToRightEvaluation}.
	 * 
	 * @param cfg           the cfg that this expression belongs to
	 * @param location      the location where the expression is defined within
	 *                          the program
	 * @param constructName the name of the construct represented by this
	 *                          expression
	 * @param subExpression the sub-expression of this expression
	 */
	protected Push(CFG cfg, CodeLocation location, String constructName,
			Expression subExpression) {
		super(cfg, location, constructName, subExpression);
	}

	@Override
	public <A extends AbstractState<A, H, V, T>,
			H extends HeapDomain<H>,
			V extends ValueDomain<V>,
			T extends TypeDomain<T>> AnalysisState<A, H, V, T> unarySemantics(
					InterproceduralAnalysis<A, H, V, T> interprocedural, AnalysisState<A, H, V, T> state,
					SymbolicExpression expr, StatementStore<A, H, V, T> expressions) throws SemanticException {
		return state.smallStepSemantics(new it.unive.lisa.symbolic.value.UnaryExpression(getStaticType(), expr,
				PushOperator.INSTANCE, getLocation()), this);
	}

	/**
	 * Return the value of the bytes pushed into the stack by the Push opcode.
	 * 
	 * @return the BigInteger value
	 */
	public BigInteger getInt() {
		String hexadecimal = ((HexDecimalLiteral) getSubExpression()).getValue().substring(2);
		// return BigInteger.parseInt(hexadecimal, 16);
		return new BigInteger(hexadecimal, 16);
	}
}
