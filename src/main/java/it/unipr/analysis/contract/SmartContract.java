package it.unipr.analysis.contract;

import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.push.Push;
import it.unipr.frontend.EVMFrontend;
import it.unipr.frontend.EVMLiSAFeatures;
import it.unipr.frontend.EVMLiSATypeSystem;
import it.unipr.utils.*;
import it.unive.lisa.LiSA;
import it.unive.lisa.conf.LiSAConfiguration;
import it.unive.lisa.program.Program;
import it.unive.lisa.program.cfg.statement.Statement;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.HashSet;
import java.util.Set;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;

/**
 * Represents an EVM smart contract with analysis capabilities. Manages contract
 * bytecode, ABI, and provides methods for CFG analysis and vulnerability
 * detection.
 */
public class SmartContract {
	private static final Logger log = LogManager.getLogger(SmartContract.class);

	private String _name;

	/** Contract address on the Ethereum blockchain. */
	private String _address;

	/** Raw contract bytecode. */
	private String _bytecode;

	/** Mnemonic representation of bytecode (opcodes). */
	private String _mnemonicBytecode;

	/** Contract ABI in JSON format. */
	private JSONArray _abi;

	/** Base directory for storing contract analysis results. */
	private static Path _workingDirectory = Path.of("execution", "results");

	/** Path to the contract's ABI file. */
	private Path _abiFilePath;

	/** Path to the contract's bytecode file. */
	private Path _bytecodeFilePath;

	/** Path to the contract's mnemonic bytecode file. */
	private Path _mnemonicBytecodeFilePath;

	/** Control flow graph of the contract. */
	private EVMCFG _cfg;

	/** Basic blocks extracted from the CFG. */
	private Set<BasicBlock> _basicBlocks;

	/** Statistical information about the contract analysis. */
	private StatisticsObject _statistics;

	/** Detected vulnerabilities in the contract. */
	private VulnerabilitiesObject _vulnerabilities;

	/** Function signatures extracted from the contract ABI. */
	private Set<Signature> _functionsSignature;

	/** Event signatures extracted from the contract ABI. */
	private Set<Signature> _eventsSignature;

	/**
	 * Constructs a new SmartContract with a generated address.
	 */
	public SmartContract() {
		this._address = "contract-" + System.currentTimeMillis();
		this._functionsSignature = new HashSet<>();
		this._eventsSignature = new HashSet<>();

		Path outputDir = _workingDirectory.resolve(_address);
		try {
			Files.createDirectories(outputDir);
		} catch (IOException e) {
			log.error("Unable to create output directory: {}", outputDir);
			JSONManager.throwNewError("Unable to create output directory: " + outputDir);
			System.exit(1);
		}
	}

