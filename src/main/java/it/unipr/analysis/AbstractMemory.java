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

	public static final int MAX_MEMORY_SIZE = 1024 * 1024 * 32; // 32 MB
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

	public AbstractMemory mstore(StackElement offset, StackElement e) {
		if (offset.isTop() || offset.isTopNotJumpdest()) {
			log.warn("Offset is TOP, ignoring mstore with offset {}, value {}.", offset, e);
			return AbstractMemory.TOP;
		}

		if (offset.compareTo(new StackElement(MAX_MEMORY_SIZE)) >= 0) {
			log.warn("Offset is greater than max memory size, ignoring mstore with offset {}, value {}.", offset, e);
			return AbstractMemory.BOTTOM;
		}
		
		int offsetInt = offset.getNumber().getInt();

		if (e.isTop() || e.isTopNotJumpdest()) {
			AbstractByte[] value = unknownBytes();
			AbstractByte[] newMemory = ensureCapacity(offsetInt + WORD_SIZE);
			System.arraycopy(value, 0, newMemory, offsetInt, WORD_SIZE);
			return new AbstractMemory(newMemory);
		} else {
			AbstractByte[] value = convertStackElementToBytes(e);
			if (value.length != WORD_SIZE) {
				throw new IllegalArgumentException("The value must be 32 bytes");
			}
			AbstractByte[] newMemory = ensureCapacity(offsetInt + WORD_SIZE);
			System.arraycopy(value, 0, newMemory, offsetInt, WORD_SIZE);
			return new AbstractMemory(newMemory);
		}
	}

	public AbstractMemory mstore8(StackElement offset, StackElement value) {
		if (offset.compareTo(new StackElement(MAX_MEMORY_SIZE)) >= 0) {
			log.warn("Offset or value are greater than max memory size, ignoring mstore8 with offset {} and value {}.", offset, value);
			return AbstractMemory.BOTTOM;
		}

		int offsetInt = offset.getNumber().getInt();
		Number result = value.getNumber().modulo(new Number(256));

		AbstractByte valueByte = (value.isTop() || value.isTopNotJumpdest())
				? AbstractByte.UNKNOWN
				: new AbstractByte(result.getInt());

		AbstractByte[] newMemory = ensureCapacity(offsetInt + 1);
		newMemory[offsetInt] = valueByte;
		return new AbstractMemory(newMemory);
	}

	public StackElement mload(StackElement offset) {
		if (offset.compareTo(new StackElement(MAX_MEMORY_SIZE)) >= 0) {
			log.warn("Offset is greater than max memory size, ignoring mload with offset {}.", offset);
			return StackElement.BOTTOM;
		} else if (offset.compareTo(new StackElement(Number.MAX_INT)) >= 0) {
			log.warn("Offset is greater than max int representation, ignoring mload with offset {}.", offset);
			return StackElement.BOTTOM; // fake path
		}

		int value = offset.getNumber().getInt();

		AbstractByte[] newMemory = ensureCapacity(value + WORD_SIZE);
		AbstractByte[] result = new AbstractByte[WORD_SIZE];
		System.arraycopy(newMemory, value, result, 0, WORD_SIZE);

		if (isUnknown(result))
			return StackElement.TOP;

		return StackElement.fromBytes(result);
	}

	public AbstractMemory mcopy(StackElement destOffset, StackElement srcOffset, StackElement length) {
		if (length.compareTo(new StackElement(MAX_MEMORY_SIZE)) >= 0) {
			log.warn("length is greater than max memory size, ignoring mcopy with destOffset {}, srcOffset {}, length {}.", destOffset, srcOffset, length);
			return AbstractMemory.TOP;
		} else if (destOffset.compareTo(new StackElement(MAX_MEMORY_SIZE)) >= 0) {
			log.warn("destOffset is greater than max memory size, ignoring mcopy with destOffset {}, srcOffset {}, length {}.", destOffset, srcOffset, length);
			return AbstractMemory.TOP;
		} else if (srcOffset.compareTo(new StackElement(MAX_MEMORY_SIZE)) >= 0) {
			log.warn("srcOffset is greater than max memory size, ignoring mcopy with destOffset {}, srcOffset {}, length {}.", destOffset, srcOffset, length);
			return AbstractMemory.TOP;
		}

		if (destOffset.compareTo(new StackElement(Number.MAX_INT)) >= 0) {
			log.warn("destOffset is greater than max int representation, ignoring mcopy with destOffset {}, srcOffset {}, length {}.", destOffset, srcOffset, length);
			return AbstractMemory.BOTTOM; // fake path
		} else if (srcOffset.compareTo(new StackElement(Number.MAX_INT)) >= 0) {
			log.warn("srcOffset is greater than max int representation, ignoring mcopy with destOffset {}, srcOffset {}, length {}.", destOffset, srcOffset, length);
			return AbstractMemory.BOTTOM; // fake path
		} else if (length.compareTo(new StackElement(Number.MAX_INT)) >= 0) {
			log.warn("length is greater than max int representation, ignoring mcopy with destOffset {}, srcOffset {}, length {}.", destOffset, srcOffset, length);
			return AbstractMemory.BOTTOM; // fake path
		}

		int srcOffsetInt = srcOffset.getNumber().getInt();
		int destOffsetInt = destOffset.getNumber().getInt();
		int lengthInt = length.getNumber().getInt();

		AbstractByte[] newMemory = ensureCapacity(Math.max(destOffsetInt + lengthInt, srcOffsetInt + lengthInt));
		int availableSrc = Math.min(srcOffsetInt + lengthInt, memory.length) - srcOffsetInt;
		int copyLength = Math.min(availableSrc, lengthInt);

		if (copyLength > 0)
			System.arraycopy(memory, srcOffsetInt, newMemory, destOffsetInt, copyLength);

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
				result[i] = AbstractByte.UNKNOWN;
			else if (i < other.memory.length && other.memory[i].isTop())
				result[i] = AbstractByte.UNKNOWN;
			else {
				AbstractByte b1 = i < this.memory.length ? this.memory[i] : new AbstractByte(0);
				AbstractByte b2 = i < other.memory.length ? other.memory[i] : new AbstractByte(0);
				result[i] = (b1.equals(b2)) ? b1 : AbstractByte.UNKNOWN;
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
			bytes[i] = AbstractByte.UNKNOWN;
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