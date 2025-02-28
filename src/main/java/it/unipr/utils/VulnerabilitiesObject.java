package it.unipr.utils;

import org.json.JSONObject;

public class VulnerabilitiesObject {
	private int reentrancy;
	private int timestamp;
	private int txOrigin;
	private JSONObject json;

	private VulnerabilitiesObject() {
		this.reentrancy = -1;
		this.timestamp = -1;
		this.txOrigin = -1;
		this.json = new JSONObject();
	}

	private VulnerabilitiesObject(int totalOpcodes, int totalJumps, int resolvedJumps, JSONObject json) {
		this.reentrancy = totalOpcodes;
		this.timestamp = totalJumps;
		this.txOrigin = resolvedJumps;
		this.json = json;

		if (reentrancy != -1)
			this.json.put("reentrancy", this.reentrancy);
		if (timestamp != -1)
			this.json.put("timestamp_dependency", this.timestamp);
		if (txOrigin != -1)
			this.json.put("tx_origin", this.txOrigin);
	}

	public int getReentrancy() {
		return reentrancy;
	}

	public int getTimestamp() {
		return timestamp;
	}

	public int getTxOrigin() {
		return txOrigin;
	}

	public static VulnerabilitiesObject newVulnerabilitiesObject() {
		return new VulnerabilitiesObject();
	}

	public VulnerabilitiesObject reentrancy(int reentrancy) {
		this.reentrancy = reentrancy;
		return this;
	}

	public VulnerabilitiesObject timestamp(int timestamp) {
		this.timestamp = timestamp;
		return this;
	}

	public VulnerabilitiesObject txOrigin(int txOrigin) {
		this.txOrigin = txOrigin;
		return this;
	}

	public VulnerabilitiesObject build() {
		return new VulnerabilitiesObject(reentrancy, timestamp, txOrigin, json);
	}

	public JSONObject toJson() {
		return json;
	}

	@Override
	public String toString() {
		return toJson().toString(4);
	}
}