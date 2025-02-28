package it.unipr.analysis;

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

public class SmartContract {
	private static final Logger log = LogManager.getLogger(SmartContract.class);

	private String _address;

	private String _bytecode;
	private String _mnemonicBytecode;
	private JSONArray _abi;

	private static Path _workingDirectory = Path.of("execution", "results");
	private Path _abiFilePath;
	private Path _bytecodeFilePath;
	private Path _mnemonicBytecodeFilePath;

	private EVMCFG _cfg;
	private Set<BasicBlock> _basicBlocks;
	private StatisticsObject _statistics;
	private VulnerabilitiesObject _vulnerabilities;

	private Set<Signature> _functionsSignature;
	private Set<Signature> _eventsSignature;

	public SmartContract() {
		this._address = "contract-" + System.currentTimeMillis();
		this._functionsSignature = new HashSet<>();
		this._eventsSignature = new HashSet<>();
	}

	public SmartContract(String address) {
		if (!EthereumUtils.isValidEVMAddress(address))
			throw new IllegalArgumentException("Invalid address: " + address);

		this._address = address;
		Path outputDir = _workingDirectory.resolve(address);
		this._abiFilePath = outputDir.resolve(address + ".abi.json");
		this._bytecodeFilePath = outputDir.resolve(address + ".bytecode");
		this._mnemonicBytecodeFilePath = outputDir.resolve(address + ".opcode");

		// If the file does not exist, we will do an API request to Etherscan
		File file = new File(String.valueOf(_bytecodeFilePath));
		if (!file.exists()) {
			try {
				this._bytecode = EVMFrontend.parseBytecodeFromEtherscan(address);
			} catch (IOException e) {
				log.warn("Failed to parse Ethereum bytecode: {}", address, e);
			}

			try {
				this._abi = EVMFrontend.parseABIFromEtherscan(address);
			} catch (IOException e) {
				log.warn("Failed to parse Ethereum ABI: {}", address, e);
			}
		} else {
			log.warn("Contract {} already present in memory, not downloaded.", address);
			try {
				this._bytecode = new String(Files.readAllBytes(Paths.get(_bytecodeFilePath.toString())));
				this._abi = new JSONArray(new String(Files.readAllBytes(Paths.get(_abiFilePath.toString()))));
			} catch (IOException e) {
				log.warn("Failed to read bytecode from {}", _bytecodeFilePath, e);
			}
		}

		try {
			Files.createDirectories(outputDir);

			// Write ABI to file
			if (this._abi != null)
				Files.writeString(this._abiFilePath, this._abi.toString(4), StandardOpenOption.CREATE,
						StandardOpenOption.TRUNCATE_EXISTING);

			// Write bytecode to file
			if (this._bytecode != null)
				Files.writeString(this._bytecodeFilePath, this._bytecode, StandardOpenOption.CREATE,
						StandardOpenOption.TRUNCATE_EXISTING);

			EVMFrontend.opcodesFromBytecode(_bytecode, _mnemonicBytecodeFilePath.toString());
			this._mnemonicBytecode = new String(Files.readAllBytes(Paths.get(_mnemonicBytecodeFilePath.toString())));

		} catch (IOException e) {
			log.error("Failed to save ABI or bytecode to file for contract {}", address, e);
		}

		this._functionsSignature = ABIManager.parseFunctionsFromABI(this._abiFilePath);
		this._eventsSignature = ABIManager.parseEventsFromABI(this._abiFilePath);
	}

	public SmartContract(Path bytecodeFilePath) {
		this();
		if (bytecodeFilePath == null)
			throw new IllegalArgumentException("bytecodeFilePath cannot be null");

		Path outputDir = _workingDirectory.resolve(_address);
		this._bytecodeFilePath = outputDir.resolve(_address + ".bytecode");
		this._mnemonicBytecodeFilePath = outputDir.resolve(_address + ".opcode");

		try {
			// TODO check if bytecodeFilePath exists
			this._bytecode = new String(Files.readAllBytes(Paths.get(bytecodeFilePath.toString())));

			EVMFrontend.opcodesFromBytecode(_bytecode, _mnemonicBytecodeFilePath.toString());
			this._mnemonicBytecode = new String(Files.readAllBytes(Paths.get(_mnemonicBytecodeFilePath.toString())));

		} catch (IOException e) {
			log.warn("Failed to read bytecode from files: {}, {}", _bytecodeFilePath, _abiFilePath);
		}

		try {
			Files.createDirectories(outputDir);

			Files.writeString(this._bytecodeFilePath, this._bytecode, StandardOpenOption.CREATE,
					StandardOpenOption.TRUNCATE_EXISTING);

			EVMFrontend.opcodesFromBytecode(_bytecode, _mnemonicBytecodeFilePath.toString());
			this._mnemonicBytecode = new String(Files.readAllBytes(Paths.get(_mnemonicBytecodeFilePath.toString())));

		} catch (IOException e) {
			log.error("Failed to parse mnemonic from bytecode: {}", _bytecodeFilePath);
		}
	}

