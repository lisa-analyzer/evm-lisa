package it.unipr.analysis;

import it.unive.lisa.caches.Caches;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.Untyped;
import it.unive.lisa.util.collections.externalSet.ExternalSet;

public class Dup16Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Dup16Operator INSTANCE = new Dup16Operator();

	private Dup16Operator() {
	}

	@Override
	public String toString() {
		return "dup16";
	}

	@Override
	public ExternalSet<Type> typeInference(ExternalSet<Type> argument) {
		return Caches.types().mkSingletonSet(Untyped.INSTANCE);
	}

}
