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
	private int preciselyResolvedJumps;
	private int soundResolvedJumps;
	private int definitelyUnreachableJumps;
	private int maybeUnreachableJumps;
	private int totalResolvedJumps;
	private double solvedJumpsPercent;
	private int unsoundJumps;
	private int maybeUnsoundJumps;
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
		this.preciselyResolvedJumps = 0;
		this.soundResolvedJumps = 0;
		this.definitelyUnreachableJumps = 0;
		this.maybeUnreachableJumps = 0;
		this.solvedJumpsPercent = 0;
		this.unsoundJumps = 0;
		this.maybeUnsoundJumps = 0;
		this.time = 0;
		this.timeLostToGetStorage = 0;
		this.actualTime = 0;
		this.notes = "";
		this.currentThread = null;
		this.json = new JSONObject();
	}

	private MyLogger(String address, int opcodes, int jumps, int preciselyResolvedJumps, int soundResolvedJumps,
			int definitelyUnreachableJumps, int maybeUnreachableJumps, int totalResolvedJumps,
			int unsoundJumps, int maybeUnsoundJumps, double solvedJumpsPercent,
			long time, long timeLostToGetStorage,
			JSONObject json, String notes) {
		this.address = address;
		this.opcodes = opcodes;
		this.jumps = jumps;
		this.preciselyResolvedJumps = preciselyResolvedJumps;
		this.soundResolvedJumps = soundResolvedJumps;
		this.definitelyUnreachableJumps = definitelyUnreachableJumps;
		this.maybeUnreachableJumps = maybeUnreachableJumps;
		if (jumps != 0) {
			if (solvedJumpsPercent == 0)
				this.solvedJumpsPercent = ((double) (preciselyResolvedJumps + soundResolvedJumps
						+ definitelyUnreachableJumps + maybeUnreachableJumps)
						/ (jumps));
		} else {
			if (solvedJumpsPercent == 0)
				this.solvedJumpsPercent = -1;
		}
		this.totalResolvedJumps = preciselyResolvedJumps + soundResolvedJumps + definitelyUnreachableJumps
				+ maybeUnreachableJumps;
		this.unsoundJumps = unsoundJumps;
		this.maybeUnsoundJumps = maybeUnsoundJumps;
		this.notes = notes;
		this.time = time;
		this.timeLostToGetStorage = timeLostToGetStorage;
		this.actualTime = time - timeLostToGetStorage;
		this.currentThread = Thread.currentThread().getName();

		this.json = json;
		this.json.put("address", this.address);
		this.json.put("opcodes", this.opcodes);
		this.json.put("jumps", this.jumps);
		this.json.put("resolved_jumps", this.totalResolvedJumps);
		this.json.put("definitely_unreachable_jumps", this.definitelyUnreachableJumps);
		this.json.put("maybe_unreachable_jumps", this.maybeUnreachableJumps);
		this.json.put("unsound_jumps", this.unsoundJumps);
		this.json.put("maybe_unsound_jumps", this.maybeUnsoundJumps);
		this.json.put("solved_jumps_percent", this.solvedJumpsPercent);
		this.json.put("time", this.time);
		this.json.put("time_lost_to_get_storage", this.timeLostToGetStorage);
		this.json.put("actual_time", this.actualTime);
		this.json.put("current_thread", this.currentThread);
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

	public MyLogger preciselyResolvedJumps(int preciselyResolvedJumps) {
		this.preciselyResolvedJumps = preciselyResolvedJumps;
		return this;
	}

	public MyLogger soundResolvedJumps(int soundResolvedJumps) {
		this.soundResolvedJumps = soundResolvedJumps;
		return this;
	}

	public MyLogger maybeUnreachableJumps(int maybeUnreachableJumps) {
		this.maybeUnreachableJumps = maybeUnreachableJumps;
		return this;
	}

	public MyLogger definitelyUnreachableJumps(int definitelyUnreachableJumps) {
		this.definitelyUnreachableJumps = definitelyUnreachableJumps;
		return this;
	}

	public MyLogger unsoundJumps(int unsoundJumps) {
		this.unsoundJumps = unsoundJumps;
		return this;
	}

	public MyLogger maybeUnsoundJumps(int maybeUnsoundJumps) {
		this.maybeUnsoundJumps = maybeUnsoundJumps;
		return this;
	}

	public MyLogger solvedJumpsPercent(double solvedJumpsPercent) {
		this.solvedJumpsPercent = solvedJumpsPercent;
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
		return new MyLogger(address, opcodes, jumps, preciselyResolvedJumps, soundResolvedJumps,
				definitelyUnreachableJumps, maybeUnreachableJumps, totalResolvedJumps,
				unsoundJumps, maybeUnsoundJumps, solvedJumpsPercent,
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
				(soundResolvedJumps + preciselyResolvedJumps) + divider +
				definitelyUnreachableJumps + divider +
				maybeUnreachableJumps + divider +
				totalResolvedJumps + divider +
				unsoundJumps + divider +
				maybeUnsoundJumps + divider +
				solvedJumpsPercent + divider +
				time + divider +
				timeLostToGetStorage + divider +
				actualTime + divider +
				json.toString() + "\n";
	}
}
