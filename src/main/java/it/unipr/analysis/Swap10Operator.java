package it.unipr.analysis;

import it.unive.lisa.caches.Caches;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.Untyped;
import it.unive.lisa.util.collections.externalSet.ExternalSet;

public class Swap10Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Swap10Operator INSTANCE = new Swap10Operator();

	private Swap10Operator() {
	}

	@Override
	public String toString() {
		return "swap10";
	}

	@Override
	public ExternalSet<Type> typeInference(ExternalSet<Type> argument) {
		return Caches.types().mkSingletonSet(Untyped.INSTANCE);
	}

}
