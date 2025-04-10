package it.unipr.utils;

import it.unipr.analysis.contract.EventKnowledge;
import it.unipr.analysis.contract.Signature;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.apache.commons.lang3.StringUtils;
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
public class ABIManager {
	private static final Logger log = LogManager.getLogger(ABIManager.class);

	/**
	 * Computes the function selector for a given function signature. The
	 * function selector is derived by applying Keccak-256 hashing to the
	 * function signature and taking the first 4 bytes of the resulting hash.
	 *
	 * @param functionSignature The function signature (e.g.,
	 *                              "transfer(address,uint256)").
	 *
	 * @return The first 4 bytes of the hash, formatted as a hexadecimal string.
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
	public static Set<Signature> parseFunctionsFromABI(Path abi) {
		return parseABI(abi, "function");
	}

	/**
	 * Parses a smart contract ABI and extracts event signatures along with
	 * their selectors. This method reads a JSON ABI file and retrieves the
	 * event definitions, computing the event selector for each event.
	 *
	 * @param abi Path to the ABI JSON file.
	 *
	 * @return A set of pairs where each pair contains the event signature and
	 *             its corresponding selector.
	 */
	public static Set<Signature> parseEventsFromABI(Path abi) {
		return parseABI(abi, "event");
	}

	private static Set<Signature> parseABI(Path abi, String type) {
		Set<String> stateMutabilityForbidden = Set.of("view", "pure");
		Set<Signature> signatures = new HashSet<>();
		String abiJson;

		try {
			abiJson = Files.readString(abi, StandardCharsets.UTF_8);
		} catch (IOException e) {
			log.error("Unable to read ABI JSON {}: {}", abi.toString(), e.getMessage());
			return signatures;
		}

		JSONArray abiArray = new JSONArray(abiJson);

		for (int i = 0; i < abiArray.length(); i++) {
			JSONObject obj = abiArray.getJSONObject(i);
			if (obj.has("type") && obj.getString("type").equals(type)) {

				/* We do not need to collect global variables */
				if (obj.has("stateMutability")
						&& stateMutabilityForbidden.contains(obj.getString("stateMutability")))
					continue;

				String functionName = obj.getString("name");
				JSONArray inputs = obj.getJSONArray("inputs");
				JSONArray outputs = obj.optJSONArray("outputs");

				List<String> paramTypes = new ArrayList<>();
				List<String> outputTypes = new ArrayList<>();
				StringBuilder signatureBuilder = new StringBuilder(functionName).append("(");

				for (int j = 0; j < inputs.length(); j++) {
					if (j > 0)
						signatureBuilder.append(",");

					String paramType = parseParameterType(inputs.getJSONObject(j));
					paramTypes.add(paramType);
					signatureBuilder.append(paramType);
				}
				signatureBuilder.append(")");

				if (outputs != null) {
					for (int j = 0; j < outputs.length(); j++) {
						String outputType = parseParameterType(outputs.getJSONObject(j));
						outputTypes.add(outputType);
					}
				}

				String fullSignature = signatureBuilder.toString();
				String selector = getFunctionSelector(fullSignature);

				signatures.add(new Signature(functionName, type, paramTypes, outputTypes, fullSignature, selector));
			}
		}
		return signatures;
	}

	/**
	 * Parses a parameter type, handling tuples and arrays properly.
	 */
	private static String parseParameterType(JSONObject param) {
		String paramType = param.getString("type");

		if (paramType.equals("tuple") || paramType.endsWith("[]")) {
			JSONArray components = param.optJSONArray("components");
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
		return paramType;
	}

	/**
	 * Verifies the presence of function selectors in the bytecode. This method
	 * checks if the function selectors extracted from the ABI are present in
	 * the compiled smart contract bytecode.
	 *
	 * @param signatures   A set of function signature-selector pairs extracted
	 *                         from the ABI.
	 * @param bytecodePath Path to the smart contract's compiled bytecode.
	 */
	public static void verifyFunctionSelectors(Set<Signature> signatures, Path bytecodePath) {
		int counter = 0;
		String bytecode;

		try {
			bytecode = Files.readString(bytecodePath, StandardCharsets.UTF_8);
		} catch (IOException e) {
			log.error("Unable to read bytecode {}: {}", bytecodePath.toString(), e.getMessage());
			return;
		}

		for (Signature entry : signatures) {
			int occurrences = StringUtils.countMatches(bytecode, entry.getSelector());

			if (occurrences > 0) {
				counter++;
				if (occurrences > 1)
					log.info("Selector {} ({}) is present {} times in the bytecode.", entry.getSelector(),
							entry.getFullSignature(), occurrences);
			} else {
				log.warn("Selector {} ({}) is NOT present in the bytecode.", entry.getSelector(),
						entry.getFullSignature());
			}
		}
		log.info("Total selectors found: {}/{}", counter, signatures.size());
	}

	// Test
	public static void main(String[] args) {
		Path abi = Paths.get("test-cross-chain-analysis", "test-ABI-function-selector", "buggy_2.abi.json");
		Path bytecode = Paths.get("test-cross-chain-analysis", "test-ABI-function-selector", "buggy_2.bytecode");

		log.info(parseABI(abi, "function"));

		String signature = "returnVaultAssets(address,address,(address,uint256)[],string)";
		String functionSelector = getFunctionSelector(signature);
		Set<Signature> signatures = new HashSet<>();
		signatures.add(
				new Signature("returnVaultAssets", "function", new ArrayList<>(4), null, signature, functionSelector));
		verifyFunctionSelectors(signatures, bytecode);

		try {
			log.info("Parsing functions");
			Set<Signature> functions = parseFunctionsFromABI(abi);
			verifyFunctionSelectors(functions, bytecode);

			log.info("Parsing events");
			Set<Signature> events = parseEventsFromABI(abi);
			verifyFunctionSelectors(events, bytecode);

			log.info("Computing events knowledge");
			for (Signature event : events) {
				log.debug("{}: {}", event.getFullSignature(), EventKnowledge.getKnowledge(event.getName()));
			}
		} catch (Exception e) {
			log.error("Error reading ABI or bytecode file", e);
		}
	}
}