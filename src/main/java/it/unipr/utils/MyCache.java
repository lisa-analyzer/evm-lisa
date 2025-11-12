package it.unipr.utils;

import it.unipr.analysis.Number;
import it.unipr.analysis.StackElement;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import org.apache.commons.collections4.map.LRUMap;
import org.apache.commons.lang3.tuple.Pair;
import org.json.JSONArray;

/**
 * Singleton class implementing a cache with an LRU (Least Recently Used)
 * eviction policy. The cache uses a {@link LRUMap} to store key-value pairs
 * where the key is a {@link Pair} of {@link String} and {@link Number}, and the
 * value is a {@link StackElement}.
 */
public class MyCache {
	private static MyCache _instance = null;
	private static long _timesUsed = 0;

	private final LRUMap<Pair<String, Number>, StackElement> _map;
	private final LRUMap<String, Long> _timeLostToGetStorage;
	private final LRUMap<String, Boolean> _reachableFrom;

	private final LRUMap<String, Set<Object>> _warningsCache;

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
		++_timesUsed;
		return _instance;
	}

	/**
	 * Retrieves the number of times the cache has been used.
	 *
	 * @return the count of times the cache has been used as a long value
	 */
	public static long getTimesUsed() {
		return _timesUsed;
	}

	/**
	 * Private constructor to prevent instantiation.
	 */
	private MyCache() {
		this._map = new LRUMap<Pair<String, it.unipr.analysis.Number>, StackElement>(500);
		this._timeLostToGetStorage = new LRUMap<String, Long>(500);
		this._reachableFrom = new LRUMap<String, Boolean>(5000);
		this._warningsCache = new LRUMap<String, Set<Object>>(20000);
	}

	/**
	 * Adds a warning to the internal warnings cache. If no warnings are
	 * associated with the key, a new synchronized set is created and the
	 * warning is added to it. This method is thread-safe.
	 *
	 * @param key   the key identifying the category or entity for which the
	 *                  warning applies
	 * @param value the warning object to be added
	 */
	private void putWarning(String key, Object value) {
		synchronized (_warningsCache) {
			_warningsCache
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(value);
		}
	}

	/**
	 * Retrieves the number of warnings associated with the specified key. If no
	 * warnings are associated with the key, the method returns 0. This method
	 * is thread-safe.
	 *
	 * @param key the key identifying the category or entity whose warnings are
	 *                to be retrieved
	 *
	 * @return the number of warnings associated with the key, or 0 if none
	 *             exist
	 */
	private int getWarnings(String key) {
		synchronized (_warningsCache) {
			return (_warningsCache.get(key) != null) ? _warningsCache.get(key).size() : 0;
		}
	}

	/**
	 * Records a vulnerability warning for a specific function identified by its
	 * key. This method ensures thread-safe access to the internal map, creating
	 * a new synchronized Set if none exists for the given key, and then adds
	 * the warning object to that set.
	 *
	 * @param key     the identifier of the function (e.g., CFG hashcode or
	 *                    program counter)
	 * @param warning the vulnerability description or warning object to record
	 */
	public void addVulnerabilityPerFunction(Integer key, Object warning) {
		String cacheKey = "vulnerabilityPerFunction:" + key.toString();
		putWarning(cacheKey, warning);
	}

	/**
	 * Retrieves all recorded vulnerability warnings for a specific function.
	 * <p>
	 * This method performs a thread-safe lookup in the internal map. If no
	 * warnings have been recorded for the given key, it returns an empty
	 * JSONArray; otherwise, it returns a JSONArray containing all stored
	 * warnings.
	 *
	 * @param key the identifier of the function whose warnings are requested
	 *
	 * @return a JSONArray of warning objects for the given function key, or an
	 *             empty JSONArray if none are present
	 */
	public JSONArray getVulnerabilityPerFunction(Integer key) {
		String cacheKey = "vulnerabilityPerFunction:" + key.toString();
		synchronized (_warningsCache) {
			Set<Object> warnings = _warningsCache.get(cacheKey);
			if (warnings == null)
				return new JSONArray();

			JSONArray results = new JSONArray();
			for (Object warning : warnings) {
				results.put(warning);
			}
			return results;
		}
	}

	/**
	 * Puts a key-value pair into the cache.
	 *
	 * @param key   the key, a {@link Pair} of {@link String} and
	 *                  {@link it.unipr.analysis.Number}.
	 * @param value the value, a {@link StackElement}.
	 */
	public void put(Pair<String, it.unipr.analysis.Number> key, StackElement value) {
		synchronized (_map) {
			_map.put(key, value);
		}
	}

	/**
	 * Retrieves a value from the cache by its key.
	 *
	 * @param key the key, a {@link Pair} of {@link String} and
	 *                {@link it.unipr.analysis.Number}.
	 *
	 * @return the value associated with the key, or {@code null} if the key is
	 *             not in the cache.
	 */
	public StackElement get(Pair<String, Number> key) {
		synchronized (_map) {
			return _map.get(key);
		}
	}

	/**
	 * Returns the number of key-value pairs currently in the cache.
	 *
	 * @return the size of the cache.
	 */
	public int size() {
		synchronized (_map) {
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
		synchronized (_timeLostToGetStorage) {
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
		synchronized (_timeLostToGetStorage) {
			return this._timeLostToGetStorage.get(address) == null ? 0 : this._timeLostToGetStorage.get(address);
		}
	}

	/**
	 * Adds a reentrancy warning for the specified key. If no warnings are
	 * associated with the key, a new set is created and the warning is added to
	 * it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addReentrancyWarning(Integer key, Object warning) {
		String cacheKey = "reentrancyWarning:" + key.toString();
		putWarning(cacheKey, warning);
	}

	/**
	 * Retrieves the number of reentrancy warnings associated with the specified
	 * key. If no warnings are associated with the key, the method returns 0.
	 * This method is thread-safe.
	 *
	 * @param key the key identifying the smart contract or entity whose
	 *                warnings are to be retrieved
	 *
	 * @return the number of warnings associated with the key, or 0 if none
	 *             exist
	 */
	public int getReentrancyWarnings(Integer key) {
		String cacheKey = "reentrancyWarning:" + key.toString();
		return getWarnings(cacheKey);
	}

	/**
	 * Adds an event order warning for the specified key. If no warnings are
	 * associated with the key, a new set is created and the warning is added to
	 * it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addEventOrderWarning(Integer key, Object warning) {
		String cacheKey = "eventOrderWarning:" + key.toString();
		putWarning(cacheKey, warning);
	}

	/**
	 * Retrieves the number of event order warnings associated with the
	 * specified key. If no warnings are associated with the key, the method
	 * returns 0. This method is thread-safe.
	 *
	 * @param key the key identifying the smart contract or entity whose
	 *                warnings are to be retrieved
	 *
	 * @return the number of warnings associated with the key, or 0 if none
	 *             exist
	 */
	public int getEventOrderWarnings(Integer key) {
		String cacheKey = "eventOrderWarning:" + key.toString();
		return getWarnings(cacheKey);
	}

	/**
	 * Adds a missing event notification warning for the specified key. If no
	 * warnings are associated with the key, a new set is created and the
	 * warning is added to it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addMissingEventNotificationWarning(Integer key, Object warning) {
		String cacheKey = "missingEventNotificationWarning:" + key.toString();
		putWarning(cacheKey, warning);
	}

	/**
	 * Retrieves the number of missing event notification warnings associated
	 * with the specified key. If no warnings are associated with the key, the
	 * method returns 0. This method is thread-safe.
	 *
	 * @param key the key identifying the smart contract or entity whose
	 *                warnings are to be retrieved
	 *
	 * @return the number of warnings associated with the key, or 0 if none
	 *             exist
	 */
	public int getMissingEventNotificationWarnings(Integer key) {
		String cacheKey = "missingEventNotificationWarning:" + key.toString();
		return getWarnings(cacheKey);
	}

	/**
	 * Adds a missing state update warning for the specified key. If no warnings
	 * are associated with the key, a new set is created and the warning is
	 * added to it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addMissingStateUpdateWarning(Integer key, Object warning) {
		String cacheKey = "missingStateUpdateWarning:" + key.toString();
		putWarning(cacheKey, warning);
	}

	/**
	 * Retrieves the number of missing state update warnings associated with the
	 * specified key. If no warnings are associated with the key, the method
	 * returns 0. This method is thread-safe.
	 *
	 * @param key the key identifying the smart contract or entity whose
	 *                warnings are to be retrieved
	 *
	 * @return the number of warnings associated with the key, or 0 if none
	 *             exist
	 */
	public int getMissingStateUpdateWarnings(Integer key) {
		String cacheKey = "missingStateUpdateWarning:" + key.toString();
		return getWarnings(cacheKey);
	}

	/**
	 * Adds an access control incompleteness warning for the specified key. If
	 * no warnings are associated with the key, a new set is created and the
	 * warning is added to it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addAccessControlIncompletenessWarning(Integer key, Object warning) {
		String cacheKey = "accessControlIncompletenessWarningDefinite:" + key.toString();
		putWarning(cacheKey, warning);
	}

	/**
	 * Retrieves the number of access control incompleteness warnings associated
	 * with the specified key. If no warnings are associated with the key, the
	 * method returns 0. This method is thread-safe.
	 *
	 * @param key the key identifying the smart contract or entity whose
	 *                warnings are to be retrieved
	 *
	 * @return the number of warnings associated with the key, or 0 if none
	 *             exist
	 */
	public int getAccessControlIncompletenessWarnings(Integer key) {
		String cacheKey = "accessControlIncompletenessWarningDefinite:" + key.toString();
		return getWarnings(cacheKey);
	}

	/**
	 * Adds a possible access control incompleteness warning for the specified
	 * key. If no warnings are associated with the key, a new set is created and
	 * the warning is added to it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addPossibleAccessControlIncompletenessWarning(Integer key, Object warning) {
		String cacheKey = "accessControlIncompletenessWarningPossible:" + key.toString();
		putWarning(cacheKey, warning);
	}

	/**
	 * Retrieves the number of possible access control incompleteness warnings
	 * associated with the specified key. If no warnings are associated with the
	 * key, the method returns 0. This method is thread-safe.
	 *
	 * @param key the key identifying the smart contract or entity whose
	 *                warnings are to be retrieved
	 *
	 * @return the number of warnings associated with the key, or 0 if none
	 *             exist
	 */
	public int getPossibleAccessControlIncompletenessWarnings(Integer key) {
		String cacheKey = "accessControlIncompletenessWarningPossible:" + key.toString();
		return getWarnings(cacheKey);
	}

	/**
	 * Adds or updates the reachability status of a specific key in the
	 * reachability map.
	 *
	 * @param key             the key representing the element to update
	 * @param isReachableFrom {@code true} if the element is reachable,
	 *                            {@code false} otherwise
	 */
	public void addReachableFrom(String key, boolean isReachableFrom) {
		synchronized (_reachableFrom) {
			_reachableFrom.put(key, isReachableFrom);
		}
	}

	/**
	 * Checks if a specific key is marked as reachable in the reachability map.
	 *
	 * @param key the key representing the element to check
	 *
	 * @return {@code true} if the key is marked as reachable, {@code false}
	 *             otherwise
	 *
	 * @throws NullPointerException if the key does not exist in the map
	 */
	public boolean isReachableFrom(String key) {
		synchronized (_reachableFrom) {
			return _reachableFrom.get(key);
		}
	}

	/**
	 * Checks if a specific key exists in the reachability map.
	 *
	 * @param key the key representing the element to check
	 *
	 * @return {@code true} if the key exists in the map, {@code false}
	 *             otherwise
	 */
	public boolean existsInReachableFrom(String key) {
		synchronized (_reachableFrom) {
			return (_reachableFrom.get(key) != null);
		}
	}

	/**
	 * Adds a tx origin warning for the specified key. If no warnings are
	 * associated with the key, a new set is created and the warning is added to
	 * it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addTxOriginWarning(Integer key, Object warning) {
		String cacheKey = "txOriginWarningDefinite:" + key.toString();
		putWarning(cacheKey, warning);
	}

	/**
	 * Retrieves the number of tx origin warnings associated with the specified
	 * key. If no warnings are associated with the key, the method returns 0.
	 * This method is thread-safe.
	 *
	 * @param key the key identifying the smart contract or entity whose
	 *                warnings are to be retrieved
	 *
	 * @return the number of warnings associated with the key, or 0 if none
	 *             exist
	 */
	public int getTxOriginWarnings(Integer key) {
		String cacheKey = "txOriginWarningDefinite:" + key.toString();
		return getWarnings(cacheKey);
	}

	/**
	 * Adds a possible tx origin warning for the specified key. If no warnings
	 * are associated with the key, a new set is created and the warning is
	 * added to it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addPossibleTxOriginWarning(Integer key, Object warning) {
		String cacheKey = "txOriginWarningPossible:" + key.toString();
		putWarning(cacheKey, warning);
	}

	/**
	 * Retrieves the number of possible tx origin warnings associated with the
	 * specified key. If no warnings are associated with the key, the method
	 * returns 0. This method is thread-safe.
	 *
	 * @param key the key identifying the smart contract or entity whose
	 *                warnings are to be retrieved
	 *
	 * @return the number of possible warnings associated with the key, or 0 if
	 *             none exist
	 */
	public int getPossibleTxOriginWarnings(Integer key) {
		String cacheKey = "txOriginWarningPossible:" + key.toString();
		return getWarnings(cacheKey);
	}

	/**
	 * Adds a randomness dependency warning for the specified key. If no
	 * warnings are associated with the key, a new set is created and the
	 * warning is added to it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addRandomnessDependencyWarning(Integer key, Object warning) {
		String cacheKey = "randomnessDependencyWarningDefinite:" + key.toString();
		putWarning(cacheKey, warning);
	}

	/**
	 * Retrieves the number of randomness dependency warnings associated with
	 * the specified key. If no warnings are associated with the key, the method
	 * returns 0. This method is thread-safe.
	 *
	 * @param key the key identifying the smart contract or entity whose
	 *                warnings are to be retrieved
	 *
	 * @return the number of warnings associated with the key, or 0 if none
	 *             exist
	 */
	public int getRandomnessDependencyWarnings(Integer key) {
		String cacheKey = "randomnessDependencyWarningDefinite:" + key.toString();
		return getWarnings(cacheKey);
	}

	/**
	 * Adds a warning indicating a possible randomness dependency to the
	 * internal collection. The method ensures thread safety during modification
	 * of warnings collection.
	 *
	 * @param key     an integer key representing the category or type of the
	 *                    warning
	 * @param warning an object representing the warning message or detail to be
	 *                    added
	 */
	public void addPossibleRandomnessDependencyWarning(Integer key, Object warning) {
		String cacheKey = "randomnessDependencyWarningPossible:" + key.toString();
		putWarning(cacheKey, warning);
	}

	/**
	 * Retrieves the number of possible randomness dependency warnings
	 * associated with a given key. The method checks the internal map for the
	 * specified key and returns the size of the list of warnings if the key
	 * exists; otherwise, it returns zero.
	 *
	 * @param key the key used to identify the list of randomness dependency
	 *                warnings in the internal map. It can be null.
	 *
	 * @return the number of randomness dependency warnings associated with the
	 *             specified key. Returns 0 if the key is not present or there
	 *             are no warnings associated with it.
	 */
	public int getPossibleRandomnessDependencyWarnings(Integer key) {
		String cacheKey = "randomnessDependencyWarningPossible:" + key.toString();
		return getWarnings(cacheKey);
	}

	/**
	 * Adds a time synchronization warning to the internal tracking map. If the
	 * key does not already exist, a new synchronized set will be created and
	 * associated with the given key.
	 *
	 * @param warning the warning object to be added to the corresponding set of
	 *                    warnings for the given key
	 */
	public void addLocalDependencyWarning(Integer key, Object warning) {
		String cacheKey = "localDependencyWarningDefinite:" + key.toString();
		putWarning(cacheKey, warning);
	}

	/**
	 * Retrieves the number of time synchronization warnings associated with the
	 * given key.
	 *
	 * @return the count of time synchronization warnings associated with the
	 *             provided key; returns 0 if the key is not present or no
	 *             warnings exist
	 */
	public int getLocalDependencyWarnings(Integer key) {
		String cacheKey = "localDependencyWarningDefinite:" + key.toString();
		return getWarnings(cacheKey);
	}

	/**
	 * Adds a possible time synchronization warning to the internal tracking
	 * map. If the key does not already exist, a new synchronized set will be
	 * created and associated with the given key.
	 *
	 * @param warning the warning object to be added to the corresponding set of
	 *                    warnings for the given key
	 */
	public void addPossibleLocalDependencyWarning(Integer key, Object warning) {
		String cacheKey = "localDependencyWarningPossible:" + key.toString();
		putWarning(cacheKey, warning);
	}

	/**
	 * Retrieves the number of possible time synchronization warnings associated
	 * with the given key.
	 *
	 * @return the count of time synchronization warnings associated with the
	 *             provided key; returns 0 if the key is not present or no
	 *             warnings exist
	 */
	public int getPossibleLocalDependencyWarnings(Integer key) {
		String cacheKey = "localDependencyWarningPossible:" + key.toString();
		return getWarnings(cacheKey);
	}
}