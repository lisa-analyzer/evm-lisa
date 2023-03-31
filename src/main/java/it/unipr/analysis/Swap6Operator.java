package it.unipr.analysis;

import it.unive.lisa.caches.Caches;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.Untyped;
import it.unive.lisa.util.collections.externalSet.ExternalSet;

public class Swap6Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Swap6Operator INSTANCE = new Swap6Operator();

	private Swap6Operator() {
	}

	@Override
	public String toString() {
		return "swap6";
	}

	@Override
	public ExternalSet<Type> typeInference(ExternalSet<Type> argument) {
		return Caches.types().mkSingletonSet(Untyped.INSTANCE);
	}

}
