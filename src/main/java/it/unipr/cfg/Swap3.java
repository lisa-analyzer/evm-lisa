package it.unipr.cfg;

import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

/**
 * Swap3 opcode of the program to analyze.
 */
public class Swap3 extends Swap {

	/**
	 * Builds a Swap3 opcode happening at the given source location.
	 * 
	 * @param cfg      the cfg that this statement belongs to
	 * @param location the location where this statement is defined within the
	 *                     program
	 */
	public Swap3(CFG cfg, CodeLocation location) {
		super(cfg, location);
	}

	@Override
	public String toString() {
		return "SWAP3";
	}
}