package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push7 extends Push {

	public Push7(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH7", expression);
	}

	@Override
	public String toString() {
		return "PUSH7 " + getSubExpression();
	}
}