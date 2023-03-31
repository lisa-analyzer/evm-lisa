package it.unipr.analysis;

import it.unive.lisa.caches.Caches;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.Untyped;
import it.unive.lisa.util.collections.externalSet.ExternalSet;

public class Swap5Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Swap5Operator INSTANCE = new Swap5Operator();

	private Swap5Operator() {
	}

	@Override
	public String toString() {
		return "swap5";
	}

	@Override
	public ExternalSet<Type> typeInference(ExternalSet<Type> argument) {
		return Caches.types().mkSingletonSet(Untyped.INSTANCE);
	}

}
