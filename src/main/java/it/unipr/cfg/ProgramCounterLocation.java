package it.unipr.cfg;

import java.util.Objects;

import it.unive.lisa.program.cfg.CodeLocation;

public class ProgramCounterLocation implements CodeLocation{

	private final int pc;

	public ProgramCounterLocation(int pc) {
		this.pc = pc;
	}
	
	@Override
	public int compareTo(CodeLocation o) {
		// TODO Auto-generated method stub
		return 0;
	}

	@Override
	public String getCodeLocation() {
		// TODO Auto-generated method stub
		return null;
	}
	
	@Override
	public int hashCode() {
		return Objects.hash(pc);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		ProgramCounterLocation other = (ProgramCounterLocation) obj;
		return pc == other.pc;
	}
	
}
