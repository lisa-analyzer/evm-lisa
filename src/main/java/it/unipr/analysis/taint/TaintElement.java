package it.unipr.analysis.taint;

import it.unive.lisa.analysis.BaseLattice;
import it.unive.lisa.analysis.Lattice;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.util.representation.StringRepresentation;
import it.unive.lisa.util.representation.StructuredRepresentation;
import java.util.Objects;

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
	private boolean isClean() {
		return this == CLEAN;
	}

	@Override
	public TaintElement lubAux(TaintElement other) throws SemanticException {
		return TOP;
	}

	@Override
	public boolean lessOrEqualAux(TaintElement other) throws SemanticException {
		return false;
	}

	@Override
	public TaintElement glbAux(TaintElement other) throws SemanticException {
		return BOTTOM;
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

		if (checkTop == true)
			return TOP;

		return CLEAN;
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
