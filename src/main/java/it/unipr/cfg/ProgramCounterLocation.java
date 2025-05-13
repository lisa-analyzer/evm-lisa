package it.unipr.cfg;

import it.unive.lisa.program.cfg.CodeLocation;
import java.util.Objects;

/**
 * Represent the code location of an opcode in the control flow graph.
 * 
 * @author <a href="mailto:vincenzo.arceri@unipr.it">Vincenzo Arceri</a>
 */
public class ProgramCounterLocation implements CodeLocation {

	/**
	 * The program counter.
	 */
	private final int pc;

	/**
	 * The source code line of the mnemonic bytecode.
	 */
	private final int sourceCodeLine;

	/**
	 * Builds a program counter location.
	 * 
	 * @param pc             the program counter
	 * @param sourceCodeLine the source code line
	 */
	public ProgramCounterLocation(int pc, int sourceCodeLine) {
		this.pc = pc;
		this.sourceCodeLine = sourceCodeLine;
	}

	/**
	 * Yields the program counter.
	 * 
	 * @return the program counter
	 */
	public int getPc() {
		return pc;
	}

	/**
	 * Yields the source code line.
	 * 
	 * @return the source code line
	 */
	public int getSourceCodeLine() {
		return sourceCodeLine;
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
