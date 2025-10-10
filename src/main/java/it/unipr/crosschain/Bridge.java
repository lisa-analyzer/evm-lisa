package it.unipr.crosschain;

import it.unipr.EVMLiSA;
import it.unipr.analysis.contract.Signature;
import it.unipr.analysis.contract.SmartContract;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.ProgramCounterLocation;
import it.unipr.utils.VulnerabilitiesObject;
import it.unive.lisa.program.ClassUnit;
import it.unive.lisa.program.cfg.CodeMemberDescriptor;
import it.unive.lisa.program.cfg.edge.Edge;
import it.unive.lisa.program.cfg.statement.Statement;
import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.lang3.tuple.Pair;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;

public class Bridge implements Iterable<SmartContract> {
	private static final Logger log = LogManager.getLogger(Bridge.class);

	private final String name;
	private final List<SmartContract> contracts;

	private EVMCFG xCFG;

	private final List<Pair<String, String>> policy;

	/** Detected vulnerabilities in the bridge. */
	private VulnerabilitiesObject _vulnerabilities;

	/**
	 * Creates a new Bridge instance with only a name.
	 *
	 * @param name the name of the bridge
	 */
	public Bridge(String name) {
		this(null, null, null, name);
	}

	/**
	 * Creates a new Bridge instance with bytecode and ABI directories, and
	 * policy path. The bridge name will be auto-generated with a timestamp.
	 *
	 * @param bytecodeDirectoryPath path to the directory containing bytecode
	 *                                  files
	 * @param abiDirectoryPath      path to the directory containing ABI files
	 * @param policyPath            path to the policy JSON file
	 */
	public Bridge(Path bytecodeDirectoryPath, Path abiDirectoryPath, Path policyPath) {
		this(bytecodeDirectoryPath, abiDirectoryPath, policyPath, "unknown_bridge_" + System.currentTimeMillis());
	}

	/**
	 * Creates a new Bridge instance with bytecode and ABI directories. No
	 * policy will be loaded and the bridge name will be auto-generated.
	 *
	 * @param bytecodeDirectoryPath path to the directory containing bytecode
	 *                                  files
	 * @param abiDirectoryPath      path to the directory containing ABI files
	 */
	public Bridge(Path bytecodeDirectoryPath, Path abiDirectoryPath) {
		this(bytecodeDirectoryPath, abiDirectoryPath, null, "unknown_bridge_" + System.currentTimeMillis());
	}

	/**
	 * Creates a new Bridge instance with all specified parameters. This is the
	 * main constructor that initializes the bridge with smart contracts from
	 * the provided bytecode and ABI directories, loads the policy if specified,
	 * and assigns the given name.
	 *
	 * @param bytecodeDirectoryPath path to the directory containing bytecode
	 *                                  files
	 * @param abiDirectoryPath      path to the directory containing ABI files
	 * @param policyPath            path to the policy JSON file, or null if no
	 *                                  policy should be loaded
	 * @param name                  the name to assign to this bridge
	 */
	public Bridge(Path bytecodeDirectoryPath, Path abiDirectoryPath, Path policyPath, String name) {
		this.name = name;
		this.contracts = new ArrayList<>();
		this.policy = new ArrayList<>();

		Map<String, Path> abiFiles = mapFilesByName(abiDirectoryPath, ".abi");
		Map<String, Path> bytecodeFiles = mapFilesByName(bytecodeDirectoryPath, ".bytecode");

		for (String contractName : bytecodeFiles.keySet()) {
			if (abiFiles.containsKey(contractName)) {
				contracts.add(new SmartContract(bytecodeFiles.get(contractName), abiFiles.get(contractName)));
			} else {
				log.warn("Cannot find ABI file: {}.", contractName);
			}
		}
		log.info("Created bridge {} with {} contracts using bytecodes at {} and ABIs at {}.",
				name, contracts.size(), bytecodeDirectoryPath.toString(), abiDirectoryPath.toString());

		if (policyPath != null)
			loadPolicy(policyPath);
		else
			log.info("Created bridge without custom policy. Using default policy");

	}

	/**
	 * Gets the name of the bridge.
	 *
	 * @return the name of the bridge
	 */
	public String getName() {
		return name;
	}

