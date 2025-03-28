package it.unipr.utils;

import it.unipr.analysis.Number;
import it.unipr.analysis.StackElement;
import it.unipr.analysis.taint.TaintElement;
import it.unive.lisa.program.cfg.statement.Statement;
import java.util.Collections;
import java.util.HashSet;
import java.util.Map;
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
	private static long _timesUsed = 0;

	private final LRUMap<Pair<String, Number>, StackElement> _map;
	private final LRUMap<String, Long> _timeLostToGetStorage;
	private final LRUMap<Integer, Set<Object>> _reentrancyWarnings;
	private final LRUMap<Integer, Set<Object>> _txOriginWarnings;
	private final LRUMap<Integer, Set<Object>> _possibleTxOriginWarnings;
	private final LRUMap<String, Boolean> _reachableFrom;
	private final LRUMap<Integer, Set<Object>> _eventOrderWarnings;
	private final LRUMap<Integer, Set<Object>> _uncheckedStateUpdateWarnings;
	private final LRUMap<Integer, Set<Object>> _possibleUncheckedStateUpdateWarnings;
	private final LRUMap<Integer, Set<Object>> _uncheckedExternalInfluenceWarnings;
	private final LRUMap<Integer, Set<Object>> _possibleUncheckedExternalInfluenceWarnings;
	private final LRUMap<Integer, Set<Object>> _possibleSemanticIntegrityViolationWarnings;
	private final LRUMap<Integer, Set<Object>> _semanticIntegrityViolationWarnings;
	private final LRUMap<Integer, Set<Object>> _randomnessDependencyWarnings;
	private final LRUMap<Integer, Set<Object>> _possibleRandomnessDependencyWarnings;
	private final Set<String> _timeSynchronizationWarnings;
	private final LRUMap<Statement, Set<String>> _eventsExitPoints;
	private final LRUMap<Statement, TaintElement> _vulnerableLogStatement;
	private final Set<Statement> _taintedCallDataLoad;
	private final LRUMap<Statement, Set<Object>> _linkFromLogToCallDataLoad;

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
		this._reentrancyWarnings = new LRUMap<Integer, Set<Object>>(5000);
		this._txOriginWarnings = new LRUMap<Integer, Set<Object>>(5000);
		this._possibleTxOriginWarnings = new LRUMap<Integer, Set<Object>>(5000);
		this._reachableFrom = new LRUMap<String, Boolean>(5000);
		this._eventOrderWarnings = new LRUMap<Integer, Set<Object>>(5000);
		this._uncheckedStateUpdateWarnings = new LRUMap<Integer, Set<Object>>(5000);
		this._possibleUncheckedStateUpdateWarnings = new LRUMap<Integer, Set<Object>>(5000);
		this._uncheckedExternalInfluenceWarnings = new LRUMap<Integer, Set<Object>>(5000);
		this._possibleUncheckedExternalInfluenceWarnings = new LRUMap<Integer, Set<Object>>(5000);
		this._semanticIntegrityViolationWarnings = new LRUMap<Integer, Set<Object>>(5000);
		this._possibleSemanticIntegrityViolationWarnings = new LRUMap<Integer, Set<Object>>(5000);
		this._eventsExitPoints = new LRUMap<Statement, Set<String>>(5000);
		this._randomnessDependencyWarnings = new LRUMap<Integer, Set<Object>>(5000);
		this._possibleRandomnessDependencyWarnings = new LRUMap<Integer, Set<Object>>(5000);
		this._timeSynchronizationWarnings = new HashSet<>();
		this._vulnerableLogStatement = new LRUMap<>(5000);
		this._taintedCallDataLoad = new HashSet<>();
		this._linkFromLogToCallDataLoad = new LRUMap<>(5000);
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
	 * Adds a possible unchecked state update warning for the specified key. If
	 * no warnings are associated with the key, a new set is created and the
	 * warning is added to it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addPossibleUncheckedStateUpdateWarning(Integer key, Object warning) {
		synchronized (_possibleUncheckedStateUpdateWarnings) {
			_possibleUncheckedStateUpdateWarnings
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(warning);
		}
	}

	/**
	 * Retrieves the number of possible unchecked state update warnings
	 * associated with the specified key. If no warnings are associated with the
	 * key, the method returns 0. This method is thread-safe.
	 *
	 * @param key the key identifying the smart contract or entity whose
	 *                warnings are to be retrieved
	 * 
	 * @return the number of warnings associated with the key, or 0 if none
	 *             exist
	 */
	public int getPossibleUncheckedStateUpdateWarnings(Integer key) {
		synchronized (_possibleUncheckedStateUpdateWarnings) {
			return (_possibleUncheckedStateUpdateWarnings.get(key) != null)
					? _possibleUncheckedStateUpdateWarnings.get(key).size()
					: 0;
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
	 * Adds a possible unchecked external influence warning for the specified
	 * key. If no warnings are associated with the key, a new set is created and
	 * the warning is added to it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addPossibleUncheckedExternalInfluenceWarning(Integer key, Object warning) {
		synchronized (_possibleUncheckedExternalInfluenceWarnings) {
			_possibleUncheckedExternalInfluenceWarnings
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(warning);
		}
	}

	/**
	 * Retrieves the number of possible unchecked external influence warnings
	 * associated with the specified key. If no warnings are associated with the
	 * key, the method returns 0. This method is thread-safe.
	 *
	 * @param key the key identifying the smart contract or entity whose
	 *                warnings are to be retrieved
	 * 
	 * @return the number of possible warnings associated with the key, or 0 if
	 *             none exist
	 */
	public int getPossibleUncheckedExternalInfluenceWarnings(Integer key) {
		synchronized (_possibleUncheckedExternalInfluenceWarnings) {
			return (_possibleUncheckedExternalInfluenceWarnings.get(key) != null)
					? _possibleUncheckedExternalInfluenceWarnings.get(key).size()
					: 0;
		}
	}

	/**
	 * \* Adds a semantic integrity violation warning for the specified key. \*
	 * If no warnings are associated, a new set is created and the warning is
	 * added. \* This method is thread-safe. \* \* @param key the integer key
	 * identifying the entity for which the warning applies \* @param warning
	 * the warning object to be added
	 */
	public void addSemanticIntegrityViolationWarning(int key, Object warning) {
		synchronized (_semanticIntegrityViolationWarnings) {
			_semanticIntegrityViolationWarnings
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(warning);
		}
	}

	/**
	 * Retrieves the number of semantic integrity violation warnings
	 * associated with the specified key. If none are associated, returns 0.
	 * This method is thread-safe.
	 * 
	 * @param key the integer key identifying the entity whose warnings to retrieve 
	 * @return the number of warnings for the specified key
	 */
	public int getSemanticIntegrityViolationWarnings(Integer key) {
		synchronized (_semanticIntegrityViolationWarnings) {
			return (_semanticIntegrityViolationWarnings).get(key) != null
					? _semanticIntegrityViolationWarnings.get(key).size()
					: 0;
		}
	}

	/**
	 * Adds a possible semantic integrity violation warning for the specified
	 * key. If no warnings are associated, a new set is created and the
	 * warning is added. This method is thread-safe. 
	 * 
	 * @param key the
	 * @param warning the warning object to be added
	 */

	public void addPossibleSemanticIntegrityViolationWarning(Integer key, Object warning) {
		synchronized (_possibleSemanticIntegrityViolationWarnings) {
			_possibleSemanticIntegrityViolationWarnings
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(warning);
		}
	}

	/**
	 * Retrieves the number of possible semantic integrity violation warnings
	 * associated with the specified key. If none are associated, returns 0.
	 * This method is thread-safe.
	 * 
	 * @param key the integer key
	 * identifying the entity whose warnings to retrieve 
	 * @return the number of possible warnings for the specified key
	 */

	public int getPossibleSemanticIntegrityViolationWarnings(Integer key) {
		synchronized (_possibleSemanticIntegrityViolationWarnings) {
			return (_possibleSemanticIntegrityViolationWarnings).get(key) != null
					? _possibleSemanticIntegrityViolationWarnings.get(key).size()
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

	/**
	 * Adds a time synchronization warning to the internal tracking map. If the
	 * key does not already exist, a new synchronized set will be created and
	 * associated with the given key.
	 *
	 * @param warning the warning object to be added to the corresponding set of
	 *                    warnings for the given key
	 */
	public void addTimeSynchronizationWarning(String warning) {
		synchronized (_timeSynchronizationWarnings) {
			_timeSynchronizationWarnings.add(warning);
		}
	}

	/**
	 * Retrieves the number of time synchronization warnings associated with the
	 * given key.
	 *
	 * @return the count of time synchronization warnings associated with the
	 *             provided key; returns 0 if the key is not present or no
	 *             warnings exist
	 */
	public int getTimeSynchronizationWarnings() {
		synchronized (_timeSynchronizationWarnings) {
			return _timeSynchronizationWarnings.size();
		}
	}

	public void addVulnerableLogStatementForTimeSynchronizationChecker(Statement key) {
		synchronized (_vulnerableLogStatement) {
			_vulnerableLogStatement.put(key, TaintElement.TAINT);
		}
	}

	public Set<Statement> getSetOfVulnerableLogStatementForTimeSynchronizationChecker() {
		synchronized (_vulnerableLogStatement) {
			return _vulnerableLogStatement.keySet();
		}
	}

	public void addTaintedCallDataLoad(Statement stmt) {
		synchronized (_taintedCallDataLoad) {
			_taintedCallDataLoad.add(stmt);
		}
	}

	public boolean isTaintedCallDataLoad(Statement stmt) {
		synchronized (_taintedCallDataLoad) {
			return _taintedCallDataLoad.contains(stmt);
		}
	}

	public int getTaintedCallDataLoadSize() {
		synchronized (_taintedCallDataLoad) {
			return _taintedCallDataLoad.size();
		}
	}

	public void addLinkFromLogToCallDataLoad(Statement key, Object warning) {
		synchronized (_linkFromLogToCallDataLoad) {
			_linkFromLogToCallDataLoad
					.computeIfAbsent(key, k -> Collections.synchronizedSet(new HashSet<>()))
					.add(warning);
		}
	}

	public Set<Object> getLinkFromLogToCallDataLoad(Statement key) {
		synchronized (_linkFromLogToCallDataLoad) {
			return (_linkFromLogToCallDataLoad.get(key) != null) ? _linkFromLogToCallDataLoad.get(key)
					: new HashSet<>();
		}
	}

	public Set<Statement> getKeysContainingValueInLinkFromLogToCallDataLoad(Object value) {
		synchronized (_linkFromLogToCallDataLoad) {
			Set<Statement> keys = new HashSet<>();
			for (Map.Entry<Statement, Set<Object>> entry : _linkFromLogToCallDataLoad.entrySet()) {
				if (entry.getValue().contains(value)) {
					keys.add(entry.getKey());
				}
			}
			return keys;
		}
	}
}