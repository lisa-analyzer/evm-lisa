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
import java.math.BigInteger;
import java.util.Arrays;
import java.util.Objects;
import java.util.function.Predicate;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class AbstractMemory implements ValueDomain<AbstractMemory>, BaseLattice<AbstractMemory> {
	private static final Logger log = LogManager.getLogger(AbstractMemory.class);
	private static final int WORD_SIZE = 32;
	private final AbstractByte[] memory;
	private final boolean isTop;
	public static final AbstractMemory BOTTOM = new AbstractMemory(null);
	public static final AbstractMemory TOP = new AbstractMemory(null, true);

	public AbstractMemory() {
		this(new AbstractByte[0]);
	}

	public AbstractMemory(AbstractByte[] memory) {
		this.memory = memory;
		this.isTop = false;
	}

	public AbstractMemory(AbstractByte[] memory, boolean isTop) {
		this.memory = memory;
		this.isTop = isTop;
	}

	public AbstractMemory mstore(int offset, StackElement e) {
		if (e.isTop() || e.isTopNotJumpdest()) {
			AbstractByte[] value = unknownBytes();
			AbstractByte[] newMemory = ensureCapacity(offset + WORD_SIZE);
			System.arraycopy(value, 0, newMemory, offset, WORD_SIZE);
			return new AbstractMemory(newMemory);
		} else {
			AbstractByte[] value = convertStackElementToBytes(e);
			if (value.length != WORD_SIZE) {
				throw new IllegalArgumentException("The value must be 32 bytes");
			}
			AbstractByte[] newMemory = ensureCapacity(offset + WORD_SIZE);
			System.arraycopy(value, 0, newMemory, offset, WORD_SIZE);
			return new AbstractMemory(newMemory);
		}
	}

	public AbstractMemory mstore8(int offset, AbstractByte value) {
		AbstractByte[] newMemory = ensureCapacity(offset + 1);
		newMemory[offset] = value;
		return new AbstractMemory(newMemory);
	}

	public StackElement mload(int offset) {
		AbstractByte[] newMemory = ensureCapacity(offset + WORD_SIZE);
		AbstractByte[] result = new AbstractByte[WORD_SIZE];
		System.arraycopy(newMemory, offset, result, 0, WORD_SIZE);

		if (isUnknown(result))
			return StackElement.TOP;

		return StackElement.fromBytes(result);
	}

	public AbstractMemory mcopy(int destOffset, int srcOffset, int length) {
		if (length <= 0)
			return this;

		AbstractByte[] newMemory = ensureCapacity(Math.max(destOffset + length, srcOffset + length));
		int availableSrc = Math.min(srcOffset + length, memory.length) - srcOffset;
		int copyLength = Math.min(availableSrc, length);

		if (copyLength > 0)
			System.arraycopy(memory, srcOffset, newMemory, destOffset, copyLength);

		return new AbstractMemory(newMemory);
	}

	private AbstractByte[] ensureCapacity(int size) {
		int alignedSize = ((size + 31) / 32) * 32;
		if (alignedSize <= memory.length)
			return Arrays.copyOf(memory, memory.length);

		AbstractByte[] newMemory = new AbstractByte[alignedSize];
		AbstractMemory.fill(newMemory, (byte) 0);
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
		return new AbstractMemory(Arrays.copyOf(this.memory, this.memory.length), false);
	}

	@Override
	public String toString() {
		if (isTop)
			return Lattice.TOP_STRING;
		else if (memory == null)
			return Lattice.BOTTOM_STRING;
		StringBuilder hexString = new StringBuilder();
		for (AbstractByte b : memory)
			hexString.append(b);
		if (memory.length == 0 || hexString.toString().matches("^0+$"))
			return "EMPTY";
		return hexString.toString();
	}

	@Override
	public AbstractMemory lubAux(AbstractMemory other) {
		int maxLength = Math.max(this.memory.length, other.memory.length);
		AbstractByte[] result = new AbstractByte[maxLength];

		for (int i = 0; i < maxLength; i++) {
			if (i < this.memory.length && this.memory[i].isTop())
				result[i] = new AbstractByte(); // top
			else if (i < other.memory.length && other.memory[i].isTop())
				result[i] = new AbstractByte(); // top
			else {
				AbstractByte b1 = i < this.memory.length ? this.memory[i] : new AbstractByte(0);
				AbstractByte b2 = i < other.memory.length ? other.memory[i] : new AbstractByte(0);
				result[i] = (b1 == b2) ? b1 : new AbstractByte();
			}
		}
		return new AbstractMemory(result);
	}

	@Override
	public boolean lessOrEqualAux(AbstractMemory other) {
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
		for (AbstractByte b : memory) {
			hexString.append(b);
		}
		if (memory.length == 0 || hexString.toString().matches("^0+$"))
			return new StringRepresentation("EMPTY");
		return new StringRepresentation(hexString.toString());
	}

	static public String printBytes(AbstractByte[] bytes) {
		StringBuilder hexString = new StringBuilder();
		for (AbstractByte b : bytes)
			hexString.append(b);
		if (hexString.length() == 0)
			hexString.append("0");
		return hexString.toString();
	}

	private AbstractByte[] convertStackElementToBytes(StackElement element) {
		AbstractByte[] bytes = new AbstractByte[32];
		BigInteger bigIntValue = Number.toBigInteger(element.getNumber());
		for (int i = 0; i < 32; i++) {
			bytes[31 - i] = new AbstractByte(bigIntValue.shiftRight(i * 8).byteValue());
		}
		return bytes;
	}

	private AbstractByte[] unknownBytes() {
		AbstractByte[] bytes = new AbstractByte[32];
		for (int i = 0; i < 32; i++)
			bytes[i] = new AbstractByte();
		return bytes;
	}

	public static void fill(AbstractByte[] bytes, byte value) {
		for (int i = 0; i < bytes.length; i++) {
			bytes[i] = new AbstractByte(value);
		}
	}

	private static boolean isUnknown(AbstractByte[] bytes) {
		for (int i = 0; i < 32; i++)
			if (bytes[i].isTop())
				return true;
		return false;
	}
}