	/**
	 * Constructs a SmartContract using an Ethereum address. Downloads bytecode
	 * and ABI from Etherscan if not available locally.
	 *
	 * @param address Ethereum address of the contract.
	 * 
	 * @throws IllegalArgumentException If the address is invalid.
	 */
	public SmartContract(String address) {
		if (!EthereumUtils.isValidEVMAddress(address)) {
			log.error("Invalid address: {}", address);
			System.err.println(JSONManager.throwNewError("Invalid address: " + address));
			System.exit(1);
		}

		this._address = address;
		Path outputDir = _workingDirectory.resolve(address);
		this._abiFilePath = outputDir.resolve(address + ".abi");
		this._bytecodeFilePath = outputDir.resolve(address + ".bytecode");
		this._mnemonicBytecodeFilePath = outputDir.resolve(address + ".opcode");

		// Bytecode case
		try {
			// If the bytecode file does not exist, we will do an API request to
			// Etherscan
			File file = new File(String.valueOf(_bytecodeFilePath));
			if (!file.exists()) {
				Thread.sleep(500); // Etherscan API request limit
				Files.createDirectories(outputDir);

				this._bytecode = EVMFrontend.parseBytecodeFromEtherscan(address);
				// Write bytecode to file
				if (this._bytecode != null)
					Files.writeString(this._bytecodeFilePath, this._bytecode, StandardOpenOption.CREATE,
							StandardOpenOption.TRUNCATE_EXISTING);
			} else {
				log.warn("Contract (bytecode) already present in {}, not downloaded.", _bytecodeFilePath);
				this._bytecode = new String(Files.readAllBytes(Paths.get(_bytecodeFilePath.toString())));
			}
		} catch (IOException e) {
			log.warn("Failed to load bytecode: {}", address, e);
		} catch (InterruptedException e) {
			log.error("Unable to parse bytecode from Etherscan: {}", address);
			System.err.println(JSONManager.throwNewError("Unable to parse bytecode from Etherscan: " + address));
			System.exit(1);
		}

		// ABI case
		try {
			// If the ABI file does not exist, we will do an API request to
			// Etherscan
			File file = new File(String.valueOf(_abiFilePath));
			if (!file.exists()) {
				Thread.sleep(500); // Etherscan API request limit

				Files.createDirectories(outputDir);
				this._abi = EVMFrontend.parseABIFromEtherscan(address);

				// Write ABI to file
				Files.writeString(this._abiFilePath, this._abi.toString(4), StandardOpenOption.CREATE,
						StandardOpenOption.TRUNCATE_EXISTING);
			} else {
				log.warn("Contract (ABI) already present in {}, not downloaded.", _abiFilePath);
				this._abi = new JSONArray(new String(Files.readAllBytes(Paths.get(_abiFilePath.toString()))));
			}
		} catch (IOException e) {
			log.warn("Failed to load ABI: {}", address, e);
		} catch (InterruptedException e) {
			log.error("Unable to parse ABI from Etherscan: {}", address);
			System.err.println(JSONManager.throwNewError("Unable to parse ABI from Etherscan: " + address));
			System.exit(1);
		}

		try {
			EVMFrontend.opcodesFromBytecode(_bytecode, _mnemonicBytecodeFilePath.toString());
			this._mnemonicBytecode = new String(Files.readAllBytes(Paths.get(_mnemonicBytecodeFilePath.toString())));
		} catch (IOException e) {
			log.error("Failed to save mnemonic bytecode to file for contract {}", address);
			System.err.println(
					JSONManager.throwNewError("Failed to save mnemonic bytecode to file for contract: " + address));
			System.exit(1);
		}

		this._functionsSignature = ABIManager.parseFunctionsFromABI(this._abiFilePath);
		this._eventsSignature = ABIManager.parseEventsFromABI(this._abiFilePath);
	}

	/**
	 * Constructs a SmartContract from a bytecode file.
	 *
	 * @param bytecodeFilePath Path to the bytecode file.
	 * 
	 * @throws IllegalArgumentException If bytecodeFilePath is null.
	 */
	public SmartContract(Path bytecodeFilePath) {
		if (bytecodeFilePath == null) {
			log.error("Bytecode file path is null");
			System.err.println(JSONManager.throwNewError("Bytecode file path is null"));
			System.exit(1);
		} else if (!Files.exists(bytecodeFilePath)) {
			log.error("Bytecode file path not found: {}", bytecodeFilePath);
			System.err.println(JSONManager.throwNewError("Bytecode file path not found: " + bytecodeFilePath));
			System.exit(1);
		}

		this._name = getFileNameWithoutExtension(bytecodeFilePath);
		this._address = getFileNameWithoutExtension(bytecodeFilePath);

		Path outputDir = _workingDirectory.resolve(_address);
		try {
			Files.createDirectories(outputDir);
		} catch (IOException e) {
			log.error("Unable to create output directory: {}", outputDir);
			JSONManager.throwNewError("Unable to create output directory: " + outputDir);
			System.exit(1);
		}

		this._bytecodeFilePath = outputDir.resolve(_address + ".bytecode");
		this._mnemonicBytecodeFilePath = outputDir.resolve(_address + ".opcode");

		try {
			this._bytecode = new String(Files.readAllBytes(Paths.get(bytecodeFilePath.toString())));
			EVMFrontend.opcodesFromBytecode(_bytecode, _mnemonicBytecodeFilePath.toString());
			this._mnemonicBytecode = new String(Files.readAllBytes(Paths.get(_mnemonicBytecodeFilePath.toString())));
		} catch (IOException e) {
			log.warn("Failed to read bytecode from files: {}", _bytecodeFilePath);
		}
	}

