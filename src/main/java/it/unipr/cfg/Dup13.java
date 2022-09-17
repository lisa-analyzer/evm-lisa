package it.unipr.cfg;

import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

/**
 * Dup13 opcode of the program to analyze.
 */
public class Dup13 extends Dup {

	/**
	 * Builds a Dup13 opcode happening at the given source location.
	 * 
	 * @param cfg      the cfg that this statement belongs to
	 * @param location the location where this statement is defined within the
	 *                     program
	 */
	public Dup13(CFG cfg, CodeLocation location) {
		super(cfg, location);
	}

	@Override
	public String toString() {
		return "DUP13";
	}
}