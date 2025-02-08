package it.unipr.abi;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashSet;
import java.util.Set;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.tuple.Pair;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.bouncycastle.jcajce.provider.digest.Keccak;
import org.json.JSONArray;
import org.json.JSONObject;

/**
 * Utility class for handling Ethereum smart contract ABIs. This class provides
 * methods to: (1) extract function selectors from function signatures; (2)
 * parse a contract's ABI to retrieve function signatures and their
 * corresponding selectors; (3) verify the presence of function selectors within
 * a contract's compiled bytecode.
 */
public class ABIFunctionSelector {
	private static final Logger log = LogManager.getLogger(ABIFunctionSelector.class);

	/**
	 * Computes the function selector for a given function signature. The
	 * function selector is derived by applying Keccak-256 hashing to the
	 * function signature and taking the first 4 bytes of the resulting hash.
	 *
	 * @param functionSignature The function signature (e.g.,
	 *                              "transfer(address,uint256)").
	 * 
	 * @return The first 4 bytes of the Keccak-256 hash, formatted as a
	 *             hexadecimal string.
	 */
	public static String getFunctionSelector(String functionSignature) {
		Keccak.Digest256 digest = new Keccak.Digest256();
		byte[] hash = digest.digest(functionSignature.getBytes(StandardCharsets.UTF_8));

		return String.format("%02x%02x%02x%02x", hash[0], hash[1], hash[2], hash[3]);
	}

	/**
	 * Parses a smart contract ABI and extracts function signatures along with
	 * their selectors. This method reads a JSON ABI file and retrieves the
	 * function definitions, computing the function selector for each function.
	 *
	 * @param abi Path to the ABI JSON file.
	 * 
	 * @return A set of pairs where each pair contains the function signature
	 *             and its corresponding selector.
	 */
	public static Set<Pair<String, String>> parseABI(Path abi) {
		Set<Pair<String, String>> functionSet = new HashSet<>();
		String abiJson;

		try {
			abiJson = Files.readString(abi, StandardCharsets.UTF_8);
		} catch (IOException e) {
			log.error("Unable to read ABI JSON {}: {}", abi.toString(), e.getMessage());
			return functionSet;
		}

		JSONArray abiArray = new JSONArray(abiJson);

		for (int i = 0; i < abiArray.length(); i++) {
			JSONObject obj = abiArray.getJSONObject(i);
			if (obj.has("type") && obj.getString("type").equals("function")) {
				String functionName = obj.getString("name");
				JSONArray inputs = obj.getJSONArray("inputs");

				StringBuilder signature = new StringBuilder(functionName + "(");
				for (int j = 0; j < inputs.length(); j++) {
					if (j > 0)
						signature.append(",");

					String paramType = inputs.getJSONObject(j).getString("type");

					// Handle tuple (struct) parameters
					if (paramType.equals("tuple") || paramType.endsWith("[]")) {
						JSONObject component = inputs.getJSONObject(j);
						JSONArray components = component.optJSONArray("components");

						if (components != null) {
							StringBuilder tupleSignature = new StringBuilder("(");
							for (int k = 0; k < components.length(); k++) {
								if (k > 0)
									tupleSignature.append(",");
								tupleSignature.append(components.getJSONObject(k).getString("type"));
							}
							tupleSignature.append(")");

							if (paramType.endsWith("[]")) {
								tupleSignature.append("[]");
							}

							paramType = tupleSignature.toString();
						}
					}

					signature.append(paramType);
				}
				signature.append(")");

				String functionSelector = getFunctionSelector(signature.toString());
				functionSet.add(Pair.of(signature.toString(), functionSelector));

				log.debug("{} -> {}", signature, functionSelector);
			}
		}
		return functionSet;
	}

	/**
	 * Verifies the presence of function selectors in the bytecode. This method
	 * checks if the function selectors extracted from the ABI are present in
	 * the compiled smart contract bytecode.
	 *
	 * @param functionSet  A set of function signature-selector pairs extracted
	 *                         from the ABI.
	 * @param bytecodePath Path to the smart contract's compiled bytecode.
	 */
	public static void verifyFunctionSelectors(Set<Pair<String, String>> functionSet, Path bytecodePath) {
		int counter = 0;
		String bytecode;

		try {
			bytecode = Files.readString(bytecodePath, StandardCharsets.UTF_8);
		} catch (IOException e) {
			log.error("Unable to read bytecode {}: {}", bytecodePath.toString(), e.getMessage());
			return;
		}

		for (Pair<String, String> entry : functionSet) {
			int occurrences = StringUtils.countMatches(bytecode, entry.getValue());

			if (occurrences > 0) {
				counter++;
				if (occurrences > 1)
					log.info("Function selector {} ({}) is present {} times in the bytecode.", entry.getValue(),
							entry.getKey(), occurrences);
			} else {
				log.warn("Function selector {} ({}) is NOT present in the bytecode.", entry.getValue(), entry.getKey());
			}
		}
		log.info("Total function selectors found: {}/{}", counter, functionSet.size());
	}

	// Test
	public static void main(String[] args) {
		Path abi = Paths.get("test-cross-chain-analysis", "test-ABI-function-selector", "buggy_2.abi.json");
		Path bytecode = Paths.get("test-cross-chain-analysis", "test-ABI-function-selector", "buggy_2.bytecode");

		String signature = "returnVaultAssets(address,address,(address,uint256)[],string)";
		String functionSelector = getFunctionSelector(signature);
		Set<Pair<String, String>> set = new HashSet<>();
		set.add(Pair.of(signature, functionSelector));
		verifyFunctionSelectors(set, bytecode);

		try {
			Set<Pair<String, String>> functionSet = parseABI(abi);
			assert functionSet != null;
			verifyFunctionSelectors(functionSet, bytecode);
		} catch (Exception e) {
			log.error("Error reading ABI or bytecode file", e);
		}
	}
}