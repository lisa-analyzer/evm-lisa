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
	private int xCallUncheckedSuccess;
	private int delegatecallTaintAddress;
	private JSONObject json;

	/**
	 * Creates a new {@code VulnerabilitiesObject} with default values (-1) for
	 * all vulnerabilities.
	 */
	private VulnerabilitiesObject() {
		this.reentrancy = -1;
		this.timestamp = -1;
		this.txOrigin = -1;
		this.xCallUncheckedSuccess = -1;
		this.delegatecallTaintAddress = -1;
		this.json = new JSONObject();
	}

	/**
	 * Creates a new {@code VulnerabilitiesObject} with specified values.
	 *
	 * @param reentrancy the reentrancy vulnerability score
	 * @param timestamp  the timestamp dependency vulnerability score
	 * @param txOrigin   the tx.origin vulnerability score
	 * @param xCallUncheckedSuccess the xcalluncheckedsuccess vulnerability score
	 * @param delegatecallTaintAddress thedelegatecalltaintaddress vulnerability
	 * @param json       the JSON representation of the object
	 */
	private VulnerabilitiesObject(int reentrancy, int timestamp, int txOrigin, int xCallUncheckedSuccess, int delegatecallTaintAddress,  JSONObject json) {
		this.reentrancy = reentrancy;
		this.timestamp = timestamp;
		this.txOrigin = txOrigin;
		this.xCallUncheckedSuccess = xCallUncheckedSuccess;
		this.delegatecallTaintAddress = delegatecallTaintAddress;
		this.json = json;

		if (reentrancy != -1)
			this.json.put("reentrancy", this.reentrancy);
		if (timestamp != -1)
			this.json.put("timestamp_dependency", this.timestamp);
		if (txOrigin != -1)
			this.json.put("tx_origin", this.txOrigin);
		if (xCallUncheckedSuccess != -1)
			this.json.put("xcall_unchecked_success", this.xCallUncheckedSuccess);
		if (delegatecallTaintAddress != -1)
			this.json.put("delegatecall_taint_address", this.delegatecallTaintAddress);
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
	 * Returns the xcalluncheckedsuccess vulnerability score.
	 *
	 * @return the xcalluncheckedsuccess score
	 */
	public int getXCallUncheckedSuccess() {return xCallUncheckedSuccess;}

	/**
	 * Returns the delegatecalltaintaddress vulnerability score.
	 *
	 * @return the delegatecalltaintaddress score
	 */
	public int getDelegatecallTaintAddress() {return delegatecallTaintAddress;}

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
	 * Sets the xcalluncheckedsuccess vulnerability score.
	 *
	 * @param xCallUncheckedSuccess the xcalluncheckedsuccess score
	 *
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject xCallUncheckedSuccess(int xCallUncheckedSuccess) {
		this.xCallUncheckedSuccess = xCallUncheckedSuccess;
		return this;
	}

	/**
	 * Sets the delegatecalltaintaddress vulnerability score.
	 *
	 * @param delegatecallTaintAddress the delegatecalltaintaddress score
	 *
	 * @return the updated {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject delegatecallTaintAddress(int delegatecallTaintAddress) {
		this.delegatecallTaintAddress = delegatecallTaintAddress;
		return this;
	}

	/**
	 * Builds a new {@code VulnerabilitiesObject} with the specified values.
	 *
	 * @return a new {@code VulnerabilitiesObject} instance
	 */
	public VulnerabilitiesObject build() {
		return new VulnerabilitiesObject(reentrancy, timestamp, txOrigin, xCallUncheckedSuccess, delegatecallTaintAddress, json);
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
		log.info("XCallUncheckedSuccess: {}", vulnerabilities.getXCallUncheckedSuccess());
		log.info("DelegatecallTaintAddress: {}", vulnerabilities.getDelegatecallTaintAddress());
	}
}