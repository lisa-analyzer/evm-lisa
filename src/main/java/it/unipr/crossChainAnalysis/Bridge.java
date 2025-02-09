package it.unipr.crossChainAnalysis;

import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class Bridge implements Iterable<SmartContract> {
	private static final Logger log = LogManager.getLogger(Bridge.class);
	private final Set<SmartContract> _contracts;

	private final List<Signature> _functions;
	private final List<Signature> _events;

	public Bridge() {
		this._contracts = new HashSet<>();
		this._functions = new ArrayList<>();
		this._events = new ArrayList<>();
	}

	/**
	 * Initializes the bridge by mapping and matching smart contracts from the
	 * ABI and bytecode directories. It creates `SmartContract` objects for each
	 * contract that has both an ABI and a bytecode file.
	 *
	 * @param abiDir      the path to the directory containing ABI files
	 * @param bytecodeDir the path to the directory containing bytecode files
	 */
	public Bridge(Path abiDir, Path bytecodeDir) {
		this();
		Map<String, Path> abiFiles = mapFilesByName(abiDir, ".abi.json");
		Map<String, Path> bytecodeFiles = mapFilesByName(bytecodeDir, ".bytecode");

		for (String name : bytecodeFiles.keySet()) {
			if (abiFiles.containsKey(name)) {
				_contracts.add(new SmartContract(name, abiFiles.get(name), bytecodeFiles.get(name)));
			} else {
				log.warn("Cannot find ABI file: {}", name);
			}
		}
	}

	public List<Signature> getFunctions() {
		return _functions;
	}

	public List<Signature> getEvents() {
		return _events;
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

	public void computeFunctionsAndEvents() {
		computeFunctions();
		computeEvents();
	}

	public void computeFunctions() {
		for (SmartContract contract : _contracts)
			_functions.addAll(contract.getFunctionsSignature());
	}

	public void computeEvents() {
		for (SmartContract contract : _contracts)
			_events.addAll(contract.getEventsSignature());
	}

	@Override
	public String toString() {
		StringBuilder result = new StringBuilder("Bridge Contracts:\n");
		for (SmartContract contract : _contracts) {
			result.append(contract).append("\n");
		}
		return result.toString();
	}

	@Override
	public Iterator<SmartContract> iterator() {
		return _contracts.iterator();
	}
}
