package it.unipr.analysis;

import it.unive.lisa.caches.Caches;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.Untyped;
import it.unive.lisa.util.collections.externalSet.ExternalSet;

public class Swap13Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Swap13Operator INSTANCE = new Swap13Operator();

	private Swap13Operator() {
	}

	@Override
	public String toString() {
		return "swap13";
	}

	@Override
	public ExternalSet<Type> typeInference(ExternalSet<Type> argument) {
		return Caches.types().mkSingletonSet(Untyped.INSTANCE);
	}

}
