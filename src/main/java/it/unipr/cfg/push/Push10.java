package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push10 extends Push {

	public Push10(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH10", expression);
	}

	@Override
	public String toString() {
		return "PUSH10 " + getSubExpression();
	}
}