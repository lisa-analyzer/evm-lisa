package it.unipr.analysis;

import it.unive.lisa.analysis.lattices.FunctionalLattice;
import it.unive.lisa.analysis.numeric.Interval;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

public class Memory extends FunctionalLattice<Memory, BigDecimal, Interval> {

	public Memory() {
		this(new Interval());
	}

	public Memory(Interval lattice) {
		this(lattice, new HashMap<BigDecimal, Interval>());
	}

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

} // ! Memory
