package it.unipr.utils;

import it.unipr.cfg.EVMCFG;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONObject;

/**
 * The {@code VulnerabilitiesObject} class represents a data model to hold
 * various security vulnerability scores within a system. It provides methods to
 * manage and build these scores, including utilities for JSON representation.
 */
public class VulnerabilitiesObject {
	private static final Logger log = LogManager.getLogger(VulnerabilitiesObject.class);

	private int reentrancy;
	private int randomness;
	private int possibleRandomness;
	private int txOrigin;
	private int possibleTxOrigin;
	private int uncheckedExternalInfluence;
	private int eventOrder;
	private int uncheckedStateUpdate;
	private int timeSynchronization;
	private JSONObject json;

	private VulnerabilitiesObject() {
		this.reentrancy = 0;
		this.randomness = 0;
		this.possibleRandomness = 0;
		this.txOrigin = 0;
		this.possibleTxOrigin = 0;
		this.uncheckedExternalInfluence = 0;
		this.eventOrder = 0;
		this.uncheckedStateUpdate = 0;
		this.timeSynchronization = 0;
		this.json = new JSONObject();
	}

	private VulnerabilitiesObject(int reentrancy, int randomness, int possibleRandomness, int txOrigin,
			int possibleTxOrigin,
			int uncheckedExternalInfluence,
			int eventOrder, int uncheckedStateUpdate, int timeSynchronization, JSONObject json) {
		this.reentrancy = reentrancy;
		this.randomness = randomness;
		this.possibleRandomness = possibleRandomness;
		this.txOrigin = txOrigin;
		this.possibleTxOrigin = possibleTxOrigin;
		this.uncheckedExternalInfluence = uncheckedExternalInfluence;
		this.eventOrder = eventOrder;
		this.uncheckedStateUpdate = uncheckedStateUpdate;
		this.timeSynchronization = timeSynchronization;
		this.json = json;

		this.json.put("reentrancy", this.reentrancy);
		this.json.put("randomness_dependency_definite", this.randomness);
		this.json.put("randomness_dependency_possible", this.possibleRandomness);
		this.json.put("tx_origin", this.txOrigin);
		this.json.put("tx_origin_possible", this.possibleTxOrigin);
		this.json.put("unchecked_external_influence", this.uncheckedExternalInfluence);
		this.json.put("event_order", this.eventOrder);
		this.json.put("unchecked_state_update", this.uncheckedStateUpdate);
		this.json.put("time_synchronization", this.timeSynchronization);
	}

	/**
	 * Returns the reentrancy vulnerability score.
	 *
	 * @return the reentrancy score
	 */
	public int getReentrancy() {
		return reentrancy;
	}

	/**
	 * Returns the randomness dependency vulnerability score.
	 *
	 * @return the randomness dependency score
	 */
	public int getRandomness() {
		return randomness;
	}

	/**
	 * Returns the tx .origin vulnerability score.
	 *
	 * @return the tx. origin score
	 */
	public int getTxOrigin() {
		return txOrigin;
	}

	/**
	 * Returns the unchecked external influence vulnerability score.
	 *
	 * @return the unchecked external influence score
	 */
	public int getUncheckedExternalInfluence() {
		return uncheckedExternalInfluence;
	}

	/**
	 * Returns the event order vulnerability score.
	 *
	 * @return the event order score
	 */
	public int getEventOrder() {
		return eventOrder;
	}

	/**
	 * Returns the unchecked state update vulnerability score.
	 *
	 * @return the unchecked state update score
	 */
	public int getUncheckedStateUpdate() {
		return uncheckedStateUpdate;
	}

	/**
	 * Returns the time synchronization vulnerability score.
	 *
	 * @return the time synchronization score
	 */
	public int getTimeSynchronization() {
		return timeSynchronization;
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
	 * Sets the unchecked external influence vulnerability score.
	 *
	 * @param uncheckedExternalInfluence the unchecked external influence score
	 * 
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject uncheckedExternalInfluence(int uncheckedExternalInfluence) {
		this.uncheckedExternalInfluence = uncheckedExternalInfluence;
		return this;
	}

	/**
	 * Sets the event order vulnerability score.
	 *
	 * @param eventOrder the event order score
	 * 
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject eventOrder(int eventOrder) {
		this.eventOrder = eventOrder;
		return this;
	}

	/**
	 * Sets the unchecked state update vulnerability score.
	 *
	 * @param uncheckedStateUpdate the unchecked state update score
	 * 
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject uncheckedStateUpdate(int uncheckedStateUpdate) {
		this.uncheckedStateUpdate = uncheckedStateUpdate;
		return this;
	}

	/**
	 * Sets the time synchronization vulnerability score.
	 *
	 * @param timeSynchronization the time synchronization score
	 * 
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject timeSynchronization(int timeSynchronization) {
		this.timeSynchronization = timeSynchronization;
		return this;
	}

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
				.eventOrder(MyCache.getInstance()
						.getEventOrderWarnings(cfg.hashCode()))
				.uncheckedExternalInfluence(MyCache.getInstance()
						.getUncheckedExternalInfluenceWarnings(cfg.hashCode()))
				.uncheckedStateUpdate(MyCache.getInstance()
						.getUncheckedStateUpdateWarnings(cfg.hashCode()))
				.build();
	}

	/**
	 * Builds a new {@code VulnerabilitiesObject} with the specified values.
	 *
	 * @return a new {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject build() {
		return new VulnerabilitiesObject(reentrancy, randomness, possibleRandomness, txOrigin, possibleTxOrigin,
				uncheckedExternalInfluence, eventOrder,
				uncheckedStateUpdate, timeSynchronization, json);
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