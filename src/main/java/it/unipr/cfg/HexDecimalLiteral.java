package it.unipr.cfg;

import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;
import it.unive.lisa.program.cfg.statement.literal.Literal;
import it.unive.lisa.type.Untyped;

/**
 * Represent an hexadecimal number with a string.
 */
public class HexDecimalLiteral extends Literal<String> {

	private final String value;

	/**
	 * Constructor of the hexadecimal.
	 * 
	 * @param cfg		the cfg that this hexadecimal belongs to
	 * @param location	the location where this hexadecimal is defined within the
	 *                  	program
	 * @param value the string value of the hexadecimal
	 */
	public HexDecimalLiteral(CFG cfg, CodeLocation location, String value) {
		super(cfg, location, value, Untyped.INSTANCE);
		this.value = value;
	}

	/**
	 * Convert the {@code hexadecimal} string into is hexadecimal value.
	 * 
	 * @return the int value of the hexadecimal literal
	 */
	public int ConvertFromHexToInt() {
		String hexadecimal = value.substring(2);
		return Integer.parseInt(hexadecimal, 16);
	}

}
