package it.unipr.analysis;

import it.unive.lisa.caches.Caches;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.Untyped;
import it.unive.lisa.util.collections.externalSet.ExternalSet;

public class SgtOperator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final SgtOperator INSTANCE = new SgtOperator();

	private SgtOperator() {
	}

	@Override
	public String toString() {
		return "sgt";
	}

	@Override
	public ExternalSet<Type> typeInference(ExternalSet<Type> argument) {
		return Caches.types().mkSingletonSet(Untyped.INSTANCE);
	}

}
