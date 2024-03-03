package it.unipr.analysis;

import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.lattices.SetLattice;
import java.math.BigInteger;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

public class KIntegerSet extends SetLattice<KIntegerSet, Number> {
	private static final Number ZERO_INT = new Number(0);
	private static final Number ONE_INT = new Number(1);
	private static final Number MAX = new Number(BigInteger.valueOf(2).pow(256));

	public static final int K = 2;

	public static final KIntegerSet ZERO = new KIntegerSet(0);
	public static final KIntegerSet ONE = new KIntegerSet(1);
	public static final KIntegerSet ZERO_OR_ONE = new KIntegerSet(0, 1);

	public static final KIntegerSet NUMERIC_TOP = new KIntegerSet(Collections.emptySet(), true);
	public static final KIntegerSet BOTTOM = new KIntegerSet(Collections.emptySet(), false);

	public KIntegerSet(Number i) {
		this(Collections.singleton(i), false);
	}

	public KIntegerSet(Integer i) {
		this(new Number(i.intValue()));
	}

	public KIntegerSet(Integer... ints) {
		super(new HashSet<>(K), ints.length > K);

		if (ints.length <= K)
			for (Integer i : ints)
				this.elements.add(new Number(i));
	}

	public KIntegerSet(BigInteger i) {
		this(new Number(i));
	}

	public KIntegerSet(Set<Number> set) {
		this(set.size() > K ? Collections.emptySet() : set, set.size() > K);
	}

	public KIntegerSet(Set<Number> elements, boolean isTop) {
		super(elements, isTop);
	}

	@Override
	public KIntegerSet top() {
		return NUMERIC_TOP;
	}

	@Override
	public KIntegerSet bottom() {
		return BOTTOM;
	}

	@Override
	public boolean isBottom() {
		return elements != null && super.isBottom();
	}

	@Override
	public boolean isTop() {
		return elements != null && super.isTop();
	}

	@Override
	public KIntegerSet lubAux(KIntegerSet other) throws SemanticException {
		KIntegerSet result = super.lubAux(other);
		return result.size() > K ? top() : result;
	}

	@Override
	public KIntegerSet wideningAux(KIntegerSet other) throws SemanticException {
		return lubAux(other);
	}

	@Override
	public KIntegerSet glbAux(KIntegerSet other) throws SemanticException {
		KIntegerSet result = super.glbAux(other);
		return result.size() > K ? top() : result;
	}

	@Override
	public KIntegerSet mk(Set<Number> set) {
		return new KIntegerSet(set);
	}

	public KIntegerSet isZero() {
		if (isBottom())
			return bottom();
		else if (isTop())
			return KIntegerSet.ZERO_OR_ONE;
		else if (equals(ZERO))
			return KIntegerSet.ONE;
		else if (!contains(ZERO_INT))
			return KIntegerSet.ZERO;
		return KIntegerSet.ZERO_OR_ONE;
	}

	public KIntegerSet sum(KIntegerSet other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();

		Set<Number> elements = new HashSet<>(K);
		for (Number i : this.elements)
			for (Number j : other.elements) {
				Number add = i.add(j);
				if (add.compareTo(MAX) >= 0)
					add = add.subtract(MAX);
				elements.add(add);
			}

		return new KIntegerSet(elements);
	}

	public KIntegerSet sub(KIntegerSet other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();

		Set<Number> elements = new HashSet<>(K);
		for (Number i : this.elements)
			for (Number j : other.elements) {
				Number sub = i.subtract(j);
				if (sub.compareTo(ZERO_INT) < 0)
					sub = sub.add(MAX);
				elements.add(sub);
			}

		return new KIntegerSet(elements);
	}

	public KIntegerSet mul(KIntegerSet other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (this.equals(ZERO) || other.equals(ZERO))
			return ZERO;
		else if (isTop() || other.isTop())
			return top();

		Set<Number> elements = new HashSet<>(K);
		for (Number i : this.elements)
			for (Number j : other.elements) {
				Number mul = i.multiply(j);
				if (mul.compareTo(ZERO_INT) < 0)
					mul = mul.add(MAX);
				if (mul.compareTo(MAX) > 0)
					mul = mul.subtract(MAX);

				elements.add(mul);
			}

		return new KIntegerSet(elements);
	}

	public KIntegerSet div(KIntegerSet other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();

		Set<Number> elements = new HashSet<>(K);
		for (Number i : this.elements)
			for (Number j : other.elements)
				if (j.equals(ZERO_INT))
					elements.add(ZERO_INT);
				else
					elements.add(i.divide(j));

//					elements.add(i.divide(j, RoundingMode.FLOOR));

		return new KIntegerSet(elements);
	}

