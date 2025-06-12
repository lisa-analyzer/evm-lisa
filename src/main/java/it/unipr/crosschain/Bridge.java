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
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;

public class Bridge implements Iterable<SmartContract> {
	private static final Logger log = LogManager.getLogger(Bridge.class);

	private final String name;
	private final List<SmartContract> contracts;

	private EVMCFG xCFG;

	/** Detected vulnerabilities in the bridge. */
	private VulnerabilitiesObject _vulnerabilities;

	public Bridge(String name) {
		this.name = name;
		this.contracts = new ArrayList<>();
	}

	/**
	 * Initializes the bridge by mapping and matching smart contracts from the
	 * ABI and bytecode directories. It creates `SmartContract` objects for each
	 * contract that has both an ABI and a bytecode file.
	 *
	 * @param bytecodeDirectoryPath the path to the directory containing
	 *                                  bytecode files
	 * @param abiDirectoryPath      the path to the directory containing ABI
	 *                                  files
	 */
	public Bridge(Path bytecodeDirectoryPath, Path abiDirectoryPath) {
		this(bytecodeDirectoryPath, abiDirectoryPath, "unknown_bridge_" + System.currentTimeMillis());
	}

	/**
	 * Constructs a Bridge object, initializing its fields and mapping smart
	 * contracts from the specified ABI and bytecode directories. It creates
	 * `SmartContract` objects for any contracts that have matching ABI and
	 * bytecode files.
	 *
	 * @param bytecodeDirectoryPath the path to the directory containing
	 *                                  bytecode files
	 * @param abiDirectoryPath      the path to the directory containing ABI
	 *                                  files
	 * @param name                  the name of the bridge
	 */
	public Bridge(Path bytecodeDirectoryPath, Path abiDirectoryPath, String name) {
		this(name);
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

		json.put("name", name);
		json.put("smart_contracts", contractsArray);
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