package it.unipr.utils;

import java.util.Objects;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONObject;

/**
 * Collects statistical data related to CFG analysis.
 */
public class StandardStatisticsObject extends StatisticsObject<StandardStatisticsObject> {

	private static final Logger log = LogManager.getLogger(StandardStatisticsObject.class);

	private int resolvedJumps;
	private int definitelyUnreachableJumps;
	private int maybeUnreachableJumps;
	private int unsoundJumps;
	private int maybeUnsoundJumps;

	/**
	 * Creates a new {@code StandardStatisticsObject} with default values.
	 */
	private StandardStatisticsObject() {
		super();
		this.resolvedJumps = 0;
		this.definitelyUnreachableJumps = 0;
		this.maybeUnreachableJumps = 0;
		this.unsoundJumps = 0;
		this.maybeUnsoundJumps = 0;
	}

	/**
	 * Creates a new {@code StandardStatisticsObject} with specified values.
	 *
	 * @param address                    the contract address
	 * @param totalOpcodes               the total number of opcodes
	 * @param totalJumps                 the total number of jumps
	 * @param totalEdges                 the total number of edges
	 * @param resolvedJumps              the number of resolved jumps
	 * @param definitelyUnreachableJumps the number of definitely unreachable
	 *                                       jumps
	 * @param maybeUnreachableJumps      the number of maybe unreachable jumps
	 * @param unsoundJumps               the number of unsound jumps
	 * @param maybeUnsoundJumps          the number of maybe unsound jumps
	 * @param json                       the JSON representation of the object
	 */
	private StandardStatisticsObject(String address, int totalOpcodes, int totalJumps, int totalEdges,
			int resolvedJumps, int definitelyUnreachableJumps,
			int maybeUnreachableJumps, int unsoundJumps, int maybeUnsoundJumps, JSONObject json) {
		super(address, totalOpcodes, totalJumps, totalEdges, json);
		this.resolvedJumps = resolvedJumps;
		this.definitelyUnreachableJumps = definitelyUnreachableJumps;
		this.maybeUnreachableJumps = maybeUnreachableJumps;
		this.unsoundJumps = unsoundJumps;
		this.maybeUnsoundJumps = maybeUnsoundJumps;

		this.json.put("resolved_jumps", this.resolvedJumps);
		this.json.put("definitely_unreachable_jumps", this.definitelyUnreachableJumps);
		this.json.put("maybe_unreachable_jumps", this.maybeUnreachableJumps);
		this.json.put("unsound_jumps", this.unsoundJumps);
		this.json.put("maybe_unsound_jumps", this.maybeUnsoundJumps);
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
	 * Creates a new {@code StandardStatisticsObject} with default values.
	 *
	 * @return a new instance of {@code StandardStatisticsObject}
	 */
	public static StandardStatisticsObject newStatisticsObject() {
		return new StandardStatisticsObject();
	}

	/**
	 * Sets the number of resolved jumps.
	 *
	 * @param resolvedJumps the resolved jumps
	 * 
	 * @return the updated {@code StandardStatisticsObject} instance
	 */
	public StandardStatisticsObject resolvedJumps(int resolvedJumps) {
		this.resolvedJumps = resolvedJumps;
		return this;
	}

	/**
	 * Sets the number of definitely unreachable jumps.
	 *
	 * @param definitelyUnreachableJumps the definitely unreachable jumps
	 * 
	 * @return the updated {@code StandardStatisticsObject} instance
	 */
	public StandardStatisticsObject definitelyUnreachableJumps(int definitelyUnreachableJumps) {
		this.definitelyUnreachableJumps = definitelyUnreachableJumps;
		return this;
	}

	/**
	 * Sets the number of maybe unreachable jumps.
	 *
	 * @param maybeUnreachableJumps the maybe unreachable jumps
	 * 
	 * @return the updated {@code StandardStatisticsObject} instance
	 */
	public StandardStatisticsObject maybeUnreachableJumps(int maybeUnreachableJumps) {
		this.maybeUnreachableJumps = maybeUnreachableJumps;
		return this;
	}

	/**
	 * Sets the number of unsound jumps.
	 *
	 * @param unsoundJumps the unsound jumps
	 * 
	 * @return the updated {@code StandardStatisticsObject} instance
	 */
	public StandardStatisticsObject unsoundJumps(int unsoundJumps) {
		this.unsoundJumps = unsoundJumps;
		return this;
	}

	/**
	 * Sets the number of maybe unsound jumps.
	 *
	 * @param maybeUnsoundJumps the maybe unsound jumps
	 * 
	 * @return the updated {@code StandardStatisticsObject} instance
	 */
	public StandardStatisticsObject maybeUnsoundJumps(int maybeUnsoundJumps) {
		this.maybeUnsoundJumps = maybeUnsoundJumps;
		return this;
	}

	/**
	 * Builds a new {@code StandardStatisticsObject} with the specified values.
	 *
	 * @return a new {@code StandardStatisticsObject} instance
	 */
	@Override
	public StandardStatisticsObject build() {
		return new StandardStatisticsObject(address, totalOpcodes, totalJumps, totalEdges, resolvedJumps,
				definitelyUnreachableJumps,
				maybeUnreachableJumps, unsoundJumps, maybeUnsoundJumps, json);
	}

	@Override
	public boolean equals(Object o) {
		if (this == o)
			return true;
		if (o == null || getClass() != o.getClass())
			return false;
		StandardStatisticsObject that = (StandardStatisticsObject) o;
		return super.equals(o)
				&& resolvedJumps == that.resolvedJumps
				&& definitelyUnreachableJumps == that.definitelyUnreachableJumps
				&& maybeUnreachableJumps == that.maybeUnreachableJumps
				&& unsoundJumps == that.unsoundJumps
				&& maybeUnsoundJumps == that.maybeUnsoundJumps;
	}

	@Override
	public int hashCode() {
		return super.hashCode() ^ Objects.hash(resolvedJumps, definitelyUnreachableJumps, maybeUnreachableJumps,
				unsoundJumps, maybeUnsoundJumps);
	}

	/**
	 * Logs the statistics of the given {@code StandardStatisticsObject}.
	 *
	 * @param statistics the statistics object to log
	 */
	@Override
	public void printStatistics() {
		log.info("Total opcodes: {}", getTotalOpcodes());
		log.info("Total jumps: {}", getTotalJumps());
		log.info("Total edges: {}", getTotalEdges());
		log.info("Resolved jumps: {}", getResolvedJumps());
		log.info("Definitely unreachable jumps: {}", getDefinitelyUnreachableJumps());
		log.info("Maybe unreachable jumps: {}", getMaybeUnreachableJumps());
		log.info("Unsound jumps: {}", getUnsoundJumps());
		log.info("Maybe unsound jumps: {}", getMaybeUnsoundJumps());
	}
}