package it.unipr.utils;

import io.github.cdimascio.dotenv.Dotenv;
import it.unipr.analysis.Number;
import it.unipr.analysis.StackElement;
import it.unipr.analysis.contract.Signature;
import it.unive.lisa.program.cfg.statement.Statement;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.Base64;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import org.apache.commons.lang3.tuple.Pair;
import org.json.JSONArray;
import redis.clients.jedis.UnifiedJedis;

/**
 * MyCache is a singleton helper that provides a Redis-backed cache and a set of
 * convenience operations used by the analysis. The implementation stores all
 * state in Redis (via a {@link redis.clients.jedis.UnifiedJedis} client) and
 * exposes the same methods previously backed by in-memory maps so callers do
 * not need to change. Methods in this class use base64-encoded Java
 * serialization for complex objects when persisted to Redis.
 */
public class MyCache {
	private static MyCache _instance = null;
	private static long _timesUsed = 0;
	private final UnifiedJedis jedis;

	/**
	 * Private constructor: initializes the Redis client using the
	 * environment/system configuration. Use {@link #getInstance()} to obtain
	 * the singleton instance.
	 */
	private MyCache() {
		/*
		 * Initialize jedis eagerly to simplify code and avoid synchronized
		 * lazy-init
		 */
		String url = Dotenv.load().get("REDIS_URL", "redis://localhost:6379");
		UnifiedJedis _j = null;
		try {
			_j = new UnifiedJedis(url);
		} catch (Exception e) {
			/*
			 * If Redis unavailable at construction, still allow instance
			 * creation; getJedis() will return this (possibly null) client
			 */
			_j = new UnifiedJedis("redis://localhost:6379");
		}
		this.jedis = _j;
	}

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
	 * Returns the pre-initialized Redis client used by this cache. This
	 * accessor is intentionally package-private/private to make calling sites
	 * in this class more readable. The returned client may be null if Redis
	 * could not be constructed at startup; callers should handle exceptions
	 * accordingly.
	 *
	 * @return the {@link UnifiedJedis} client used to access Redis
	 */
	private UnifiedJedis getJedis() {
		return jedis;
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
	 * Adds a mapping between an event signature and a function signature. The
	 * mapping is stored in Redis as a set under the key
	 * "mapEventsFunctions:<base64(event)>". Members are base64-serialized
	 * representations of {@link Signature} objects.
	 *
	 * @param event    the event signature used as the set key
	 * @param function the function signature to add as a member
	 */
	public void addMapEventsFunctions(Signature event, Signature function) {
		try {
			String key = "mapEventsFunctions:" + base64Serialize(event);
			getJedis().sadd(key, base64Serialize(function));
		} catch (Exception e) {
			/* Ignore */
		}
	}

	/**
	 * Retrieves the set of functions previously associated with the given event
	 * signature. If no mapping exists, an empty set is returned.
	 *
	 * @param event the event signature whose associated functions are requested
	 *
	 * @return a set of {@link Signature} objects (empty if none)
	 */
	public Set<Signature> getMapEventsFunctions(Signature event) {
		try {
			String key = "mapEventsFunctions:" + base64Serialize(event);
			var members = getJedis().smembers(key);
			if (members == null || members.isEmpty())
				return Set.of();
			Set<Signature> results = Collections.synchronizedSet(new HashSet<>());
			for (String m : members) {
				try {
					Signature s = (Signature) base64Deserialize(m);
					if (s != null)
						results.add(s);
				} catch (Exception ex) {
					/* Ignore */
				}
			}
			return results;
		} catch (Exception e) {
			return Set.of();
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
		try {
			String redisKey = "vulnPerFunc:" + key;
			getJedis().sadd(redisKey, base64Serialize(warning));
		} catch (Exception e) {
			/* Ignore */
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
		try {
			String redisKey = "vulnPerFunc:" + key;
			var members = getJedis().smembers(redisKey);
			if (members == null || members.isEmpty())
				return new JSONArray();
			JSONArray results = new JSONArray();
			for (String m : members) {
				try {
					Object obj = base64Deserialize(m);
					results.put(obj == null ? m : obj);
				} catch (Exception ex) {
					results.put(m);
				}
			}
			return results;
		} catch (Exception e) {
			return new JSONArray();
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
		try {
			String redisKey = "cache:" + base64Serialize(key);
			String payload = base64Serialize(value);
			getJedis().set(redisKey, payload);
		} catch (Exception e) {
			/* Ignore */
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
		try {
			String redisKey = "cache:" + base64Serialize(key);
			String payload = getJedis().get(redisKey);
			if (payload == null)
				return null;
			Object obj = base64Deserialize(payload);
			if (obj instanceof StackElement) {
				return (StackElement) obj;
			}
			return null;
		} catch (Exception e) {
			return null;
		}
	}

	/**
	 * Returns the number of key-value pairs currently in the cache.
	 *
	 * @return the size of the cache.
	 */
	public int size() {
		try {
			var keys = getJedis().keys("cache:*");
			return keys == null ? 0 : keys.size();
		} catch (Exception e) {
			return 0;
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
		try {
			String redisKey = "timeLost:" + address;
			getJedis().set(redisKey, String.valueOf(timeLostToGetStorage));
		} catch (Exception e) {
			/* Ignore */
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
		try {
			String redisKey = "timeLost:" + address;
			String val = getJedis().get(redisKey);
			if (val == null)
				return 0;
			return Long.parseLong(val);
		} catch (Exception e) {
			return 0;
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
		try {
			String redisKey = "reentrancy:" + key;
			getJedis().sadd(redisKey, base64Serialize(warning));
		} catch (Exception e) {
			/* Ignore */
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
		try {
			String redisKey = "reentrancy:" + key;
			var members = getJedis().smembers(redisKey);
			return members == null ? 0 : members.size();
		} catch (Exception e) {
			return 0;
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
		try {
			String redisKey = "eventOrder:" + key;
			getJedis().sadd(redisKey, base64Serialize(warning));
		} catch (Exception e) {
			/* Ignore */
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
		try {
			String redisKey = "eventOrder:" + key;
			var members = getJedis().smembers(redisKey);
			return members == null ? 0 : members.size();
		} catch (Exception e) {
			return 0;
		}
	}

	/**
	 * Adds a possible event order warning for the specified key. If no warnings
	 * are associated with the key, a new set is created and the warning is
	 * added to it. This method is thread-safe.
	 *
	 * @param key     the key identifying the smart contract or entity for which
	 *                    the warning applies
	 * @param warning the warning object to be added
	 */
	public void addPossibleEventOrderWarning(Integer key, Object warning) {
		try {
			String redisKey = "possibleEventOrder:" + key;
			getJedis().sadd(redisKey, base64Serialize(warning));
		} catch (Exception e) {
			/* Ignore */
		}
	}

	/**
	 * Retrieves the number of possible event order warnings associated with the
	 * specified key. If no warnings are associated with the key, the method
	 * returns 0. This method is thread-safe.
	 *
	 * @param key the key identifying the smart contract or entity whose
	 *                warnings are to be retrieved
	 *
	 * @return the number of warnings associated with the key, or 0 if none
	 *             exist
	 */
	public int getPossibleEventOrderWarnings(Integer key) {
		try {
			String redisKey = "possibleEventOrder:" + key;
			var members = getJedis().smembers(redisKey);
			return members == null ? 0 : members.size();
		} catch (Exception e) {
			return 0;
		}
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
		try {
			String redisKey = "missingEventNotification:" + key;
			getJedis().sadd(redisKey, base64Serialize(warning));
		} catch (Exception e) {
			/* Ignore */
		}
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
		try {
			String redisKey = "missingEventNotification:" + key;
			var members = getJedis().smembers(redisKey);
			return members == null ? 0 : members.size();
		} catch (Exception e) {
			return 0;
		}
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
		try {
			String redisKey = "accessControlIncompleteness:" + key;
			getJedis().sadd(redisKey, base64Serialize(warning));
		} catch (Exception e) {
			/* Ignore */
		}
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
		try {
			String redisKey = "accessControlIncompleteness:" + key;
			var members = getJedis().smembers(redisKey);
			return members == null ? 0 : members.size();
		} catch (Exception e) {
			return 0;
		}
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
		try {
			String redisKey = "possibleAccessControlIncompleteness:" + key;
			getJedis().sadd(redisKey, base64Serialize(warning));
		} catch (Exception e) {
			/* Ignore */
		}
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
		try {
			String redisKey = "possibleAccessControlIncompleteness:" + key;
			var members = getJedis().smembers(redisKey);
			return members == null ? 0 : members.size();
		} catch (Exception e) {
			return 0;
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
		try {
			String redisKey = "reachableFrom:" + key;
			getJedis().set(redisKey, String.valueOf(isReachableFrom));
		} catch (Exception e) {
			/* Ignore */
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
		try {
			String redisKey = "reachableFrom:" + key;
			String val = getJedis().get(redisKey);
			if (val == null)
				throw new NullPointerException();
			return Boolean.parseBoolean(val);
		} catch (NullPointerException npe) {
			throw npe;
		} catch (Exception e) {
			// if redis unavailable, fall back to false
			return false;
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
		try {
			String redisKey = "reachableFrom:" + key;
			return getJedis().exists(redisKey);
		} catch (Exception e) {
			return false;
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
		try {
			String redisKey = "txOrigin:" + key;
			getJedis().sadd(redisKey, base64Serialize(warning));
		} catch (Exception e) {
			/* Ignore */
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
		try {
			String redisKey = "txOrigin:" + key;
			var members = getJedis().smembers(redisKey);
			return members == null ? 0 : members.size();
		} catch (Exception e) {
			return 0;
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
		try {
			String redisKey = "possibleTxOrigin:" + key;
			getJedis().sadd(redisKey, base64Serialize(warning));
		} catch (Exception e) {
			/* Ignore */
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
		try {
			String redisKey = "possibleTxOrigin:" + key;
			var members = getJedis().smembers(redisKey);
			return members == null ? 0 : members.size();
		} catch (Exception e) {
			return 0;
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
		try {
			String redisKey = "randomnessDependency:" + key;
			getJedis().sadd(redisKey, base64Serialize(warning));
		} catch (Exception e) {
			/* Ignore */
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
		try {
			String redisKey = "randomnessDependency:" + key;
			var members = getJedis().smembers(redisKey);
			return members == null ? 0 : members.size();
		} catch (Exception e) {
			return 0;
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
		try {
			String redisKey = "possibleRandomnessDependency:" + key;
			getJedis().sadd(redisKey, base64Serialize(warning));
		} catch (Exception e) {
			/* Ignore */
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
		try {
			String redisKey = "possibleRandomnessDependency:" + key;
			var members = getJedis().smembers(redisKey);
			return members == null ? 0 : members.size();
		} catch (Exception e) {
			return 0;
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
	public void addLocalDependencyWarning(Integer key, Object warning) {
		try {
			String redisKey = "timeSynchronization:" + key;
			getJedis().sadd(redisKey, base64Serialize(warning));
		} catch (Exception e) {
			/* Ignore */
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
	public int getLocalDependencyWarnings(Integer key) {
		try {
			String redisKey = "timeSynchronization:" + key;
			var members = getJedis().smembers(redisKey);
			return members == null ? 0 : members.size();
		} catch (Exception e) {
			return 0;
		}
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
		try {
			String redisKey = "possibleLocalDependency:" + key;
			getJedis().sadd(redisKey, base64Serialize(warning));
		} catch (Exception e) {
			/* Ignore */
		}
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
		try {
			String redisKey = "possibleLocalDependency:" + key;
			var members = getJedis().smembers(redisKey);
			return members == null ? 0 : members.size();
		} catch (Exception e) {
			return 0;
		}
	}

	/**
	 * Marks a LOG statement as vulnerable for the Local Dependency Checker.
	 * <p>
	 * Associates the given LOG statement with a taint marker to indicate it
	 * should be analyzed for local dependency issues.
	 *
	 * @param key the LOG statement to mark as vulnerable
	 */
	public void addVulnerableLogStatementForLocalDependencyChecker(Statement key) {
		try {
			String redisKey = "vulnerableLogStatement";
			getJedis().sadd(redisKey, base64Serialize(key));
		} catch (Exception e) {
			/* Ignore */
		}
	}

	/**
	 * Retrieves all LOG statements previously marked as vulnerable for the
	 * Local Dependency Checker.
	 *
	 * @return a set of LOG statements to be checked for local dependency
	 */
	public Set<Statement> getSetOfVulnerableLogStatementForLocalDependencyChecker() {
		try {
			String redisKey = "vulnerableLogStatement";
			var members = getJedis().smembers(redisKey);
			if (members == null || members.isEmpty())
				return Set.of();
			Set<Statement> results = new HashSet<>();
			for (String m : members) {
				try {
					Object o = base64Deserialize(m);
					if (o instanceof Statement)
						results.add((Statement) o);
				} catch (Exception e) {
					/* Ignore */
				}
			}
			return results;
		} catch (Exception e) {
			return Set.of();
		}
	}

	/**
	 * Records that a CALLDATALOAD statement has been tainted by a vulnerable
	 * LOG statement in the Local Dependency analysis.
	 *
	 * @param stmt the CALLDATALOAD statement to mark as tainted
	 */
	public void addTaintedCallDataLoad(Statement stmt) {
		try {
			String redisKey = "taintedCallDataLoad";
			getJedis().sadd(redisKey, base64Serialize(stmt));
		} catch (Exception e) {
			/* Ignore */
		}
	}

	/**
	 * Checks whether a given CALLDATALOAD statement is marked as tainted by the
	 * Local Dependency Checker.
	 *
	 * @param stmt the CALLDATALOAD statement to query
	 *
	 * @return true if the statement is tainted, false otherwise
	 */
	public boolean isTaintedCallDataLoad(Statement stmt) {
		try {
			String redisKey = "taintedCallDataLoad";
			return getJedis().sismember(redisKey, base64Serialize(stmt));
		} catch (Exception e) {
			return false;
		}
	}

	/**
	 * Links a vulnerable LOG statement to its corresponding tainted
	 * CALLDATALOAD statement(s).
	 * <p>
	 * Stores a mapping from the LOG statement to one or more tainted
	 * CALLDATALOAD warnings for cross-reference during analysis.
	 *
	 * @param key     the LOG statement
	 * @param warning the tainted CALLDATALOAD statement or warning object
	 */
	public void addLinkFromLogToCallDataLoad(Statement key, Object warning) {
		try {
			String redisKey = "linkFromLogToCallDataLoad:" + base64Serialize(key);
			getJedis().sadd(redisKey, base64Serialize(warning));
		} catch (Exception e) {
			/* Ignore */
		}
	}

	/**
	 * Retrieves the set of tainted CALLDATALOAD warnings associated with a
	 * given LOG statement.
	 *
	 * @param key the LOG statement whose links are requested
	 *
	 * @return a set of warning objects linked to that LOG statement, or an
	 *             empty set if none exist
	 */
	public Set<Object> getLinkFromLogToCallDataLoad(Statement key) {
		try {
			String redisKey = "linkFromLogToCallDataLoad:" + base64Serialize(key);
			var members = getJedis().smembers(redisKey);
			if (members == null || members.isEmpty())
				return new HashSet<>();
			Set<Object> results = new HashSet<>();
			for (String m : members) {
				try {
					Object o = base64Deserialize(m);
					results.add(o == null ? m : o);
				} catch (Exception e) {
					results.add(m);
				}
			}
			return results;
		} catch (Exception e) {
			return new HashSet<>();
		}
	}

	/**
	 * Finds all LOG statements that are linked to a specific tainted
	 * CALLDATALOAD warning. This is the reverse lookup of
	 * {@link #getLinkFromLogToCallDataLoad(Statement)}.
	 *
	 * @param value the tainted CALLDATALOAD warning object
	 *
	 * @return a set of LOG statements that reference the given warning
	 */
	public Set<Statement> getKeysContainingValueInLinkFromLogToCallDataLoad(Object value) {
		try {
			// scan all keys matching pattern
			var keys = getJedis().keys("linkFromLogToCallDataLoad:*");
			Set<Statement> results = new HashSet<>();
			if (keys == null)
				return results;
			for (String k : keys) {
				try {
					var members = getJedis().smembers(k);
					if (members == null)
						continue;
					for (String m : members) {
						Object o = null;
						try {
							o = base64Deserialize(m);
						} catch (Exception ex) {
							o = m;
						}
						if ((o != null && o.equals(value)) || (o == null && m.equals(value))) {
							// extract statement from key suffix
							String b64stmt = k.substring("linkFromLogToCallDataLoad:".length());
							try {
								Object stmtObj = base64Deserialize(b64stmt);
								if (stmtObj instanceof Statement)
									results.add((Statement) stmtObj);
							} catch (Exception ex) {
								/* Ignore */
							}
						}
					}
				} catch (Exception e) {
					/* Ignore */
				}
			}
			return results;
		} catch (Exception e) {
			return new HashSet<>();
		}
	}

	/**
	 * Serializes an object to a base64-encoded string suitable for storing in
	 * Redis. Strings and primitive wrappers are converted via
	 * {@code toString()}, complex objects are serialized using Java
	 * serialization and then base64-encoded.
	 *
	 * @param obj the object to serialize (may be {@code null})
	 *
	 * @return a base64-encoded representation of the object (empty string for
	 *             {@code null})
	 *
	 * @throws IOException if Java serialization fails
	 */
	private String base64Serialize(Object obj) throws IOException {
		if (obj == null)
			return "";
		// If object is String or primitive wrapper, store toString directly
		if (obj instanceof String || obj instanceof Number || obj instanceof Boolean) {
			return Base64.getEncoder().encodeToString(obj.toString().getBytes());
		}
		try (ByteArrayOutputStream bos = new ByteArrayOutputStream();
				ObjectOutputStream oos = new ObjectOutputStream(bos)) {
			oos.writeObject(obj);
			oos.flush();
			return Base64.getEncoder().encodeToString(bos.toByteArray());
		}
	}

	/**
	 * Deserializes a base64-encoded string previously produced by
	 * {@link #base64Serialize(Object)}. If the decoded bytes look like a
	 * printable string the method returns that string; otherwise it attempts
	 * Java deserialization and returns the resulting object.
	 *
	 * @param b64 the base64-encoded payload
	 *
	 * @return the decoded object (or {@code null} if input is {@code null})
	 *
	 * @throws IOException            if IO during deserialization fails
	 * @throws ClassNotFoundException if a serialized class cannot be found
	 */
	private Object base64Deserialize(String b64) throws IOException, ClassNotFoundException {
		if (b64 == null)
			return null;
		byte[] data = Base64.getDecoder().decode(b64);
		/* Try to detect if payload is a UTF-8 string representation */
		String asString = new String(data);
		/*
		 * Crude heuristic: if the decoded bytes are valid JSON or plain string
		 * without binary content, return the string. Otherwise, attempt Java
		 * deserialization.
		 */
		if (asString.chars().allMatch(c -> c >= 9 && c <= 126)) {
			/* return as string (caller can parse if needed) */
			return asString;
		}
		try (ByteArrayInputStream bis = new ByteArrayInputStream(data);
				ObjectInputStream ois = new ObjectInputStream(bis)) {
			return ois.readObject();
		}
	}
}