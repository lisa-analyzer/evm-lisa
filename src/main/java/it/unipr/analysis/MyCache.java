package it.unipr.analysis;

import org.apache.commons.collections4.map.LRUMap;
import org.apache.commons.lang3.tuple.Pair;

/**
 * Singleton class implementing a cache with an LRU (Least Recently Used)
 * eviction policy. The cache uses a {@link LRUMap} to store key-value pairs
 * where the key is a {@link Pair} of {@link String} and {@link Number}, and the
 * value is a {@link StackElement}.
 */
public class MyCache {
	private static MyCache _instance = null;
	private LRUMap<Pair<String, Number>, StackElement> _map;
	private LRUMap<String, Long> _timeLostToGetStorage;
	private LRUMap<Pair<Object, Object>, Boolean> _stmtReachableFrom;

	/**
	 * Retrieves the singleton instance of the cache.
	 *
	 * @return the singleton instance of {@link MyCache}.
	 */
	public static MyCache getInstance() {
		if (_instance == null) {
			synchronized (MyCache.class) {
				if (_instance == null)
					_instance = new MyCache();
			}
		}
		return _instance;
	}

	/**
	 * Private constructor to prevent instantiation. Initializes the LRUMap with
	 * a maximum size of 500.
	 */
	private MyCache() {
		this._map = new LRUMap<Pair<String, Number>, StackElement>(500);
		this._timeLostToGetStorage = new LRUMap<String, Long>(500);
		this._stmtReachableFrom = new LRUMap<Pair<Object, Object>, Boolean>(1000);
	}

	/**
	 * Puts a key-value pair into the cache.
	 *
	 * @param key   the key, a {@link Pair} of {@link String} and
	 *                  {@link Number}.
	 * @param value the value, a {@link StackElement}.
	 */
	public void put(Pair<String, Number> key, StackElement value) {
		synchronized (MyCache.class) {
			_map.put(key, value);
		}
	}

	/**
	 * Retrieves a value from the cache by its key.
	 *
	 * @param key the key, a {@link Pair} of {@link String} and {@link Number}.
	 * 
	 * @return the value associated with the key, or {@code null} if the key is
	 *             not in the cache.
	 */
	public StackElement get(Pair<String, Number> key) {
		synchronized (MyCache.class) {
			return _map.get(key);
		}
	}

	/**
	 * Removes a key-value pair from the cache.
	 *
	 * @param key the key, a {@link Pair} of {@link String} and {@link Number}.
	 */
	public void remove(Pair<String, Number> key) {
		synchronized (MyCache.class) {
			_map.remove(key);
		}
	}

	/**
	 * Returns the number of key-value pairs currently in the cache.
	 *
	 * @return the size of the cache.
	 */
	public int size() {
		synchronized (MyCache.class) {
			return _map.size();
		}
	}

	/**
	 * Updates the cumulative time lost due to fetching live-storage by adding
	 * the specified amount of time to the existing total.
	 *
	 * @param timeLostToGetStorage the amount of time (in milliseconds) to add
	 *                                 to the total time lost due to fetching
	 *                                 storage
	 */
	public void updateTimeLostToGetStorage(String address, long timeLostToGetStorage) {
		if (address == null)
			throw new NullPointerException("Address is null");
		synchronized (MyCache.class) {
			this._timeLostToGetStorage.put(address, timeLostToGetStorage);
		}
	}

	/**
	 * Retrieves the total cumulative time lost due to fetching storage.
	 *
	 * @return the total time (in milliseconds) lost due to fetching storage
	 */
	public long getTimeLostToGetStorage(String address) {
		if (address == null)
			return 0;
		synchronized (MyCache.class) {
			return this._timeLostToGetStorage.get(address) == null ? 0 : this._timeLostToGetStorage.get(address);
		}
	}

	// TODO documentation
	public boolean isStmtReachableFrom(Pair<Object, Object> stmts) {
		synchronized (MyCache.class) {
			return _stmtReachableFrom.get(stmts) != null && _stmtReachableFrom.get(stmts);
		}
	}

	// TODO documentation
	public void setStmtReachableFrom(Pair<Object, Object> stmts, Boolean value) {
		synchronized (MyCache.class) {
			_stmtReachableFrom.put(stmts, value);
		}
	}

	// TODO documentation
	public boolean existsStmtReachableFrom(Pair<Object, Object> stmts) {
		synchronized (MyCache.class) {
			return _stmtReachableFrom.get(stmts) != null;
		}
	}
}
