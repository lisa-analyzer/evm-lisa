package it.unipr.analysis;

import it.unive.lisa.analysis.BaseLattice;
import it.unive.lisa.analysis.Lattice;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.util.representation.StringRepresentation;
import it.unive.lisa.util.representation.StructuredRepresentation;
import java.math.BigInteger;
import java.util.Objects;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class StackElement implements BaseLattice<StackElement>, Comparable<StackElement> {
	private static final Logger log = LogManager.getLogger(StackElement.class);

	private static final Number ZERO_INT = new Number(0);
	private static final Number ONE_INT = new Number(1);
	private static final Number MAX = new Number(BigInteger.valueOf(2).pow(256));

	public static final StackElement ZERO = new StackElement(0);
	public static final StackElement ONE = new StackElement(1);

	public static final StackElement NOT_JUMPDEST_TOP = new StackElement(-10);

	/**
	 * The top abstract element.
	 */
	public static final StackElement TOP = new StackElement(true, false);

	/**
	 * The bottom abstract element.
	 */
	public static final StackElement BOTTOM = new StackElement(false, true);

	private final Number n;
	private final boolean isTop, isBottom;

	/**
	 * Builds the top stack element.
	 */
	public StackElement() {
		this(null, true, false);
	}

	/**
	 * Builds a stack element, that can be either top or bottom.
	 * 
	 * @param isTop    if it is the top abstract element
	 * @param isBottom if it is the bottom abstract element
	 */
	private StackElement(boolean isTop, boolean isBottom) {
		this(null, isTop, isBottom);
	}

	/**
	 * Builds a stack element.
	 * 
	 * @param n        the number of this stack element
	 * @param isTop    if it is the top abstract element
	 * @param isBottom if it is the bottom abstract element
	 */
	private StackElement(Number n, boolean isTop, boolean isBottom) {
		this.n = n;
		this.isTop = isTop;
		this.isBottom = isBottom;
	}

	/**
	 * Builds a stack element starting from a number.
	 * 
	 * @param n the number
	 */
	public StackElement(Number n) {
		this(n, false, false);
	}

	/**
	 * Builds a stack element starting from an integer.
	 * 
	 * @param i the integer value
	 */
	public StackElement(int i) {
		this(new Number(i));
	}

	/**
	 * Builds a stack element starting from a big integer.
	 * 
	 * @param i the big integer value
	 */
	public StackElement(BigInteger i) {
		this(new Number(i));
	}

	@Override
	public StackElement top() {
		return TOP;
	}

	@Override
	public boolean isTop() {
		return isTop;
	}

	@Override
	public boolean isBottom() {
		return isBottom;
	}

	@Override
	public StackElement bottom() {
		return BOTTOM;
	}

	@Override
	public boolean lessOrEqualAux(StackElement other) throws SemanticException {
		if (isTopNotJumpdest())
			if (other.isTopNotJumpdest())
				return true;
			else
				return false;
		else if (other.isTopNotJumpdest())
			return true;
		return false;
	}

	@Override
	public StackElement lubAux(StackElement other) throws SemanticException {
		if (isTopNotJumpdest())
			return this;
		else if (other.isTopNotJumpdest())
			return other;

		return top();
	}

	@Override
	public final String toString() {
		if (isTop())
			return Lattice.TOP_STRING;

		if (isTopNotJumpdest())
			return "#TOPNJD#";

		if (isBottom())
			return Lattice.BOTTOM_STRING;

		return n.toString();
	}

	@Override
	public StackElement glbAux(StackElement other) throws SemanticException {
		return bottom();
	}

	public StackElement isZero() {
		if (isBottom())
			return bottom();
		else if (isTop())
			return NOT_JUMPDEST_TOP;
		else if (isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;
		else if (equals(ZERO))
			return ONE;
		else if (!equals(ZERO))
			return ZERO;
		return NOT_JUMPDEST_TOP;
	}

	/**
	 * Yields the number of this stack element.
	 * 
	 * @return the number of this stack element
	 */
	public Number getNumber() {
		return n;
	}

	/**
	 * Computes the sum of this stack element and another stack element.
	 * <p>
	 * The method follows these rules:
	 * <ul>
	 * <li>If either element is bottom, the result is bottom.</li>
	 * <li>If either element is top, the result is top.</li>
	 * <li>If either element is top but not a jump destination, the result is
	 * NOT_JUMPDEST_TOP.</li>
	 * <li>Otherwise, performs numeric addition with modular reduction by
	 * MAX.</li>
	 * </ul>
	 *
	 * @param other the stack element to be added
	 * 
	 * @return a new {@code StackElement} representing the sum of this and the
	 *             other stack element
	 */
	public StackElement sum(StackElement other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;

		Number add = this.n.add(other.n);
		if (add.compareTo(MAX) >= 0)
			add = add.subtract(MAX);

		return new StackElement(add);
	}

	public StackElement sub(StackElement other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;

		Number sub;
		if (this.n.compareTo(other.n) < 0) {
			sub = MAX.subtract(other.n);
			sub = sub.add(this.n);
		} else
			sub = this.n.subtract(other.n);

		return new StackElement(sub);
	}

	/**
	 * Computes the product of this stack element and another stack element.
	 * <p>
	 * The method follows these rules:
	 * <ul>
	 * <li>If either element is bottom, the result is bottom.</li>
	 * <li>If either element is zero, the result is zero.</li>
	 * <li>If either element is top, the result is top.</li>
	 * <li>If either element is top but not a jump destination, the result is
	 * NOT_JUMPDEST_TOP.</li>
	 * <li>Otherwise, performs numeric multiplication with modular
	 * handling.</li>
	 * <li>If the multiplication results in a negative number, it wraps around
	 * by adding MAX.</li>
	 * <li>If the result exceeds MAX, it wraps around by subtracting MAX.</li>
	 * </ul>
	 *
	 * @param other the stack element to multiply with this element
	 * 
	 * @return a new {@code StackElement} representing the product of this and
	 *             the other stack element
	 */
	public StackElement mul(StackElement other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (this.equals(ZERO) || other.equals(ZERO))
			return ZERO;
		else if (isTop() || other.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;

		Number mul = this.n.multiply(other.n);
		mul = mul.modulo(MAX);

		return new StackElement(mul);
	}

	public StackElement div(StackElement other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (other.equals(ZERO))
			return ZERO;
		else if (isTop() || other.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;

		if (other.n.equals(ZERO_INT))
			return new StackElement(ZERO_INT);
		else
			return new StackElement(this.n.divide(other.n));
	}

	public StackElement mod(StackElement other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (other.equals(ZERO))
			return ZERO;
		else if (isTop() || other.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;

		if (other.n.equals(ZERO_INT))
			return new StackElement(this.n);
		else
			return new StackElement(this.n.subtract(other.n.multiply(this.n.divide(other.n))));
	}

	public StackElement addmod(StackElement that, StackElement other) {
		if (isBottom() || other.isBottom() || that.isBottom())
			return bottom();
		else if (other.equals(ZERO))
			return ZERO;
		else if (isTop() || other.isTop() || that.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest() || that.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;

		if (other.n.equals(ZERO_INT))
			return new StackElement(ZERO_INT);
		else
			return new StackElement(this.n.add(that.n).subtract(other.n.multiply(this.n.add(that.n).divide(other.n))));

	}

	public StackElement mulmod(StackElement that, StackElement other) {
		if (isBottom() || other.isBottom() || that.isBottom())
			return bottom();
		else if (other.equals(ZERO))
			return ZERO;
		else if (isTop() || other.isTop() || that.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest() || that.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;

		if (other.n.equals(ZERO_INT))
			return new StackElement(ZERO_INT);
		else
			return new StackElement(
					this.n.multiply(that.n).subtract(other.n.multiply(this.n.multiply(that.n).divide(other.n))));
	}

	public StackElement exp(StackElement other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (other.equals(ZERO))
			return ONE;
		else if (isTop() || other.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;

		Number r = this.n;

		for (int k = 0; other.n.compareTo(new Number(k)) > 0; k++)
			if (r.compareTo(MAX) > 0)
				return TOP;
			else
				r = r.multiply(this.n);

		return new StackElement(r);
	}

	public StackElement lt(StackElement other) {
		if (isBottom() || other.isBottom())
			return StackElement.BOTTOM;
		else if (isTop() || other.isTop())
			return StackElement.NOT_JUMPDEST_TOP;
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;

		if (this.n.compareTo(other.n) < 0)
			return StackElement.ONE;
		else
			return StackElement.ZERO;
	}

	public StackElement gt(StackElement other) {
		if (isBottom() || other.isBottom())
			return StackElement.BOTTOM;
		else if (isTop() || other.isTop())
			return StackElement.NOT_JUMPDEST_TOP;
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return StackElement.NOT_JUMPDEST_TOP;

		if (this.n.compareTo(other.n) > 0)
			return StackElement.ONE;
		else
			return StackElement.ZERO;
	}

	public StackElement eq(StackElement other) {
		if (isBottom() || other.isBottom())
			return StackElement.BOTTOM;
		else if (isTop() || other.isTop())
			return StackElement.NOT_JUMPDEST_TOP;
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return StackElement.NOT_JUMPDEST_TOP;

		if (this.n.compareTo(other.n) == 0)
			return StackElement.ONE;
		else
			return StackElement.ZERO;
	}

	public StackElement and(StackElement other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (this.equals(ZERO) || other.equals(ZERO))
			return ZERO;
		else if (isTop() || other.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;

		return new StackElement(this.n.and(other.n));
	}

	public StackElement or(StackElement other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;

		return new StackElement(this.n.or(other.n));

	}

	public StackElement xor(StackElement other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;

		return new StackElement(this.n.xor(other.n));
	}

	public StackElement not() {
		if (isBottom())
			return bottom();
		else if (isTop())
			return top();
		else if (isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;

		if (this.n.compareTo(ZERO_INT) >= 0)
			return new StackElement(MAX.subtract(this.n.add(ONE_INT)));
		else
			return new StackElement(this.n.not());
	}

	public StackElement shl(StackElement other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;
		else if (n.compareTo(new Number(256)) >= 0)
			return ZERO;

		return new StackElement(other.n.shiftLeft(this.n.getInt()));

	}

	public StackElement shr(StackElement other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;
		else if (n.compareTo(new Number(256)) >= 0)
			return ZERO;

		return new StackElement(other.n.shiftRight(this.n.getInt()));
	}

	public StackElement sar(StackElement other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;
		else if (n.compareTo(new Number(256)) > 0)
			return ZERO;

		return new StackElement(
				new Number(
						new BigInteger(
								StackElement.shiftArithmeticRight(
										other.n.toByteArray(),
										this.n.getInt()))));
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
	 * Creates a new StackElement by extracting the byte values from the given
	 * 32-element AbstractByte array and interpreting them as an unsigned
	 * big-endian integer.
	 *
	 * @param bytes a 32-element array of AbstractByte instances
	 * 
	 * @return a StackElement whose numeric value corresponds to the byte values
	 *             of the provided AbstractByte array
	 * 
	 * @throws IllegalArgumentException if the input array is null or its length
	 *                                      is not exactly 32 elements
	 */
	public static StackElement fromBytes(AbstractByte[] bytes) {
		if (bytes == null || bytes.length != 32)
			throw new IllegalArgumentException("Invalid byte array: must be exactly 32 bytes");

		byte[] tmp = new byte[bytes.length];
		for (int i = 0; i < bytes.length; i++)
			tmp[i] = bytes[i].getValue();
		BigInteger value = new BigInteger(1, tmp);

		return new StackElement(new Number(value));
	}

	/**
	 * Checks whether this set it is definitely evaluated to {@code true}, i.e.,
	 * if it does not contain zero.
	 * 
	 * @return {@code true} if this set does not contain zero, {@code false}
	 *             otherwise.
	 */
	public boolean isDefinitelyTrue() {
		if (isTop() || isBottom() || isTopNotJumpdest())
			return false;
		return !this.n.equals(ZERO_INT);
	}

	/**
	 * Checks whether this set it is definitely evaluated to {@code false},
	 * i.e., if it is equal to zero.
	 * 
	 * @return {@code true} if this set is zero, {@code false} otherwise.
	 */
	public boolean isDefinitelyFalse() {
		if (isTop() || isBottom() || isTopNotJumpdest())
			return false;
		return this.n.equals(ZERO_INT);
	}

	/**
	 * Checks whether the Boolean value of this set cannot be determined.
	 * 
	 * @return {@code true} if the Boolean value of this set cannot be
	 *             determined, {@code false} otherwise
	 */
	public boolean isUnknown() {
		return isTop() || isTopNotJumpdest() || (!isBottom() && !isDefinitelyFalse() && !isDefinitelyTrue());
	}

	public boolean isTopNotJumpdest() {
		return this == NOT_JUMPDEST_TOP;
	}

	public boolean isTopNumeric() {
		return this == TOP;
	}

	@Override
	public int hashCode() {
		return Objects.hash(isBottom, isTop, n);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		else if (obj == null)
			return false;
		else if (getClass() != obj.getClass())
			return false;
		else if (isBottom() && ((StackElement) obj).isBottom())
			return true;
		else if (isTop() && ((StackElement) obj).isTop())
			return true;
		else if (isTopNotJumpdest() && ((StackElement) obj).isTopNotJumpdest())
			return true;
		if (!isBottom() && !isTop() && !isTopNotJumpdest() &&
				!((StackElement) obj).isBottom() && !((StackElement) obj).isTop()
				&& !((StackElement) obj).isTopNotJumpdest())
			return this.n.equals(((StackElement) obj).n);
		return false;
	}

	@Override
	public int compareTo(StackElement o) {
		if (this.isBottom())
			return o.isBottom() ? 0 : -1;
		else if (this.isTop())
			return o.isTop() ? 0 : 1;
		return this.n.compareTo(o.n);
	}

	@Override
	public StructuredRepresentation representation() {
		return new StringRepresentation(toString());
	}
}