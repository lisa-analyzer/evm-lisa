package it.unipr.analysis.operator;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

public class ExpOperator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final ExpOperator INSTANCE = new ExpOperator();

	private ExpOperator() {
	}

	@Override
	public String toString() {
		return "exp";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}

}
