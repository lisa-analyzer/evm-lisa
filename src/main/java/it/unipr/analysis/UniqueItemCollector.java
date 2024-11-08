package it.unipr.analysis;

import java.util.HashSet;
import java.util.Set;

/**
 * Singleton class that collects unique Item<?, ?> elements.
 */
public class UniqueItemCollector {
	private static UniqueItemCollector _instance = null;
	private Set<Object> itemSet;

	/**
	 * Retrieves the singleton instance of the collector.
	 *
	 * @return the singleton instance of {@link UniqueItemCollector}.
	 */
	public static UniqueItemCollector getInstance() {
		if (_instance == null) {
			synchronized (UniqueItemCollector.class) {
				if (_instance == null)
					_instance = new UniqueItemCollector();
			}
		}
		return _instance;
	}

	/**
	 * Private constructor to prevent instantiation. Initializes the set for
	 * storing unique items.
	 */
	private UniqueItemCollector() {
		this.itemSet = new HashSet<>();
	}

	/**
	 * Adds a item to the collection if it is unique.
	 *
	 * @param item the item to add.
	 * 
	 * @return true if the item was added, false if it was a duplicate.
	 */
	public boolean add(Object item) {
		synchronized (UniqueItemCollector.class) {
			return itemSet.add(item);
		}
	}

	/**
	 * Returns the number of unique items in the collection.
	 *
	 * @return the size of the collection.
	 */
	public int size() {
		synchronized (UniqueItemCollector.class) {
			return itemSet.size();
		}
	}

	/**
	 * Checks if a given item is present in the collection.
	 *
	 * @param item the item to check.
	 * 
	 * @return true if the item is present, false otherwise.
	 */
	public boolean contains(Object item) {
		synchronized (UniqueItemCollector.class) {
			return itemSet.contains(item);
		}
	}

	/**
	 * Clear the set.
	 */
	public void clear() {
		synchronized (UniqueItemCollector.class) {
			itemSet.clear();
		}
	}
}