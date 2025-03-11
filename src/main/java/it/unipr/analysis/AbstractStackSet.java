package it.unipr.analysis;

import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.lattices.SetLattice;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

public class AbstractStackSet extends SetLattice<AbstractStackSet, AbstractStack> {

	/**
	 * The maximum size of an abstract stack set.
	 */
	private static int SIZE = 8;

	/**
	 * The bottom element of the abstract stack set domain.
	 */
	private static final AbstractStackSet BOTTOM = new AbstractStackSet(null, false);

	/**
	 * The top element of the abstract stack set domain.
	 */
	private static final AbstractStackSet TOP = new AbstractStackSet(Collections.emptySet(), true);

	public AbstractStackSet() {
		super(new HashSet<AbstractStack>(), false);
		this.elements.add(new AbstractStack());
	}

	public AbstractStackSet(Set<AbstractStack> elements, boolean isTop) {
		super(elements, isTop);
	}

	/**
	 * Add a new abstract stack to the set if it is not bottom
	 * 
	 * @param other AbstractStack
	 */
	public void add(AbstractStack other) {
		if (!other.isBottom())
			this.elements.add(other);
	}

	@Override
	public AbstractStackSet top() {
		return TOP;
	}

	@Override
	public AbstractStackSet bottom() {
		return BOTTOM;
	}

	@Override
	public boolean isTop() {
		return !isBottom() && this.elements().isEmpty() && this.isTop == true;
	}

	@Override
	public boolean isBottom() {
		return this.elements == null;
	}

	@Override
	public int size() {
		return this.elements().size();
	}

	@Override
	public AbstractStackSet lubAux(AbstractStackSet other) throws SemanticException {
		AbstractStackSet lubAux = super.lubAux(other);
		if (lubAux.size() > SIZE)
			return TOP;
		return lubAux;
	}

	@Override
	public AbstractStackSet mk(Set<AbstractStack> set) {
		return new AbstractStackSet(set, false);
	}

	/**
	 * Sets the stack set limit.
	 * 
	 * @param n the new stack set limit
	 */
	public static void setStackSetSize(int n) {
		if (n > 0)
			SIZE = n;
	}

	/**
	 * Yields the stack set limit.
	 * 
	 * @return the stack set limit
	 */
	public static int getStackSetLimit() {
		return SIZE;
	}
}
