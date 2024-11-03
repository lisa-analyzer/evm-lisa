package it.unipr.analysis;

import java.util.HashSet;
import java.util.Set;
import org.apache.commons.lang3.tuple.Pair;

/**
 * Singleton class that collects unique Pair<?, ?> elements.
 */
public class UniquePairCollector {
	private static UniquePairCollector _instance = null;
	private Set<Pair<?, ?>> pairSet;

	/**
	 * Retrieves the singleton instance of the collector.
	 *
	 * @return the singleton instance of {@link UniquePairCollector}.
	 */
	public static UniquePairCollector getInstance() {
		if (_instance == null) {
			synchronized (UniquePairCollector.class) {
				if (_instance == null)
					_instance = new UniquePairCollector();
			}
		}
		return _instance;
	}

	/**
	 * Private constructor to prevent instantiation. Initializes the set for
	 * storing unique pairs.
	 */
	private UniquePairCollector() {
		this.pairSet = new HashSet<>();
	}

	/**
	 * Adds a pair to the collection if it is unique.
	 *
	 * @param pair the pair to add.
	 * 
	 * @return true if the pair was added, false if it was a duplicate.
	 */
	public boolean add(Pair<?, ?> pair) {
		synchronized (UniquePairCollector.class) {
			return pairSet.add(pair);
		}
	}

	/**
	 * Returns the number of unique pairs in the collection.
	 *
	 * @return the size of the collection.
	 */
	public int size() {
		synchronized (UniquePairCollector.class) {
			return pairSet.size();
		}
	}

	/**
	 * Checks if a given pair is present in the collection.
	 *
	 * @param pair the pair to check.
	 * 
	 * @return true if the pair is present, false otherwise.
	 */
	public boolean contains(Pair<?, ?> pair) {
		synchronized (UniquePairCollector.class) {
			return pairSet.contains(pair);
		}
	}
}