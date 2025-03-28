package it.unipr.utils;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONObject;

/**
 * Represents an object that stores information about potential smart contract
 * vulnerabilities, including reentrancy, timestamp dependency, and tx. origin
 * usage.
 */
public class VulnerabilitiesObject {
	private static final Logger log = LogManager.getLogger(VulnerabilitiesObject.class);

	private int reentrancy;
	private int timestamp;
	private int txOrigin;
	private JSONObject json;

	/**
	 * Creates a new {@code VulnerabilitiesObject} with default values (-1) for
	 * all vulnerabilities.
	 */
	private VulnerabilitiesObject() {
		this.reentrancy = -1;
		this.timestamp = -1;
		this.txOrigin = -1;
		this.json = new JSONObject();
	}

	/**
	 * Creates a new {@code VulnerabilitiesObject} with specified values.
	 *
	 * @param reentrancy the reentrancy vulnerability score
	 * @param timestamp  the timestamp dependency vulnerability score
	 * @param txOrigin   the tx.origin vulnerability score
	 * @param json       the JSON representation of the object
	 */
	private VulnerabilitiesObject(int reentrancy, int timestamp, int txOrigin, JSONObject json) {
		this.reentrancy = reentrancy;
		this.timestamp = timestamp;
		this.txOrigin = txOrigin;
		this.json = json;

		if (reentrancy != -1)
			this.json.put("reentrancy", this.reentrancy);
		if (timestamp != -1)
			this.json.put("timestamp_dependency", this.timestamp);
		if (txOrigin != -1)
			this.json.put("tx_origin", this.txOrigin);
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
	 * Returns the timestamp dependency vulnerability score.
	 *
	 * @return the timestamp dependency score
	 */
	public int getTimestamp() {
		return timestamp;
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
	 * Sets the timestamp dependency vulnerability score.
	 *
	 * @param timestamp the timestamp dependency score
	 * 
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject timestamp(int timestamp) {
		this.timestamp = timestamp;
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
	 * Builds a new {@code VulnerabilitiesObject} with the specified values.
	 *
	 * @return a new {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject build() {
		return new VulnerabilitiesObject(reentrancy, timestamp, txOrigin, json);
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

	/**
	 * Logs the vulnerability scores of the given {@code VulnerabilitiesObject}.
	 *
	 * @param vulnerabilities the vulnerabilities object to log
	 */
	public static void printVulnerabilities(VulnerabilitiesObject vulnerabilities) {
		log.info("Reentrancy: {}", vulnerabilities.getReentrancy());
		log.info("Timestamp dependency: {}", vulnerabilities.getTimestamp());
		log.info("Tx.Origin: {}", vulnerabilities.getTxOrigin());
	}
}