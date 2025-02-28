package it.unipr.utils;

import java.util.Objects;
import org.json.JSONObject;

/**
 * Collects statistical data related to CFG analysis.
 */
public class StatisticsObject {
	private String address;
	private int totalOpcodes;
	private int totalJumps;
	private int resolvedJumps;
	private int definitelyUnreachableJumps;
	private int maybeUnreachableJumps;
	private int unsoundJumps;
	private int maybeUnsoundJumps;
	private JSONObject json;

	private StatisticsObject() {
		this.address = "";
		this.totalOpcodes = 0;
		this.totalJumps = 0;
		this.resolvedJumps = 0;
		this.definitelyUnreachableJumps = 0;
		this.maybeUnreachableJumps = 0;
		this.unsoundJumps = 0;
		this.maybeUnsoundJumps = 0;
		this.json = new JSONObject();
	}

	private StatisticsObject(String address, int totalOpcodes, int totalJumps, int resolvedJumps,
			int definitelyUnreachableJumps,
			int maybeUnreachableJumps, int unsoundJumps, int maybeUnsoundJumps, JSONObject json) {
		this.address = address;
		this.totalOpcodes = totalOpcodes;
		this.totalJumps = totalJumps;
		this.resolvedJumps = resolvedJumps;
		this.definitelyUnreachableJumps = definitelyUnreachableJumps;
		this.maybeUnreachableJumps = maybeUnreachableJumps;
		this.unsoundJumps = unsoundJumps;
		this.maybeUnsoundJumps = maybeUnsoundJumps;
		this.json = json;

		this.json.put("total_opcodes", this.totalOpcodes);
		this.json.put("total_jumps", this.totalJumps);
		this.json.put("resolved_jumps", this.resolvedJumps);
		this.json.put("definitely_unreachable_jumps", this.definitelyUnreachableJumps);
		this.json.put("maybe_unreachable_jumps", this.maybeUnreachableJumps);
		this.json.put("unsound_jumps", this.unsoundJumps);
		this.json.put("maybe_unsound_jumps", this.maybeUnsoundJumps);
	}

	public String getAddress() {
		return address;
	}

	public int getTotalOpcodes() {
		return totalOpcodes;
	}

	public int getTotalJumps() {
		return totalJumps;
	}

	public int getResolvedJumps() {
		return resolvedJumps;
	}

	public int getDefinitelyUnreachableJumps() {
		return definitelyUnreachableJumps;
	}

	public int getMaybeUnreachableJumps() {
		return maybeUnreachableJumps;
	}

	public int getUnsoundJumps() {
		return unsoundJumps;
	}

	public int getMaybeUnsoundJumps() {
		return maybeUnsoundJumps;
	}

	public static StatisticsObject newStatisticsObject() {
		return new StatisticsObject();
	}

	public StatisticsObject address(String address) {
		this.address = address;
		return this;
	}

	public StatisticsObject totalOpcodes(int totalOpcodes) {
		this.totalOpcodes = totalOpcodes;
		return this;
	}

	public StatisticsObject totalJumps(int totalJumps) {
		this.totalJumps = totalJumps;
		return this;
	}

	public StatisticsObject resolvedJumps(int resolvedJumps) {
		this.resolvedJumps = resolvedJumps;
		return this;
	}

	public StatisticsObject definitelyUnreachableJumps(int definitelyUnreachableJumps) {
		this.definitelyUnreachableJumps = definitelyUnreachableJumps;
		return this;
	}

	public StatisticsObject maybeUnreachableJumps(int maybeUnreachableJumps) {
		this.maybeUnreachableJumps = maybeUnreachableJumps;
		return this;
	}

	public StatisticsObject unsoundJumps(int unsoundJumps) {
		this.unsoundJumps = unsoundJumps;
		return this;
	}

	public StatisticsObject maybeUnsoundJumps(int maybeUnsoundJumps) {
		this.maybeUnsoundJumps = maybeUnsoundJumps;
		return this;
	}

	public StatisticsObject buildJson(JSONObject json) {
		this.json = json;
		return this;
	}

	public void addTotalOpcodes(int totalOpcodes) {
		this.totalOpcodes = totalOpcodes;
	}

	public void addTotalJumps(int totalJumps) {
		this.totalJumps = totalJumps;
	}

	public void addResolvedJumps(int resolvedJumps) {
		this.resolvedJumps = resolvedJumps;
	}

	public void addDefinitelyUnreachableJumps(int definitelyUnreachableJumps) {
		this.definitelyUnreachableJumps = definitelyUnreachableJumps;
	}

	public void addMaybeUnreachableJumps(int maybeUnreachableJumps) {
		this.maybeUnreachableJumps = maybeUnreachableJumps;
	}

	public void addUnsoundJumps(int unsoundJumps) {
		this.unsoundJumps = unsoundJumps;
	}

	public void addMaybeUnsoundJumps(int maybeUnsoundJumps) {
		this.maybeUnsoundJumps = maybeUnsoundJumps;
	}

	public StatisticsObject build() {
		return new StatisticsObject(address, totalOpcodes, totalJumps, resolvedJumps, definitelyUnreachableJumps,
				maybeUnreachableJumps, unsoundJumps, maybeUnsoundJumps, json);
	}

	public JSONObject toJson() {
		return json;
	}

	@Override
	public String toString() {
		return toJson().toString(4);
	}

	@Override
	public boolean equals(Object o) {
		if (this == o)
			return true;
		if (o == null || getClass() != o.getClass())
			return false;
		StatisticsObject that = (StatisticsObject) o;
		return totalOpcodes == that.totalOpcodes
				&& totalJumps == that.totalJumps
				&& resolvedJumps == that.resolvedJumps
				&& definitelyUnreachableJumps == that.definitelyUnreachableJumps
				&& maybeUnreachableJumps == that.maybeUnreachableJumps
				&& unsoundJumps == that.unsoundJumps
				&& maybeUnsoundJumps == that.maybeUnsoundJumps
				&& Objects.equals(address, that.address);
	}

	@Override
	public int hashCode() {
		return Objects.hash(address, totalOpcodes, totalJumps, resolvedJumps, definitelyUnreachableJumps,
				maybeUnreachableJumps, unsoundJumps, maybeUnsoundJumps);
	}
}