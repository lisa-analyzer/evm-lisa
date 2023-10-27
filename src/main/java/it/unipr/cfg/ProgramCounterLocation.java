package it.unipr.cfg;

import it.unive.lisa.program.cfg.CodeLocation;
import java.util.Objects;

/**
 * Represent the code location of an opcode in the control flow graph.
 */
public class ProgramCounterLocation implements CodeLocation {

	private final int pc;
	private final int sourceCodeLine;

	/**
	 * Default constructor.
	 * 
	 * @param pc integer representing the code location of the opcode
	 */
	public ProgramCounterLocation(int pc, int sourceCodeLine) {
		this.pc = pc;
		this.sourceCodeLine = sourceCodeLine;
	}

	@Override
	public int compareTo(CodeLocation o) {
		if (o instanceof ProgramCounterLocation) {
			ProgramCounterLocation other = (ProgramCounterLocation) o;
			if (this.pc < other.pc)
				return -1;
			if (this.pc > other.pc)
				return 1;
			return 0;
		} else
			return -1;
	}

	public int getPc() {
		return pc;
	}

	@Override
	public String getCodeLocation() {
		return toString();
	}

	@Override
	public int hashCode() {
		return Objects.hash(pc);
	}

	@Override
	public String toString() {
		return String.valueOf(pc);
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
