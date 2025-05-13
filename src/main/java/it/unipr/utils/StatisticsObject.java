package it.unipr.utils;

import java.util.Objects;
import org.json.JSONObject;

/**
 * Collects statistical data related to CFG analysis.
 */
public abstract class StatisticsObject<T extends StatisticsObject<T>> {

	protected String address;
	protected int totalOpcodes;
	protected int totalJumps;
	protected int totalEdges;
	protected JSONObject json;

	/**
	 * Creates a new {@code StatisticsObject} with default values.
	 */
	protected StatisticsObject() {
		this.address = "";
		this.totalOpcodes = 0;
		this.totalJumps = 0;
		this.totalEdges = 0;
		this.json = new JSONObject();
	}

	/**
	 * Creates a new {@code StatisticsObject} with specified values.
	 *
	 * @param address                    the contract address
	 * @param totalOpcodes               the total number of opcodes
	 * @param totalJumps                 the total number of jumps
	 * @param totalEdges                 the number of edges
	 * @param json                       the JSON representation of the object
	 */
	protected StatisticsObject(String address, int totalOpcodes, int totalJumps, int totalEdges, JSONObject json) {
		this.address = address;
		this.totalOpcodes = totalOpcodes;
		this.totalJumps = totalJumps;
		this.totalEdges = totalEdges;
		this.json = json;

		this.json.put("total_opcodes", this.totalOpcodes);
		this.json.put("total_jumps", this.totalJumps);
		this.json.put("total_edges", this.totalEdges);
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
	 * Returns the total number of edges.
	 *
	 * @return the total edges
	 */
	public int getTotalEdges() {
		return totalEdges;
	}

	/**
	 * Sets the contract address.
	 *
	 * @param address the contract address
	 * 
	 * @return the updated {@code StatisticsObject} instance
	 */
	@SuppressWarnings("unchecked")
	public T address(String address) {
		this.address = address;
		return (T) this;
	}

	/**
	 * Sets the total number of opcodes.
	 *
	 * @param totalOpcodes the total opcodes
	 * 
	 * @return the updated {@code StatisticsObject} instance
	 */
	@SuppressWarnings("unchecked")
	public T totalOpcodes(int totalOpcodes) {
		this.totalOpcodes = totalOpcodes;
		return (T) this;
	}

	/**
	 * Sets the total number of jumps.
	 *
	 * @param totalJumps the total jumps
	 * 
	 * @return the updated {@code StatisticsObject} instance
	 */
	@SuppressWarnings("unchecked")
	public T totalJumps(int totalJumps) {
		this.totalJumps = totalJumps;
		return (T) this;
	}

	/**
	 * Sets the total number of edges.
	 *
	 * @param totalEdges the total edges
	 * 
	 * @return the updated {@code StatisticsObject} instance
	 */
	@SuppressWarnings("unchecked")
	public T totalEdges(int totalEdges) {
		this.totalEdges = totalEdges;
		return (T) this;
	}

	/**
	 * Builds a new {@code StatisticsObject} with the specified values.
	 *
	 * @return a new {@code StatisticsObject} instance
	 */
	public abstract T build();

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
		StatisticsObject<?> that = (StatisticsObject<?>) o;
		return totalOpcodes == that.totalOpcodes
				&& totalJumps == that.totalJumps
				&& totalEdges == that.totalEdges
				&& Objects.equals(address, that.address);
	}

	@Override
	public int hashCode() {
		return Objects.hash(address, totalOpcodes, totalJumps, totalEdges);
	}

	/**
	 * Logs this object's statistics.
	 */
	public abstract void printStatistics();
}