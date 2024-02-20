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
	
	
	

//	@Override
//	public Iterator<AbstractStack> iterator() {
//		return stacks.iterator();
//	}

//	@Override
//	public String toString() {
//		String str = "{";
//		for (AbstractStack stack : stacks) {
//			str += stack.toString() + ", ";
//		}
//		str += "}";
//		return str;
//	}


//	// TODO check
//	public AbstractStackSet widening(AbstractStackSet other) throws SemanticException {
//		AbstractStackSet result = this.clone();
//		for (AbstractStack stack : other)
//			result.add(stack);
//		return result;
//	}
//
//	// TODO check
//	public AbstractStackSet glb(AbstractStackSet other) throws SemanticException {
//		AbstractStackSet result = this.clone();
//		for (AbstractStack stack : other)
//			result.add(stack);
//		return result;
//	}

//	// TODO check
//	@Override
//	public AbstractStackSet lubAux(AbstractStackSet other) throws SemanticException {
//		AbstractStackSet result = this.clone();
//		for (AbstractStack stack : other)
//			result.add(stack);
//		return result;
//	}

//	// TODO check
//	@Override
//	public boolean lessOrEqualAux(AbstractStackSet other) throws SemanticException {
//		if (this.size() < other.size())
//			return true;
//		else if (this.size() > other.size())
//			return false;
//
//		Iterator<AbstractStack> itThis = this.iterator();
//		Iterator<AbstractStack> itOther = other.iterator();
//
//		while (itThis.hasNext() && itOther.hasNext()) {
//			if (!itThis.next().lessOrEqualAux(itOther.next()))
//				return false;
//		}
//
//		return true;
//	}

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
