package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;
import it.unive.lisa.program.cfg.statement.evaluation.EvaluationOrder;
import it.unive.lisa.program.cfg.statement.evaluation.LeftToRightEvaluation;
import it.unive.lisa.type.Untyped;

/**
 * A Push5 opcode with a single sub-expression.
 */
public class Push5 extends Push {

	/**
	 * Builds the Push opcode, happening at the given location in the program.
	 * The static type of this expression is {@link Untyped}. The
	 * {@link EvaluationOrder} is {@link LeftToRightEvaluation}.
	 * 
	 * @param cfg        the cfg that this expression belongs to
	 * @param location   the location where the expression is defined within the
	 *                       program
	 * @param expression the {@link HexDecimalLiteral} expression of the jump
	 */
	public Push5(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH5", expression);
	}

	@Override
	public String toString() {
		return "PUSH5 " + getSubExpression();
	}
}