package it.unipr.crossChainAnalysis;

import it.unipr.abi.ABIFunctionSelector;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.push.Push;
import it.unive.lisa.program.cfg.statement.Statement;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.Set;
import org.apache.commons.lang3.tuple.Pair;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class SmartContract {
	private static final Logger log = LogManager.getLogger(SmartContract.class);

	private final Path _abiPath;
	private final Path _bytecodePath;
	private final String _name;
	private EVMCFG _cfg;

	private final Set<Pair<String, String>> _functionsSignature;
	private final Set<Pair<String, String>> _eventsSignature;
	private final Set<Pair<String, Statement>> _functionsSignatureEntrypoints;
	private final Set<Pair<String, Statement>> _eventsSignatureEntrypoints;

	private final Set<Pair<String, String>> _emittingBlocksSignature;
	private final Set<Pair<String, String>> _informationBlocksSignature;
	private final Set<Pair<String, Statement>> _emittingBlocksSignatureEntrypoints;
	private final Set<Pair<String, Statement>> _informationBlocksSignatureEntrypoints;

	public SmartContract(String name, Path abiPath, Path bytecodePath) {
		this._name = name;
		this._abiPath = abiPath;
		this._bytecodePath = bytecodePath;
		this._cfg = null;
		this._functionsSignature = ABIFunctionSelector.parseFunctionsFromABI(abiPath);
		this._eventsSignature = ABIFunctionSelector.parseEventsFromABI(abiPath);
		this._functionsSignatureEntrypoints = new HashSet<>();
		this._eventsSignatureEntrypoints = new HashSet<>();
		this._emittingBlocksSignature = new HashSet<>();
		this._informationBlocksSignature = new HashSet<>();
		this._emittingBlocksSignatureEntrypoints = new HashSet<>();
		this._informationBlocksSignatureEntrypoints = new HashSet<>();
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

	public Set<Pair<String, String>> getFunctionsSignature() {
		return this._functionsSignature;
	}

	public Set<Pair<String, String>> getEventsSignature() {
		return this._eventsSignature;
	}

	public Set<Pair<String, Statement>> getFunctionsSignatureEntrypoints() {
		return this._functionsSignatureEntrypoints;
	}

	public Set<Pair<String, String>> getEmittingBlocksSignature() {
		return this._emittingBlocksSignature;
	}

	public Set<Pair<String, String>> getInformationBlocksSignature() {
		return this._informationBlocksSignature;
	}

	public Set<Pair<String, Statement>> getEmittingBlocksSignatureEntrypoints() {
		return this._emittingBlocksSignatureEntrypoints;
	}

	public Set<Pair<String, Statement>> getInformationBlocksSignatureEntrypoints() {
		return this._informationBlocksSignatureEntrypoints;
	}

	public void setCFG(EVMCFG cfg) {
		this._cfg = cfg;
	}

	/**
	 * This method iterates over all known entry points in the CFG and searches
	 * for corresponding function selectors in the bytecode. The results are
	 * stored in `_functionsSignatureEntrypoints`, which maps function
	 * signatures to their corresponding statement nodes.
	 */
	public void computeFunctionsSignatureEntrypoints() {
		for (Statement node : _cfg.getNodes())
			if (node instanceof Push)
				for (Pair<String, String> signature : _functionsSignature)
					if (node.toString().contains(signature.getRight()))
						_functionsSignatureEntrypoints.add(Pair.of(signature.getLeft(), node));
	}

	/**
	 * This method iterates over all known entry points in the CFG and searches
	 * for corresponding event selectors in the bytecode. The results are stored
	 * in `_eventsSignatureEntrypoints`, which maps function signatures to their
	 * corresponding statement nodes.
	 */
	public void computeEventsSignatureEntrypoints() {
		for (Statement node : _cfg.getNodes())
			if (node instanceof Push)
				for (Pair<String, String> signature : _eventsSignature)
					if (node.toString().contains(signature.getRight()))
						_eventsSignatureEntrypoints.add(Pair.of(signature.getLeft(), node));
	}

	public void computeKnowledgeBlocks() {
		for (Pair<String, String> event : _eventsSignature) {
			EventKnowledge.EventType eventType = EventKnowledge.getKnowledge(event.getKey());

			switch (eventType) {
			case DEPOSIT:
				_emittingBlocksSignature.add(event);
				break;
			case WITHDRAWAL:
				_informationBlocksSignature.add(event);
				break;
			default:
			case UNKNOWN:
				// We don't know how to classify its so we handle this event as
				// both
				_emittingBlocksSignature.add(event);
				_informationBlocksSignature.add(event);
				break;
			}
		}

		for (Statement node : _cfg.getNodes()) {
			if (node instanceof Push) {
				// Emitting blocks
				for (Pair<String, String> signature : _emittingBlocksSignature)
					if (node.toString().contains(signature.getRight()))
						_emittingBlocksSignatureEntrypoints.add(Pair.of(signature.getLeft(), node));
				// Information blocks
				for (Pair<String, String> signature : _informationBlocksSignature)
					if (node.toString().contains(signature.getRight()))
						_informationBlocksSignatureEntrypoints.add(Pair.of(signature.getLeft(), node));
			}
		}
	}

	@Override
	public String toString() {
		StringBuilder sb = new StringBuilder();
		String indent = "  ";

		sb.append("{\n")
				.append(indent).append("\"name\": \"").append(_name).append("\",\n")
				.append(indent).append("\"abiPath\": \"").append(_abiPath).append("\",\n")
				.append(indent).append("\"bytecodePath\": \"").append(_bytecodePath).append("\",\n")
				.append(indent).append("\"cfgNodeCount\": ").append(_cfg.getNodes().size()).append(",\n")
				.append(indent).append("\"cfgEdgeCount\": ").append(_cfg.getEdges().size()).append(",\n")
				.append(indent).append("\"functionsCount\": ").append(_functionsSignature.size()).append(",\n")
				.append(indent).append("\"eventsCount\": ").append(_eventsSignature.size()).append(",\n")
				.append(indent).append("\"functionEntrypointsCount\": ").append(_functionsSignatureEntrypoints.size())
				.append(",\n")
				.append(indent).append("\"eventEntrypointsCount\": ").append(_eventsSignatureEntrypoints.size())
				.append(",\n")
				.append(indent).append("\"emittingBlocksCount\": ").append(_emittingBlocksSignature.size())
				.append(",\n")
				.append(indent).append("\"informationBlocksCount\": ").append(_informationBlocksSignature.size())
				.append(",\n")
				.append(indent).append("\"emittingBlocksEntrypointsCount\": ")
				.append(_emittingBlocksSignatureEntrypoints.size()).append(",\n")
				.append(indent).append("\"informationBlocksEntrypointsCount\": ")
				.append(_informationBlocksSignatureEntrypoints.size()).append("\n")
				.append("}");

		return sb.toString();
	}
}