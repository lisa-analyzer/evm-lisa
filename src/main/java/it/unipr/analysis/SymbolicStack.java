package it.unipr.analysis;

import java.math.BigInteger;
import java.util.ArrayDeque;
import java.util.Objects;

import it.unive.lisa.analysis.Lattice;
import it.unive.lisa.analysis.ScopeToken;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.representation.DomainRepresentation;
import it.unive.lisa.analysis.representation.StringRepresentation;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.program.cfg.ProgramPoint;
import it.unive.lisa.symbolic.SymbolicExpression;
import it.unive.lisa.symbolic.value.Constant;
import it.unive.lisa.symbolic.value.Identifier;
import it.unive.lisa.symbolic.value.UnaryExpression;
import it.unive.lisa.symbolic.value.ValueExpression;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;

/**
 * Semantic domain of the execution stack of the contract.
 */
public class SymbolicStack implements ValueDomain<SymbolicStack> {

	private static final SymbolicStack TOP = new SymbolicStack();
	private static final SymbolicStack BOTTOM = new SymbolicStack(null);

	private final ArrayDeque<BigInteger> stack;
	private final boolean isTop;

	/**
	 * Constructor of the SymbolicStack class.
	 */
	public SymbolicStack() {
		this(true);
	}

	private SymbolicStack(boolean isTop) {
		this.isTop = isTop;
		this.stack = new ArrayDeque<BigInteger>();
	}

	private SymbolicStack(ArrayDeque<BigInteger> stack) {
		this.stack = stack;
		this.isTop = false;
	}

	@Override
	public SymbolicStack assign(Identifier id, ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public SymbolicStack smallStepSemantics(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		if (expression instanceof Constant) {
			return this;
		} else if (expression instanceof UnaryExpression) {
			UnaryExpression un = (UnaryExpression) expression;
			UnaryOperator op = un.getOperator();

			if (op instanceof PushOperator) { // PUSH
				ArrayDeque<BigInteger> result = stack.clone();

				result.push(toBigInteger(un.getExpression()));

				return new SymbolicStack(result);
			} else if (op instanceof AddOperator) { // ADD
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.add(opnd2));

				return new SymbolicStack(result);
			} else if (op instanceof SubOperator) { // SUB
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.subtract(opnd2));

				return new SymbolicStack(result);
			} else if (op instanceof MulOperator) { // MUL
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.multiply(opnd2));

				return new SymbolicStack(result);
			} else if ((op instanceof DivOperator) || (op instanceof SdivOperator)) { // DIV, SDIV
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				if (opnd2.equals(BigInteger.ZERO)) {
					result.push(BigInteger.ZERO);
				} else {
					result.push(opnd1.divide(opnd2));
				}

				return new SymbolicStack(result);
			} else if ((op instanceof ModOperator) || (op instanceof SmodOperator)) { // MOD, SMOD
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				if (opnd2.equals(BigInteger.ZERO)) {
					result.push(BigInteger.ZERO);
				} else {
					result.push(opnd1.mod(opnd2));
				}

				return new SymbolicStack(result);
			} else if (op instanceof AddmodOperator) { // ADDMOD
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();
				BigInteger opnd3 = result.pop();

				if (opnd3.equals(BigInteger.ZERO)) {
					result.push(BigInteger.ZERO);
				} else {
					result.push((opnd1.add(opnd2)).mod(opnd3));
				}

				return new SymbolicStack(result);
			} else if (op instanceof MulmodOperator) { // MULMOD
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();
				BigInteger opnd3 = result.pop();

				if (opnd3.equals(BigInteger.ZERO)) {
					result.push(BigInteger.ZERO);
				} else {
					result.push((opnd1.multiply(opnd2)).mod(opnd3));
				}

				return new SymbolicStack(result);
			} else if (op instanceof ExpOperator) { // EXP
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.pow(opnd2.intValue()));

				return new SymbolicStack(result);
			} else if ((op instanceof LtOperator) || (op instanceof SltOperator)) { // LT, SLT
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.compareTo(opnd2) < 0 ? BigInteger.ONE : BigInteger.ZERO);

				return new SymbolicStack(result);
			} else if ((op instanceof GtOperator) || (op instanceof SgtOperator)) { // GT, SGT
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.compareTo(opnd2) > 0 ? BigInteger.ONE : BigInteger.ZERO);

				return new SymbolicStack(result);
			} else if (op instanceof EqOperator) { // EQ
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.compareTo(opnd2) == 0 ? BigInteger.ONE : BigInteger.ZERO);

				return new SymbolicStack(result);
			} else if (op instanceof IszeroOperator) { // ISZERO
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();

				result.push(opnd1.compareTo(BigInteger.ZERO) == 0 ? BigInteger.ONE : BigInteger.ZERO);

				return new SymbolicStack(result);
			} else if (op instanceof AndOperator) { // AND
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.and(opnd2));

				return new SymbolicStack(result);
			} else if (op instanceof OrOperator) { // OR
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.or(opnd2));

				return new SymbolicStack(result);
			} else if (op instanceof XorOperator) { // XOR
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.xor(opnd2));

				return new SymbolicStack(result);
			} else if (op instanceof NotOperator) { // NOT
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();

				result.push(opnd1.not());

				return new SymbolicStack(result);
			}
		}

		return top();
	}

	@Override
	public SymbolicStack assume(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public SymbolicStack forgetIdentifier(Identifier id) throws SemanticException {
		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public Satisfiability satisfies(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// TODO Auto-generated method stub
		return Satisfiability.UNKNOWN;
	}

	@Override
	public SymbolicStack pushScope(ScopeToken token) throws SemanticException {
		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public SymbolicStack popScope(ScopeToken token) throws SemanticException {
		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public DomainRepresentation representation() {
		if (isBottom())
			return Lattice.BOTTOM_REPR;
		else if (isTop())
			return Lattice.TOP_REPR;
		return new StringRepresentation(stack);
	}

	@Override
	public SymbolicStack lub(SymbolicStack other) throws SemanticException {
		if (isBottom())
			return other;
		if (other.isBottom())
			return this;

		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public SymbolicStack widening(SymbolicStack other) throws SemanticException {
		if (isBottom())
			return other;
		if (other.isBottom())
			return this;

		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public boolean lessOrEqual(SymbolicStack other) throws SemanticException {
		// TODO Auto-generated method stub
		return true;
	}

	@Override
	public SymbolicStack top() {
		return TOP;
	}

	@Override
	public SymbolicStack bottom() {
		return BOTTOM;
	}

	@Override
	public boolean isBottom() {
		return stack == null;
	}

	@Override
	public boolean isTop() {
		return isTop;
	}

	private BigInteger toBigInteger(SymbolicExpression expression) {
		Constant c = (Constant) expression;
		String hex = (String) c.getValue();
		String hexadecimal = hex.substring(2);
		Integer intVal = Integer.parseInt(hexadecimal, 16);
		return new BigInteger(intVal.toString());
	}

	@Override
	public int hashCode() {
		return Objects.hash(stack);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		SymbolicStack other = (SymbolicStack) obj;
		return Objects.equals(stack, other.stack);
	}

}