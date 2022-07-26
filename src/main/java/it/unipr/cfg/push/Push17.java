package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push17 extends Push {

	public Push17(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH17", expression);
	}

	@Override
	public String toString() {
		return "PUSH17 " + getSubExpression();
	}
}