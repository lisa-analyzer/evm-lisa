package it.unipr.analysis.taint;

import it.unive.lisa.analysis.BaseLattice;
import it.unive.lisa.analysis.Lattice;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.util.representation.StringRepresentation;
import it.unive.lisa.util.representation.StructuredRepresentation;

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
	
	/**
	 * Yields {@code true} if this value is taint, {@code false} otherwise.
	 * @return {@code true} if this value is taint, {@code false} otherwise
	 */ 
	private boolean isTaint() {
		return this == TAINT;
	}

	/**
	 * Yields {@code true} if this value is clean, {@code false} otherwise.
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

	
	
}
