package it.unipr.analysis.operator;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

/**
 * The MUL symbolic operator.
 * 
 * @author <a href="mailto:vincenzo.arceri@unipr.it">Vincenzo Arceri</a>
 */
public class MulOperator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final MulOperator INSTANCE = new MulOperator();

	private MulOperator() {
	}

	@Override
	public String toString() {
		return "mul";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}

}
