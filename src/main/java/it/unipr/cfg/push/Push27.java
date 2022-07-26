package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push27 extends Push {

	public Push27(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH27", expression);
		// TODO Auto-generated constructor stub
	}

	@Override
	public String toString() {
		return "PUSH27 " + getSubExpression();
	}
}