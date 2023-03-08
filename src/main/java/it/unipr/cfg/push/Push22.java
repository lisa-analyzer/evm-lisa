package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

/**
 * A Push22 opcode with a single sub-expression.
 */
public class Push22 extends Push {

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
	public Push22(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH22", expression);
	}

	@Override
	public String toString() {
		return "PUSH22 " + getSubExpression();
	}
}