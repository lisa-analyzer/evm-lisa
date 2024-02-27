package it.unipr.analysis;

import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.lattices.SetLattice;
import java.util.Collections;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;

public class AbstractStackSet extends SetLattice<AbstractStackSet, AbstractStack> {

	private static int SIZE = 256;
	private static final AbstractStackSet BOTTOM = new AbstractStackSet(null, false);
	private static final AbstractStackSet TOP = new AbstractStackSet(Collections.emptySet(), true);

	public AbstractStackSet() {
		super(new HashSet<AbstractStack>(), false);
		this.elements.add(new AbstractStack());
	}

	public AbstractStackSet(Set<AbstractStack> elements, boolean isTop) {
		super(elements, isTop);
	}

	/**
	 * Add a new AbstractStack to the set if it is not bottom
	 * 
	 * @param other AbstractStack
	 */
	public void add(AbstractStack other) {
		if (!other.isBottom())
			this.elements.add(other);
	}

	public AbstractStackSet top() {
		return TOP;
	}

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
	public AbstractStackSet clone() {
		if (isTop())
			return TOP;
		else if (isBottom())
			return BOTTOM;
		return new AbstractStackSet(new HashSet<>(this.elements), false);

//		AbstractStackSet result = new AbstractStackSet(new HashSet<AbstractStack>(), false);
//		for (AbstractStack stack : elements())
//			result.add(stack.clone());
//		return result;
	}

	@Override
	public AbstractStackSet lubAux(AbstractStackSet other) throws SemanticException {
		AbstractStackSet lubAux = super.lubAux(other);
		if (lubAux.size() > SIZE)
			return TOP;
		return lubAux;
	}

	@Override
	public int hashCode() {
		return super.hashCode();
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (!super.equals(obj))
			return false;
		if (getClass() != obj.getClass())
			return false;
		return true;
	}

	@Override
	public AbstractStackSet mk(Set<AbstractStack> set) {
		return new AbstractStackSet(set, false);
	}

	public String toString2() {
		String result = "{";
		Iterator<AbstractStack> it = elements.iterator();

		while (it.hasNext()) {
			result += it.next().toString();
			if (it.hasNext())
				result += ", ";
		}

		result += "}";

		return result;
	}

	/**
	 * Set the stack set limit
	 * 
	 * @param n the new stack set limit
	 */
	public static void setStackSetSize(int n) {
		if (n > 0)
			SIZE = n;
	}

	/**
	 * Yields the stack set limit
	 * 
	 * @return the stack set limit
	 */
	public static int getStackSetLimit() {
		return SIZE;
	}
}