	public KIntegerSet mod(KIntegerSet other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();

		Set<Number> elements = new HashSet<>(K);
		for (Number i : this.elements)
			for (Number j : other.elements) {

				if (j.equals(ZERO_INT))
					elements.add(i);
				else
					elements.add(i.subtract(j.multiply(i.divide(j))));
			}

		return new KIntegerSet(elements);
	}

	public KIntegerSet addmod(KIntegerSet that, KIntegerSet other) {
		if (isBottom() || other.isBottom() || that.isBottom())
			return bottom();
		else if (isTop() || other.isTop() || that.isTop())
			return top();

		Set<Number> elements = new HashSet<>(K);
		for (Number i : this.elements)
			for (Number j : that.elements)
				for (Number k : other.elements)
					if (k.equals(ZERO_INT))
						elements.add(ZERO_INT);
					else
						elements.add(i.add(j).subtract(k.multiply(i.add(j).divide(k))));

		return new KIntegerSet(elements);
	}

	public KIntegerSet mulmod(KIntegerSet that, KIntegerSet other) {
		if (isBottom() || other.isBottom() || that.isBottom())
			return bottom();
		else if (isTop() || other.isTop() || that.isTop())
			return top();

		Set<Number> elements = new HashSet<>(K);
		for (Number i : this.elements)
			for (Number j : that.elements)
				for (Number k : other.elements)
					if (k.equals(ZERO_INT))
						elements.add(ZERO_INT);
					else
						elements.add(i.multiply(j).subtract(k.multiply(i.multiply(j).divide(k))));

		return new KIntegerSet(elements);
	}

	public KIntegerSet exp(KIntegerSet other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();

		Set<Number> elements = new HashSet<>(K);
		for (Number i : this.elements) {
			for (Number j : other.elements) {
				Number r = i;

				for (int k = 0; j.compareTo(new Number(k)) > 0; k++)
					if (r.compareTo(MAX) > 0)
						return NUMERIC_TOP;
					else
						r = r.multiply(i);
				elements.add(r);
			}
		}

		return new KIntegerSet(elements);
	}

	public KIntegerSet lt(KIntegerSet other) {
		if (isBottom() || other.isBottom())
			return KIntegerSet.BOTTOM;
		else if (isTop() || other.isTop())
			return KIntegerSet.ZERO_OR_ONE;

		Set<Boolean> r = new HashSet<Boolean>();
		for (Number i : this.elements)
			for (Number j : other.elements)
				r.add(i.compareTo(j) < 0);

		if (r.size() == 2)
			return KIntegerSet.ZERO_OR_ONE;
		else if (r.contains(true))
			return KIntegerSet.ONE;

		return KIntegerSet.ZERO;
	}

	public KIntegerSet gt(KIntegerSet other) {
		if (isBottom() || other.isBottom())
			return KIntegerSet.BOTTOM;
		else if (isTop() || other.isTop())
			return KIntegerSet.ZERO_OR_ONE;

		Set<Boolean> r = new HashSet<Boolean>();
		for (Number i : this.elements)
			for (Number j : other.elements)
				r.add(i.compareTo(j) > 0);

		if (r.size() == 2)
			return KIntegerSet.ZERO_OR_ONE;
		else if (r.contains(true))
			return KIntegerSet.ONE;

		return KIntegerSet.ZERO;
	}

	public KIntegerSet eq(KIntegerSet other) {
		if (isBottom() || other.isBottom())
			return KIntegerSet.BOTTOM;
		else if (isTop() || other.isTop())
			return KIntegerSet.ZERO_OR_ONE;

		Set<Boolean> r = new HashSet<Boolean>();
		for (Number i : this.elements)
			for (Number j : other.elements)
				r.add(i.compareTo(j) == 0);

		if (r.size() == 2)
			return KIntegerSet.ZERO_OR_ONE;
		else if (r.contains(true))
			return KIntegerSet.ONE;

		return KIntegerSet.ZERO;
	}

	public KIntegerSet and(KIntegerSet other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (this.equals(ZERO) || other.equals(ZERO))
			return ZERO;
		else if (isTop() || other.isTop())
			return top();

		Set<Number> elements = new HashSet<>(K);
		for (Number i : this.elements)
			for (Number j : other.elements)
				elements.add(i.and(j));

		return new KIntegerSet(elements);
	}

