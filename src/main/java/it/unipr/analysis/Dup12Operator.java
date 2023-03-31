package it.unipr.analysis;

import it.unive.lisa.caches.Caches;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.Untyped;
import it.unive.lisa.util.collections.externalSet.ExternalSet;

public class Dup12Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Dup12Operator INSTANCE = new Dup12Operator();

	private Dup12Operator() {
	}

	@Override
	public String toString() {
		return "dup12";
	}

	@Override
	public ExternalSet<Type> typeInference(ExternalSet<Type> argument) {
		return Caches.types().mkSingletonSet(Untyped.INSTANCE);
	}

}
