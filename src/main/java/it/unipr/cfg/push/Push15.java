package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push15 extends Push {

	public Push15(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH15", expression);
	}

	@Override
	public String toString() {
		return "PUSH15 " + getSubExpression();
	}
}