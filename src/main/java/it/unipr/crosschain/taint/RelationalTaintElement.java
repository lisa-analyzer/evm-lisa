package it.unipr.crosschain.taint;

import it.unipr.analysis.taint.TaintElement;
import it.unive.lisa.analysis.BaseLattice;
import it.unive.lisa.analysis.Lattice;
import it.unive.lisa.util.representation.StringRepresentation;
import it.unive.lisa.util.representation.StructuredRepresentation;
import java.util.*;

public class RelationalTaintElement implements BaseLattice<RelationalTaintElement> {
	public static final RelationalTaintElement TOP = new RelationalTaintElement((byte) 0);
	public static final RelationalTaintElement BOTTOM = new RelationalTaintElement((byte) 1);
	public static final RelationalTaintElement TAINT = new RelationalTaintElement((byte) 2);
	public static final RelationalTaintElement CLEAN = new RelationalTaintElement((byte) 3);

	private final byte v;
	private Set<Integer> programPoints = new HashSet<>();

	public RelationalTaintElement(byte v) {
		this(v, null);
	}

	public RelationalTaintElement(byte v, Integer programPoint) {
		this.v = v;
		if (programPoint != null)
			this.programPoints.add(programPoint);
	}

	/**
	 * Creates a new tainted relational taint element with the specified program
	 * points.
	 * 
	 * @param programPoints the program points to associate with the tainted
	 *                          element
	 * 
	 * @return a new RelationalTaintElement with type TAINT containing all the
	 *             provided program points
	 */
	public static RelationalTaintElement newRelationalTaintedElement(Integer... programPoints) {
		RelationalTaintElement t = new RelationalTaintElement((byte) 2);
		t.programPoints.addAll(List.of(programPoints));
		return t;
	}

	/**
	 * Returns the number of program points associated with this taint element.
	 * 
	 * @return the size of the program points set
	 */
	public int size() {
		return programPoints.size();
	}

	@Override
	public RelationalTaintElement lubAux(RelationalTaintElement other) {
		return TOP;
	}

	@Override
	public boolean lessOrEqualAux(RelationalTaintElement other) {
		return false;
	}

	@Override
	public RelationalTaintElement top() {
		return TOP;
	}

	@Override
	public RelationalTaintElement bottom() {
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

		if (programPoints.isEmpty())
			return new StringRepresentation("Taint");

		StringJoiner joiner = new StringJoiner(", ");
		for (Integer pp : programPoints) {
			joiner.add(String.valueOf(pp));
		}

		return new StringRepresentation("Taint[" + joiner.toString() + "]");
	}

	@Override
	public String toString() {
		if (isTop())
			return Lattice.TOP_STRING;
		else if (isBottom())
			return Lattice.BOTTOM_STRING;
		else if (isClean())
			return "C";
		if (programPoints.isEmpty())
			return "T";
		StringJoiner joiner = new StringJoiner(", ");
		for (Integer pp : programPoints) {
			joiner.add(String.valueOf(pp));
		}

		return "T[" + joiner.toString() + "]";
	}

	/**
	 * Yields {@code true} if this value is clean, {@code false} otherwise.
	 *
	 * @return {@code true} if this value is clean, {@code false} otherwise
	 */
	public boolean isClean() {
		return this == CLEAN;
	}

	/**
	 * Yields {@code true} if this value is taint, {@code false} otherwise.
	 *
	 * @return {@code true} if this value is taint, {@code false} otherwise
	 */
	public boolean isTaint() {
		return this.v == TAINT.v;
	}

	/**
	 * Computes the semantics of multiple relational taint elements by combining
	 * their program points.
	 * <p>
	 * This method combines all program points from taint elements encountered
	 * during semantic analysis. If any element is TOP, returns TOP immediately.
	 * If at least one element is taint, returns a new taint element containing
	 * all program points from the taint elements. If no taint elements are
	 * found, returns CLEAN. If no elements are provided, returns BOTTOM.
	 *
	 * @param elements the relational taint elements to combine
	 *
	 * @return a new RelationalTaintElement representing the combined semantics:
	 *             TOP if any element is TOP, a new taint element with combined
	 *             program points if at least one taint is found, CLEAN if no
	 *             taint elements are present, BOTTOM if the elements array is
	 *             empty
	 */
	public static RelationalTaintElement semantics(RelationalTaintElement... elements) {
		if (elements.length == 0)
			return BOTTOM;

		Set<Integer> combinedProgramPoints = new HashSet<>();
		boolean hasTaint = false;

		for (RelationalTaintElement t : elements) {
			if (t.isTop())
				return TOP;

			if (t.isTaint()) {
				hasTaint = true;
				combinedProgramPoints.addAll(t.programPoints);
			}
		}

		if (hasTaint) {
			RelationalTaintElement result = new RelationalTaintElement((byte) 2);
			result.programPoints = combinedProgramPoints;
			return result;
		}

		return CLEAN;
	}

	/**
	 * Checks if any of the provided {@link RelationalTaintElement} objects is
	 * tainted or has the top value.
	 *
	 * @param elements the array of {@link RelationalTaintElement} objects to
	 *                     check
	 *
	 * @return {@code true} if at least one of the elements is tainted or has
	 *             the top value, {@code false} otherwise
	 */
	public static boolean isTaintedOrTop(RelationalTaintElement... elements) {
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
	public static boolean isAtLeastOneTainted(RelationalTaintElement... elements) {
		for (RelationalTaintElement element : elements) {
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
	public static boolean isAtLeastOneTop(RelationalTaintElement... elements) {
		for (RelationalTaintElement element : elements) {
			if (element.isTop())
				return true;
		}
		return false;
	}

	@Override
	public int hashCode() {
		return Objects.hash(v, programPoints);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		RelationalTaintElement other = (RelationalTaintElement) obj;
		return v == other.v && programPoints.equals(other.programPoints);
	}
}
