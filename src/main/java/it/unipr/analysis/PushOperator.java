package it.unipr.analysis;

import java.util.Collections;
import java.util.Set;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;

/**
 * Implementation of UnaryOperator to represent the Push operator of Ethereum
 * Bytecode.
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
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}

}
