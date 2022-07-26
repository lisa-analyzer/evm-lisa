package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push14 extends Push {

	public Push14(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH14", expression);
	}

	@Override
	public String toString() {
		return "PUSH14 " + getSubExpression();
	}
}