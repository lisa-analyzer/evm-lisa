package it.unipr.cfg;

import it.unive.lisa.program.cfg.CodeLocation;
import java.util.Objects;

/**
 * Represent the code location of an opcode in the control flow graph.
 */
public class ProgramCounterLocation implements CodeLocation {

	private final int pc;
	private final int sourceCodeLine;
	private final int cfgHashCode;

	/**
	 * Constructs a {@code ProgramCounterLocation} with the specified program
	 * counter (PC) and source code line.
	 *
	 * @param pc             the integer representing the code location of the
	 *                           opcode
	 * @param sourceCodeLine the corresponding line number in the source code
	 */
	public ProgramCounterLocation(int pc, int sourceCodeLine) {
		this(pc, sourceCodeLine, 0);
	}

	/**
	 * Constructs a {@code ProgramCounterLocation} with the specified program
	 * counter (PC), source code line, and control flow graph (CFG) hash code.
	 *
	 * @param pc             the integer representing the code location of the
	 *                           opcode
	 * @param sourceCodeLine the corresponding line number in the source code
	 * @param cfgHashCode    the hash code of the associated control flow graph
	 *                           (CFG)
	 */
	public ProgramCounterLocation(int pc, int sourceCodeLine, int cfgHashCode) {
		this.pc = pc;
		this.sourceCodeLine = sourceCodeLine;
		this.cfgHashCode = cfgHashCode;
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
		return Objects.hash(pc) + Objects.hash(sourceCodeLine) + Objects.hash(cfgHashCode);
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
		return pc == other.pc && cfgHashCode == other.cfgHashCode && sourceCodeLine == other.sourceCodeLine;
	}

	/**
	 * @return the source code line
	 */
	public int getSourceCodeLine() {
		return sourceCodeLine;
	}

}
