package it.unipr.analysis;

import it.unive.lisa.caches.Caches;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.Untyped;
import it.unive.lisa.util.collections.externalSet.ExternalSet;

public class Dup10Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Dup10Operator INSTANCE = new Dup10Operator();

	private Dup10Operator() {
	}

	@Override
	public String toString() {
		return "dup10";
	}

	@Override
	public ExternalSet<Type> typeInference(ExternalSet<Type> argument) {
		return Caches.types().mkSingletonSet(Untyped.INSTANCE);
	}

}
