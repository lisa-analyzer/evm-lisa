package it.unipr.utils;

import java.util.Objects;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONObject;

/**
 * Collects statistical data related to CFG analysis.
 */
public class StatisticsObject {
	private static final Logger log = LogManager.getLogger(StatisticsObject.class);

	private String address;
	private int totalOpcodes;
	private int totalJumps;
	private int resolvedJumps;
	private int definitelyUnreachableJumps;
	private int maybeUnreachableJumps;
	private int unsoundJumps;
	private int maybeUnsoundJumps;
	private JSONObject json;

	/**
	 * Creates a new {@code StatisticsObject} with default values.
	 */
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


	/**
	 * Creates a new {@code StatisticsObject} with specified values.
	 *
	 * @param address                     the contract address
	 * @param totalOpcodes                 the total number of opcodes
	 * @param totalJumps                   the total number of jumps
	 * @param resolvedJumps                the number of resolved jumps
	 * @param definitelyUnreachableJumps   the number of definitely unreachable jumps
	 * @param maybeUnreachableJumps        the number of maybe unreachable jumps
	 * @param unsoundJumps                 the number of unsound jumps
	 * @param maybeUnsoundJumps            the number of maybe unsound jumps
	 * @param json                         the JSON representation of the object
	 */
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

	/**
	 * Returns the contract address.
	 *
	 * @return the contract address
	 */
	public String getAddress() {
		return address;
	}


	/**
	 * Returns the total number of opcodes.
	 *
	 * @return the total opcodes
	 */
	public int getTotalOpcodes() {
		return totalOpcodes;
	}

	/**
	 * Returns the total number of jumps.
	 *
	 * @return the total jumps
	 */
	public int getTotalJumps() {
		return totalJumps;
	}

	/**
	 * Returns the number of resolved jumps.
	 *
	 * @return the resolved jumps
	 */
	public int getResolvedJumps() {
		return resolvedJumps;
	}

	/**
	 * Returns the number of definitely unreachable jumps.
	 *
	 * @return the definitely unreachable jumps
	 */
	public int getDefinitelyUnreachableJumps() {
		return definitelyUnreachableJumps;
	}

	/**
	 * Returns the number of maybe unreachable jumps.
	 *
	 * @return the maybe unreachable jumps
	 */
	public int getMaybeUnreachableJumps() {
		return maybeUnreachableJumps;
	}

	/**
	 * Returns the number of unsound jumps.
	 *
	 * @return the unsound jumps
	 */
	public int getUnsoundJumps() {
		return unsoundJumps;
	}

	/**
	 * Returns the number of maybe unsound jumps.
	 *
	 * @return the maybe unsound jumps
	 */
	public int getMaybeUnsoundJumps() {
		return maybeUnsoundJumps;
	}

	/**
	 * Creates a new {@code StatisticsObject} with default values.
	 *
	 * @return a new instance of {@code StatisticsObject}
	 */
	public static StatisticsObject newStatisticsObject() {
		return new StatisticsObject();
	}


	/**
	 * Sets the contract address.
	 *
	 * @param address the contract address
	 * @return the updated {@code StatisticsObject} instance
	 */
	public StatisticsObject address(String address) {
		this.address = address;
		return this;
	}

	/**
	 * Sets the total number of opcodes.
	 *
	 * @param totalOpcodes the total opcodes
	 * @return the updated {@code StatisticsObject} instance
	 */
	public StatisticsObject totalOpcodes(int totalOpcodes) {
		this.totalOpcodes = totalOpcodes;
		return this;
	}

	/**
	 * Sets the total number of jumps.
	 *
	 * @param totalJumps the total jumps
	 * @return the updated {@code StatisticsObject} instance
	 */
	public StatisticsObject totalJumps(int totalJumps) {
		this.totalJumps = totalJumps;
		return this;
	}


	/**
	 * Sets the number of resolved jumps.
	 *
	 * @param resolvedJumps the resolved jumps
	 * @return the updated {@code StatisticsObject} instance
	 */
	public StatisticsObject resolvedJumps(int resolvedJumps) {
		this.resolvedJumps = resolvedJumps;
		return this;
	}

	/**
	 * Sets the number of definitely unreachable jumps.
	 *
	 * @param definitelyUnreachableJumps the definitely unreachable jumps
	 * @return the updated {@code StatisticsObject} instance
	 */
	public StatisticsObject definitelyUnreachableJumps(int definitelyUnreachableJumps) {
		this.definitelyUnreachableJumps = definitelyUnreachableJumps;
		return this;
	}


	/**
	 * Sets the number of maybe unreachable jumps.
	 *
	 * @param maybeUnreachableJumps the maybe unreachable jumps
	 * @return the updated {@code StatisticsObject} instance
	 */
	public StatisticsObject maybeUnreachableJumps(int maybeUnreachableJumps) {
		this.maybeUnreachableJumps = maybeUnreachableJumps;
		return this;
	}

	/**
	 * Sets the number of unsound jumps.
	 *
	 * @param unsoundJumps the unsound jumps
	 * @return the updated {@code StatisticsObject} instance
	 */
	public StatisticsObject unsoundJumps(int unsoundJumps) {
		this.unsoundJumps = unsoundJumps;
		return this;
	}

	/**
	 * Sets the number of maybe unsound jumps.
	 *
	 * @param maybeUnsoundJumps the maybe unsound jumps
	 * @return the updated {@code StatisticsObject} instance
	 */
	public StatisticsObject maybeUnsoundJumps(int maybeUnsoundJumps) {
		this.maybeUnsoundJumps = maybeUnsoundJumps;
		return this;
	}

	/**
	 * Builds a new {@code StatisticsObject} with the specified values.
	 *
	 * @return a new {@code StatisticsObject} instance
	 */
	public StatisticsObject build() {
		return new StatisticsObject(address, totalOpcodes, totalJumps, resolvedJumps, definitelyUnreachableJumps,
				maybeUnreachableJumps, unsoundJumps, maybeUnsoundJumps, json);
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

	/**
	 * Logs the statistics of the given {@code StatisticsObject}.
	 *
	 * @param statistics the statistics object to log
	 */
	public static void printStatistics(StatisticsObject statistics) {
		log.info("Total opcodes: {}", statistics.getTotalOpcodes());
		log.info("Total jumps: {}", statistics.getTotalJumps());
		log.info("Resolved jumps: {}", statistics.getResolvedJumps());
		log.info("Definitely unreachable jumps: {}", statistics.getDefinitelyUnreachableJumps());
		log.info("Maybe unreachable jumps: {}", statistics.getMaybeUnreachableJumps());
		log.info("Unsound jumps: {}", statistics.getUnsoundJumps());
		log.info("Maybe unsound jumps: {}", statistics.getMaybeUnsoundJumps());
	}
}