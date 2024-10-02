package it.unipr.analysis;

import java.math.BigInteger;
import java.nio.ByteBuffer;
import java.util.Objects;

public class Number implements Comparable<Number> {

	static enum Type {
		LONG,
		BIGINTEGER
	}

	private long l = -1;
	private BigInteger b;

	public Number(long other) {
		this.l = other;
		this.b = null;
	}

	public Number(BigInteger other) {
		if (other.bitLength() <= 63)
			this.l = other.longValue();
		else
			this.b = other;
	}

	public Type getType() {
		if (b != null)
			return Type.BIGINTEGER;
		return Type.LONG;
	}

	public long getLong() {
		return l;
	}

	public BigInteger getBigInteger() {
		return b;
	}

	public static BigInteger toBigInteger(Number other) {
		if (other.getType() == Type.LONG)
			return BigInteger.valueOf(other.getLong());
		else
			return other.getBigInteger();
	}

	public Number add(Number other) {
		if (this.getType() == other.getType() && this.getType() == Type.LONG && this.getLong() > 0 && other.getLong() > 0 && this.getLong() > Long.MAX_VALUE - other.getLong()) 
			return new Number(this.getLong() + other.getLong());

		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.add(ot));
	}

	public Number subtract(Number other) {
		if (this.getType() == other.getType() && other.getType() == Type.LONG)
			return new Number(l - other.getLong());

		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.subtract(ot));
	}

	public Number multiply(Number other) {
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.multiply(ot));
	}

	public Number divide(Number other) {
		if (this.getType() == other.getType() && other.getType() == Type.LONG)
			return new Number(l / other.getLong());

		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.divide(ot));
	}

	public Number and(Number other) {
		if (this.getType() == other.getType() && other.getType() == Type.LONG)
			return new Number(l & other.getLong());
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.and(ot));
	}

	public Number or(Number other) {
		if (this.getType() == other.getType() && other.getType() == Type.LONG)
			return new Number(l | other.getLong());
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.or(ot));
	}

	public Number xor(Number other) {
		if (this.getType() == other.getType() && other.getType() == Type.LONG)
			return new Number(l ^ other.getLong());
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.xor(ot));
	}

	public Number not() {
		if (this.getType() == Type.LONG)
			return new Number(~l);
		BigInteger me = toBigInteger(this);

		return new Number(me.not());
	}

	public byte[] toByteArray() {
		if (getType() == Type.LONG) {
			ByteBuffer buffer = ByteBuffer.allocate(Long.BYTES);
			buffer.putLong(getLong());
			return buffer.array();
		} else {
			return getBigInteger().toByteArray();
		}
	}

	public Number shiftRight(int other) {
		BigInteger me = toBigInteger(this);

		return new Number(me.shiftRight(other));
	}

	public Number shiftLeft(int other) {
		BigInteger me = toBigInteger(this);

		return new Number(me.shiftLeft(other));
	}

	public int intValue() {
		if (getType() == Type.LONG)
			return Long.valueOf(l).intValue();
		else
			return toBigInteger(this).intValue();
	}

	@Override
	public String toString() {
		if (b != null)
			return b.toString();
		return l + "";
	}

	@Override
	public int compareTo(Number other) {
		if (this.getType() == other.getType() && other.getType() == Type.LONG)
			return Long.compare(this.getLong(), other.getLong());
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return me.compareTo(ot);
	}

	@Override
	public int hashCode() {
		if (getType() == Type.LONG) 
			return Long.hashCode(this.getLong());
		else 
			return Objects.hashCode(this.getBigInteger());
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
		if (this.getType() == other.getType() && this.getType() == Type.LONG)
			return this.getLong() == other.getLong();
		return Objects.equals(toBigInteger(this), toBigInteger(other));
	}
}
