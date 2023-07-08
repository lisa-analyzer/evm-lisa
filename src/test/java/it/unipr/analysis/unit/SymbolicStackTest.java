package it.unipr.analysis.unit;

import static org.junit.Assert.assertEquals;

import it.unipr.analysis.SymbolicStack;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.numeric.Interval;
import java.util.ArrayDeque;
import org.junit.Test;

public class SymbolicStackTest {

	private final SymbolicStack top = new SymbolicStack().top();
	private final SymbolicStack bottom = new SymbolicStack().bottom();

	/*
	 * Builds a symbolic stack from a list of values, note that the first value
	 * (to the left) is the top of the stack
	 */
	private SymbolicStack buildSymbolicStack(Integer... values) {
		ArrayDeque<Interval> stack = new ArrayDeque<>();
		for (int i = values.length - 1; i >= 0; i--)
			stack.push(new Interval(values[i], values[i]));
		return new SymbolicStack(stack);
	}

	private SymbolicStack buildSymbolicStackIntervals(Interval... intervals) {
		ArrayDeque<Interval> stack = new ArrayDeque<>();
		for (int i = intervals.length - 1; i >= 0; i--)
			stack.push(intervals[i]);
		return new SymbolicStack(stack);
	}

	@Test
	public void testLub() throws SemanticException {
		// Test subjects
		SymbolicStack s1, s2;

		// top/bottom against top/bottom
		assertEquals(top, top.lub(top));
		assertEquals(bottom, bottom.lub(bottom));
		assertEquals(top, top.lub(bottom));
		assertEquals(top, bottom.lub(top));

		// top/bottom against other symbolic stack
		s1 = buildSymbolicStack(1, 2, 3);

		assertEquals(top, top.lub(s1));
		assertEquals(s1, bottom.lub(s1));
		assertEquals(top, s1.lub(top));
		assertEquals(s1, s1.lub(bottom));

		// two symbolic stacks with same size
		s1 = buildSymbolicStack(1, 2, 3);
		s2 = buildSymbolicStack(4, -5, 6);
		assertEquals(buildSymbolicStackIntervals(new Interval(1, 4), new Interval(-5, 2), new Interval(3, 6)),
				s1.lub(s2));

		// two symbolic stacks, first is higher
		s1 = buildSymbolicStack(1, 2, 3, 4);
		s2 = buildSymbolicStack(5, 6, 7);
		assertEquals(buildSymbolicStackIntervals(new Interval(1, 1), new Interval(2, 5), new Interval(3, 6),
				new Interval(4, 7)), s1.lub(s2));

		// two symbolic stacks, second is higher
		s1 = buildSymbolicStack(1, 2, 3);
		s2 = buildSymbolicStack(-4, 5, -6, 7);
		assertEquals(buildSymbolicStackIntervals(new Interval(-4, -4), new Interval(1, 5), new Interval(-6, 2),
				new Interval(3, 7)), s1.lub(s2));
	}

	@Test
	public void testWidening() throws SemanticException {

	}
}
