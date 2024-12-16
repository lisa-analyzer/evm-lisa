package it.unipr.analysis;

import org.json.JSONObject;

/**
 * Represents a logger object for recording statistical data related to Ethereum
 * smart contracts.
 */
public class MyLogger {
	private static String divider = ", ";
	private String address;
	private int opcodes;
	private int jumps;
	private int resolvedJumps;
	private int unknownJumps;
	private int unreachableJumps;
	private int erroneousJumps;
	private int edges;
	private long time;
	private long timeLostToGetStorage;
	private long actualTime;
	private String notes;
	private String currentThread;
	private JSONObject json;

	private MyLogger() {
		this.address = null;
		this.opcodes = 0;
		this.jumps = 0;
		this.resolvedJumps = 0;
		this.unknownJumps = 0;
		this.unreachableJumps = 0;
		this.erroneousJumps = 0;
		this.edges = 0;
		this.time = 0;
		this.timeLostToGetStorage = 0;
		this.actualTime = 0;
		this.notes = "";
		this.currentThread = null;
		this.json = new JSONObject();
	}

	private MyLogger(String address, int opcodes, int jumps, int resolvedJumps, int unknownJumps,
			int unreachableJumps, int erroneousJumps, int edges,
			long time, long timeLostToGetStorage,
			JSONObject json, String notes) {
		this.address = address;
		this.opcodes = opcodes;
		this.jumps = jumps;
		this.resolvedJumps = resolvedJumps;
		this.unknownJumps = unknownJumps;
		this.unreachableJumps = unreachableJumps;
		this.erroneousJumps = erroneousJumps;
		this.edges = edges;
		this.notes = notes;
		this.time = time;
		this.timeLostToGetStorage = timeLostToGetStorage;
		this.actualTime = time - timeLostToGetStorage;
		this.currentThread = Thread.currentThread().getName();

		this.json = json;
		this.json.put("address", this.address);
		this.json.put("opcodes", this.opcodes);
		this.json.put("jumps", this.jumps);
		this.json.put("resolved-jumps", this.resolvedJumps);
		this.json.put("unknown-jumps", this.unknownJumps);
		this.json.put("unreachable-jumps", this.unreachableJumps);
		this.json.put("erroneous-jumps", this.erroneousJumps);
		this.json.put("edges", this.edges);
		this.json.put("time", this.time);
		this.json.put("time-lost-to-get-storage", this.timeLostToGetStorage);
		this.json.put("actual-time", this.actualTime);
		this.json.put("current-thread", this.currentThread);
	}

	public static MyLogger newLogger() {
		return new MyLogger();
	}

	public MyLogger address(String address) {
		this.address = address;
		return this;
	}

	public MyLogger opcodes(int opcodes) {
		this.opcodes = opcodes;
		return this;
	}

	public MyLogger jumps(int jumps) {
		this.jumps = jumps;
		return this;
	}

	public MyLogger resolvedJumps(int resolvedJumps) {
		this.resolvedJumps = resolvedJumps;
		return this;
	}

	public MyLogger unknownJumps(int unknownJumps) {
		this.unknownJumps = unknownJumps;
		return this;
	}

	public MyLogger erroneousJumps(int erroneousJumps) {
		this.erroneousJumps = erroneousJumps;
		return this;
	}

	public MyLogger unreachableJumps(int unreachableJumps) {
		this.unreachableJumps = unreachableJumps;
		return this;
	}
	
	public MyLogger edges(int edges) {
		this.edges = edges;
		return this;
	}

	public MyLogger time(long time) {
		this.time = time;
		return this;
	}

	public MyLogger timeLostToGetStorage(long timeLostToGetStorage) {
		this.timeLostToGetStorage = timeLostToGetStorage;
		return this;
	}

	public MyLogger notes(String notes) {
		this.notes = notes;
		return this;
	}

	public MyLogger buildJson(JSONObject json) {
		this.json = json;
		return this;
	}

	public MyLogger build() {
		return new MyLogger(address, opcodes, jumps, resolvedJumps, unknownJumps,
				unreachableJumps, erroneousJumps, edges,
				time, timeLostToGetStorage, json, notes);
	}

	public int jumpSize() {
		return jumps;
	}

	public String getJson() {
		return json.toString(4);
	}

	@Override
	public String toString() {
		return address + divider +
				opcodes + divider +
				jumps + divider +
				resolvedJumps + divider +
				unknownJumps + divider +
				unreachableJumps + divider +
				erroneousJumps + divider +
				edges + divider +
				time + divider +
				timeLostToGetStorage + divider +
				actualTime + divider +
				notes + "\n";
	}
}
