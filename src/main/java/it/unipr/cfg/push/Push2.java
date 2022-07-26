package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push2 extends Push {

	public Push2(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH2", expression);
	}

	@Override
	public String toString() {
		return "PUSH2 " + getSubExpression();
	}
}