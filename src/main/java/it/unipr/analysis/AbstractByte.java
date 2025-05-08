package it.unipr.analysis;

import java.util.Objects;

public class AbstractByte {
	
	public static final AbstractByte UNKNOWN = new AbstractByte();
	private final byte value;
	private final boolean isTop;

	/**
	 * Constructs an Abstract Byte representing the top element (unknown value).
	 */
	private AbstractByte() {
		this((byte) 0, true);
	}

	/**
	 * Constructs an Abstract Byte with a concrete integer value.
	 *
	 * @param value the integer value to wrap as a byte
	 */
	public AbstractByte(int value) {
		this((byte) value, false);
	}

	/**
	 * Constructs an Abstract Byte with a concrete byte value.
	 *
	 * @param value the byte value to encapsulate
	 */
	public AbstractByte(byte value) {
		this(value, false);
	}

	/**
	 * Constructs an Abstract Byte with the specified byte value and Top flag.
	 *
	 * @param value the byte value to encapsulate
	 * @param isTop if true, this instance represents an unknown (Top) value
	 */
	public AbstractByte(byte value, boolean isTop) {
		this.value = value;
		this.isTop = isTop;
	}

	/**
	 * Retrieves the concrete byte value of this abstract element.
	 *
	 * @return the stored byte value
	 */
	public byte getValue() {
		if (isTop())
			throw new RuntimeException("Cannot retrieve the value of a top abstract byte");
		return value;
	}

	/**
	 * Indicates whether this Abstract Byte represents the Top element
	 *
	 * @return true if this is the Top element, false otherwise
	 */
	public boolean isTop() {
		return isTop;
	}

	@Override
	public boolean equals(Object o) {
		if (this == o)
			return true;
		if (o == null)
			return false;
		if (!(o instanceof AbstractByte))
			return false;
		AbstractByte that = (AbstractByte) o;
		return value == that.value && isTop == that.isTop;
	}

	@Override
	public int hashCode() {
		return Objects.hash(value, isTop);
	}

	@Override
	public String toString() {
		return this.isTop() ? "T" : String.format("%02X", value);
	}
}
