package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Push32 extends Push {

	public Push32(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, "PUSH32", expression);
		// TODO Auto-generated constructor stub
	}

	@Override
	public String toString() {
		return "PUSH32 " + getSubExpression();
	}
}