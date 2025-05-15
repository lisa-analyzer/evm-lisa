package it.unipr.analysis;

import it.unipr.utils.BitManager;
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

	/**
	 * Determines the result of an application-specific "isZero" operation on
	 * the current stack element. The operation performs checks to identify
	 * whether the stack element is equivalent to zero, or evaluates specific
	 * cases such as being the top or bottom abstract element.
	 *
	 * @return If the current stack element is the abstract bottom, returns
	 *             {@code BOTTOM}. If it is the top abstract element, a specific
	 *             non-jump destination top representation is returned. If the
	 *             stack element equals zero, returns {@code ONE}; otherwise,
	 *             returns {@code ZERO}. For any other cases, returns the
	 *             non-jump destination top representation.
	 */
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
	 * Retrieves the number associated with this stack element.
	 *
	 * @return the number stored in this stack element, or null if no number is
	 *             associated
	 */
	public Number getNumber() {
		return n;
	}

	/**
	 * Calculates the sum of this stack element with another stack element. The
	 * resulting stack element depends on the values and states of the two
	 * elements being summed.
	 *
	 * @param other the other {@code StackElement} to be summed with this one
	 * 
	 * @return a new {@code StackElement} representing the sum of this element
	 *             and the given element, accounting for conditions such as
	 *             "top" or "bottom" states
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

	/**
	 * Computes the subtraction of this {@code StackElement} and another
	 * {@code StackElement}. The computation handles specific cases such as if
	 * either element is a top or bottom abstract element, or if it's a numeric
	 * subtraction.
	 *
	 * @param other the {@code StackElement} to subtract from this element
	 * 
	 * @return the resulting {@code StackElement} after subtraction
	 */
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
	 * Multiplies this StackElement with another one, returning a new
	 * StackElement that represents the result of the operation. This method
	 * takes into account the states of the two elements, such as whether they
	 * are top, bottom, or zero. The multiplication result is wrapped within a
	 * modulo operation using the maximum allowed value.
	 *
	 * @param other the StackElement to multiply this StackElement by
	 * 
	 * @return a new StackElement representing the product of this StackElement
	 *             and the provided one
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

	/**
	 * Computes the division of this stack element by the specified stack
	 * element. The behavior of the division depends on the properties of the
	 * stack elements: - If either stack element is the bottom element, the
	 * result is the bottom element. - If the divisor is equivalent to zero, the
	 * result is zero. - If either stack element is the top element, the result
	 * is the top element. - If either stack element is a top element that is
	 * not a jump destination, the result is the "not jump destination top".
	 * Otherwise, the element values are divided numerically.
	 *
	 * @param other the divisor stack element
	 * 
	 * @return a new stack element resulting from the division, or a predefined
	 *             element based on the conditions described above
	 */
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

	/**
	 * Performs a signed division operation between this stack element and
	 * another. The result of the division depends on various conditions such as
	 * whether either of the stack elements is top, bottom, or a specific value.
	 *
	 * @param other the stack element to divide this stack element by
	 * 
	 * @return the result of the signed division as a new stack element
	 */
	public StackElement sdiv(StackElement other) {
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

		int[] thisBits = BitManager.toBitArray(Number.toBigInteger(this.n));
		int[] otherBits = BitManager.toBitArray(Number.toBigInteger(other.n));

		int[] sdivBits = BitManager.sdiv(thisBits, otherBits);
		BigInteger result = BitManager.fromBitArray(sdivBits);

		return new StackElement(new Number(result));
	}

	/**
	 * Computes the modulus of this {@code StackElement} with the provided
	 * {@code StackElement}. The behavior of the method depends on the
	 * properties of both operands, such as whether they are top, bottom, or
	 * specific numerical values.
	 *
	 * @param other the {@code StackElement} to compute the modulus with
	 * 
	 * @return a new {@code StackElement} representing the result of the modulus
	 *             operation. Returns {@code bottom()}, {@code top()},
	 *             {@code NOT_JUMPDEST_TOP}, or other specific
	 *             {@code StackElement} instances depending on the conditions of
	 *             the operands.
	 */
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

	/**
	 * Computes the modular addition of this {@code StackElement}, along with
	 * the given {@code that} and {@code other} arguments. The result is
	 * determined based on the states and numerical values of all three stack
	 * elements while accounting for modular arithmetic rules.
	 *
	 * @param that  the first {@code StackElement} to be added
	 * @param other the second {@code StackElement} used in the modulus
	 *                  operation
	 * 
	 * @return a new {@code StackElement} representing the modular addition
	 *             result. Returns special stack elements, such as
	 *             {@code bottom()}, {@code top()}, or {@code NOT_JUMPDEST_TOP},
	 *             if conditions related to the states of the input elements are
	 *             met.
	 */
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

	/**
	 * Computes the modular multiplication of this {@code StackElement} with the
	 * given {@code StackElement} {@code that}, using the {@code StackElement}
	 * {@code other} as the modulus. This method considers various abstract
	 * states such as "top", "bottom", and specific values to determine the
	 * result.
	 *
	 * @param that  the {@code StackElement} to multiply this element with
	 * @param other the {@code StackElement} to use as the modulus
	 * 
	 * @return a new {@code StackElement} representing the modular
	 *             multiplication result. Depending on the states of the
	 *             provided elements, the result could be {@code bottom()},
	 *             {@code top()}, {@code NOT_JUMPDEST_TOP}, or other specific
	 *             {@code StackElement} values.
	 */
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

	/**
	 * Computes the exponentiation of this {@code StackElement} raised to the
	 * power of another {@code StackElement}. The behavior of the computation
	 * depends on the properties and states of the involved elements.
	 *
	 * @param other the {@code StackElement} representing the exponent
	 * 
	 * @return a new {@code StackElement} representing the result of the
	 *             exponentiation. Specific cases are handled as follows: - If
	 *             either the base or the exponent is the bottom element,
	 *             returns bottom. - If the exponent is zero, returns one. - If
	 *             either the base or the exponent is top, returns top. - If
	 *             either the base or the exponent is "top, not jump
	 *             destination", returns "not jump destination top". -
	 *             Otherwise, performs numeric exponentiation while checking for
	 *             overflow.
	 */
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

	/**
	 * Compares this {@code StackElement} with another {@code StackElement} to
	 * determine if this element is less than the given element. The comparison
	 * considers special cases such as whether the elements are "top" or
	 * "bottom" abstract elements or specific numeric values.
	 *
	 * @param other the {@code StackElement} to compare with this element
	 * 
	 * @return a {@code StackElement} representing the result of the comparison:
	 *             - {@code BOTTOM} if either operand is the bottom abstract
	 *             element - {@code NOT_JUMPDEST_TOP} if either operand is the
	 *             top abstract element or a non-jump-destination top -
	 *             {@code ONE} if this element is less than the given element -
	 *             {@code ZERO} otherwise
	 */
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

	/**
	 * Compares this {@code StackElement} with another {@code StackElement} to
	 * determine if the current element is greater than the provided one. The
	 * method evaluates conditions specific to the stack element's state such as
	 * whether it is top, bottom, or a specific value.
	 *
	 * @param other the {@code StackElement} to compare against this one
	 * 
	 * @return a {@code StackElement} representing the result of the comparison:
	 *             - {@code BOTTOM} if either element is the bottom element -
	 *             {@code NOT_JUMPDEST_TOP} if one of the elements is a top or
	 *             top not jump destination - {@code ONE} if this element is
	 *             greater than the given element - {@code ZERO} if this element
	 *             is not greater
	 */
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

	/**
	 * Compares this {@code StackElement} with another {@code StackElement} for
	 * equality. The result of the comparison depends on the properties of the
	 * two elements: - If either element is the bottom abstract element, the
	 * result is the bottom element. - If either element is the top abstract
	 * element, the result is the "not jump destination top" element. - If
	 * either element is a top element that is not a jump destination, the
	 * result is the "not jump destination top" element. - If both elements have
	 * the same numeric value, the result is the representation of {@code ONE}.
	 * - If the numeric values are different, the result is the representation
	 * of {@code ZERO}.
	 *
	 * @param other the {@code StackElement} to compare with this
	 *                  {@code StackElement}
	 * 
	 * @return a new {@code StackElement} representing the result of the
	 *             equality comparison: {@code BOTTOM},
	 *             {@code NOT_JUMPDEST_TOP}, {@code ONE}, or {@code ZERO}
	 */
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

	/**
	 * Computes the logical AND operation between this stack element and the
	 * specified stack element. The behavior of this operation depends on the
	 * properties of the two elements (e.g., whether they are top, bottom, or
	 * specific values like zero).
	 *
	 * @param other the {@code StackElement} to perform the AND operation with
	 * 
	 * @return a new {@code StackElement} representing the result of the AND
	 *             operation. The resulting element is determined by the
	 *             following conditions: - Returns {@code bottom()} if either
	 *             element is the abstract bottom element. - Returns
	 *             {@code ZERO} if either element equals zero. - Returns
	 *             {@code top()} if either element is the abstract top element.
	 *             - Returns {@code NOT_JUMPDEST_TOP} if either element is a top
	 *             element that is not a jump destination. - Otherwise, returns
	 *             a new {@code StackElement} resulting from the bitwise AND
	 *             operation on the numeric values of the elements.
	 */
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

	/**
	 * Performs a logical "or" operation between this {@code StackElement} and
	 * the provided {@code StackElement}. The behavior of the method depends on
	 * the properties of the two elements: - If either element is the bottom
	 * element, the result is the bottom element. - If either element is the top
	 * element, the result is the top element. - If either element is a top
	 * element that is not a jump destination, the result is the "not jump
	 * destination top". - Otherwise, performs a bitwise "or" operation on the
	 * numeric values of the elements.
	 *
	 * @param other the {@code StackElement} to logically "or" with this one
	 * 
	 * @return a new {@code StackElement} representing the result of the logical
	 *             "or" operation
	 */
	public StackElement or(StackElement other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;

		return new StackElement(this.n.or(other.n));

	}

	/**
	 * Computes the bitwise XOR operation between this {@code StackElement} and
	 * another {@code StackElement}. The result is determined by the properties
	 * and values of the two elements: - If either of the elements is
	 * {@code bottom}, the result is {@code bottom}. - If either of the elements
	 * is {@code top}, the result is {@code top}. - If either of the elements is
	 * a {@code top} that is not a jump destination, the result is the
	 * {@code NOT_JUMPDEST_TOP} element. Otherwise, the bitwise XOR operation is
	 * performed on their numeric values.
	 *
	 * @param other the {@code StackElement} to be XORed with this element
	 * 
	 * @return a new {@code StackElement} representing the result of the XOR
	 *             operation, or a specific predefined element based on the
	 *             conditions described above
	 */
	public StackElement xor(StackElement other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;

		return new StackElement(this.n.xor(other.n));
	}

	/**
	 * Performs a bitwise NOT operation on this {@code StackElement}. The result
	 * depends on the properties of the current stack element: - If the stack
	 * element is the bottom abstract element, the result is the bottom element.
	 * - If the stack element is the top abstract element, the result is the top
	 * element. - If the stack element is a top element that is not a jump
	 * destination, the result is a specific "not jump destination top". -
	 * Otherwise, the operation is performed on the numeric value of the
	 * element.
	 *
	 * @return a new {@code StackElement} representing the result after applying
	 *             the NOT operation, or a specific predefined element (e.g.,
	 *             top, bottom, or "not jump destination top") based on the
	 *             conditions.
	 */
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

	/**
	 * Performs a signed less-than comparison between this {@code StackElement}
	 * and another {@code StackElement}. The comparison considers specific
	 * states of the stack elements, such as whether they are top, bottom, or
	 * other special cases. If either element is the bottom, top, or a
	 * top-not-jumpdest element, it returns corresponding predefined
	 * {@code StackElement} results. For numeric elements, the comparison is
	 * performed as a signed comparison over 256-bit numbers.
	 *
	 * @param other the {@code StackElement} to compare this element against
	 * 
	 * @return a {@code StackElement} which is {@code ONE} if this element is
	 *             less than the given one, {@code ZERO} otherwise. Returns
	 *             specific predefined results in case of top, bottom, or
	 *             non-jumpdest elements.
	 */
	public StackElement slt(StackElement other) {
		if (isBottom() || other.isBottom())
			return BOTTOM;
		if (isTop() || other.isTop())
			return NOT_JUMPDEST_TOP;
		if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;

		BigInteger a = Number.toBigInteger(this.n);
		BigInteger b = Number.toBigInteger(other.n);

		BigInteger HALF = BigInteger.valueOf(2).pow(255);
		BigInteger MOD = BigInteger.valueOf(2).pow(256);
		if (a.compareTo(HALF) >= 0)
			a = a.subtract(MOD);
		if (b.compareTo(HALF) >= 0)
			b = b.subtract(MOD);

		return (a.compareTo(b) < 0 ? ONE : ZERO);
	}

	/**
	 * Performs a signed greater-than comparison between this
	 * {@code StackElement} and another {@code StackElement}. The comparison
	 * considers the signed numerical values of the two elements and returns a
	 * new {@code StackElement} representing the result.
	 *
	 * @param other the {@code StackElement} to compare this
	 *                  {@code StackElement} with
	 * 
	 * @return a new {@code StackElement} representing the result of the
	 *             comparison: {@code ONE} if this element is greater than
	 *             {@code other}, {@code ZERO} otherwise. Returns predefined
	 *             elements such as {@code BOTTOM}, {@code NOT_JUMPDEST_TOP}, or
	 *             other specific cases depending on the properties of the
	 *             operands.
	 */
	public StackElement sgt(StackElement other) {
		if (isBottom() || other.isBottom())
			return BOTTOM;
		if (isTop() || other.isTop())
			return NOT_JUMPDEST_TOP;
		if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;

		BigInteger a = Number.toBigInteger(this.n);
		BigInteger b = Number.toBigInteger(other.n);

		BigInteger HALF = BigInteger.valueOf(2).pow(255);
		BigInteger MOD = BigInteger.valueOf(2).pow(256);
		if (a.compareTo(HALF) >= 0)
			a = a.subtract(MOD);
		if (b.compareTo(HALF) >= 0)
			b = b.subtract(MOD);

		return (a.compareTo(b) > 0 ? ONE : ZERO);
	}

	/**
	 * Performs a left bitwise shift operation on this {@code StackElement}
	 * using the value of another {@code StackElement}.
	 *
	 * @param other the {@code StackElement} whose value is used as the shift
	 *                  amount
	 * 
	 * @return a new {@code StackElement} resulting from the left-shift
	 *             operation or a special {@code StackElement} (e.g., bottom,
	 *             top) in certain cases
	 */
	public StackElement shl(StackElement other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;
		else if (n.compareTo(new Number(256)) > 0)
			return ZERO;

		int[] bits = BitManager.toBitArray(Number.toBigInteger(other.n));
		int[] shiftedBits = BitManager.shiftLeft(bits, n.getInt());
		BigInteger result = BitManager.fromBitArray(shiftedBits);

		return new StackElement(new Number(result));
	}

	/**
	 * Performs a bitwise shift right operation on the current stack element
	 * using another stack element as the shift operand.
	 *
	 * @param other The stack element that specifies the number of positions to
	 *                  shift to the right. It must not be null.
	 * 
	 * @return The resulting StackElement after performing the shift operation.
	 *             Returns a "bottom" StackElement if the operation is invalid
	 *             or if either of the StackElements involved indicate a
	 *             "bottom" condition.
	 */
	public StackElement shr(StackElement other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;
		else if (n.compareTo(new Number(256)) > 0)
			return ZERO;

		int[] bits = BitManager.toBitArray(Number.toBigInteger(other.n));
		int[] shiftedBits = BitManager.shiftRight(bits, n.getInt());
		BigInteger result = BitManager.fromBitArray(shiftedBits);

		return new StackElement(new Number(result));
	}

	/**
	 * Performs an arithmetic shift-right operation between this stack element
	 * and another stack element provided as input. The method considers
	 * specific cases such as bottom, top, or top not jumpdest, and directly
	 * returns appropriate stack elements for those cases. Otherwise, it
	 * calculates the result based on the arithmetic shift-right operation.
	 *
	 * @param other the stack element with which this stack element is to be
	 *                  processed using the arithmetic shift-right operation.
	 * 
	 * @return a new stack element resulting from the arithmetic shift-right
	 *             operation, or a special stack element (bottom, top,
	 *             NOT_JUMPDEST_TOP) based on predefined conditions.
	 */
	public StackElement sar(StackElement other) {
		if (isBottom() || other.isBottom())
			return bottom();
		else if (isTop() || other.isTop())
			return top();
		else if (isTopNotJumpdest() || other.isTopNotJumpdest())
			return NOT_JUMPDEST_TOP;
		else if (n.compareTo(new Number(Number.MAX_INT)) > 0)
			return bottom(); // fake path

		int[] bits = BitManager.toBitArray(Number.toBigInteger(other.n));
		int[] shiftedBits = BitManager.arithmeticShiftRight(bits, n.getInt());
		BigInteger result = BitManager.fromBitArray(shiftedBits);

		return new StackElement(new Number(result));
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

	/**
	 * Checks if the current instance is equal to the constant NOT_JUMPDEST_TOP.
	 *
	 * @return true if the current instance is NOT_JUMPDEST_TOP, otherwise
	 *             false.
	 */
	public boolean isTopNotJumpdest() {
		return this == NOT_JUMPDEST_TOP;
	}

	/**
	 * Checks if the current instance is equal to the constant TOP.
	 *
	 * @return true if the current instance is equal to TOP, false otherwise.
	 */
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
		StackElement other = (StackElement) obj;
		if (this.isBottom() && other.isBottom())
			return true;
		if (this.isTop() && other.isTop())
			return true;
		if (this.isTopNotJumpdest() && other.isTopNotJumpdest())
			return true;

		if (this.isBottom() || other.isBottom() ||
				this.isTop() || other.isTop() ||
				this.isTopNotJumpdest() || other.isTopNotJumpdest())
			return false;

		return this.n.equals(other.n);
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