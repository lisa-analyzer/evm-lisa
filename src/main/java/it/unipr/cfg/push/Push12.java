package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push12 extends Push {

	public Push12(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH12", expression);
	}

	@Override
	public String toString() {
		return "PUSH12 " + getSubExpression();
	}
}