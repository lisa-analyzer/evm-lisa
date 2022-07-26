package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push4 extends Push {

	public Push4(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH4", expression);
	}

	@Override
	public String toString() {
		return "PUSH4 " + getSubExpression();
	}
}