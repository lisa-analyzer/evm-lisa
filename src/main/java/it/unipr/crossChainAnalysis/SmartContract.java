package it.unipr.crossChainAnalysis;

import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.push.Push;
import it.unipr.frontend.EVMFeatures;
import it.unipr.frontend.EVMTypeSystem;
import it.unipr.utils.ABIManager;
import it.unipr.utils.LiSAConfigurationManager;
import it.unipr.utils.MyCache;
import it.unive.lisa.LiSA;
import it.unive.lisa.conf.LiSAConfiguration;
import it.unive.lisa.program.Program;
import it.unive.lisa.program.cfg.statement.Statement;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.Set;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class SmartContract {
	private static final Logger log = LogManager.getLogger(SmartContract.class);

	private final Path _abiPath;
	private final Path _bytecodePath;
	private final String _name;
	private EVMCFG _cfg;

	private final Set<Signature> _functionsSignature;
	private final Set<Signature> _eventsSignature;

	private final Set<Signature> _emittingBlocksSignature;
	private final Set<Signature> _informationBlocksSignature;

	public SmartContract(String name, Path abiPath, Path bytecodePath) {
		this._name = name;
		this._abiPath = abiPath;
		this._bytecodePath = bytecodePath;
		this._cfg = null;

		this._functionsSignature = ABIManager.parseFunctionsFromABI(abiPath);
		this._eventsSignature = ABIManager.parseEventsFromABI(abiPath);

		this._emittingBlocksSignature = new HashSet<>();
		this._informationBlocksSignature = new HashSet<>();
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

	public Set<Signature> getFunctionsSignature() {
		return this._functionsSignature;
	}

	public Set<Signature> getEventsSignature() {
		return this._eventsSignature;
	}

	public Set<Signature> getEmittingBlocksSignature() {
		return this._emittingBlocksSignature;
	}

	public Set<Signature> getInformationBlocksSignature() {
		return this._informationBlocksSignature;
	}

	public void setCFG(EVMCFG cfg) {
		this._cfg = cfg;
	}

	/**
	 * This method iterates over all known entry points in the CFG and searches
	 * for corresponding function selectors in the bytecode. The results are
	 * stored in `_functionsSignatureEntryPoints`, which maps function
	 * signatures to their corresponding statement nodes.
	 */
	public void computeFunctionsSignatureEntryPoints() {
		for (Statement node : _cfg.getNodes())
			if (node instanceof Push)
				for (Signature signature : _functionsSignature)
					if (node.toString().contains(signature.getSelector()))
						signature.addEntryPoint(node);
	}

	public void computeFunctionsSignatureExitPoints() {
		// TODO implement
	}

	/**
	 * This method iterates over all known entry points in the CFG and searches
	 * for corresponding event selectors in the bytecode. The results are stored
	 * in `_eventsSignatureEntryPoints`, which maps function signatures to their
	 * corresponding statement nodes.
	 */
	public void computeEventsSignatureEntryPoints() {
		for (Statement node : _cfg.getNodes())
			if (node instanceof Push)
				for (Signature signature : _eventsSignature)
					if (node.toString().contains(signature.getSelector()))
						signature.addEntryPoint(node);
	}

	/**
	 * Categorizes event signatures into emitting or information blocks based on
	 * their type.
	 */
	public void computeKnowledgeBlocks() {
		for (Signature event : _eventsSignature) {
			EventKnowledge.EventType eventType = EventKnowledge.getKnowledge(event.getName());

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
	}

	/**
	 * Computes and registers event exit points for this smart contract. This
	 * method sets up a LiSA analysis environment and runs the
	 * {@code EventsExitPointsComputer} to identify statements where events
	 * exit.
	 */
	public void computeEventsExitPoints() {
		// Setup configuration
		Program program = new Program(new EVMFeatures(), new EVMTypeSystem());
		program.addCodeMember(this._cfg);
		LiSAConfiguration conf = LiSAConfigurationManager.createConfiguration(this);
		LiSA lisa = new LiSA(conf);

		EventsExitPointsComputer checker = new EventsExitPointsComputer();
		conf.semanticChecks.add(checker);
		lisa.run(program);
	}

	/**
	 * Prints the detected vulnerabilities for this smart contract.
	 */
	public void printVulnerabilities() {
		if (this._cfg == null)
			return;

		int key = this._cfg.hashCode();

		if (MyCache.getInstance().getReentrancyWarnings(key) > 0)
			log.warn("{} reentrancy warning",
					MyCache.getInstance().getReentrancyWarnings(key));

		if (MyCache.getInstance().getEventOrderWarnings(key) > 0)
			log.warn("{} event order warning",
					MyCache.getInstance().getEventOrderWarnings(key));

		if (MyCache.getInstance().getUncheckedStateUpdateWarnings(key) > 0)
			log.warn("{} unchecked state update warning",
					MyCache.getInstance().getUncheckedStateUpdateWarnings(key));

		if (MyCache.getInstance().getUncheckedExternalInfluenceWarnings(key) > 0)
			log.warn("{} unchecked external influence warning",
					MyCache.getInstance().getUncheckedExternalInfluenceWarnings(key));

		if (MyCache.getInstance().getTimestampDependencyWarnings(key) > 0)
			log.warn("{} timestamp dependency warning",
					MyCache.getInstance().getTimestampDependencyWarnings(key));

		if (MyCache.getInstance().getTxOriginWarnings(key) > 0)
			log.warn("{} tx. origin warning",
					MyCache.getInstance().getTxOriginWarnings(key));
	}

	@Override
	public String toString() {
		StringBuilder sb = new StringBuilder();
		String indent = "  ";

		sb.append("{\n");
		sb.append(indent).append("\"name\": \"").append(_name).append("\",\n");
		sb.append(indent).append("\"abiPath\": \"").append(_abiPath).append("\",\n");
		sb.append(indent).append("\"bytecodePath\": \"").append(_bytecodePath).append("\",\n");

		sb.append(indent).append("\"cfg\": {\n");
		sb.append(indent).append(indent).append("\"nodes\": ").append(_cfg.getNodes().size()).append(",\n");
		sb.append(indent).append(indent).append("\"edges\": ").append(_cfg.getEdges().size()).append("\n");
		sb.append(indent).append("},\n");

		sb.append(indent).append("\"functions\": ").append(formatSignatureSet(_functionsSignature)).append(",\n");
		sb.append(indent).append("\"events\": ").append(formatSignatureSet(_eventsSignature)).append(",\n");
		sb.append(indent).append("\"emittingBlocks\": ").append(formatSignatureSet(_emittingBlocksSignature))
				.append(",\n");
		sb.append(indent).append("\"informationBlocks\": ").append(formatSignatureSet(_informationBlocksSignature))
				.append("\n");

		sb.append("}");
		return sb.toString();
	}

	/**
	 * Formats a set of Signature objects as a JSON-like array.
	 */
	private String formatSignatureSet(Set<Signature> signatures) {
		StringBuilder sb = new StringBuilder();
		String indent = "  ";

		sb.append("[");
		if (!signatures.isEmpty()) {
			sb.append("\n");
			int count = 0;
			for (Signature sig : signatures) {
				sb.append(indent).append(indent).append(sig.toString());
				if (++count < signatures.size()) {
					sb.append(",");
				}
				sb.append("\n");
			}
			sb.append(indent);
		}
		sb.append("]");
		return sb.toString();
	}
}