package it.unipr.analysis;

import it.unive.lisa.analysis.numeric.Interval;
import java.math.BigDecimal;

public class MemoryTest {
	public static void main(String[] args) {
		Memory m = new Memory(new Interval(10, 20));

		m = m.putState(new BigDecimal(10), new Interval(10, 20));
		m = m.putState(new BigDecimal(20), new Interval(13, 21));
		m = m.putState(new BigDecimal(30), new Interval(16, 26));
		m = m.putState(new BigDecimal(40), new Interval(1, 21));

		System.out.println(m);
	}
}
