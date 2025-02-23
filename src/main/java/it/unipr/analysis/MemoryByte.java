package it.unipr.analysis;

import it.unive.lisa.analysis.*;
import it.unive.lisa.analysis.lattices.Satisfiability;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.program.cfg.ProgramPoint;
import it.unive.lisa.symbolic.value.Identifier;
import it.unive.lisa.symbolic.value.ValueExpression;
import it.unive.lisa.util.representation.StringRepresentation;
import it.unive.lisa.util.representation.StructuredRepresentation;
import java.util.Arrays;
import java.util.Objects;
import java.util.function.Predicate;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class MemoryByte implements ValueDomain<MemoryByte>, BaseLattice<MemoryByte> {
	private static final Logger log = LogManager.getLogger(MemoryByte.class);

	private static final int WORD_SIZE = 32;
	private byte[] memory;
	private final boolean isTop;
	public static final MemoryByte BOTTOM = new MemoryByte(null);
	public static final MemoryByte TOP = new MemoryByte(null, true);

	public MemoryByte() {
		this(new byte[0]);
	}

	public MemoryByte(byte[] memory) {
		this.memory = memory;
		this.isTop = false;
	}

	public MemoryByte(byte[] memory, boolean isTop) {
		this.memory = memory;
		this.isTop = isTop;
	}

	public void mstore(int offset, byte[] value) {
		if (value.length != WORD_SIZE) {
			throw new IllegalArgumentException("The value must be 32 bytes");
		}

		ensureCapacity(offset + WORD_SIZE);

		System.arraycopy(value, 0, memory, offset, WORD_SIZE);
	}

	public void mstore8(int offset, byte value) {
		ensureCapacity(offset + 1);
		memory[offset] = value;
	}

	public byte[] mload(int offset) {
		ensureCapacity(offset + WORD_SIZE);

		byte[] result = new byte[WORD_SIZE];
		System.arraycopy(memory, offset, result, 0, WORD_SIZE);

		return result;
	}

	private void ensureCapacity(int size) {
		if (size > memory.length) {
			byte[] newMemory = new byte[size];
			Arrays.fill(newMemory, (byte) 0);
			System.arraycopy(memory, 0, newMemory, 0, memory.length);
			memory = newMemory;
		}
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + Arrays.hashCode(memory);
		result = prime * result + Objects.hash(isTop);
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		MemoryByte other = (MemoryByte) obj;
		return isTop == other.isTop && Arrays.equals(memory, other.memory);
	}

	@Override
	public MemoryByte clone() {
		if (isTop())
			return TOP;
		else if (isBottom())
			return BOTTOM;
		MemoryByte cloned = new MemoryByte(Arrays.copyOf(this.memory, this.memory.length), false);
		return cloned;
	}

	@Override
	public String toString() {
		if (isTop)
			return Lattice.TOP_STRING;
		else if (memory == null)
			return Lattice.BOTTOM_STRING;
		else if (memory.length == 0)
			return "EMPTY";

		StringBuilder hexString = new StringBuilder("");
		for (byte b : memory)
			hexString.append(String.format("%02X", b));

		return hexString.toString();
	}

	@Override
	public MemoryByte lubAux(MemoryByte other) throws SemanticException {
		return TOP;
	}

	@Override
	public boolean lessOrEqualAux(MemoryByte other) throws SemanticException {
		return false;
	}

	@Override
	public MemoryByte top() {
		return TOP;
	}

	@Override
	public boolean isTop() {
		return isTop;
	}

	@Override
	public MemoryByte bottom() {
		return BOTTOM;
	}

	@Override
	public boolean isBottom() {
		return memory == null && !isTop;
	}

	@Override
	public MemoryByte assign(Identifier id, ValueExpression expression, ProgramPoint pp, SemanticOracle oracle)
			throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public MemoryByte smallStepSemantics(ValueExpression expression, ProgramPoint pp, SemanticOracle oracle)
			throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public MemoryByte assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest, SemanticOracle oracle)
			throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public boolean knowsIdentifier(Identifier id) {
		return false;
	}

	@Override
	public MemoryByte forgetIdentifier(Identifier id) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public MemoryByte forgetIdentifiersIf(Predicate<Identifier> test) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public Satisfiability satisfies(ValueExpression expression, ProgramPoint pp, SemanticOracle oracle)
			throws SemanticException {
		// nothing to do here
		return Satisfiability.UNKNOWN;
	}

	@Override
	public MemoryByte pushScope(ScopeToken token) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public MemoryByte popScope(ScopeToken token) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public StructuredRepresentation representation() {
		if (isTop())
			return Lattice.topRepresentation();
		else if (isBottom())
			return Lattice.bottomRepresentation();

		StringBuilder hexString = new StringBuilder("");
		for (byte b : memory) {
			hexString.append(String.format("%02X", b));
		}

		return new StringRepresentation(hexString.toString());
	}

	static public String printBytes(byte[] bytes) {
		StringBuilder hexString = new StringBuilder("");
		for (byte b : bytes)
			hexString.append(String.format("%02X", b));

		if (hexString.length() == 0)
			hexString.append("0");

		return hexString.toString();
	}
}