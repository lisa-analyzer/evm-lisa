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

	private int uncheckedExternalInfluence;
	private int possibleUncheckedExternalInfluence;

	private int eventOrder;
	private int possibleEventOrder;

	private int uncheckedExternalCall;
	private int possibleUncheckedExternalCall;

	private int semanticIntegrityViolation;
	private int possibleSemanticIntegrityViolation;

	private int timeSynchronization;
	private int possibleTimeSynchronization;

	private int missingEventNotification;

	private JSONObject json;

	private VulnerabilitiesObject() {
		this.reentrancy = 0;

		this.randomness = 0;
		this.possibleRandomness = 0;

		this.txOrigin = 0;
		this.possibleTxOrigin = 0;

		this.uncheckedExternalInfluence = 0;
		this.possibleUncheckedExternalInfluence = 0;

		this.eventOrder = 0;
		this.possibleEventOrder = 0;

		this.uncheckedExternalCall = 0;
		this.possibleUncheckedExternalCall = 0;

		this.semanticIntegrityViolation = 0;
		this.possibleSemanticIntegrityViolation = 0;

		this.timeSynchronization = 0;
		this.possibleTimeSynchronization = 0;

		this.missingEventNotification = 0;

		this.json = new JSONObject();
	}

	private VulnerabilitiesObject(int reentrancy,
			int randomness, int possibleRandomness,
			int txOrigin, int possibleTxOrigin,
			int uncheckedExternalInfluence, int possibleUncheckedExternalInfluence,
			int eventOrder, int possibleEventOrder,
			int uncheckedExternalCall, int possibleUncheckedExternalCall,
			int semanticIntegrityViolation, int possibleSemanticIntegrityViolation,
			int timeSynchronization, int possibleTimeSynchronization,
			int missingEventNotification,
			JSONObject json) {

		this.reentrancy = reentrancy;

		this.randomness = randomness;
		this.possibleRandomness = possibleRandomness;

		this.txOrigin = txOrigin;
		this.possibleTxOrigin = possibleTxOrigin;

		this.uncheckedExternalInfluence = uncheckedExternalInfluence;
		this.possibleUncheckedExternalInfluence = possibleUncheckedExternalInfluence;

		this.eventOrder = eventOrder;
		this.possibleEventOrder = possibleEventOrder;

		this.uncheckedExternalCall = uncheckedExternalCall;
		this.possibleUncheckedExternalCall = possibleUncheckedExternalCall;

		this.semanticIntegrityViolation = semanticIntegrityViolation;
		this.possibleSemanticIntegrityViolation = possibleSemanticIntegrityViolation;

		this.timeSynchronization = timeSynchronization;
		this.possibleTimeSynchronization = possibleTimeSynchronization;

		this.missingEventNotification = missingEventNotification;

		this.json = json;

		this.json.put("reentrancy", this.reentrancy);
		this.json.put("randomness_dependency_definite", this.randomness);
		this.json.put("randomness_dependency_possible", this.possibleRandomness);
		this.json.put("tx_origin", this.txOrigin);
		this.json.put("tx_origin_possible", this.possibleTxOrigin);
		this.json.put("unchecked_external_influence_definite", this.uncheckedExternalInfluence);
		this.json.put("unchecked_external_influence_possible", this.possibleUncheckedExternalInfluence);
		this.json.put("semantic_integrity_violation_definite", this.semanticIntegrityViolation);
		this.json.put("semantic_integrity_violation_possible", this.possibleSemanticIntegrityViolation);
		this.json.put("event_order_definite", this.eventOrder);
		this.json.put("event_order_possible", this.possibleEventOrder);
		this.json.put("unchecked_external_call_definite", this.uncheckedExternalCall);
		this.json.put("unchecked_external_call_possible", this.possibleUncheckedExternalCall);
		this.json.put("time_synchronization_definite", this.timeSynchronization);
		this.json.put("time_synchronization_possible", this.possibleTimeSynchronization);
		this.json.put("missing_event_notification", this.missingEventNotification);
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
	 * Sets the possible unchecked external influence vulnerability score.
	 *
	 * @param possibleUncheckedExternalInfluence the unchecked external
	 *                                               influence score
	 *
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject possibleUncheckedExternalInfluence(int possibleUncheckedExternalInfluence) {
		this.possibleUncheckedExternalInfluence = possibleUncheckedExternalInfluence;
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
	 * Sets the possible event order vulnerability score.
	 *
	 * @param possibleEventOrder the possible event order score
	 *
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject possibleEventOrder(int possibleEventOrder) {
		this.possibleEventOrder = possibleEventOrder;
		return this;
	}

	/**
	 * Sets the unchecked external call vulnerability score.
	 *
	 * @param uncheckedExternalCall the unchecked external call score
	 * 
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject uncheckedExternalCall(int uncheckedExternalCall) {
		this.uncheckedExternalCall = uncheckedExternalCall;
		return this;
	}

	/**
	 * Sets the possible unchecked external call vulnerability score.
	 *
	 * @param possibleUncheckedExternalCall the unchecked external call score
	 *
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject possibleUncheckedExternalCall(int possibleUncheckedExternalCall) {
		this.possibleUncheckedExternalCall = possibleUncheckedExternalCall;
		return this;
	}

	/**
	 * Sets the semantic integrity violation vulnerability score.
	 *
	 * @param semanticIntegrityViolation the semantic integrity violation score
	 *
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject semanticIntegrityViolation(int semanticIntegrityViolation) {
		this.semanticIntegrityViolation = semanticIntegrityViolation;
		return this;
	}

	/**
	 * Sets the possible semantic integrity violation vulnerability score.
	 *
	 * @param possibleSemanticIntegrityViolation the semantic integrity
	 *                                               violation score
	 *
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject possibleSemanticIntegrityViolation(int possibleSemanticIntegrityViolation) {
		this.possibleSemanticIntegrityViolation = possibleSemanticIntegrityViolation;
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

	/**
	 * Sets the possible time synchronization vulnerability score.
	 *
	 * @param possibleTimeSynchronization the time synchronization score
	 *
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject possibleTimeSynchronization(int possibleTimeSynchronization) {
		this.possibleTimeSynchronization = possibleTimeSynchronization;
		return this;
	}

	/**
	 * Sets the missing event notification vulnerability score.
	 *
	 * @param missingEventNotification the missing event notification score
	 *
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject missingEventNotification(int missingEventNotification) {
		this.missingEventNotification = missingEventNotification;
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
				.eventOrder(MyCache.getInstance()
						.getEventOrderWarnings(cfg.hashCode()))
				.possibleEventOrder(MyCache.getInstance()
						.getPossibleEventOrderWarnings(cfg.hashCode()))
				.uncheckedExternalInfluence(MyCache.getInstance()
						.getUncheckedExternalInfluenceWarnings(cfg.hashCode()))
				.possibleUncheckedExternalInfluence(MyCache.getInstance()
						.getPossibleUncheckedExternalInfluenceWarnings(cfg.hashCode()))
				.uncheckedExternalCall(MyCache.getInstance()
						.getUncheckedExternalCallWarnings(cfg.hashCode()))
				.semanticIntegrityViolation(MyCache.getInstance()
						.getSemanticIntegrityViolationWarnings(cfg.hashCode()))
				.possibleSemanticIntegrityViolation(MyCache.getInstance()
						.getPossibleSemanticIntegrityViolationWarnings(cfg.hashCode()))
				.possibleUncheckedExternalCall(MyCache.getInstance()
						.getPossibleUncheckedExternalCallWarnings(cfg.hashCode()))
				.missingEventNotification(MyCache.getInstance()
						.getMissingEventNotificationWarnings(cfg.hashCode()))
				.timeSynchronization(MyCache.getInstance()
						.getTimeSynchronizationWarnings(cfg.hashCode()))
				.possibleTimeSynchronization(MyCache.getInstance()
						.getPossibleTimeSynchronizationWarnings(cfg.hashCode()))
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
				uncheckedExternalInfluence, possibleUncheckedExternalInfluence,
				eventOrder, possibleEventOrder,
				uncheckedExternalCall, possibleUncheckedExternalCall,
				semanticIntegrityViolation, possibleSemanticIntegrityViolation,
				timeSynchronization, possibleTimeSynchronization,
				missingEventNotification,
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