package it.unipr.analysis;

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
	private double preciselySolvedJumpsPercent;
	private double solvedJumpsPercent;
	private long time;
	private String notes;
	private String currentThread;

	private MyLogger() {
		this.address = null;
		this.opcodes = 0;
		this.jumps = 0;
		this.preciselyResolvedJumps = 0;
		this.soundResolvedJumps = 0;
		this.definitelyUnreachableJumps = 0;
		this.maybeUnreachableJumps = 0;
		this.solvedJumpsPercent = 0;
		this.time = 0;
		this.notes = "";
		this.currentThread = null;
	}

	private MyLogger(String address, int opcodes, int jumps, int preciselyResolvedJumps, int soundResolvedJumps,
			int definitelyUnreachableJumps, int maybeUnreachableJumps, int totalResolvedJumps,
			double solvedJumpsPercent, long time, String notes) {
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
						+ definitelyUnreachableJumps)
						/ jumps);
			this.preciselySolvedJumpsPercent = ((double) (preciselyResolvedJumps) / jumps);
		} else {
			if (solvedJumpsPercent == 0)
				this.solvedJumpsPercent = -1;
			this.preciselySolvedJumpsPercent = -1;
		}
		this.totalResolvedJumps = preciselyResolvedJumps + soundResolvedJumps;
		this.notes = notes;
		this.time = time;
		this.currentThread = Thread.currentThread().getName();
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

	public MyLogger solvedJumpsPercent(double solvedJumpsPercent) {
		this.solvedJumpsPercent = solvedJumpsPercent;
		return this;
	}

	public MyLogger time(long time) {
		this.time = time;
		return this;
	}

	public MyLogger notes(String notes) {
		this.notes = notes;
		return this;
	}

	public MyLogger build() {
		return new MyLogger(address, opcodes, jumps, preciselyResolvedJumps, soundResolvedJumps,
				definitelyUnreachableJumps, maybeUnreachableJumps, totalResolvedJumps, solvedJumpsPercent, time, notes);
	}

	public int jumpSize() {
		return jumps;
	}

	@Override
	public String toString() {
		return address + divider +
				opcodes + divider +
				jumps + divider +
				preciselyResolvedJumps + divider +
				soundResolvedJumps + divider +
				definitelyUnreachableJumps + divider +
				maybeUnreachableJumps + divider +
				totalResolvedJumps + divider +
				preciselySolvedJumpsPercent + divider +
				solvedJumpsPercent + divider +
				time + divider +
				currentThread + divider +
				notes + " \n";
	}
}
