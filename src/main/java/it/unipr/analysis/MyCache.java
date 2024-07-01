package it.unipr.analysis;

import org.apache.commons.collections4.map.LRUMap;
import org.apache.commons.lang3.tuple.Pair;

/**
 * Singleton class implementing a cache with an LRU (Least Recently Used)
 * eviction policy. The cache uses a {@link LRUMap} to store key-value pairs
 * where the key is a {@link Pair} of {@link String} and {@link Number}, and the
 * value is a {@link KIntegerSet}.
 */
public class MyCache {
	private static MyCache _instance = null;
	private LRUMap<Pair<String, Number>, KIntegerSet> _map;

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
		this._map = new LRUMap<Pair<String, Number>, KIntegerSet>(500);
	}

	/**
	 * Puts a key-value pair into the cache.
	 *
	 * @param key   the key, a {@link Pair} of {@link String} and
	 *                  {@link Number}.
	 * @param value the value, a {@link KIntegerSet}.
	 */
	public void put(Pair<String, Number> key, KIntegerSet value) {
		synchronized (_map) {
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
	public KIntegerSet get(Pair<String, Number> key) {
		synchronized (_map) {
			KIntegerSet value = _map.get(key);
			return value;
		}
	}

	/**
	 * Removes a key-value pair from the cache.
	 *
	 * @param key the key, a {@link Pair} of {@link String} and {@link Number}.
	 */
	public void remove(Pair<String, Number> key) {
		synchronized (_map) {
			_map.remove(key);
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

	public static void main(String[] args) {
		// TODO remove these tests
		Pair<String, Number> p1 = Pair.of("test1", new Number(1));

		MyCache.getInstance().put(p1, new KIntegerSet(10));

		Pair<String, Number> p2 = Pair.of("test2", new Number(2));
		Pair<String, Number> p3 = Pair.of("test3", new Number(3));

		MyCache.getInstance().put(p2, new KIntegerSet(20));
		MyCache.getInstance().put(p3, new KIntegerSet(30));

		System.out.println(MyCache.getInstance().size());
		System.out.println(MyCache.getInstance().toString());

		Pair<String, Number> p4 = Pair.of("test4", new Number(4));
		Pair<String, Number> p5 = Pair.of("test5", new Number(5));
		Pair<String, Number> p6 = Pair.of("test6", new Number(6));

		MyCache.getInstance().put(p4, new KIntegerSet(40));
		MyCache.getInstance().put(p5, new KIntegerSet(50));

		System.out.println(MyCache.getInstance().size());
		System.out.println(MyCache.getInstance().toString());

		new Thread(() -> {
			System.out.println(MyCache.getInstance().get(p1));
		}).start();
		new Thread(() -> {
			System.out.println(MyCache.getInstance().get(p2));
		}).start();
		new Thread(() -> {
			System.out.println(MyCache.getInstance().get(p3));
		}).start();
		new Thread(() -> {
			System.out.println(MyCache.getInstance().get(p4));
		}).start();
		new Thread(() -> {
			System.out.println(MyCache.getInstance().get(p5));
		}).start();
		new Thread(() -> {
			System.out.println(MyCache.getInstance().get(p6)); // null expected
		}).start();
	}
}