	/**
	 * Constructs a SmartContract from bytecode and ABI files.
	 *
	 * @param bytecodeFilePath Path to the bytecode file.
	 * @param abiFilePath      Path to the ABI file.
	 * 
	 * @throws IllegalArgumentException If either path is null.
	 */
	public SmartContract(Path bytecodeFilePath, Path abiFilePath) {
		this(bytecodeFilePath);

		if (abiFilePath == null) {
			log.error("ABI file path is null");
			System.err.println(JSONManager.throwNewError("ABI file path is null"));
			System.exit(1);
		} else if (!Files.exists(abiFilePath)) {
			log.error("ABI file not found: {}", abiFilePath);
			System.err.println(JSONManager.throwNewError("ABI file not found: " + abiFilePath));
			System.exit(1);
		}

		this._abiFilePath = abiFilePath;

		try {
			this._abi = new JSONArray(new String(Files.readAllBytes(Paths.get(_abiFilePath.toString()))));
		} catch (IOException e) {
			log.warn("Failed to read ABI from files: {}", _abiFilePath);
		}

		this._functionsSignature = ABIManager.parseFunctionsFromABI(abiFilePath);
		this._eventsSignature = ABIManager.parseEventsFromABI(abiFilePath);
	}

	///////////////////// GETTERs
	/**
	 * Returns the contract address.
	 *
	 * @return The contract address.
	 */
	public String getAddress() {
		return _address;
	}

	/**
	 * Returns the contract bytecode.
	 *
	 * @return The raw bytecode.
	 */
	public String getBytecode() {
		return _bytecode;
	}

	/**
	 * Returns the contract ABI.
	 *
	 * @return The ABI as a JSONArray.
	 */
	public JSONArray getAbi() {
		return _abi;
	}

	/**
	 * Returns the path of the ABI file.
	 *
	 * @return Path of the ABI file.
	 */
	public Path getAbiPath() {
		return this._abiFilePath;
	}

	/**
	 * Returns the path of the bytecode file.
	 *
	 * @return Path of the bytecode file.
	 */
	public Path getBytecodePath() {
		return this._bytecodeFilePath;
	}

	/**
	 * Returns the working directory for this contract.
	 *
	 * @return Working directory path.
	 */
	public Path getWorkingDirectory() {
		return _workingDirectory.resolve(this._address);
	}

	/**
	 * Returns the path of the mnemonic bytecode file.
	 *
	 * @return Path of the mnemonic bytecode file.
	 */
	public Path getMnemonicBytecodePath() {
		return this._mnemonicBytecodeFilePath;
	}

	/**
	 * Returns the control flow graph of the contract.
	 *
	 * @return The contract's CFG.
	 */
	public EVMCFG getCFG() {
		return this._cfg;
	}

	/**
	 * Returns the basic blocks of the contract.
	 *
	 * @return Set of basic blocks.
	 */
	public Set<BasicBlock> getBasicBlocks() {
		return this._basicBlocks;
	}

	/**
	 * Returns the function signatures of the contract.
	 *
	 * @return Set of function signatures.
	 */
	public Set<Signature> getFunctionsSignature() {
		return this._functionsSignature;
	}

