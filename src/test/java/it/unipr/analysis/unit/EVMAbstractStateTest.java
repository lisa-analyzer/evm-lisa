package it.unipr.analysis.unit;

import static org.junit.Assert.assertEquals;

import it.unipr.analysis.AbstractStack;
import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.Memory;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.numeric.Interval;
import it.unive.lisa.util.numeric.MathNumber;
import java.util.ArrayDeque;
import org.junit.Test;

/**
 * JUnit tests for {@link EVMAbstractState} class. Checks the implementation of
 * {@link EVMAbstractState#lub(EVMAbstractState)},
 * {@link EVMAbstractState#widening(EVMAbstractState)}, and
 * {@link EVMAbstractState#lessOrEqual(EVMAbstractState)} methods.
 * 
 * @see EVMAbstractState
 */
public class EVMAbstractStateTest {

	// TOP and BOTTOM elements of the lattice
	private final EVMAbstractState TOP = new EVMAbstractState().top();
	private final EVMAbstractState BOTTOM = new EVMAbstractState().bottom();

	/*
	 * Helper method to build a EVMAbsDomain from a list of values. The first
	 * value in the list will be the top of the stack.
	 */
	private EVMAbstractState buildEVMAbsDomain(Integer... values) {
		ArrayDeque<Interval> stack = new ArrayDeque<>();
		for (int i = values.length - 1; i >= 0; i--)
			stack.push(new Interval(values[i], values[i]));
		return new EVMAbstractState(new AbstractStack(stack), new Memory(), new Interval(0, 0));
	}

	/*
	 * Helper method to build a EVMAbsDomain from a list of intervals. The first
	 * interval in the list will be the top of the stack.
	 */
	private EVMAbstractState buildEVMAbsDomainIntervals(Interval... intervals) {
		ArrayDeque<Interval> stack = new ArrayDeque<>();
		for (int i = intervals.length - 1; i >= 0; i--)
			stack.push(intervals[i]);
		return new EVMAbstractState(new AbstractStack(stack), new Memory(), new Interval(0, 0));
	}

	/**
	 * Tests the least upper bound (lub) operation of {@link EVMAbstractState}.
	 * It tests the lub operation between TOP and BOTTOM, TOP and another
	 * EVMAbsDomain, BOTTOM and another symbolic stack, and two EVMAbsDomain
	 * with different sizes. The method asserts that the lub operation returns
	 * the expected result for each test case.
	 * 
	 * @throws SemanticException if a semantic error occurs during the test.
	 */
	@Test
	public void testLub() throws SemanticException {
		// Test subjects
		EVMAbstractState s1, s2;

		// TOP/BOTTOM against TOP/BOTTOM
		assertEquals(TOP, TOP.lub(TOP)); // TOP against TOP
		assertEquals(BOTTOM, BOTTOM.lub(BOTTOM)); // BOTTOM against BOTTOM
		assertEquals(TOP, TOP.lub(BOTTOM)); // TOP against BOTTOM
		assertEquals(TOP, BOTTOM.lub(TOP)); // BOTTOM against TOP

		// TOP/BOTTOM against other symbolic stack
		s1 = buildEVMAbsDomain(1, 2, 3);

		assertEquals(TOP, TOP.lub(s1)); // TOP against s1
		assertEquals(s1, BOTTOM.lub(s1)); // BOTTOM against s1
		assertEquals(TOP, s1.lub(TOP)); // s1 against TOP
		assertEquals(s1, s1.lub(BOTTOM)); // s1 against BOTTOM

		// Two symbolic stacks with same size
		s1 = buildEVMAbsDomain(1, 2, 3);
		s2 = buildEVMAbsDomain(4, -5, 6);
		assertEquals(buildEVMAbsDomainIntervals(new Interval(1, 4), new Interval(-5, 2), new Interval(3, 6)),
				s1.lub(s2));

		// Two symbolic stacks, first is higher
		s1 = buildEVMAbsDomain(1, 2, 3, 4);
		s2 = buildEVMAbsDomain(5, 6, 7);
		assertEquals(buildEVMAbsDomainIntervals(new Interval(1, 1), new Interval(2, 5), new Interval(3, 6),
				new Interval(4, 7)), s1.lub(s2));

		// Two symbolic stacks, second is higher
		s1 = buildEVMAbsDomain(1, 2, 3);
		s2 = buildEVMAbsDomain(-4, 5, -6, 7);
		assertEquals(buildEVMAbsDomainIntervals(new Interval(-4, -4), new Interval(1, 5), new Interval(-6, 2),
				new Interval(3, 7)), s1.lub(s2));
	}

