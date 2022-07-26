package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push20 extends Push {

	public Push20(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH20", expression);
	}

	@Override
	public String toString() {
		return "PUSH20 " + getSubExpression();
	}
}