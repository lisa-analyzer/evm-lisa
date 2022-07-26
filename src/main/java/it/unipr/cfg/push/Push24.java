package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push24 extends Push {

	public Push24(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH24", expression);
	}

	@Override
	public String toString() {
		return "PUSH24 " + getSubExpression();
	}
}