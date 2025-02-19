package it.unipr.cfg.push;

import java.math.BigInteger;

import it.unipr.analysis.operator.PushOperator;
import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.analysis.AbstractState;
import it.unive.lisa.analysis.AnalysisState;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.StatementStore;
import it.unive.lisa.interprocedural.InterproceduralAnalysis;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;
import it.unive.lisa.program.cfg.statement.Expression;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.program.cfg.statement.UnaryExpression;
import it.unive.lisa.program.cfg.statement.evaluation.EvaluationOrder;
import it.unive.lisa.program.cfg.statement.evaluation.LeftToRightEvaluation;
import it.unive.lisa.symbolic.SymbolicExpression;
import it.unive.lisa.type.Untyped;

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
	public <A extends AbstractState<A>> AnalysisState<A> fwdUnarySemantics(InterproceduralAnalysis<A> interprocedural,
			AnalysisState<A> state, SymbolicExpression expr, StatementStore<A> expressions) throws SemanticException {

		return state.smallStepSemantics(new it.unive.lisa.symbolic.value.UnaryExpression(getStaticType(), expr,
				PushOperator.INSTANCE, getLocation()), this);
	}

	/**
	 * Returns the value of the bytes pushed into the stack by the PUSH opcode.
	 * 
	 * @return the BigInteger value
	 */
	public BigInteger getInt() {
		String hexadecimal = ((HexDecimalLiteral) getSubExpression()).getValue().substring(2);
		return new BigInteger(hexadecimal, 16);
	}

	@Override
	protected int compareSameClassAndParams(Statement o) {
		// we cannot have more than one statement on the same code location
		return 0;
	}
}
