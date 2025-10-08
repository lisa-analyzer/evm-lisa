package it.unipr.utils;

import java.util.regex.Pattern;

public class EthereumUtils {
	private static final Pattern EVM_ADDRESS_PATTERN = Pattern.compile("^0x[a-fA-F0-9]{40}$");

	/**
	 * Checks if the given string is a valid EVM address.
	 *
	 * @param address the address to validate
	 * 
	 * @return true if the address is a valid EVM address, false otherwise
	 */
	public static boolean isValidEVMAddress(String address) {
		return address != null && EVM_ADDRESS_PATTERN.matcher(address).matches();
	}
}