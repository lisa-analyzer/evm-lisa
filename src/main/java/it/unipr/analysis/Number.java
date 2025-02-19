package it.unipr.analysis;

import java.math.BigInteger;
import java.util.Objects;

public class Number implements Comparable<Number> {
	public static final BigInteger MAX_INT = BigInteger.valueOf(2).pow(31);
	public static final BigInteger MAX_LONG = BigInteger.valueOf(2).pow(63);

	static enum Type {
		INT,
		LONG,
		BIGINTEGER
	}

	private final int i;
	private final long l;
	private final BigInteger b;

	public Number(int other) {
		this.i = other;
		this.l = -1;
		this.b = null;
	}

	public Number(long other) {
		this.l = other;
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

	public Type getType() {
		if (b != null)
			return Type.BIGINTEGER;
		if (i != -1)
			return Type.INT;
		return Type.LONG;
	}

	public int getInt() {
		return i;
	}

	public long getLong() {
		return l;
	}

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

	public Number add(Number other) {
		if (this.getType() == other.getType() && other.getType() == Type.INT)
			return new Number(i + other.getInt());
		if (this.getType() == other.getType() && other.getType() == Type.LONG)
			return new Number((long) l - other.getLong());
		
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.add(ot));
	}

	public Number subtract(Number other) {
		if (this.getType() == other.getType() && other.getType() == Type.INT)
			return new Number(i - other.getInt());
		if (this.getType() == other.getType() && other.getType() == Type.LONG)
			return new Number(l - other.getLong());

		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.subtract(ot));
	}

	public Number multiply(Number other) {
		if (this.getType() == other.getType() && other.getType() == Type.INT)
			return new Number((long) i * other.getInt());

		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.multiply(ot));
	}

	public Number divide(Number other) {
		if (this.getType() == other.getType() && other.getType() == Type.INT)
			return new Number(i / other.getInt());
		if (this.getType() == other.getType() && other.getType() == Type.LONG)
			return new Number(l / other.getLong());

		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.divide(ot));
	}

	public Number and(Number other) {
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.and(ot));
	}

	public Number or(Number other) {
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.or(ot));
	}

	public Number xor(Number other) {
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.xor(ot));
	}

	public Number not() {
		BigInteger me = toBigInteger(this);

		return new Number(me.not());
	}

	public byte[] toByteArray() {
		BigInteger me = toBigInteger(this);

		return me.toByteArray();
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
		if (getType() == Type.INT)
			return i;
		else if (getType() == Type.LONG)
			return Long.valueOf(l).intValue();
		else
			return toBigInteger(this).intValue();
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