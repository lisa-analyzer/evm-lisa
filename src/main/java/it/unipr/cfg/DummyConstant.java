package it.unipr.cfg;

import it.unive.lisa.program.SyntheticLocation;
import it.unive.lisa.program.cfg.CodeLocation;
import it.unive.lisa.symbolic.value.Constant;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.Untyped;

/**
 * Dummy constant used in the EVM bytecode small-step semantics.
 * 
 * @author <a href="mailto:vincenzo.arceri@unipr.it">Vincenzo Arceri</a>
 */
public class DummyConstant extends Constant {

	/**
	 * Singleton instance of a dummy constant.
	 */
	public static final DummyConstant INSTANCE = new DummyConstant(Untyped.INSTANCE, 1, SyntheticLocation.INSTANCE);

	private DummyConstant(Type type, Object value, CodeLocation location) {
		super(type, value, location);
	}

	@Override
	public int hashCode() {
		return System.identityHashCode(INSTANCE);
	}

	@Override
	public boolean equals(Object obj) {
		return this == obj;
	}
}
