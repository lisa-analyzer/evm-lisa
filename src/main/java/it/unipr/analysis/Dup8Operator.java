package it.unipr.analysis;

import it.unive.lisa.caches.Caches;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.Untyped;
import it.unive.lisa.util.collections.externalSet.ExternalSet;

public class Dup8Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Dup8Operator INSTANCE = new Dup8Operator();

	private Dup8Operator() {
	}

	@Override
	public String toString() {
		return "dup8";
	}

	@Override
	public ExternalSet<Type> typeInference(ExternalSet<Type> argument) {
		return Caches.types().mkSingletonSet(Untyped.INSTANCE);
	}

}
