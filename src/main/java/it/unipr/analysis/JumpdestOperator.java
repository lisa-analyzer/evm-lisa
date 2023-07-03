package it.unipr.analysis;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

public class JumpdestOperator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final JumpdestOperator INSTANCE = new JumpdestOperator();

	private JumpdestOperator() {
	}

	@Override
	public String toString() {
		return "jumpdest";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}

}
