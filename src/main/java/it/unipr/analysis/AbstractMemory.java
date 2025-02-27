package it.unipr.analysis;

import it.unive.lisa.analysis.BaseLattice;
import it.unive.lisa.analysis.Lattice;
import it.unive.lisa.analysis.ScopeToken;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.SemanticOracle;
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

public class AbstractMemory implements ValueDomain<AbstractMemory>, BaseLattice<AbstractMemory> {
	private static final Logger log = LogManager.getLogger(AbstractMemory.class);

	private static final int WORD_SIZE = 32;
	private final byte[] memory;
	private final boolean isTop;
	public static final AbstractMemory BOTTOM = new AbstractMemory(null);
	public static final AbstractMemory TOP = new AbstractMemory(null, true);

	public AbstractMemory() {
		this(new byte[0]);
	}

	public AbstractMemory(byte[] memory) {
		this.memory = memory;
		this.isTop = false;
	}

	public AbstractMemory(byte[] memory, boolean isTop) {
		this.memory = memory;
		this.isTop = isTop;
	}

	public AbstractMemory mstore(int offset, byte[] value) {
		if (value.length != WORD_SIZE) {
			throw new IllegalArgumentException("The value must be 32 bytes");
		}
		byte[] newMemory = ensureCapacity(offset + WORD_SIZE);
		System.arraycopy(value, 0, newMemory, offset, WORD_SIZE);
		return new AbstractMemory(newMemory);
	}

	public AbstractMemory mstore8(int offset, byte value) {
		byte[] newMemory = ensureCapacity(offset + 1);
		newMemory[offset] = value;
		return new AbstractMemory(newMemory);
	}

	public byte[] mload(int offset) {
		byte[] newMemory = ensureCapacity(offset + WORD_SIZE);
		byte[] result = new byte[WORD_SIZE];
		System.arraycopy(newMemory, offset, result, 0, WORD_SIZE);
		return result;
	}

	public AbstractMemory mcopy(int destOffset, int srcOffset, int length) {
		if (length <= 0)
			return this;

		byte[] newMemory = ensureCapacity(Math.max(destOffset + length, srcOffset + length));

		int availableSrc = Math.min(srcOffset + length, memory.length) - srcOffset;
		int copyLength = Math.min(availableSrc, length);

		if (copyLength > 0)
			System.arraycopy(memory, srcOffset, newMemory, destOffset, copyLength);

		return new AbstractMemory(newMemory);
	}

	private byte[] ensureCapacity(int size) {
		int alignedSize = ((size + 31) / 32) * 32;
		if (alignedSize <= memory.length) {
			return Arrays.copyOf(memory, memory.length);
		}
		byte[] newMemory = new byte[alignedSize];
		Arrays.fill(newMemory, (byte) 0);
		System.arraycopy(memory, 0, newMemory, 0, memory.length);
		return newMemory;
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
		AbstractMemory other = (AbstractMemory) obj;
		return isTop == other.isTop && Arrays.equals(memory, other.memory);
	}

	@Override
	public AbstractMemory clone() {
		if (isTop())
			return TOP;
		else if (isBottom())
			return BOTTOM;
		AbstractMemory cloned = new AbstractMemory(Arrays.copyOf(this.memory, this.memory.length), false);
		return cloned;
	}

	@Override
	public String toString() {
		if (isTop)
			return Lattice.TOP_STRING;
		else if (memory == null)
			return Lattice.BOTTOM_STRING;

		StringBuilder hexString = new StringBuilder("");
		for (byte b : memory)
			hexString.append(String.format("%02X", b));

		if (memory.length == 0 || hexString.toString().matches("^0+$"))
			return "EMPTY";

		return hexString.toString();
	}

	@Override
	public AbstractMemory lubAux(AbstractMemory other) throws SemanticException {
		return TOP;
	}

	@Override
	public boolean lessOrEqualAux(AbstractMemory other) throws SemanticException {
		return false;
	}

	@Override
	public AbstractMemory top() {
		return TOP;
	}

	@Override
	public boolean isTop() {
		return isTop;
	}

	@Override
	public AbstractMemory bottom() {
		return BOTTOM;
	}

	@Override
	public boolean isBottom() {
		return memory == null && !isTop;
	}

	@Override
	public AbstractMemory assign(Identifier id, ValueExpression expression, ProgramPoint pp, SemanticOracle oracle)
			throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public AbstractMemory smallStepSemantics(ValueExpression expression, ProgramPoint pp, SemanticOracle oracle)
			throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public AbstractMemory assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest, SemanticOracle oracle)
			throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public boolean knowsIdentifier(Identifier id) {
		return false;
	}

	@Override
	public AbstractMemory forgetIdentifier(Identifier id) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public AbstractMemory forgetIdentifiersIf(Predicate<Identifier> test) throws SemanticException {
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
	public AbstractMemory pushScope(ScopeToken token) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public AbstractMemory popScope(ScopeToken token) throws SemanticException {
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

		if (memory.length == 0 || hexString.toString().matches("^0+$"))
			return new StringRepresentation("EMPTY");

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