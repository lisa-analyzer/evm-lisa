package it.unipr.analysis;

import it.unive.lisa.caches.Caches;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.common.Int32;
import it.unive.lisa.util.collections.externalSet.ExternalSet;

/**
 * Implementation of UnaryOperator to represent the Push operator of Ethereum Bytecode.
 */
public class PushOperator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final PushOperator INSTANCE = new PushOperator();

	private PushOperator() {
	}

	@Override
	public String toString() {
		return "push";
	}

	@Override
	public ExternalSet<Type> typeInference(ExternalSet<Type> argument) {
		return Caches.types().mkSingletonSet(Int32.INSTANCE);
	}

}
