package it.unipr.crossChainAnalysis;

import it.unipr.abi.ABIFunctionSelector;
import it.unipr.cfg.EVMCFG;
import it.unive.lisa.program.cfg.statement.Statement;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.Set;
import org.apache.commons.lang3.tuple.Pair;

public class SmartContract {
	private final Path _abiPath;
	private final Path _bytecodePath;
	private final String _name;
	private EVMCFG _cfg;
	private final Set<Pair<String, String>> _abiFunctionSet;
	private Set<Pair<String, Statement>> _functionEntrypointsSet;

	public SmartContract(String name, Path abiPath, Path bytecodePath) {
		this._name = name;
		this._abiPath = abiPath;
		this._bytecodePath = bytecodePath;
		this._cfg = null;
		this._abiFunctionSet = ABIFunctionSelector.parseABI(abiPath);
		this._functionEntrypointsSet = new HashSet<>();
	}

	public Path getAbiPath() {
		return this._abiPath;
	}

	public Path getBytecodePath() {
		return this._bytecodePath;
	}

	public String getName() {
		return this._name;
	}

	public EVMCFG getCFG() {
		return this._cfg;
	}

	public Set<Pair<String, String>> getABIFunctionSet() {
		return this._abiFunctionSet;
	}

	public Set<Pair<String, Statement>> getFunctionEntrypointsSet() {
		return this._functionEntrypointsSet;
	}

	public void setCFG(EVMCFG cfg) {
		this._cfg = cfg;
	}

	/**
	 * This method iterates over all known entry points in the CFG and searches
	 * for corresponding function selectors in the bytecode. The results are
	 * stored in `_functionEntrypointsSet`, which maps function signatures to
	 * their corresponding statement nodes.
	 */
	public void computeFunctionEntrypoints() {
		for (Statement entrypoint : _cfg.getEntrypoints()) {
			_functionEntrypointsSet.addAll(_cfg.findMatchingStatements(entrypoint, _abiFunctionSet));
		}
	}

	@Override
	public String toString() {
		return "SmartContract{name='" + _name + "', abiPath=" + _abiPath + ", bytecodePath=" + _bytecodePath + "}";
	}
}