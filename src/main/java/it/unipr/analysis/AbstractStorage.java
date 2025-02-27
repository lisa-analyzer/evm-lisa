package it.unipr.analysis;

import it.unive.lisa.analysis.lattices.FunctionalLattice;
import java.util.HashMap;
import java.util.Map;

public class AbstractStorage extends FunctionalLattice<AbstractStorage, Number, StackElement> {

	/**
	 * Default constructor for AbstractStorage. Initializes the AbstractStorage
	 * with a default lattice (Interval). The default lattice is a single
	 * Interval representing the entire range of possible values (TOP).
	 */
	public AbstractStorage() {
		this(new StackElement());
	}

	/**
	 * Constructor for AbstractStorage that allows specifying an initial
	 * lattice.
	 *
	 * @param lattice The initial lattice (Interval) for the AbstractStorage.
	 */
	public AbstractStorage(StackElement lattice) {
		this(lattice, new HashMap<>());
	}

	/**
	 * Constructor for AbstractStorage that allows specifying both an initial
	 * lattice and an initial function.
	 *
	 * @param lattice  The initial lattice (Interval) for the AbstractStorage.
	 * @param function The initial function (mapping of addresses to Intervals)
	 *                     for the AbstractStorage.
	 */
	public AbstractStorage(StackElement lattice, Map<Number, StackElement> function) {
		super(lattice, function);
	}

	@Override
	public AbstractStorage top() {
		return isTop() ? this : new AbstractStorage(lattice.top(), null);
	}

	@Override
	public AbstractStorage bottom() {
		return isBottom() ? this : new AbstractStorage(lattice.bottom(), null);
	}

	@Override
	public AbstractStorage mk(StackElement lattice, Map<Number, StackElement> function) {
		return new AbstractStorage(lattice, function);
	}

	/**
	 * Yields the lattice inside this memory.
	 * 
	 * @return the lattice inside this memory
	 */
	public StackElement getLattice() {
		return this.lattice;
	}

	@Override
	public AbstractStorage clone() {
		return new AbstractStorage(lattice, getMap());
	}

	@Override
	public StackElement stateOfUnknown(Number key) {
		return StackElement.TOP;
	}
}
