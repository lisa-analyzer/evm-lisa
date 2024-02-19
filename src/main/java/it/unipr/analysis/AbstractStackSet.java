package it.unipr.analysis;

import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.lattices.SetLattice;
import java.util.Collections;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Objects;
import java.util.Set;

public class AbstractStackSet extends SetLattice<AbstractStackSet, AbstractStack>
		implements Iterable<AbstractStack> {

	private Set<AbstractStack> stacks;
	private static final AbstractStackSet BOTTOM = new AbstractStackSet(null);
	private static final AbstractStackSet TOP = new AbstractStackSet(Collections.emptySet(), true);

	public AbstractStackSet() {
		super(new HashSet<AbstractStack>(), false);
		this.stacks = new HashSet<AbstractStack>();
		this.stacks.add(new AbstractStack());
	}

	public AbstractStackSet(AbstractStack other) {
		this();
		this.stacks.add(other);
	}

	public AbstractStackSet(Set<AbstractStack> elements, boolean isTop) {
		super(elements, isTop);
	}

	public void add(AbstractStack other) {
		stacks.add(other);
	}

	public AbstractStackSet top() {
		return TOP;
	}

	public AbstractStackSet bottom() {
		return BOTTOM;
	}

	public int size() {
		return stacks.size();
	}

	@Override
	public AbstractStackSet clone() {
		AbstractStackSet result = new AbstractStackSet();
		for (AbstractStack stack : stacks)
			result.add(stack.clone());
		return result;
	}

	@Override
	public Iterator<AbstractStack> iterator() {
		return stacks.iterator();
	}

//	@Override
//	public String toString() {
//		String str = "{";
//		for (AbstractStack stack : stacks) {
//			str += stack.toString() + ", ";
//		}
//		str += "}";
//		return str;
//	}

	@Override
	public int hashCode() {
		return Objects.hash(stacks);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;

		AbstractStackSet other = (AbstractStackSet) obj;

		if (this.size() != other.size())
			return false;

		Iterator<AbstractStack> itThis = this.iterator();
		Iterator<AbstractStack> itOther = other.iterator();

		while (itThis.hasNext() && itOther.hasNext()) {
			if (!Objects.equals(itThis.next(), itOther.next()))
				return false;
		}

		return true;
	}

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

	// TODO check
	@Override
	public boolean lessOrEqualAux(AbstractStackSet other) throws SemanticException {
		if (this.size() < other.size())
			return true;
		else if (this.size() > other.size())
			return false;

		Iterator<AbstractStack> itThis = this.iterator();
		Iterator<AbstractStack> itOther = other.iterator();

		while (itThis.hasNext() && itOther.hasNext()) {
			if (!itThis.next().lessOrEqualAux(itOther.next()))
				return false;
		}

		return true;
	}

	@Override
	public AbstractStackSet mk(Set<AbstractStack> set) {
		// TODO Auto-generated method stub
		return null;
	}

}
