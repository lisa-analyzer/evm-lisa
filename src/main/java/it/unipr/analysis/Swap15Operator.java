package it.unipr.analysis;

import it.unive.lisa.caches.Caches;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.Untyped;
import it.unive.lisa.util.collections.externalSet.ExternalSet;

public class Swap15Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Swap15Operator INSTANCE = new Swap15Operator();

	private Swap15Operator() {
	}

	@Override
	public String toString() {
		return "swap15";
	}

	@Override
	public ExternalSet<Type> typeInference(ExternalSet<Type> argument) {
		return Caches.types().mkSingletonSet(Untyped.INSTANCE);
	}

}
