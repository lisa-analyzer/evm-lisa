package it.unipr.analysis.operator;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

/**
 * The DUP4 symbolic operator.
 * 
 * @author <a href="mailto:vincenzo.arceri@unipr.it">Vincenzo Arceri</a>
 */
public class Dup4Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Dup4Operator INSTANCE = new Dup4Operator();

	private Dup4Operator() {
	}

	@Override
	public String toString() {
		return "dup4";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}

}
