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

	public Bridge(String name) {
		this(null, null, null, name);
	}

	public Bridge(Path bytecodeDirectoryPath, Path abiDirectoryPath, Path policyPath) {
		this(bytecodeDirectoryPath, abiDirectoryPath, policyPath, "unknown_bridge_" + System.currentTimeMillis());
	}

	public Bridge(Path bytecodeDirectoryPath, Path abiDirectoryPath) {
		this(bytecodeDirectoryPath, abiDirectoryPath, null, "unknown_bridge_" + System.currentTimeMillis());
	}

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
		log.info("Created bridge {} with {} contracts.", name, contracts.size());

		if (policyPath != null)
			loadPolicy(policyPath);
		else
			log.info("Created bridge without policy. Using default policy");

	}

	public String getName() {
		return name;
	}

	public List<SmartContract> getSmartContracts() {
		return contracts;
	}

	public List<Signature> getFunctions() {
		List<Signature> functions = new ArrayList<>();
		for (SmartContract contract : contracts)
			functions.addAll(contract.getFunctionsSignature());
		return functions;
	}

	public List<Signature> getEvents() {
		List<Signature> events = new ArrayList<>();
		for (SmartContract contract : contracts)
			events.addAll(contract.getEventsSignature());
		return events;
	}

	public EVMCFG getXCFG() {
		return xCFG;
	}

	public List<Pair<String, String>> getPolicy() {
		return policy;
	}

	public boolean hasEventFunctionMapping(String event) {
		for (Pair<String, String> pair : policy)
			if (pair.getLeft().equals(event))
				return true;
		return false;
	}

	public String getFunctionForEvent(String event) {
		for (Pair<String, String> pair : policy)
			if (pair.getLeft().equals(event))
				return pair.getRight();
		return null;
	}

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
			log.error("Error reading policy file: {}", e.getMessage());
		} catch (Exception e) {
			log.error("Error parsing policy JSON: {}", e.getMessage());
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

	@Override
	public Iterator<SmartContract> iterator() {
		return contracts.iterator();
	}
}