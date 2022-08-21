package it.unipr.cfg;

import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;

public class Dup16 extends Dup {

	public Dup16(CFG cfg, CodeLocation location) {
		super(cfg, location);
	}

	@Override
	public String toString() {
		return "DUP16";
	}
}