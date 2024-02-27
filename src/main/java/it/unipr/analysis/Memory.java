package it.unipr.analysis;

import java.math.BigInteger;
import java.util.HashMap;
import java.util.Map;

import it.unive.lisa.analysis.lattices.FunctionalLattice;

public class Memory extends FunctionalLattice<Memory, BigInteger, KIntegerSet> {

	/**
	 * Default constructor for Memory. Initializes the Memory with a default
	 * lattice (Interval). The default lattice is a single Interval representing
	 * the entire range of possible values (TOP).
	 */
	public Memory() {
		this(new KIntegerSet());
	}

	/**
	 * Constructor for Memory that allows specifying an initial lattice.
	 *
	 * @param lattice The initial lattice (Interval) for the Memory.
	 */
	public Memory(KIntegerSet lattice) {
		this(lattice, new HashMap<>());
	}

	/**
	 * Constructor for Memory that allows specifying both an initial lattice and
	 * an initial function.
	 *
	 * @param lattice  The initial lattice (Interval) for the Memory.
	 * @param function The initial function (mapping of addresses to Intervals)
	 *                     for the Memory.
	 */
	public Memory(KIntegerSet lattice, Map<BigInteger, KIntegerSet> function) {
		super(lattice, function);
	}

	@Override
	public Memory top() {
		return isTop() ? this : new Memory(lattice.top(), null);
	}

	@Override
	public Memory bottom() {
		return isBottom() ? this : new Memory(lattice.bottom(), null);
	}

	@Override
	public Memory mk(KIntegerSet lattice, Map<BigInteger, KIntegerSet> function) {
		return new Memory(lattice, function);
	}

	/**
	 * Yields the lattice inside this memory.
	 * 
	 * @return the lattice inside this memory
	 */
	public KIntegerSet getLattice() {
		return this.lattice;
	}

	@Override
	public Memory clone() {
		return new Memory(lattice, getMap());
	}

}
