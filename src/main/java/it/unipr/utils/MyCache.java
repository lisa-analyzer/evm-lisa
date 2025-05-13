package it.unipr.utils;

import it.unipr.analysis.Number;
import it.unipr.analysis.StackElement;
import it.unipr.analysis.contract.Signature;
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

	private final LRUMap<Integer, Set<Object>> _reentrancyWarnings;

	private final LRUMap<Integer, Set<Object>> _txOriginWarnings;
	private final LRUMap<Integer, Set<Object>> _possibleTxOriginWarnings;

	private final LRUMap<Integer, Set<Object>> _randomnessDependencyWarnings;
	private final LRUMap<Integer, Set<Object>> _possibleRandomnessDependencyWarnings;

	private final LRUMap<Integer, Set<Object>> _vulnerabilityPerFunction;
	private final LRUMap<Signature, Set<Signature>> _mapEventsFunctions;

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

		this._reentrancyWarnings = new LRUMap<Integer, Set<Object>>(5000);

		this._txOriginWarnings = new LRUMap<Integer, Set<Object>>(5000);
		this._possibleTxOriginWarnings = new LRUMap<Integer, Set<Object>>(5000);

		this._randomnessDependencyWarnings = new LRUMap<Integer, Set<Object>>(5000);
		this._possibleRandomnessDependencyWarnings = new LRUMap<Integer, Set<Object>>(5000);

		this._vulnerabilityPerFunction = new LRUMap<>(10000);
		this._mapEventsFunctions = new LRUMap<>(10000);
	}

	public void addMapEventsFunctions(Signature event, Signature function) {
		synchronized (_mapEventsFunctions) {
			_mapEventsFunctions
					.computeIfAbsent(event, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(function);
		}
	}

	public Set<Signature> getMapEventsFunctions(Signature event) {
		synchronized (_mapEventsFunctions) {
			return (_mapEventsFunctions.get(event) != null)
					? _mapEventsFunctions.get(event)
					: Set.of();
		}
	}

	/**
	 * Records a vulnerability warning for a specific function identified by its
	 * key.
	 * <p>
	 * This method ensures thread-safe access to the internal map, creating a
	 * new synchronized Set if none exists for the given key, and then adds the
	 * warning object to that set.
	 *
	 * @param key     the identifier of the function (e.g., CFG hashcode or
	 *                    program counter)
	 * @param warning the vulnerability description or warning object to record
	 */
	public void addVulnerabilityPerFunction(Integer key, Object warning) {
		synchronized (_vulnerabilityPerFunction) {
			_vulnerabilityPerFunction
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(warning);
		}
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
		synchronized (_vulnerabilityPerFunction) {
			if (_vulnerabilityPerFunction.get(key) == null)
				return new JSONArray();

			JSONArray results = new JSONArray();
			for (Object warning : _vulnerabilityPerFunction.get(key)) {
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
		synchronized (_reentrancyWarnings) {
			_reentrancyWarnings
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(warning);
		}
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
		synchronized (_reentrancyWarnings) {
			return (_reentrancyWarnings.get(key) != null) ? _reentrancyWarnings.get(key).size() : 0;
		}
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
		synchronized (_txOriginWarnings) {
			_txOriginWarnings
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(warning);
		}
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
		synchronized (_txOriginWarnings) {
			return (_txOriginWarnings.get(key) != null) ? _txOriginWarnings.get(key).size() : 0;
		}
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
		synchronized (_possibleTxOriginWarnings) {
			_possibleTxOriginWarnings
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(warning);
		}
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
		synchronized (_possibleTxOriginWarnings) {
			return (_possibleTxOriginWarnings.get(key) != null) ? _possibleTxOriginWarnings.get(key).size() : 0;
		}
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
		synchronized (_randomnessDependencyWarnings) {
			_randomnessDependencyWarnings
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(warning);
		}
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
		synchronized (_randomnessDependencyWarnings) {
			return (_randomnessDependencyWarnings.get(key) != null) ? _randomnessDependencyWarnings.get(key).size() : 0;
		}
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
		synchronized (_possibleRandomnessDependencyWarnings) {
			_possibleRandomnessDependencyWarnings
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(warning);
		}
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
		synchronized (_possibleRandomnessDependencyWarnings) {
			return (_possibleRandomnessDependencyWarnings.get(key) != null)
					? _possibleRandomnessDependencyWarnings.get(key).size()
					: 0;
		}
	}
}