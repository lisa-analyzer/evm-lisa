package it.unipr.analysis;

import java.math.BigInteger;
import java.util.Objects;

public class Number implements Comparable<Number> {
	public static final BigInteger MAX_INT = BigInteger.valueOf((long) Math.pow(2, 32));
	public static final BigInteger MAX_LONG = BigInteger.valueOf((long) Math.pow(2, 64));

	static enum Type {
		INT,
		LONG,
		BIGINTEGER
	}

	private int i = -1;
	private long l = -1;
	private BigInteger b;

	public Number(int other) {
		this.i = other;
		this.b = null;
	}

	public Number(long other) {
		this.l = other;
		this.b = null;
	}

	public Number(BigInteger other) {
		if (other.compareTo(MAX_INT) < 0)
			this.i = other.intValue();
		else if (other.compareTo(MAX_LONG) < 0)
			this.l = other.longValue();
		else
			this.b = other;
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

	public BigInteger toBigInteger(Number other) {
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
		if(this.getType() == other.getType() && other.getType() == Type.INT)
			return new Number((long) i + other.getInt());
		
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.add(ot));
	}

	public Number subtract(Number other) {
		if(this.getType() == other.getType() && other.getType() == Type.INT)
			return new Number(i - other.getInt());
		if(this.getType() == other.getType() && other.getType() == Type.LONG)
			return new Number(l - other.getLong());
		
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.subtract(ot));
	}

	public Number multiply(Number other) {
		if(this.getType() == other.getType() && other.getType() == Type.INT)
			return new Number((long) i * other.getInt());
		
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return new Number(me.multiply(ot));
	}

	public Number divide(Number other) {
		if(this.getType() == other.getType() && other.getType() == Type.INT)
			return new Number(i / other.getInt());
		if(this.getType() == other.getType() && other.getType() == Type.LONG)
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
		BigInteger me = toBigInteger(this);

		return me.intValue();
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
		if(this.getType() == other.getType() && other.getType() == Type.INT)
			return i > other.getInt() ? (+1) : i < other.getInt() ? (-1) : 0;
		if(this.getType() == other.getType() && other.getType() == Type.LONG)
			return i > other.getLong() ? (+1) : i < other.getLong() ? (-1) : 0;
		
		BigInteger me = toBigInteger(this);
		BigInteger ot = toBigInteger(other);

		return me.compareTo(ot);
	}

	@Override
	public int hashCode() {
		return Objects.hash(b, i, l);
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
		return Objects.equals(b, other.b) && i == other.i && l == other.l;
	}
	
	public static void main(String[] args) {
		int i = 1;
		long l = 1;
		BigInteger b = BigInteger.valueOf(l);
		System.out.println(new Number(i).toByteArray().length);
		System.out.println(new Number(l).toByteArray().length);
		System.out.println(new Number(b).toByteArray().length);
	}
	
}
