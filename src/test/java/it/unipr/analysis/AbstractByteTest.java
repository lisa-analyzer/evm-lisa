package it.unipr.analysis;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

/** Tests the byte representation used in analysis reports. */
public class AbstractByteTest {

	/**
	 * Checks every concrete byte and the unknown value against the report
	 * format.
	 */
	@Test
	public void rendersUnsignedHexAndUnknown() {
		for (int value = 0; value <= 0xff; value++)
			assertEquals(String.format("%02X", (byte) value), new AbstractByte(value).toString());
		assertEquals("T", AbstractByte.UNKNOWN.toString());
	}
}
