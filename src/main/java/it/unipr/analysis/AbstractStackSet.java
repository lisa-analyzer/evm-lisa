package it.unipr.analysis;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

import it.unive.lisa.analysis.lattices.SetLattice;

public class AbstractStackSet extends SetLattice<AbstractStackSet, AbstractStack> {

	private static final AbstractStackSet BOTTOM = new AbstractStackSet(null, false);
	private static final AbstractStackSet TOP = new AbstractStackSet(Collections.emptySet(), true);

	public AbstractStackSet() {
		super(new HashSet<AbstractStack>(), false);
		this.elements.add(new AbstractStack());
	}

	public AbstractStackSet(Set<AbstractStack> elements, boolean isTop) {
		super(elements, isTop);
	}

	public void add(AbstractStack other) {
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

	public int size() {
		return this.elements().size();
	}

	@Override
	public AbstractStackSet clone() {
		if (isTop())
			return TOP;
		else if (isBottom())
			return BOTTOM;
		AbstractStackSet result = new AbstractStackSet();
		for (AbstractStack stack : elements())
			result.add(stack.clone());
		return result;
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
		// TODO Auto-generated method stub
		return null;
	}

}
