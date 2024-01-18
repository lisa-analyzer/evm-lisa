package it.unipr.analysis;

import it.unive.lisa.analysis.lattices.FunctionalLattice;
import it.unive.lisa.analysis.numeric.Interval;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

public class Memory extends FunctionalLattice<Memory, BigDecimal, Interval> {

	/**
	 * Default constructor for Memory. Initializes the Memory with a default
	 * lattice (Interval). The default lattice is a single Interval representing
	 * the entire range of possible values (TOP).
	 */
	public Memory() {
		this(new Interval());
	}

	/**
	 * Constructor for Memory that allows specifying an initial lattice.
	 *
	 * @param lattice The initial lattice (Interval) for the Memory.
	 */
	public Memory(Interval lattice) {
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
	public Memory(Interval lattice, Map<BigDecimal, Interval> function) {
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
	public Memory mk(Interval lattice, Map<BigDecimal, Interval> function) {
		return new Memory(lattice, function);
	}

	/**
	 * Yields the lattice inside this memory.
	 * 
	 * @return the lattice inside this memory
	 */
	public Interval getLattice() {
		return this.lattice;
	}

	@Override
	public Memory clone() {
		return new Memory(lattice, getMap());
	}

}
