package it.unipr.utils;

import java.util.Objects;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONObject;

/**
 * Collects statistical data related to CFG analysis.
 */
public class PaperStatisticsObject extends StatisticsObject<PaperStatisticsObject> {

	private static final Logger log = LogManager.getLogger(PaperStatisticsObject.class);

	private int resolved;
	private int unreachable;
	private int erroneous;
	private int unknown;
	private int topState;

	/**
	 * Creates a new {@code PaperStatisticsObject} with default values.
	 */
	private PaperStatisticsObject() {
		super();
		this.resolved = 0;
		this.unreachable = 0;
		this.erroneous = 0;
		this.unknown = 0;
		this.topState = 0;
	}

	/**
	 * Creates a new {@code PaperStatisticsObject} with specified values.
	 *
	 * @param address      the contract address
	 * @param totalOpcodes the total number of opcodes
	 * @param totalJumps   the total number of jumps
	 * @param totalEdges   the total number of edges
	 * @param resolved     the number of resolved jumps
	 * @param unreachable  the number of unreachable jumps
	 * @param erroneous    the number of erroneous jumps
	 * @param unknown      the number of unknown jumps
	 * @param topState     the number of unknown jumps where the whole state was
	 *                         top
	 * @param json         the JSON representation of the object
	 */
	private PaperStatisticsObject(String address, int totalOpcodes, int totalJumps, int totalEdges,
			int resolved, int unreachable, int erroneous, int unknown, int topState, JSONObject json) {
		super(address, totalOpcodes, totalJumps, totalEdges, json);
		this.resolved = resolved;
		this.unreachable = unreachable;
		this.erroneous = erroneous;
		this.unknown = unknown;
		this.topState = topState;

		this.json.put("resolved_jumps", this.resolved);
		this.json.put("unreachable_jumps", this.unreachable);
		this.json.put("erroneous_jumps", this.erroneous);
		this.json.put("unknown_jumps", this.unknown);
		this.json.put("top_stack_head_jumps", this.topState);
	}

	/**
	 * Returns the number of resolved jumps.
	 *
	 * @return the resolved jumps
	 */
	public int getResolved() {
		return resolved;
	}

	/**
	 * Returns the number of unreachable jumps.
	 *
	 * @return the unreachable jumps
	 */
	public int getUnreachable() {
		return unreachable;
	}

	/**
	 * Returns the number of erroneous jumps.
	 *
	 * @return the erroneous jumps
	 */
	public int getErroneous() {
		return erroneous;
	}

	/**
	 * Returns the number of unknown jumps.
	 *
	 * @return the unknown jumps
	 */
	public int getUnknown() {
		return unknown;
	}

	/**
	 * Returns the number of unknown jumps where the whole state was top.
	 *
	 * @return the unknown jumps where the whole state was top
	 */
	public int getTopState() {
		return topState;
	}

	/**
	 * Creates a new {@code PaperStatisticsObject} with default values.
	 *
	 * @return a new instance of {@code PaperStatisticsObject}
	 */
	public static PaperStatisticsObject newStatisticsObject() {
		return new PaperStatisticsObject();
	}

	/**
	 * Constructs a PaperStatisticsObject from a JSON representation. Missing
	 * fields are treated as zero/defaults.
	 *
	 * @param json the JSONObject containing statistics
	 *
	 * @return a built PaperStatisticsObject
	 */
	public static PaperStatisticsObject fromJson(org.json.JSONObject json) {
		if (json == null)
			return null;
		return PaperStatisticsObject.newStatisticsObject()
				.address(json.optString("address", ""))
				.totalOpcodes(json.optInt("total_opcodes", 0))
				.totalJumps(json.optInt("total_jumps", 0))
				.totalEdges(json.optInt("total_edges", 0))
				.resolved(json.optInt("resolved_jumps", 0))
				.unreachable(json.optInt("unreachable_jumps", 0))
				.erroneous(json.optInt("erroneous_jumps", 0))
				.unknown(json.optInt("unknown_jumps", 0))
				.topState(json.optInt("top_stack_head_jumps", 0))
				.build();
	}

	/**
	 * Sets the number of resolved jumps.
	 *
	 * @param resolved the resolved jumps
	 *
	 * @return the updated {@code PaperStatisticsObject} instance
	 */
	public PaperStatisticsObject resolved(int resolved) {
		this.resolved = resolved;
		return this;
	}

	/**
	 * Sets the number of unreachable jumps.
	 *
	 * @param unreachable the unreachable jumps
	 *
	 * @return the updated {@code PaperStatisticsObject} instance
	 */
	public PaperStatisticsObject unreachable(int unreachable) {
		this.unreachable = unreachable;
		return this;
	}

	/**
	 * Sets the number of erroneous jumps.
	 *
	 * @param erroneous the erroneous jumps
	 *
	 * @return the updated {@code PaperStatisticsObject} instance
	 */
	public PaperStatisticsObject erroneous(int erroneous) {
		this.erroneous = erroneous;
		return this;
	}

	/**
	 * Sets the number of unknown jumps.
	 *
	 * @param unknown the unknown jumps
	 *
	 * @return the updated {@code PaperStatisticsObject} instance
	 */
	public PaperStatisticsObject unknown(int unknown) {
		this.unknown = unknown;
		return this;
	}

	/**
	 * Sets the number of unknown jumps where the whole state was top.
	 *
	 * @param topState the unknown jumps where the whole state was top
	 *
	 * @return the updated {@code PaperStatisticsObject} instance
	 */
	public PaperStatisticsObject topState(int topState) {
		this.topState = topState;
		return this;
	}

	/**
	 * Builds a new {@code PaperStatisticsObject} with the specified values.
	 *
	 * @return a new {@code PaperStatisticsObject} instance
	 */
	@Override
	public PaperStatisticsObject build() {
		return new PaperStatisticsObject(address, totalOpcodes, totalJumps, totalEdges, resolved, unreachable,
				erroneous, unknown, topState, json);
	}

	@Override
	public boolean equals(Object o) {
		if (this == o)
			return true;
		if (o == null || getClass() != o.getClass())
			return false;
		PaperStatisticsObject that = (PaperStatisticsObject) o;
		return super.equals(o)
				&& resolved == that.resolved
				&& unreachable == that.unreachable
				&& erroneous == that.erroneous
				&& unknown == that.unknown
				&& topState == that.topState;
	}

	@Override
	public int hashCode() {
		return super.hashCode() ^ Objects.hash(resolved, unreachable, erroneous, unknown, topState);
	}

	/**
	 * Logs the statistics of the given {@code PaperStatisticsObject}.
	 */
	@Override
	public void printStatistics() {
		log.info("Total opcodes: {}", getTotalOpcodes());
		log.info("Total jumps: {}", getTotalJumps());
		log.info("Total edges: {}", getTotalEdges());
		log.info("Resolved jumps: {}", getResolved());
		log.info("Unreachable jumps: {}", getUnreachable());
		log.info("Erroneous jumps: {}", getErroneous());
		log.info("Unknown jumps: {}", getUnknown());
		log.info("Unknown jumps with top state: {}", getTopState());
	}
}