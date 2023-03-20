package it.unipr.analysis;

import it.unive.lisa.caches.Caches;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.Untyped;
import it.unive.lisa.util.collections.externalSet.ExternalSet;

public class AddOperator implements UnaryOperator {
	
	/**
	 * The singleton instance of this class.
	 */
	public static final AddOperator INSTANCE = new AddOperator();

	private AddOperator() {
	}

	@Override
	public String toString() {
		return "add";
	}

	@Override
	public ExternalSet<Type> typeInference(ExternalSet<Type> argument) {
		return Caches.types().mkSingletonSet(Untyped.INSTANCE);
	}
}
