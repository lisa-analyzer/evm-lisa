package it.unipr.analysis.taint;

import it.unive.lisa.analysis.BaseLattice;
import it.unive.lisa.analysis.Lattice;
import it.unive.lisa.util.representation.StringRepresentation;
import it.unive.lisa.util.representation.StructuredRepresentation;
import java.util.Objects;

/**
 * Represents an element in the taint abstract domain for EVM bytecode analysis.
 * <p>
 * This class models a taint element using a simple byte value and defines
 * several special constants:
 * <ul>
 * <li><b>TOP</b>: Represents the highest abstract value, indicating an unknown
 * or over-approximated value.</li>
 * <li><b>BOTTOM</b>: Represents the lowest abstract value, indicating the
 * absence of any information or an error state.</li>
 * <li><b>TAINT</b>: Marks an element as tainted, meaning it carries untrusted
 * or external data that may lead to vulnerabilities.</li>
 * <li><b>CLEAN</b>: Marks an element as clean, meaning it is not tainted.</li>
 * </ul>
 * </p>
 *
 * @see BaseLattice
 * @see Lattice
 */
public class TaintElement implements BaseLattice<TaintElement> {

	public static final TaintElement TOP = new TaintElement((byte) 0);
	public static final TaintElement BOTTOM = new TaintElement((byte) 1);
	public static final TaintElement TAINT = new TaintElement((byte) 2);
	public static final TaintElement CLEAN = new TaintElement((byte) 3);

	private final byte v;

	public TaintElement(byte v) {
		this.v = v;
	}

	@Override
	public TaintElement top() {
		return TOP;
	}

	@Override
	public TaintElement bottom() {
		return BOTTOM;
	}

	@Override
	public StructuredRepresentation representation() {
		if (isTop())
			return Lattice.topRepresentation();
		else if (isBottom())
			return Lattice.bottomRepresentation();
		else if (isClean())
			return new StringRepresentation("Clean");
		return new StringRepresentation("Taint");
	}

	@Override
	public String toString() {
		if (isTop())
			return Lattice.TOP_STRING;
		else if (isBottom())
			return Lattice.BOTTOM_STRING;
		else if (isClean())
			return "C";
		return "T";
	}

	/**
	 * Yields {@code true} if this value is taint, {@code false} otherwise.
	 * 
	 * @return {@code true} if this value is taint, {@code false} otherwise
	 */
	public boolean isTaint() {
		return this == TAINT;
	}

	/**
	 * Yields {@code true} if this value is clean, {@code false} otherwise.
	 * 
	 * @return {@code true} if this value is clean, {@code false} otherwise
	 */
	public boolean isClean() {
		return this == CLEAN;
	}

	@Override
	public TaintElement lubAux(TaintElement other) {
		return TOP;
	}

	@Override
	public boolean lessOrEqualAux(TaintElement other) {
		return false;
	}

	@Override
	public TaintElement glbAux(TaintElement other) {
		return BOTTOM;
	}

	@Override
	public boolean isTop() {
		return this == TOP;
	}

	@Override
	public boolean isBottom() {
		return this == BOTTOM;
	}

	/**
	 * Check whether a set of {@link TaintElement}s contains at least one
	 * tainted element, if so returns taint. Otherwise, if there is at least a
	 * top element, top is returned. As last, clean is returned.
	 * 
	 * @param elements the array of abstract values
	 * 
	 * @return taint, top, bottom or clean after checking the value of the
	 *             elements in the given array
	 */
	public static TaintElement semantics(TaintElement... elements) {
		if (elements.length == 0)
			return BOTTOM;

		boolean checkTop = false;
		for (TaintElement t : elements)
			if (t == TAINT)
				return TAINT;
			else if (t == TOP)
				checkTop = true;

		if (checkTop)
			return TOP;

		return CLEAN;
	}

	/**
	 * Checks if any of the provided {@link TaintElement} objects is tainted or
	 * has the top value.
	 *
	 * @param elements the array of {@link TaintElement} objects to check
	 * 
	 * @return {@code true} if at least one of the elements is tainted or has
	 *             the top value, {@code false} otherwise
	 */
	public static boolean isTaintedOrTop(TaintElement... elements) {
		return isAtLeastOneTainted(elements) || isAtLeastOneTop(elements);
	}

	/**
	 * Checks if at least one of the provided {@link TaintElement} objects is
	 * tainted.
	 *
	 * @param elements the array of {@link TaintElement} objects to check
	 * 
	 * @return {@code true} if at least one of the elements is tainted,
	 *             {@code false} otherwise
	 */
	public static boolean isAtLeastOneTainted(TaintElement... elements) {
		for (TaintElement element : elements) {
			if (element.isTaint())
				return true;
		}
		return false;
	}

	/**
	 * Checks if at least one of the provided {@link TaintElement} objects has
	 * the top value.
	 *
	 * @param elements the array of {@link TaintElement} objects to check
	 * 
	 * @return {@code true} if at least one of the elements has the top value,
	 *             {@code false} otherwise
	 */
	public static boolean isAtLeastOneTop(TaintElement... elements) {
		for (TaintElement element : elements) {
			if (element.isTop())
				return true;
		}
		return false;
	}

	@Override
	public int hashCode() {
		return Objects.hash(v);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		TaintElement other = (TaintElement) obj;
		return v == other.v;
	}
}