	/**
	 * Gets the list of smart contracts in this bridge.
	 *
	 * @return a list of SmartContract objects
	 */
	public List<SmartContract> getSmartContracts() {
		return contracts;
	}

	/**
	 * Gets all function signatures from all contracts in this bridge.
	 *
	 * @return a list of function signatures
	 */
	public List<Signature> getFunctions() {
		List<Signature> functions = new ArrayList<>();
		for (SmartContract contract : contracts)
			functions.addAll(contract.getFunctionsSignature());
		return functions;
	}

	/**
	 * Gets all event signatures from all contracts in this bridge.
	 *
	 * @return a list of event signatures
	 */
	public List<Signature> getEvents() {
		List<Signature> events = new ArrayList<>();
		for (SmartContract contract : contracts)
			events.addAll(contract.getEventsSignature());
		return events;
	}

	/**
	 * Gets the cross-chain control flow graph (xCFG) of this bridge.
	 *
	 * @return the EVMCFG representing the cross-chain control flow graph
	 */
	public EVMCFG getXCFG() {
		return xCFG;
	}

	/**
	 * Gets the cross-chain policy containing event-function pairs.
	 *
	 * @return a list of event-function pairs
	 */
	public List<Pair<String, String>> getPolicy() {
		return policy;
	}

	/**
	 * Checks if an event has an associated function in the policy.
	 *
	 * @param event the name of the event to check
	 *
	 * @return true if the event has an associated function, false otherwise
	 */
	public boolean hasEventFunctionMapping(String event) {
		for (Pair<String, String> pair : policy)
			if (pair.getLeft().equals(event))
				return true;
		return false;
	}

	/**
	 * Gets the function name associated with an event from the policy.
	 *
	 * @param event the name of the event
	 *
	 * @return the associated function name, or null if not found
	 */
	public String getFunctionForEvent(String event) {
		for (Pair<String, String> pair : policy)
			if (pair.getLeft().equals(event))
				return pair.getRight();
		return null;
	}

	/**
	 * Adds multiple cross-chain edges to the xCFG.
	 *
	 * @param edges a set of edges to be added
	 */
	public void addEdges(Set<Edge> edges) {
		for (Edge edge : edges)
			addEdge(edge);
	}

	/**
	 * Returns the vulnerabilities detected in the bridge.
	 *
	 * @return Vulnerabilities object.
	 */
	public VulnerabilitiesObject getVulnerabilities() {
		return _vulnerabilities;
	}

	/**
	 * Sets the vulnerabilities object.
	 *
	 * @param vulnerabilities Vulnerabilities object.
	 *
	 * @return This SmartContract instance for method chaining.
	 */
	public Bridge setVulnerabilities(VulnerabilitiesObject vulnerabilities) {
		this._vulnerabilities = vulnerabilities;
		return this;
	}

	/**
	 * Adds a single cross-chain edge to the xCFG.
	 *
	 * @param edge the edge to be added
	 */
	public void addEdge(Edge edge) {
		xCFG.addEdge(edge);
	}

	/**
	 * Builds the partial cross-chain control flow graph (xCFG) by merging
	 * individual smart contract CFGs into a unified representation.
	 *
	 * @return The constructed xCFG.
	 */
	public EVMCFG buildPartialXCFG() {
		log.info("Building partial xCFG.");

		String filePath = EVMLiSA.getWorkingDirectory().toString();
		ClassUnit unit = new ClassUnit(new ProgramCounterLocation(-1, -1), null, "program", false);
		String normalizedFilePath = FilenameUtils.separatorsToUnix(filePath);
		CodeMemberDescriptor cfgDesc = new CodeMemberDescriptor(new ProgramCounterLocation(-1, -1), unit, false,
				normalizedFilePath);

		EVMCFG xCFG = new EVMCFG(cfgDesc);

		for (SmartContract contract : contracts) {
			for (Statement n : contract.getCFG().getNodes())
				xCFG.addNode(n);

			for (Edge e : contract.getCFG().getEdges())
				xCFG.addEdge(e);
		}

		log.info("Partial xCFG built.");

		this.xCFG = xCFG;
		return xCFG;
	}

