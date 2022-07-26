package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push9 extends Push {

	public Push9(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH9", expression);
	}

	@Override
	public String toString() {
		return "PUSH9 " + getSubExpression();
	}
}