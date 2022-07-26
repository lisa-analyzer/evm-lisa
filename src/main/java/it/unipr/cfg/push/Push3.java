package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push3 extends Push {

	public Push3(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH3", expression);
	}

	@Override
	public String toString() {
		return "PUSH3 " + getSubExpression();
	}
}