	/**
	 * Loads the cross-chain policy from a JSON file and populates the policy
	 * list. The JSON file should contain an array named "policy" with
	 * event-function pairs.
	 *
	 * @param policyPath the path to the policy JSON file
	 */
	private void loadPolicy(Path policyPath) {
		try {
			log.info("Loading policy from: {}", policyPath);
			String content = Files.readString(policyPath);
			JSONObject policyJson = new JSONObject(content);

			if (policyJson.has("policy")) {
				JSONArray eventFunctionPairs = policyJson.getJSONArray("policy");

				for (int i = 0; i < eventFunctionPairs.length(); i++) {
					JSONObject pair = eventFunctionPairs.getJSONObject(i);
					String event = pair.getString("event");
					String function = pair.getString("function");
					policy.add(Pair.of(event, function));
				}

				log.info("Loaded {} event-function pairs from policy.", policy.size());
				log.debug("Policy: {}", policy);
			} else {
				log.warn("Policy file does not contain 'policy' array.");
			}
		} catch (IOException e) {
			log.warn("Error reading policy file: {}. Creating bridge without custom policy. Using default policy",
					e.getMessage());
		} catch (Exception e) {
			log.warn("Error parsing policy JSON: {}. Creating bridge without custom policy. Using default policy",
					e.getMessage());
		}
	}

	/**
	 * Scans a directory for files with a given extension and maps them by their
	 * base name. The base name is derived from the file name without its
	 * extension.
	 *
	 * @param directory the directory to scan
	 * @param extension the file extension to filter by (e.g., ".abi.json",
	 *                      ".bytecode")
	 *
	 * @return a map where keys are base file names and values are their
	 *             corresponding paths
	 */
	private Map<String, Path> mapFilesByName(Path directory, String extension) {
		Map<String, Path> fileMap = new HashMap<>();
		try (DirectoryStream<Path> stream = Files.newDirectoryStream(directory, "*" + extension)) {
			for (Path file : stream) {
				String fileName = file.getFileName().toString();
				String baseName = fileName.substring(0, fileName.indexOf('.'));
				fileMap.put(baseName, file);
			}
		} catch (IOException e) {
			log.error("Error reading directory: {}", e.getMessage());
		}
		return fileMap;
	}

	/**
	 * Converts the Bridge object to a JSON representation.
	 *
	 * @return JSONObject representing the Bridge.
	 */
	public JSONObject toJson() {
		JSONObject json = new JSONObject();
		JSONArray contractsArray = new JSONArray();

		for (SmartContract contract : contracts) {
			contractsArray.put(contract.toJson());
		}

		JSONObject policyJson = new JSONObject();
		for (Pair<String, String> pair : policy) {
			policyJson.put(pair.getLeft(), pair.getRight());
		}

		json.put("name", name);
		json.put("smart_contracts", contractsArray);
		json.put("policy", policyJson);
		json.put("bridge_vulnerabilities", _vulnerabilities != null ? _vulnerabilities.toJson() : new JSONArray());
		return json;
	}

	/**
	 * Constructs a JSON object containing the vulnerabilities detected in all
	 * the smart contracts within the bridge.
	 *
	 * @return JSONArray aggregating all vulnerabilities.
	 */
	public JSONArray vulnerabilitiesToJson() {
		JSONArray vulnerabilitiesArray = new JSONArray();

		for (SmartContract contract : contracts) {
			if (contract.getVulnerabilities() != null) {
				JSONObject contractVulnerabilities = new JSONObject();
				contractVulnerabilities.put("contract_name", contract.getName());
				contractVulnerabilities.put("vulnerabilities", contract.getVulnerabilities().toJson());
				vulnerabilitiesArray.put(contractVulnerabilities);
			}
		}

		return vulnerabilitiesArray;
	}

	/**
	 * Returns the JSON representation of the Bridge as a formatted string.
	 *
	 * @return String representation of the Bridge in JSON format.
	 */
	@Override
	public String toString() {
		return toJson().toString(4);
	}

	/**
	 * Returns an iterator over the smart contracts in this bridge.
	 *
	 * @return an Iterator over SmartContract objects
	 */
	@Override
	public Iterator<SmartContract> iterator() {
		return contracts.iterator();
	}
}