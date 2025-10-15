package it.unipr.utils;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Utility class for generating formatted timestamps.
 * <p>
 * This class provides static methods to retrieve the current timestamp in
 * various formats. All methods are thread-safe as they use immutable
 * {@link DateTimeFormatter} instances.
 */
public final class MyTimestampUtil {

	/**
	 * Date-time formatter for timestamp in the format: yyyyMMdd-HHmmss-SSS
	 * (e.g., 20251015-143025-123)
	 */
	private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss-SSS");

	/**
	 * Private constructor to prevent instantiation of this utility class.
	 */
	private MyTimestampUtil() {
		throw new AssertionError("Utility class should not be instantiated");
	}

	/**
	 * Returns the current timestamp as a formatted string.
	 * <p>
	 * The format is: yyyyMMdd-HHmmss-SSS
	 * <ul>
	 * <li>yyyyMMdd: Year, month, day (e.g., 20251015)</li>
	 * <li>HHmmss: Hour, minutes, seconds in 24-hour format (e.g., 143025)</li>
	 * <li>SSS: Milliseconds (e.g., 123)</li>
	 * </ul>
	 * Example output: "20251015-143025-123"
	 *
	 * @return the current timestamp as a formatted string
	 */
	public static String getCurrentTimestamp() {
		return LocalDateTime.now().format(FORMATTER);
	}
}
