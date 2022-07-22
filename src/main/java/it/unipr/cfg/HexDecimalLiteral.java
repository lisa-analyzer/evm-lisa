package it.unipr.cfg;

import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;
import it.unive.lisa.program.cfg.statement.literal.Literal;
import it.unive.lisa.type.Untyped;


public class HexDecimalLiteral extends Literal<String>{
	
	private final String value;

	public HexDecimalLiteral(CFG cfg, CodeLocation location, String value) {
		super(cfg, location, value, Untyped.INSTANCE);
		this.value = value;
	}
	
	public int ConvertFromHexToInt() {
		String hexadecimal = value.substring(2);
		return Integer.parseInt(hexadecimal, 16);
	}

}