	/**
	 * Returns the event signatures of the contract.
	 *
	 * @return Set of event signatures.
	 */
	public Set<Signature> getEventsSignature() {
		return this._eventsSignature;
	}

	/**
	 * Returns the statistical information about the contract.
	 *
	 * @return Statistical object.
	 */
	public StatisticsObject getStatistics() {
		return _statistics;
	}

	/**
	 * Returns the vulnerabilities detected in the contract.
	 *
	 * @return Vulnerabilities object.
	 */
	public VulnerabilitiesObject getVulnerabilities() {
		return _vulnerabilities;
	}

	///////////////////// SETTERs
	/**
	 * Sets the contract address.
	 *
	 * @param address The contract address.
	 * 
	 * @return This SmartContract instance for method chaining.
	 */
	public SmartContract setAddress(String address) {
		this._address = address;
		return this;
	}

	/**
	 * Sets the contract bytecode and generates the mnemonic representation.
	 *
	 * @param bytecode The raw bytecode.
	 * 
	 * @return This SmartContract instance for method chaining.
	 * 
	 * @throws IllegalArgumentException If bytecode is null.
	 */
	public SmartContract setBytecode(String bytecode) {
		if (bytecode == null)
			throw new IllegalArgumentException("Bytecode cannot be null");

		this._bytecode = bytecode;

		Path outputDir = _workingDirectory.resolve(_address);
		this._bytecodeFilePath = outputDir.resolve(_address + ".bytecode");
		this._mnemonicBytecodeFilePath = outputDir.resolve(_address + ".opcode");

		try {
			Files.createDirectories(outputDir);
			Files.writeString(this._bytecodeFilePath, this._bytecode, StandardOpenOption.CREATE,
					StandardOpenOption.TRUNCATE_EXISTING);

			EVMFrontend.opcodesFromBytecode(_bytecode, _mnemonicBytecodeFilePath.toString());
			this._mnemonicBytecode = new String(Files.readAllBytes(Paths.get(_mnemonicBytecodeFilePath.toString())));
		} catch (IOException e) {
			log.error("Failed to write bytecode or mnemonic bytecode to files {}", outputDir);
			System.err.println(JSONManager
					.throwNewError("Failed to write bytecode or mnemonic bytecode to files in " + outputDir));
			System.exit(1);
		}

		return this;
	}

	/**
	 * Sets the contract ABI.
	 *
	 * @param abi The ABI as a JSONArray.
	 * 
	 * @return This SmartContract instance for method chaining.
	 */
	public SmartContract setAbi(JSONArray abi) {
		this._abi = abi;
		return this;
	}

	/**
	 * Sets the control flow graph and extracts basic blocks.
	 *
	 * @param cfg The {@link EVMCFG} to set.
	 * 
	 * @return This SmartContract instance for method chaining.
	 */
	public SmartContract setCFG(EVMCFG cfg) {
		if (cfg == null) {
			System.err.println(JSONManager.throwNewError("CFG cannot be null"));
			System.exit(1);
		}

		this._cfg = cfg;
		this._basicBlocks = BasicBlock.getBasicBlocks(cfg);
		return this;
	}

	/**
	 * Sets the statistical information.
	 *
	 * @param statistics Statistical object.
	 * 
	 * @return This SmartContract instance for method chaining.
	 */
	public SmartContract setStatistics(StatisticsObject statistics) {
		this._statistics = statistics;
		return this;
	}

	/**
	 * Sets the vulnerabilities object.
	 *
	 * @param vulnerabilities Vulnerabilities object.
	 * 
	 * @return This SmartContract instance for method chaining.
	 */
	public SmartContract setVulnerabilities(VulnerabilitiesObject vulnerabilities) {
		this._vulnerabilities = vulnerabilities;
		return this;
	}

	/**
	 * Sets the path to the ABI file.
	 *
	 * @param abiFilePath Path to the ABI file.
	 * 
	 * @return This SmartContract instance for method chaining.
	 */
	public SmartContract setAbiFilePath(Path abiFilePath) {
		this._abiFilePath = abiFilePath;
		return this;
	}

