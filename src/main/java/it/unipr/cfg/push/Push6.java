package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push6 extends Push {

	public Push6(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH6", expression);
		// TODO Auto-generated constructor stub
	}

	@Override
	public String toString() {
		return "PUSH6 " + getSubExpression();
	}
}