	public KIntegerSet or(KIntegerSet other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();

		Set<Number> elements = new HashSet<>(K);
		for (Number i : this.elements)
			for (Number j : other.elements)
				elements.add(i.or(j));

		return new KIntegerSet(elements);
	}

	public KIntegerSet xor(KIntegerSet other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();

		Set<Number> elements = new HashSet<>(K);
		for (Number i : this.elements)
			for (Number j : other.elements)
				elements.add(i.xor(j));

		return new KIntegerSet(elements);
	}

	public KIntegerSet not() {
		if (isBottom())
			return bottom();
		else if (isTop())
			return top();

		Set<Number> elements = new HashSet<>(K);
		for (Number i : this.elements)
			if (i.compareTo(ZERO_INT) >= 0)
				elements.add(MAX.subtract(i.add(ONE_INT)));
			else
				elements.add(i.not());

		return new KIntegerSet(elements);
	}

	public KIntegerSet shl(KIntegerSet other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();

		Set<Number> elements = new HashSet<>(K);
		for (Number i : this.elements)
			for (Number j : other.elements)
				elements.add(new Number(new BigInteger(shiftLeft(j.toByteArray(), i.intValue()))));

		return new KIntegerSet(elements);
	}

	public KIntegerSet shr(KIntegerSet other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();

		Set<Number> elements = new HashSet<>(K);
		for (Number i : this.elements)
			for (Number j : other.elements)
				elements.add(j.shiftRight(i.intValue()));

		return new KIntegerSet(elements);
	}

	public KIntegerSet sar(KIntegerSet other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();

		Set<Number> elements = new HashSet<>(K);
		for (Number i : this.elements)
			for (Number j : other.elements)
				elements.add(
						new Number(new BigInteger(shiftArithmeticRight(j.toByteArray(), i.intValue()))));

		return new KIntegerSet(elements);
	}

	public KIntegerSet mload(Memory memory) throws SemanticException {
		if (isBottom())
			return bottom();
		else if (isTop())
			return top();

		KIntegerSet r = KIntegerSet.BOTTOM;

		for (Number i : this.elements) {
			KIntegerSet state = memory.getState(i);
			if (state.isBottom())
				r = r.lub(KIntegerSet.NUMERIC_TOP);
			else
				r = r.lub(state);
		}
		return r;
	}

	/**
	 * Shifts the given byte array to the left by the specified number of bits.
	 *
	 * @param byteArray     The byte array to be left-shifted.
	 * @param shiftBitCount The number of bits by which to shift the byte array
	 *                          to the left.
	 * 
	 * @return The resulting byte array after left-shifting by the specified bit
	 *             count.
	 *             <p>
	 *             This method performs a left shift on the provided byte array,
	 *             where each byte is shifted to the left by the given number of
	 *             bits. The shift operation is performed in a bitwise manner,
	 *             and the bits shifted beyond the byte boundary are wrapped
	 *             around to the opposite end. The shift is done in place, and
	 *             the modified byte array is returned as the result.
	 *             </p>
	 *             <p>
	 *             The {@code shiftBitCount} parameter determines the number of
	 *             bits to shift.
	 *             </p>
	 * 
	 * @throws IllegalArgumentException If the input {@code byteArray} is
	 *                                      {@code null}.
	 */
	public static byte[] shiftLeft(byte[] byteArray, int shiftBitCount) {
		final int shiftMod = shiftBitCount % 8;
		final byte carryMask = (byte) ((1 << shiftMod) - 1);
		final int offsetBytes = (shiftBitCount / 8);

		int start;

		if (byteArray.length > 32)
			start = 1;
		else
			start = 0;

		int sourceIndex;
		for (int i = start; i < byteArray.length; i++) {
			sourceIndex = i + offsetBytes;
			if (sourceIndex >= byteArray.length) {
				byteArray[i] = 0;
			} else {
				byte src = byteArray[sourceIndex];
				byte dst = (byte) (src << shiftMod);
				if (sourceIndex + 1 < byteArray.length) {
					dst |= byteArray[sourceIndex + 1] >>> (8 - shiftMod) & carryMask;
				}
				byteArray[i] = dst;
			}
		}
		return byteArray;
	}