	public SmartContract(Path bytecodeFilePath, Path abiFilePath) {
		this();

		if (bytecodeFilePath == null || abiFilePath == null)
			throw new IllegalArgumentException("bytecodeFilePath and abiFilePath cannot be null");

		this._bytecodeFilePath = bytecodeFilePath;
		this._abiFilePath = abiFilePath;
		this._mnemonicBytecodeFilePath = _workingDirectory.resolve(this._address + ".opcode");

		try {
			this._bytecode = new String(Files.readAllBytes(Paths.get(_bytecodeFilePath.toString())));
			this._abi = new JSONArray(new String(Files.readAllBytes(Paths.get(_abiFilePath.toString()))));

			EVMFrontend.opcodesFromBytecode(_bytecode, _mnemonicBytecodeFilePath.toString());
			this._mnemonicBytecode = new String(Files.readAllBytes(Paths.get(_mnemonicBytecodeFilePath.toString())));

		} catch (IOException e) {
			log.warn("Failed to read bytecode or ABI from files: {}, {}", _bytecodeFilePath, _abiFilePath);
		} catch (NullPointerException npe) {
			log.warn("Failed to read bytecode or ABI from files: {}", _bytecodeFilePath);
		}

		this._functionsSignature = ABIManager.parseFunctionsFromABI(abiFilePath);
		this._eventsSignature = ABIManager.parseEventsFromABI(abiFilePath);
	}

	///////////////////// GETTERs
	public String getAddress() {
		return _address;
	}

	public String getBytecode() {
		return _bytecode;
	}

	public JSONArray getAbi() {
		return _abi;
	}

	public Path getAbiPath() {
		return this._abiFilePath;
	}

	public Path getBytecodePath() {
		return this._bytecodeFilePath;
	}

	public Path getWorkingDirectory() {
		return _workingDirectory.resolve(this._address);
	}

	public Path getMnemonicBytecodePath() {
		return this._mnemonicBytecodeFilePath;
	}

	public EVMCFG getCFG() {
		return this._cfg;
	}

	public Set<BasicBlock> getBasicBlocks() {
		return this._basicBlocks;
	}

	public Set<Signature> getFunctionsSignature() {
		return this._functionsSignature;
	}

	public Set<Signature> getEventsSignature() {
		return this._eventsSignature;
	}

	public StatisticsObject getStatistics() {
		return _statistics;
	}

	public VulnerabilitiesObject getVulnerabilities() {
		return _vulnerabilities;
	}

	public void printStatistics() {
		log.info("Total opcodes: {}", _statistics.getTotalOpcodes());
		log.info("Total jumps: {}", _statistics.getTotalJumps());
		log.info("Resolved jumps: {}", _statistics.getResolvedJumps());
		log.info("Definitely unreachable jumps: {}", _statistics.getDefinitelyUnreachableJumps());
		log.info("Maybe unreachable jumps: {}", _statistics.getMaybeUnreachableJumps());
		log.info("Unsound jumps: {}", _statistics.getUnsoundJumps());
		log.info("Maybe unsound jumps: {}", _statistics.getMaybeUnsoundJumps());
	}

	public void printVulnerabilities() {
		log.info("Reentrancy: {}", _vulnerabilities.getReentrancy());
		log.info("Timestamp dependency: {}", _vulnerabilities.getTimestamp());
		log.info("Tx.Origin: {}", _vulnerabilities.getTxOrigin());
	}

	///////////////////// SETTERs
	public SmartContract setAddress(String address) {
		this._address = address;
		return this;
	}

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
		}

		return this;
	}

	public SmartContract setAbi(JSONArray abi) {
		this._abi = abi;
		return this;
	}

	public SmartContract setCFG(EVMCFG cfg) {
		this._cfg = cfg;
		this._basicBlocks = BasicBlock.getBasicBlocks(cfg);
		return this;
	}

	public SmartContract setStatistics(StatisticsObject statistics) {
		this._statistics = statistics;
		return this;
	}

	public SmartContract setVulnerabilities(VulnerabilitiesObject vulnerabilities) {
		this._vulnerabilities = vulnerabilities;
		return this;
	}

	public SmartContract setAbiFilePath(Path abiFilePath) {
		this._abiFilePath = abiFilePath;
		return this;
	}

	public SmartContract setBytecodeFilePath(Path bytecodeFilePath) {
		this._bytecodeFilePath = bytecodeFilePath;
		return this;
	}

	public SmartContract setFunctionsSignature(Set<Signature> functionsSignature) {
		this._functionsSignature = functionsSignature;
		return this;
	}

	public SmartContract setEventsSignature(Set<Signature> eventsSignature) {
		this._eventsSignature = eventsSignature;
		return this;
	}

	public static void setWorkingDirectory(Path workingDirectory) {
		_workingDirectory = workingDirectory;
	}

	/**
	 * Identifies and associates entry points for each function signature in the
	 * contract. TODO fix this is not fully correct
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
						signature.addEntryPoint(node);
	}

	/**
	 * Computes the exit points for each function signature in the contract.
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
	 * contract.
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

	public void generateCFGWithBasicBlocks() {
		log.info("Generating graph with basic blocks...");
		Path dotFile = _workingDirectory.resolve(_address).resolve("CFG.dot");
		DOTFileManager.generateDotGraph(JSONManager.basicBlocksToJson(this), dotFile.toString());
		log.info("Generated graph with basic blocks at {}", dotFile);
	}

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
}