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

	/**
	 * Creates a new {@code PaperStatisticsObject} with default values.
	 */
	private PaperStatisticsObject() {
		super();
		this.resolved = 0;
		this.unreachable = 0;
		this.erroneous = 0;
		this.unknown = 0;
	}

	/**
	 * Creates a new {@code PaperStatisticsObject} with specified values.
	 *
	 * @param address        the contract address
	 * @param totalOpcodes   the total number of opcodes
	 * @param totalJumps     the total number of jumps
	 * @param totalEdges     the total number of edges
	 * @param resolved       the number of resolved jumps
	 * @param unreachable    the number of definitely unreachable jumps
	 * @param erroneous      the number of maybe unreachable jumps
	 * @param unknown        the number of unsound jumps
	 * @param json           the JSON representation of the object
	 */
	private PaperStatisticsObject(String address, int totalOpcodes, int totalJumps, int totalEdges, 
			int resolved, int unreachable, int erroneous, int unknown, JSONObject json) {
		super(address, totalOpcodes, totalJumps, totalEdges, json);
		this.resolved = resolved;
		this.unreachable = unreachable;
		this.erroneous = erroneous;
		this.unknown = unknown;

		this.json.put("resolved_jumps", this.resolved);
		this.json.put("unreachable_jumps", this.unreachable);
		this.json.put("erroneous_jumps", this.erroneous);
		this.json.put("unknown_jumps", this.unknown);
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
	 * Creates a new {@code PaperStatisticsObject} with default values.
	 *
	 * @return a new instance of {@code PaperStatisticsObject}
	 */
	public static PaperStatisticsObject newStatisticsObject() {
		return new PaperStatisticsObject();
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
	 * Builds a new {@code PaperStatisticsObject} with the specified values.
	 *
	 * @return a new {@code PaperStatisticsObject} instance
	 */
	@Override
	public PaperStatisticsObject build() {
		return new PaperStatisticsObject(address, totalOpcodes, totalJumps, totalEdges, resolved, unreachable,
				erroneous, unknown, json);
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
				&& unknown == that.unknown;
	}

	@Override
	public int hashCode() {
		return super.hashCode() ^ Objects.hash(resolved, unreachable, erroneous, unknown);
	}

	/**
	 * Logs the statistics of the given {@code PaperStatisticsObject}.
	 *
	 * @param statistics the statistics object to log
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
	}
}