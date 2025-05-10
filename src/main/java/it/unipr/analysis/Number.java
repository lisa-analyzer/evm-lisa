package it.unipr.analysis;

import java.math.BigInteger;
import java.util.Objects;

/**
 * Custom class representing a number that can be implemented as an {@code int},
 * {@code long}, or {@code BigInteger}.
 * 
 * @author <a href="mailto:vincenzo.arceri@unipr.it">Vincenzo Arceri</a>
 * @author <a href="mailto:saveriomattia.merenda@studenti.unipr.it">Mattia
 *             Merenda</a>
 */
public class Number implements Comparable<Number> {
	/**
	 * Maximal representable integer value.
	 */
	public static final BigInteger MAX_INT = BigInteger.valueOf(2).pow(31);

	/**
	 * Maximal representable long value.
	 */
	public static final BigInteger MAX_LONG = BigInteger.valueOf(2).pow(63);

	public static final Number ZERO = new Number(0);
	public static final Number ONE = new Number(1);

	public enum Type {
		INT,
		LONG,
		BIGINTEGER
	}

	private final int i;
	private final long l;
	private final BigInteger b;

	/**
	 * Builds a number starting from an integer value.
	 * 
	 * @param i the integer value
	 */
	public Number(int i) {
		this.i = i;
		this.l = -1;
		this.b = null;
	}

	/**
	 * Builds a number starting from a long value.
	 * 
	 * @param l the long value
	 */
	public Number(long l) {
		this.l = l;
		this.b = null;
		this.i = -1;
	}

	public Number(BigInteger other) {
		if (other.compareTo(MAX_INT) < 0) {
			this.i = other.intValue();
			this.l = -1;
			this.b = null;
		} else if (other.compareTo(MAX_LONG) < 0) {
			this.i = -1;
			this.l = other.longValue();
			this.b = null;
		} else {
			this.i = -1;
			this.l = -1;
			this.b = other;
		}
	}

	/**
	 * Yields the backing implementation of the number.
	 * 
	 * @return the backing implementation of the number
	 */
	public Type getType() {
		if (b != null)
			return Type.BIGINTEGER;
		if (i != -1)
			return Type.INT;
		return Type.LONG;
	}

	/**
	 * Yields the integer value.
	 * 
	 * @return the integer value
	 */
	public int getInt() {
		return i;
	}

	/**
	 * Yields the long value.
	 * 
	 * @return the long value
	 */
	public long getLong() {
		return l;
	}

	/**
	 * Yields the big integer value.
	 * 
	 * @return the big integer value
	 */
	public BigInteger getBigInteger() {
		return b;
	}

	public static BigInteger toBigInteger(Number other) {
		BigInteger ot;
		if (other.getType() == Type.INT)
			ot = BigInteger.valueOf(other.getInt());
		else if (other.getType() == Type.LONG)
			ot = BigInteger.valueOf(other.getLong());
		else
			ot = other.getBigInteger();

		return ot;
	}

	/**
	 * Adds two numbers and returns the result as a {@code Number}.
	 * 
	 * @param other the number to add
	 * 
	 * @return the sum as a {@code Number}
	 */
	public Number add(Number other) {
		if (this.getType() == other.getType() && other.getType() == Type.INT)
			return new Number(i + other.getInt());
		if (this.getType() == other.getType() && other.getType() == Type.LONG)
			return new Number((long) l + other.getLong());

		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.add(ot));
	}

	/**
	 * Subtracts another number from this one and returns the result.
	 * 
	 * @param other the number to subtract
	 * 
	 * @return the result as a {@code Number}
	 */
	public Number subtract(Number other) {
		if (this.getType() == other.getType() && other.getType() == Type.INT)
			return new Number(i - other.getInt());
		if (this.getType() == other.getType() && other.getType() == Type.LONG)
			return new Number(l - other.getLong());

		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.subtract(ot));
	}

	/**
	 * Multiplies this number by another.
	 * 
	 * @param other the number to multiply by
	 * 
	 * @return the product as a {@code Number}
	 */
	public Number multiply(Number other) {
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);
		return new Number(me.multiply(ot));
	}

	/**
	 * Multiplies this number by another.
	 * 
	 * @param other the number to multiply by
	 * 
	 * @return the product as a {@code Number}
	 */
	public Number divide(Number other) {
		if (this.getType() == other.getType() && other.getType() == Type.INT)
			return new Number(i / other.getInt());
		if (this.getType() == other.getType() && other.getType() == Type.LONG)
			return new Number(l / other.getLong());

		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);
		return new Number(me.divide(ot));
	}

	/**
	 * Performs bitwise AND between two numbers.
	 * 
	 * @param other the number to AND with
	 * 
	 * @return the result as a {@code Number}
	 */
	public Number and(Number other) {
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);
		return new Number(me.and(ot));
	}

	/**
	 * Performs bitwise OR between two numbers.
	 * 
	 * @param other the number to OR with
	 * 
	 * @return the result as a {@code Number}
	 */
	public Number or(Number other) {
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);
		return new Number(me.or(ot));
	}

	/**
	 * Performs bitwise XOR between two numbers.
	 * 
	 * @param other the number to XOR with
	 * 
	 * @return the result as a {@code Number}
	 */
	public Number xor(Number other) {
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);
		return new Number(me.xor(ot));
	}

	/**
	 * Returns the bitwise NOT of this number.
	 *
	 * @return the bitwise complement as a {@code Number}
	 */
	public Number not() {
		BigInteger me = toBigInteger(this);
		return new Number(me.not());
	}

	/**
	 * Computes the modulo of this number by another number.
	 *
	 * @param other the number to divide by
	 * @return the result as a {@code Number}
	 */
	public Number modulo(Number other) {
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);
		return new Number(me.mod(ot));
	}

	/**
	 * Converts this number into a byte array.
	 * 
	 * @return the byte array representation
	 */
	public byte[] toByteArray() {
		BigInteger me = toBigInteger(this);
		return me.toByteArray();
	}

	/**
	 * Shifts this number right by a specified number of bits.
	 * 
	 * @param other the number of positions to shift
	 * 
	 * @return the shifted number
	 */
	public Number shiftRight(int other) {
		BigInteger me = toBigInteger(this);
		return new Number(me.shiftRight(other));
	}

	/**
	 * Shifts this number left by a specified number of bits.
	 * 
	 * @param other the number of positions to shift
	 * 
	 * @return the shifted number
	 */
	public Number shiftLeft(int other) {
		BigInteger me = toBigInteger(this);
		return new Number(me.shiftLeft(other));
	}

	@Override
	public String toString() {
		if (b != null)
			return b.toString();
		if (i != -1)
			return i + "";
		return l + "";
	}

	@Override
	public int compareTo(Number other) {
		if (getType() == other.getType()) {
			if (getType() == Type.INT)
				return Integer.compare(this.i, other.i);
			else if (getType() == Type.LONG)
				return Long.compare(this.l, other.l);
		}

		// Otherwise, fall back to BigInteger comparisons.
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);
		return me.compareTo(ot);
	}

	@Override
	public int hashCode() {
		return Objects.hash(toBigInteger(this));
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		Number other = (Number) obj;
		return Objects.equals(toBigInteger(this), toBigInteger(other));
	}
}