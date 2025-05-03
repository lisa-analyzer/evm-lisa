package it.unipr.utils;

import it.unipr.cfg.EVMCFG;
import org.json.JSONObject;

/**
 * The {@code VulnerabilitiesObject} class represents a data model to hold
 * various security vulnerability scores within a system. It provides methods to
 * manage and build these scores, including utilities for JSON representation.
 */
public class VulnerabilitiesObject {
	private int reentrancy;

	private int randomness;
	private int possibleRandomness;

	private int txOrigin;
	private int possibleTxOrigin;

	private JSONObject json;

	private VulnerabilitiesObject() {
		this.reentrancy = 0;

		this.randomness = 0;
		this.possibleRandomness = 0;

		this.txOrigin = 0;
		this.possibleTxOrigin = 0;

		this.json = new JSONObject();
	}

	private VulnerabilitiesObject(int reentrancy,
			int randomness, int possibleRandomness,
			int txOrigin, int possibleTxOrigin,
			JSONObject json) {

		this.reentrancy = reentrancy;

		this.randomness = randomness;
		this.possibleRandomness = possibleRandomness;

		this.txOrigin = txOrigin;
		this.possibleTxOrigin = possibleTxOrigin;

		this.json = json;

		this.json.put("reentrancy", this.reentrancy);
		this.json.put("randomness_dependency_definite", this.randomness);
		this.json.put("randomness_dependency_possible", this.possibleRandomness);
		this.json.put("tx_origin", this.txOrigin);
		this.json.put("tx_origin_possible", this.possibleTxOrigin);
	}

	/**
	 * Creates a new {@code VulnerabilitiesObject} with default values.
	 *
	 * @return a new instance of {@code VulnerabilitiesObject}
	 */
	public static VulnerabilitiesObject newVulnerabilitiesObject() {
		return new VulnerabilitiesObject();
	}

	/**
	 * Sets the reentrancy vulnerability score.
	 *
	 * @param reentrancy the reentrancy score
	 * 
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject reentrancy(int reentrancy) {
		this.reentrancy = reentrancy;
		return this;
	}

	/**
	 * Sets the randomness dependency vulnerability score.
	 *
	 * @param randomness the randomness dependency score
	 * 
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject randomness(int randomness) {
		this.randomness = randomness;
		return this;
	}

	/**
	 * Sets the possible randomness dependency vulnerability score.
	 *
	 * @param possibleRandomness the possible randomness dependency score
	 * 
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject possibleRandomness(int possibleRandomness) {
		this.possibleRandomness = possibleRandomness;
		return this;
	}

	/**
	 * Sets the tx. origin vulnerability score.
	 *
	 * @param txOrigin the tx. origin score
	 * 
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject txOrigin(int txOrigin) {
		this.txOrigin = txOrigin;
		return this;
	}

	/**
	 * Sets the possible tx. origin vulnerability score.
	 *
	 * @param possibleTxOrigin the tx. origin score
	 *
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject possibleTxOrigin(int possibleTxOrigin) {
		this.possibleTxOrigin = possibleTxOrigin;
		return this;
	}

	/**
	 * Builds a {@link VulnerabilitiesObject} from the given EVM control-flow
	 * graph (CFG). This method retrieves various vulnerability warnings from
	 * the cache based on the CFG's hash code and compiles them into a
	 * {@link VulnerabilitiesObject}.
	 *
	 * @param cfg the EVM control-flow graph from which to extract vulnerability
	 *                data
	 * 
	 * @return a {@link VulnerabilitiesObject} containing detected
	 *             vulnerabilities
	 */
	public static VulnerabilitiesObject buildFromCFG(EVMCFG cfg) {
		return VulnerabilitiesObject.newVulnerabilitiesObject()
				.reentrancy(
						MyCache.getInstance().getReentrancyWarnings(cfg.hashCode()))
				.txOrigin(MyCache.getInstance().getTxOriginWarnings(cfg.hashCode()))
				.possibleTxOrigin(MyCache.getInstance()
						.getPossibleTxOriginWarnings(cfg.hashCode()))
				.randomness(MyCache.getInstance()
						.getRandomnessDependencyWarnings(cfg.hashCode()))
				.possibleRandomness(MyCache.getInstance()
						.getPossibleRandomnessDependencyWarnings(cfg.hashCode()))
				.build();
	}

	/**
	 * Builds a new {@code VulnerabilitiesObject} with the specified values.
	 *
	 * @return a new {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject build() {
		return new VulnerabilitiesObject(reentrancy,
				randomness, possibleRandomness,
				txOrigin, possibleTxOrigin,
				json);
	}

	/**
	 * Returns the JSON representation of this object.
	 *
	 * @return a {@code JSONObject} representing this object
	 */
	public JSONObject toJson() {
		return json;
	}

	/**
	 * Returns a formatted string representation of this object.
	 *
	 * @return a formatted JSON string
	 */
	@Override
	public String toString() {
		return toJson().toString(4);
	}

}