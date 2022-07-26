package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push21 extends Push {

	public Push21(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH21", expression);
	}

	@Override
	public String toString() {
		return "PUSH21 " + getSubExpression();
	}
}