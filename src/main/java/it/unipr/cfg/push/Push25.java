package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push25 extends Push {

	public Push25(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH25", expression);
	}

	@Override
	public String toString() {
		return "PUSH25 " + getSubExpression();
	}
}