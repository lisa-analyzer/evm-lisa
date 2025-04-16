package it.unipr.utils;

import it.unipr.analysis.Number;
import it.unipr.analysis.StackElement;
import it.unive.lisa.program.cfg.statement.Statement;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
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
	private final LRUMap<Pair<String, Number>, StackElement> _map;
	private final LRUMap<String, Long> _timeLostToGetStorage;
	private final LRUMap<Integer, Set<Object>> _reentrancyWarnings;
	private final LRUMap<Integer, Set<Object>> _txOriginWarnings;
	private final LRUMap<Integer, Set<Object>> _xCallUncheckedSuccessWarnings;
	private final LRUMap<Integer, Set<Object>> _delegatecallTaintAddressWarnings;
	private final LRUMap<String, Boolean> _reachableFrom;
	private final LRUMap<Integer, Set<Object>> _eventOrderWarnings;
	private final LRUMap<Integer, Set<Object>> _uncheckedStateUpdateWarnings;
	private final LRUMap<Integer, Set<Object>> _uncheckedExternalInfluenceWarnings;
	private final LRUMap<Integer, Set<Object>> _timestampDependencyWarnings;
	public final LRUMap<Statement, Set<String>> _eventsExitPoints;

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
	 * Private constructor to prevent instantiation.
	 */
	private MyCache() {
		this._map = new LRUMap<Pair<String, it.unipr.analysis.Number>, StackElement>(500);
		this._timeLostToGetStorage = new LRUMap<String, Long>(500);
		this._reentrancyWarnings = new LRUMap<Integer, Set<Object>>(1000);
		this._txOriginWarnings = new LRUMap<Integer, Set<Object>>(1000);
		this._xCallUncheckedSuccessWarnings = new LRUMap<Integer, Set<Object>>(1000);
		this._delegatecallTaintAddressWarnings = new LRUMap<Integer, Set<Object>>(1000);
		this._reachableFrom = new LRUMap<String, Boolean>(2000);
		this._eventOrderWarnings = new LRUMap<Integer, Set<Object>>(1000);
		this._uncheckedStateUpdateWarnings = new LRUMap<Integer, Set<Object>>(1000);
		this._uncheckedExternalInfluenceWarnings = new LRUMap<Integer, Set<Object>>(1000);
		this._eventsExitPoints = new LRUMap<Statement, Set<String>>(2000);
		this._timestampDependencyWarnings = new LRUMap<Integer, Set<Object>>(1000);
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
	 * Adds an event order warning for the specified key. If no warnings are
	 * associated with the key, a new set is created and the warning is added to
	 * it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addEventOrderWarning(Integer key, Object warning) {
		synchronized (_eventOrderWarnings) {
			_eventOrderWarnings
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(warning);
		}
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
		synchronized (_eventOrderWarnings) {
			return (_eventOrderWarnings.get(key) != null) ? _eventOrderWarnings.get(key).size() : 0;
		}
	}

	/**
	 * Adds an unchecked state update warning for the specified key. If no
	 * warnings are associated with the key, a new set is created and the
	 * warning is added to it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addUncheckedStateUpdateWarning(Integer key, Object warning) {
		synchronized (_uncheckedStateUpdateWarnings) {
			_uncheckedStateUpdateWarnings
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(warning);
		}
	}

	/**
	 * Retrieves the number of unchecked state update warnings associated with
	 * the specified key. If no warnings are associated with the key, the method
	 * returns 0. This method is thread-safe.
	 *
	 * @param key the key identifying the smart contract or entity whose
	 *                warnings are to be retrieved
	 *
	 * @return the number of warnings associated with the key, or 0 if none
	 *             exist
	 */
	public int getUncheckedStateUpdateWarnings(Integer key) {
		synchronized (_uncheckedStateUpdateWarnings) {
			return (_uncheckedStateUpdateWarnings.get(key) != null) ? _uncheckedStateUpdateWarnings.get(key).size() : 0;
		}
	}

	/**
	 * Adds an unchecked external influence warning for the specified key. If no
	 * warnings are associated with the key, a new set is created and the
	 * warning is added to it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addUncheckedExternalInfluenceWarning(Integer key, Object warning) {
		synchronized (_uncheckedExternalInfluenceWarnings) {
			_uncheckedExternalInfluenceWarnings
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(warning);
		}
	}

	/**
	 * Retrieves the number of unchecked external influence warnings associated
	 * with the specified key. If no warnings are associated with the key, the
	 * method returns 0. This method is thread-safe.
	 *
	 * @param key the key identifying the smart contract or entity whose
	 *                warnings are to be retrieved
	 *
	 * @return the number of warnings associated with the key, or 0 if none
	 *             exist
	 */
	public int getUncheckedExternalInfluenceWarnings(Integer key) {
		synchronized (_uncheckedExternalInfluenceWarnings) {
			return (_uncheckedExternalInfluenceWarnings.get(key) != null)
					? _uncheckedExternalInfluenceWarnings.get(key).size()
					: 0;
		}
	}

	/**
	 * Adds an event exit point associated with a given statement. If the
	 * statement does not already have an associated set of event exit points, a
	 * new synchronized HashSet is created. This method is thread-safe.
	 *
	 * @param key       The statement representing the exit point.
	 * @param signature The event signature to associate with the statement.
	 */
	public void addEventExitPoint(Statement key, String signature) {
		synchronized (_eventsExitPoints) {
			_eventsExitPoints
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(signature);
		}
	}

	/**
	 * Retrieves the set of event exit points associated with a given statement.
	 * If the statement has no associated exit points, an empty set is returned.
	 * This method is thread-safe.
	 *
	 * @param key The statement whose event exit points are being queried.
	 *
	 * @return A set of event signatures associated with the given statement, or
	 *             an empty set if none exist.
	 */
	public Set<String> getEventExitPoints(Statement key) {
		synchronized (_eventsExitPoints) {
			return _eventsExitPoints.get(key) == null ? new HashSet<>() : _eventsExitPoints.get(key);
		}
	}

	/**
	 * Checks whether there are event exit points associated with a given
	 * statement.
	 *
	 * @param key The statement to check.
	 *
	 * @return {@code true} if the statement has associated event exit points,
	 *             {@code false} otherwise.
	 */
	public boolean containsEventExitPoints(Statement key) {
		synchronized (_eventsExitPoints) {
			return _eventsExitPoints.get(key) != null;
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
	 * Adds a xcalluncheckedsuccess warning for the specified key. If no
	 * warnings are associated with the key, a new set is created and the
	 * warning is added to it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addXCallUncheckedSuccessWarning(Integer key, Object warning) {
		synchronized (_xCallUncheckedSuccessWarnings) {
			_xCallUncheckedSuccessWarnings
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(warning);
		}
	}

	/**
	 * Retrieves the number of xcalluncheckedsuccess warnings associated with the
	 * specified key. If no warnings are associated with the key, the method
	 * returns 0. This method is thread-safe.
	 *
	 * @param key the key identifying the smart contract or entity whose
	 *                warnings are to be retrieved
	 *
	 * @return the number of warnings associated with the key, or 0 if none
	 *             exist
	 */
	public int getXCallUncheckedSuccessWarnings(Integer key) {
		synchronized (_xCallUncheckedSuccessWarnings) {
			return (_xCallUncheckedSuccessWarnings.get(key) != null) ? _xCallUncheckedSuccessWarnings.get(key).size() : 0;
		}
	}
	/**
	 * Adds a delegatecalltaintaddress warning for the specified key. If no
	 * warnings are associated with the key, a new set is created and the
	 * warning is added to it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addDelegatecallTaintAddressWarning(Integer key, Object warning) {
		synchronized (_delegatecallTaintAddressWarnings) {
			_delegatecallTaintAddressWarnings
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(warning);
		}
	}
	/**
	 * Retrieves the number of delegatecalltaintaddress warnings associated with
	 * the specified key. If no warnings are associated with the key, the method
	 * returns 0. This method is thread-safe.
	 *
	 * @param key the key identifying the smart contract or entity whose
	 *                warnings are to be retrieved
	 *
	 * @return the number of warnings associated with the key, or 0 if none
	 *             exist
	 */
	public int getDelegatecallTaintAddressWarnings(Integer key) {
		synchronized (_delegatecallTaintAddressWarnings) {
			return (_delegatecallTaintAddressWarnings.get(key) != null) ? _delegatecallTaintAddressWarnings.get(key).size() : 0;
		}
	}

	/**
	 * Adds a timestamp dependency warning for the specified key. If no warnings
	 * are associated with the key, a new set is created and the warning is
	 * added to it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addTimestampDependencyWarning(Integer key, Object warning) {
		synchronized (_timestampDependencyWarnings) {
			_timestampDependencyWarnings
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(warning);
		}
	}

	/**
	 * Retrieves the number of timestamp dependency warnings associated with the
	 * specified key. If no warnings are associated with the key, the method
	 * returns 0. This method is thread-safe.
	 *
	 * @param key the key identifying the smart contract or entity whose
	 *                warnings are to be retrieved
	 *
	 * @return the number of warnings associated with the key, or 0 if none
	 *             exist
	 */
	public int getTimestampDependencyWarnings(Integer key) {
		synchronized (_timestampDependencyWarnings) {
			return (_timestampDependencyWarnings.get(key) != null) ? _timestampDependencyWarnings.get(key).size() : 0;
		}
	}
}