package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push23 extends Push {

	public Push23(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH23", expression);
	}

	@Override
	public String toString() {
		return "PUSH23 " + getSubExpression();
	}
}