	/**
	 * Sets the path to the bytecode file.
	 *
	 * @param bytecodeFilePath Path to the bytecode file.
	 * 
	 * @return This SmartContract instance for method chaining.
	 */
	public SmartContract setBytecodeFilePath(Path bytecodeFilePath) {
		this._bytecodeFilePath = bytecodeFilePath;
		return this;
	}

	/**
	 * Sets the function signatures.
	 *
	 * @param functionsSignature Set of function signatures.
	 * 
	 * @return This SmartContract instance for method chaining.
	 */
	public SmartContract setFunctionsSignature(Set<Signature> functionsSignature) {
		this._functionsSignature = functionsSignature;
		return this;
	}

	/**
	 * Sets the event signatures.
	 *
	 * @param eventsSignature Set of event signatures.
	 * 
	 * @return This SmartContract instance for method chaining.
	 */
	public SmartContract setEventsSignature(Set<Signature> eventsSignature) {
		this._eventsSignature = eventsSignature;
		return this;
	}

	/**
	 * Sets the working directory for all contract analyses.
	 *
	 * @param workingDirectory Path to the working directory.
	 */
	public static void setWorkingDirectory(Path workingDirectory) {
		_workingDirectory = workingDirectory;
	}

	/**
	 * Identifies and associates entry points for each function signature in the
	 * contract. Uses the selector from each signature to find matching Push
	 * statements in the CFG.
	 */
	public void computeFunctionsSignatureEntryPoints() {
		if (_functionsSignature == null) {
			log.warn("Unable to compute functions entry points (_functionsSignature is null)");
			return;
		}

		for (Statement node : _cfg.getNodes())
			if (node instanceof Push)
				for (Signature signature : _functionsSignature)
					if (node.toString().contains(signature.getSelector()))
						signature.addEntryPoint(_cfg.getCloserJumpdest(node));

	}

	/**
	 * Computes the exit points for each function signature in the contract.
	 * Exit points are determined based on whether the function returns a value.
	 */
	public void computeFunctionsSignatureExitPoints() {
		if (_functionsSignature == null) {
			log.warn("Unable to compute functions exit points (_functionsSignature is null)");
			return;
		}

		for (Signature signature : _functionsSignature) {
			boolean isVoid = signature.getOutputParamCount() == 0;

			for (Statement functionEntryPoint : signature.getEntryPoints())
				for (Statement functionExitPoint : _cfg.getFunctionExitPoints(functionEntryPoint, isVoid))
					signature.addExitPoint(functionExitPoint);
		}
	}

	/**
	 * Identifies and associates entry points for each event signature in the
	 * contract. Uses the selector from each signature to find matching Push
	 * statements in the CFG.
	 */
	public void computeEventsSignatureEntryPoints() {
		if (_eventsSignature == null) {
			log.warn("Unable to compute functions entry points (_eventsSignature is null)");
			return;
		}

		for (Statement node : _cfg.getNodes())
			if (node instanceof Push)
				for (Signature signature : _eventsSignature)
					if (node.toString().contains(signature.getSelector()))
						signature.addEntryPoint(node);
	}

	/**
	 * Computes and registers event exit points for this smart contract. This
	 * method sets up a LiSA analysis environment and runs the
	 * {@code EventsExitPointsComputer} to identify statements where events
	 * exit.
	 */
	public void computeEventsExitPoints() {
		if (_eventsSignature == null) {
			log.warn("Unable to compute functions exit points (_eventsSignature is null)");
			return;
		}

		// Setup configuration
		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
		program.addCodeMember(this._cfg);
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(this);
		LiSA lisa = new LiSA(conf);

		EventsExitPointsComputer checker = new EventsExitPointsComputer();
		conf.semanticChecks.add(checker);
		lisa.run(program);
	}

