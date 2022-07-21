package it.unipr.cfg;

import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;
import it.unive.lisa.program.cfg.statement.literal.Literal;
import it.unive.lisa.type.Untyped;


public class HexDecimalLiteral extends Literal<String>{

	public HexDecimalLiteral(CFG cfg, CodeLocation location, String value) {
		super(cfg, location, value, Untyped.INSTANCE);
	}

}
