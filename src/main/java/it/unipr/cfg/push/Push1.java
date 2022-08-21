package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push1 extends Push {

	public Push1(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH1", expression);
	}

	@Override
	public String toString() {
		return "PUSH1 " + getSubExpression();
	}
}