	/**
	 * Generates a DOT graph visualization of the CFG with basic blocks. Saves
	 * the graph to a file in the contract's working directory.
	 */
	public void generateCFGWithBasicBlocks() {
		Path dotFile = _workingDirectory.resolve(_address).resolve("CFG.dot");
		DOTFileManager.generateDotGraph(JSONManager.basicBlocksToJson(this), dotFile.toString());
		log.info("Generated CFG at {}", dotFile);
	}

	/**
	 * Converts this SmartContract to a JSON object. Includes all fields of the
	 * contract, including bytecode, ABI, signatures, and analysis results.
	 *
	 * @return JSONObject representation of this contract.
	 */
	public JSONObject toJson() {
		JSONObject jsonObject = new JSONObject();

		jsonObject.put("address", _address != null ? _address : new JSONArray());
		jsonObject.put("bytecode", _bytecode != null ? _bytecode : new JSONArray());
		jsonObject.put("mnemonic_bytecode", _mnemonicBytecode != null ? _mnemonicBytecode : new JSONArray());
		jsonObject.put("abi", _abi != null ? _abi : new JSONArray());

		jsonObject.put("working_directory", _workingDirectory.toString());

		jsonObject.put("abi_file_path", _abiFilePath != null ? _abiFilePath.toString() : new JSONArray());
		jsonObject.put("bytecode_file_path",
				_bytecodeFilePath != null ? _bytecodeFilePath.toString() : new JSONArray());
		jsonObject.put("mnemonic_bytecode_file_path", _mnemonicBytecodeFilePath.toString());

		jsonObject.put("statistics", _statistics != null ? _statistics.toJson() : new JSONArray());

		jsonObject.put("vulnerabilities", _vulnerabilities != null ? _vulnerabilities.toJson() : new JSONArray());

		jsonObject.put("basic_blocks",
				_basicBlocks != null ? JSONManager.basicBlocksToJson(this) : new JSONArray());

		jsonObject.put("basic_blocks_pc", _basicBlocks != null ? BasicBlock.basicBlocksToLongArrayToString(
				BasicBlock.basicBlocksToLongArray(_basicBlocks)) : new JSONArray());

		JSONArray functionsArray = new JSONArray();
		if (_functionsSignature != null && !_functionsSignature.isEmpty())
			for (Signature signature : _functionsSignature)
				functionsArray.put(signature.toJson());
		jsonObject.put("functions_signature", !functionsArray.isEmpty() ? functionsArray : new JSONArray());

		JSONArray eventsArray = new JSONArray();
		if (_eventsSignature != null && !_eventsSignature.isEmpty())
			for (Signature signature : _eventsSignature)
				eventsArray.put(signature.toJson());
		jsonObject.put("events_signature", !eventsArray.isEmpty() ? eventsArray : new JSONArray());

		return jsonObject;
	}

	@Override
	public String toString() {
		return toJson().toString(4);
	}

	/**
	 * Saves the contract information to a JSON file in the working directory.
	 *
	 * @return true if the operation was successful, false otherwise.
	 */
	public boolean toFile() {
		Path outputDir = _workingDirectory.resolve(_address);
		try {
			Files.createDirectories(outputDir);
			Files.writeString(
					outputDir.resolve("results.json"),
					this.toJson().toString(4),
					StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
		} catch (IOException e) {
			log.error("Failed to save results in {}", outputDir, e);
			return false;
		}
		return true;
	}

	/**
	 * Extracts the filename without extension from a given Path.
	 *
	 * @param path The file path
	 * 
	 * @return The filename without extension
	 */
	private static String getFileNameWithoutExtension(Path path) {
		String fileName = path.getFileName().toString();
		int lastDotIndex = fileName.lastIndexOf('.');
		return (lastDotIndex == -1) ? fileName : fileName.substring(0, lastDotIndex);
	}
}