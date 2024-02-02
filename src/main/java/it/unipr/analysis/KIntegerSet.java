package it.unipr.analysis;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

import it.unive.lisa.analysis.SemanticDomain.Satisfiability;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.lattices.SetLattice;

public class KIntegerSet extends SetLattice<KIntegerSet, BigDecimal> {

	public static final KIntegerSet ZERO = new KIntegerSet(0);
	public static final KIntegerSet ONE = new KIntegerSet(1);
	public static final KIntegerSet ZERO_OR_ONE = new KIntegerSet(0, 1);
	public static final KIntegerSet TOP = new KIntegerSet(true);
	public static final KIntegerSet BOTTOM = new KIntegerSet();

	public static int K = 3;

	public KIntegerSet() {
		this(Collections.emptySet(), false);
	}

	public KIntegerSet(BigDecimal i) {
		this(Collections.singleton(i), false);
	}

	public KIntegerSet(Integer... ints) {
		super(new HashSet<>(), false);
		for (Integer i : ints)
			this.elements.add(new BigDecimal(i));
	}
	
	public KIntegerSet(BigDecimal... ints) {
		super(Collections.emptySet(), false);
		for (BigDecimal i : ints)
			this.elements.add(i);
	}

	public KIntegerSet(Integer i) {
		this(Collections.singleton(new BigDecimal(i)), false);
	}

	public KIntegerSet(Set<BigDecimal> set) {
		this(set, false);
	}

	private KIntegerSet(boolean isTop) {
		this(Collections.emptySet(), isTop);
	}

	public KIntegerSet(Set<BigDecimal> elements, boolean isTop) {
		super(elements, isTop);
	}

	@Override
	public KIntegerSet top() {
		return TOP;
	}

	@Override
	public KIntegerSet bottom() {
		return new KIntegerSet();
	}

	@Override
	public KIntegerSet lubAux(KIntegerSet other) throws SemanticException {
		KIntegerSet result = super.lubAux(other);
		return result.size() > K ? top() : result;
	}

	@Override
	public KIntegerSet wideningAux(KIntegerSet other) throws SemanticException {
		KIntegerSet result = super.widening(other);
		return result.size() > K ? top() : result;
	}

	@Override
	public KIntegerSet glbAux(KIntegerSet other) throws SemanticException {
		KIntegerSet result = super.glb(other);
		return result.size() > K ? top() : result;
	}

	@Override
	public KIntegerSet mk(Set<BigDecimal> set) {
		return new KIntegerSet(set);
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

	public Satisfiability isZero() {
		if (equals(ZERO))
			return Satisfiability.SATISFIED;
		else if (!contains(new BigDecimal(0)))
			return Satisfiability.NOT_SATISFIED;
		return Satisfiability.UNKNOWN;
	}

	public KIntegerSet sum(KIntegerSet other) {
		Set<BigDecimal> elements = new HashSet<>();

		for (BigDecimal i : this.elements)
			for (BigDecimal j : other.elements)
				elements.add(i.add(j));

		return new KIntegerSet(elements);
	}

	public KIntegerSet sub(KIntegerSet other) {
		Set<BigDecimal> elements = new HashSet<>();

		for (BigDecimal i : this.elements)
			for (BigDecimal j : other.elements)
				elements.add(i.subtract(j));

		return new KIntegerSet(elements);
	}

	public KIntegerSet mul(KIntegerSet other) {
		Set<BigDecimal> elements = new HashSet<>();

		for (BigDecimal i : this.elements)
			for (BigDecimal j : other.elements)
				elements.add(i.multiply(j));

		return new KIntegerSet(elements);
	}

	public KIntegerSet div(KIntegerSet other) {
		// TODO: to implement
		return top();
	}

	public KIntegerSet mod(KIntegerSet other) {
		// TODO: to implement
		return top();
	}

	public KIntegerSet exp(KIntegerSet other) {
		Set<BigDecimal> elements = new HashSet<>();

		for (BigDecimal i : this.elements)
			for (BigDecimal j : other.elements)
				elements.add(new BigDecimal(Math.pow(i.doubleValue(), j.doubleValue())));

		return new KIntegerSet(elements);
	}

	public Satisfiability lt(KIntegerSet other) {
		Set<Boolean> r = new HashSet<Boolean>();

		for (BigDecimal i : this.elements)
			for (BigDecimal j : other.elements)
				r.add(i.compareTo(j) == -1);

		if (r.size() == 2)
			return Satisfiability.UNKNOWN;
		else if (r.contains(true))
			return Satisfiability.SATISFIED;
		return Satisfiability.NOT_SATISFIED;
	}

	public Satisfiability gt(KIntegerSet other) {
		Set<Boolean> r = new HashSet<Boolean>();

		for (BigDecimal i : this.elements)
			for (BigDecimal j : other.elements)
				r.add(i.compareTo(j) == 1);

		if (r.size() == 2)
			return Satisfiability.UNKNOWN;
		else if (r.contains(true))
			return Satisfiability.SATISFIED;
		return Satisfiability.NOT_SATISFIED;
	}

	public Satisfiability eq(KIntegerSet other) {
		Set<Boolean> r = new HashSet<Boolean>();

		for (BigDecimal i : this.elements)
			for (BigDecimal j : other.elements)
				r.add(i.compareTo(j) == 0);

		if (r.size() == 2)
			return Satisfiability.UNKNOWN;
		else if (r.contains(true))
			return Satisfiability.SATISFIED;
		return Satisfiability.NOT_SATISFIED;
	}

	public KIntegerSet and(KIntegerSet other) {
		Set<BigDecimal> elements = new HashSet<>();

		for (BigDecimal i : this.elements)
			for (BigDecimal j : other.elements)
				elements.add(new BigDecimal(i.longValue() & j.longValue()));

		return new KIntegerSet(elements);
	}	

	public KIntegerSet or(KIntegerSet other) {
		Set<BigDecimal> elements = new HashSet<>();

		for (BigDecimal i : this.elements)
			for (BigDecimal j : other.elements)
				elements.add(new BigDecimal(i.longValue() | j.longValue()));

		return new KIntegerSet(elements);
	}

	public KIntegerSet xor(KIntegerSet other) {
		Set<BigDecimal> elements = new HashSet<>();

		for (BigDecimal i : this.elements)
			for (BigDecimal j : other.elements)
				elements.add(new BigDecimal(i.longValue() ^ j.longValue()));

		return new KIntegerSet(elements);
	}
}