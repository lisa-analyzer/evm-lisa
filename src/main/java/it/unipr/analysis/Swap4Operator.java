package it.unipr.analysis;

import it.unive.lisa.caches.Caches;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.Untyped;
import it.unive.lisa.util.collections.externalSet.ExternalSet;

public class Swap4Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Swap4Operator INSTANCE = new Swap4Operator();

	private Swap4Operator() {
	}

	@Override
	public String toString() {
		return "swap4";
	}

	@Override
	public ExternalSet<Type> typeInference(ExternalSet<Type> argument) {
		return Caches.types().mkSingletonSet(Untyped.INSTANCE);
	}

}
