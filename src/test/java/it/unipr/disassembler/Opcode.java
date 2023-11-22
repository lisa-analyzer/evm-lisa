package it.unipr.disassembler;

import java.math.BigInteger;

/**
 * The Opcode class represents an Ethereum opcode with its associated offset,
 * opcode type, and optional parameter. It is used in the Disassembler class to
 * store and retrieve information about each opcode during the disassembly
 * process.
 * <p>
 * An Opcode instance can be constructed with or without an offset value. The
 * class provides getters and setters for the opcode, parameter, and offset.
 * Additionally, it overrides the toString method to generate a human-readable
 * string representation of the opcode, including its offset, name, and
 * parameter (if present).
 */
public class Opcode {

	private int offset;
	private Opcodes opcode;
	private BigInteger parameter;

	public Opcode() {
	}

	public Opcode(int offset, Opcodes opcode, BigInteger parameter) {
		this.offset = offset;
		this.opcode = opcode;
		this.parameter = parameter;
	}

	public Opcode(Opcodes opcode, BigInteger parameter) {
		this.opcode = opcode;
		this.parameter = parameter;
	}

	public Opcodes getOpcode() {
		return opcode;
	}

	void setOpcode(Opcodes opcode) {
		this.opcode = opcode;
	}

	public BigInteger getParameter() {
		return parameter;
	}

	void setParameter(BigInteger parameter) {
		this.parameter = parameter;
	}

	public int getOffset() {
		return offset;
	}

	public void setOffset(int offset) {
		this.offset = offset;
	}

	@Override
	public String toString() {
		// String toString = "0x" + String.format("%03X", this.offset) + " " +
		// this.opcode.name();
		String toString = this.opcode.name();
		if (parameter != null) {
			toString += " 0x" + parameter.toString(16);
		}
		return toString;
	}
}