	/**
	 * Tests the widening operation of {@link EVMAbstractState}. It tests the
	 * widening operation between TOP and BOTTOM, TOP and another EVMAbsDomai,n
	 * BOTTOM and another EVMAbsDomain, and two symbolic stacks with different
	 * sizes. The method asserts that the widening operation returns the
	 * expected result for each test case.
	 * 
	 * @throws SemanticException if a semantic error occurs during the test.
	 */
	@Test
	public void testWidening() throws SemanticException {
		// Test subjects
		EVMAbstractState s1, s2;

		// TOP/BOTTOM against TOP/BOTTOM
		assertEquals(TOP, TOP.widening(TOP)); // TOP against TOP
		assertEquals(BOTTOM, BOTTOM.widening(BOTTOM)); // BOTTOM against BOTTOM
		assertEquals(TOP, TOP.widening(BOTTOM)); // TOP against BOTTOM
		assertEquals(TOP, BOTTOM.widening(TOP)); // BOTTOM against TOP

		// TOP/BOTTOM against other symbolic stack
		s1 = buildEVMAbsDomain(1, 2, 3);

		assertEquals(TOP, TOP.widening(s1)); // TOP against s1
		assertEquals(s1, BOTTOM.widening(s1)); // BOTTOM against s1
		assertEquals(TOP, s1.widening(TOP)); // s1 against TOP
		assertEquals(s1, s1.widening(BOTTOM)); // s1 against BOTTOM

		// Two symbolic stacks with same size
		s1 = buildEVMAbsDomain(1, 2, 3);
		s2 = buildEVMAbsDomain(4, -5, 6);

		assertEquals(buildEVMAbsDomainIntervals(new Interval(new MathNumber(1), MathNumber.PLUS_INFINITY),
				new Interval(MathNumber.MINUS_INFINITY, new MathNumber(2)),
				new Interval(new MathNumber(3), MathNumber.PLUS_INFINITY)), s1.widening(s2));

		// Two symbolic stacks, first is higher
		s1 = buildEVMAbsDomain(1, 2, 3, 4);
		s2 = buildEVMAbsDomain(5, 6, 7);

		assertEquals(s1, s1.widening(s2));

		// Two symbolic stacks, second is higher
		s1 = buildEVMAbsDomain(1, 2, 3);
		s2 = buildEVMAbsDomain(-4, 5, -6, 7);

		assertEquals(buildEVMAbsDomainIntervals(new Interval(-4, -4),
				new Interval(new MathNumber(1), MathNumber.PLUS_INFINITY),
				new Interval(MathNumber.MINUS_INFINITY, new MathNumber(2)),
				new Interval(new MathNumber(3), MathNumber.PLUS_INFINITY)), s1.widening(s2));
	}

	/**
	 * Tests the less or equal operation of {@link EVMAbstractState}. It tests
	 * the less or equal operation between TOP and BOTTOM, TOP and another
	 * EVMAbsDomain, BOTTOM and another symbolic stack, and two EVMAbsDomain
	 * with different sizes. The method asserts that the less or equal operation
	 * returns the expected result for each test case.
	 * 
	 * @throws SemanticException if a semantic error occurs during the test.
	 */
	@Test
	public void testLessOrEqual() throws SemanticException {
		// Test subjects
		EVMAbstractState s1, s2;

		// TOP/BOTTOM against TOP/BOTTOM
		assertEquals(true, TOP.lessOrEqual(TOP)); // TOP against TOP
		assertEquals(true, BOTTOM.lessOrEqual(BOTTOM)); // BOTTOM against BOTTOM
		assertEquals(false, TOP.lessOrEqual(BOTTOM)); // TOP against BOTTOM
		assertEquals(true, BOTTOM.lessOrEqual(TOP)); // BOTTOM against TOP

		// TOP/BOTTOM against other symbolic stack
		s1 = buildEVMAbsDomain(1, 2, 3);

		assertEquals(false, TOP.lessOrEqual(s1)); // TOP against s1
		assertEquals(true, BOTTOM.lessOrEqual(s1)); // BOTTOM against s1
		assertEquals(true, s1.lessOrEqual(TOP)); // s1 against TOP
		assertEquals(false, s1.lessOrEqual(BOTTOM)); // s1 against BOTTOM

		// Two symbolic stacks, identical
		s1 = buildEVMAbsDomain(1, 2, 3);
		s2 = buildEVMAbsDomain(1, 2, 3);
		assertEquals(true, s1.lessOrEqual(s2));

		// Two symbolic stacks, first is higher
		s1 = buildEVMAbsDomainIntervals(new Interval(2, 3), new Interval(1, 5), new Interval(0, 10));
		s2 = buildEVMAbsDomainIntervals(new Interval(2, 3), new Interval(4, 6));
		assertEquals(false, s1.lessOrEqual(s2));

		// Two symbolic stacks, second is higher and first is contained
		s1 = buildEVMAbsDomainIntervals(new Interval(2, 3), new Interval(4, 6));
		s2 = buildEVMAbsDomainIntervals(new Interval(40, 40), new Interval(1, 5), new Interval(0, 10));
		assertEquals(true, s1.lessOrEqual(s2));

		// Two symbolic stacks, second is higher and first is not contained
		s1 = buildEVMAbsDomainIntervals(new Interval(2, 3), new Interval(14, 20));
		s2 = buildEVMAbsDomainIntervals(new Interval(40, 40), new Interval(1, 5), new Interval(0, 10));
		assertEquals(false, s1.lessOrEqual(s2));
	}
}