	/**
	 * Shifts the elements of a byte array to the right by a specified number of
	 * bits.
	 *
	 * @param byteArray     The byte array to be shifted.
	 * @param shiftBitCount The number of bits by which the array elements
	 *                          should be shifted to the right.
	 * 
	 * @return The byte array after the right shift operation.
	 *             <p>
	 *             This method performs a bitwise right shift on the input byte
	 *             array, where each element is treated as a single byte. The
	 *             shift operation is performed in-place, and the original array
	 *             is modified.
	 *             </p>
	 *             <p>
	 *             If the {@code shiftBitCount} is zero, the array remains
	 *             unchanged.
	 *             </p>
	 *             <p>
	 *             The method uses a circular shift approach, with consideration
	 *             for byte boundaries and a carry mechanism.
	 *             </p>
	 *
	 * @throws IllegalArgumentException If the {@code byteArray} is
	 *                                      {@code null}.
	 */
	public static byte[] shiftRight(byte[] byteArray, int shiftBitCount) {
		final int shiftMod = shiftBitCount % 8;
		final byte carryMask = (byte) (0xFF << (8 - shiftMod));
		final int offsetBytes = (shiftBitCount / 8);

		int sourceIndex;
		for (int i = byteArray.length - 1; i >= 0; i--) {
			sourceIndex = i - offsetBytes;
			if (sourceIndex < 0) {
				byteArray[i] = 0;
			} else {
				byte src = byteArray[sourceIndex];
				byte dst = (byte) ((0xff & src) >>> shiftMod);
				if (sourceIndex - 1 >= 0) {
					dst |= byteArray[(sourceIndex - 1)] << (8 - shiftMod) & carryMask;
				}
				byteArray[i] = dst;
			}
		}
		return byteArray;
	}

	/**
	 * Shifts the bits of the given byte array towards the least significant bit
	 * (SAR - Shift Arithmetic Right). The bits moved before the first one are
	 * discarded, and the new bits are set to 0 if the previous most significant
	 * bit was 0; otherwise, the new bits are set to 1.
	 *
	 * @param byteArray     The byte array to be right-shifted.
	 * @param shiftBitCount The number of bits by which to shift the byte array
	 *                          to the right.
	 * 
	 * @return The resulting byte array after right-shifting by the specified
	 *             bit count.
	 *             <p>
	 *             This method performs a right shift on the provided byte array
	 *             (SAR operation), where each byte is shifted to the right by
	 *             the given number of bits. The shift operation is performed in
	 *             a bitwise manner, and the bits shifted beyond the byte
	 *             boundary are discarded. The new bits introduced during the
	 *             shift are set based on the value of the previous most
	 *             significant bit (0 or 1).
	 *             </p>
	 *             <p>
	 *             The {@code shiftBitCount} parameter determines the number of
	 *             bits to shift.
	 *             </p>
	 *
	 * @throws IllegalArgumentException If the input {@code byteArray} is
	 *                                      {@code null}.
	 */
	public static byte[] shiftArithmeticRight(byte[] byteArray, int shiftBitCount) {
		final int shiftMod = shiftBitCount % 8;
		final byte carryMask = (byte) (0xFF << (8 - shiftMod));
		final int offsetBytes = (shiftBitCount / 8);

		int sourceIndex;
		int start;

		if (byteArray.length > 32)
			start = 1;
		else
			start = 0;
		for (int i = start; i < byteArray.length; i++) {
			sourceIndex = i + offsetBytes;
			if (sourceIndex >= byteArray.length) {
				byteArray[i] = (byte) (byteArray[i] < 0 ? 0xFF : 0);
			} else {
				byte src = byteArray[sourceIndex];
				byte dst = (byte) (src >>> shiftMod);
				if (sourceIndex + 1 < byteArray.length) {
					dst |= byteArray[sourceIndex + 1] << (8 - shiftMod) & carryMask;
				}
				byteArray[i] = dst;
			}
		}
		return byteArray;
	}

	/**
	 * Checks whether this set it is definitely evaluated to {@code true}, i.e.,
	 * if it does not contains zero.
	 * 
	 * @return {@code true} if this set does not contains zero, {@code false}
	 *             otherwise.
	 */
	public boolean isDefinitelyTrue() {
		if (isTop() || isBottom())
			return false;
		return !this.elements().contains(ZERO_INT);
	}

	/**
	 * Checks whether this set it is definitely evaluated to {@code false},
	 * i.e., if it is equal to zero.
	 * 
	 * @return {@code true} if this set is zero, {@code false} otherwise.
	 */
	public boolean isDefinitelyFalse() {
		if (isTop() || isBottom())
			return false;
		return this.equals(ZERO);
	}

	/**
	 * Checks whether the Boolean value of this set cannot be determined.
	 * 
	 * @return {@code true} if the Boolean value of this set cannot be
	 *             determined, {@code false} otherwise
	 */
	public boolean isUnknown() {
		return isTop() || (!isBottom() && !isDefinitelyFalse() && !isDefinitelyTrue());
	}
}