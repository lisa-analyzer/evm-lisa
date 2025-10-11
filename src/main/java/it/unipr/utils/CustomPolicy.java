package it.unipr.utils;

import java.io.IOException;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONTokener;

/**
 * Utility component that loads and exposes the cross-chain policy described in
 * a JSON file. The policy is expected to follow the schema:
 *
 * <pre>
 * {
 *   "policy": [
 *     {
 *       "sourceFunction": {
 *         "name": "deposit",
 *         "events": ["Deposit"]
 *       },
 *       "destinationFunction": {
 *         "name": "deposit"
 *       }
 *     }
 *   ]
 * }
 * </pre>
 *
 * Instances of this class cache frequently used lookups (by source function,
 * destination function, and emitting events) to make repeated accesses
 * efficient.
 */
public final class CustomPolicy {
	private static final Logger log = LogManager.getLogger(CustomPolicy.class);

	private final List<PolicyEntry> entries;
	private final Map<String, List<PolicyEntry>> entriesBySourceName;
	private final Map<String, List<PolicyEntry>> entriesByDestinationName;
	private final Map<String, List<PolicyEntry>> entriesByEvent;
	private final Set<String> knownEvents;

	/**
	 * Creates an empty policy with no entries. All lookups return empty
	 * collections and {@link #toJson()} yields an empty {@code policy} array.
	 */
	public CustomPolicy() {
		this.entries = Collections.emptyList();
		this.entriesBySourceName = Collections.emptyMap();
		this.entriesByDestinationName = Collections.emptyMap();
		this.entriesByEvent = Collections.emptyMap();
		this.knownEvents = Collections.emptySet();
	}

	/**
	 * Creates a policy view by eagerly loading and caching the data contained
	 * in the provided JSON file.
	 *
	 * @param policyPath the path to the JSON file that stores the policy
	 *
	 * @throws IOException              if reading the file fails
	 * @throws IllegalArgumentException if the JSON structure does not contain a
	 *                                      {@code policy} array or if any entry
	 *                                      lacks mandatory fields
	 */
	public CustomPolicy(Path policyPath) throws IOException {
		Objects.requireNonNull(policyPath, "policyPath cannot be null");

		List<PolicyEntry> tmpEntries = new ArrayList<>();
		Map<String, List<PolicyEntry>> tmpBySource = new HashMap<>();
		Map<String, List<PolicyEntry>> tmpByDestination = new HashMap<>();
		Map<String, List<PolicyEntry>> tmpByEvent = new HashMap<>();

		try (Reader reader = Files.newBufferedReader(policyPath, StandardCharsets.UTF_8)) {
			JSONObject root = new JSONObject(new JSONTokener(reader));
			JSONArray policyArray = root.optJSONArray("policy");
			if (policyArray == null)
				throw new IllegalArgumentException(
						"Missing 'policy' array in file " + policyPath.toAbsolutePath());

			for (int i = 0; i < policyArray.length(); i++) {
				JSONObject entryObject = policyArray.getJSONObject(i);
				PolicyEntry entry = parsePolicyEntry(entryObject, policyPath);
				tmpEntries.add(entry);
				indexEntry(entry, tmpBySource, entry.getSourceFunction().getName());
				indexEntry(entry, tmpByDestination, entry.getDestinationFunction().getName());
				for (String event : entry.getSourceFunction().getEvents())
					indexEntry(entry, tmpByEvent, event);
			}
		}

		this.entries = Collections.unmodifiableList(tmpEntries);
		this.entriesBySourceName = toUnmodifiableMultiMap(tmpBySource);
		this.entriesByDestinationName = toUnmodifiableMultiMap(tmpByDestination);
		this.entriesByEvent = toUnmodifiableMultiMap(tmpByEvent);
		this.knownEvents = Collections.unmodifiableSet(new LinkedHashSet<>(tmpByEvent.keySet()));

		log.info("Loaded {} policy entries from {}.", tmpEntries.size(), policyPath.toString());
	}

	/**
	 * Parses a single raw JSON object into a {@link PolicyEntry} instance,
	 * validating that both source and destination function descriptors are
	 * present.
	 *
	 * @param entryObject the JSON object representing a policy entry
	 * @param policyPath  the path of the policy file, used for contextual error
	 *                        messages
	 *
	 * @return the parsed policy entry
	 */
	private PolicyEntry parsePolicyEntry(JSONObject entryObject, Path policyPath) {
		JSONObject sourceObject = entryObject.optJSONObject("sourceFunction");
		JSONObject destinationObject = entryObject.optJSONObject("destinationFunction");

		if (sourceObject == null || destinationObject == null)
			throw new IllegalArgumentException("Both 'sourceFunction' and 'destinationFunction' must be provided in "
					+ policyPath.toAbsolutePath());

		FunctionSpec source = parseFunctionSpec(sourceObject, true);
		FunctionSpec destination = parseFunctionSpec(destinationObject, false);

		return new PolicyEntry(source, destination);
	}

	/**
	 * Converts the JSON description of a function into a {@link FunctionSpec},
	 * optionally enforcing the presence of an {@code events} array.
	 *
	 * @param functionObject the JSON object describing the function
	 * @param eventsRequired whether at least one event must be declared for the
	 *                           function
	 *
	 * @return the resulting function specification
	 */
	private FunctionSpec parseFunctionSpec(JSONObject functionObject, boolean eventsRequired) {
		String name = functionObject.optString("name", null);
		if (name == null || name.isEmpty())
			throw new IllegalArgumentException("Function specification is missing mandatory 'name' property");

		List<String> events = new ArrayList<>();
		JSONArray eventsArray = functionObject.optJSONArray("events");
		if (eventsArray != null) {
			for (int i = 0; i < eventsArray.length(); i++) {
				String event = eventsArray.optString(i, null);
				if (event != null && !event.isEmpty())
					events.add(event);
			}
		} else if (eventsRequired)
			throw new IllegalArgumentException("Source function '" + name + "' must declare an 'events' array");

		if (eventsRequired && events.isEmpty())
			throw new IllegalArgumentException("Source function '" + name + "' must declare at least one event");

		return new FunctionSpec(name, events);
	}

	/**
	 * Adds the provided entry to a multimap keyed by the supplied value,
	 * creating the backing list if required.
	 *
	 * @param entry the policy entry to index
	 * @param map   the multimap that holds indexed entries
	 * @param key   the lookup key associated with the entry
	 */
	private void indexEntry(PolicyEntry entry, Map<String, List<PolicyEntry>> map, String key) {
		map.computeIfAbsent(key, unused -> new ArrayList<>()).add(entry);
	}

	/**
	 * Produces an immutable copy of the supplied multimap, preserving insertion
	 * order for deterministic iteration.
	 *
	 * @param source the original, modifiable multimap
	 *
	 * @return an unmodifiable view that mirrors the source content
	 */
	private Map<String, List<PolicyEntry>> toUnmodifiableMultiMap(Map<String, List<PolicyEntry>> source) {
		Map<String, List<PolicyEntry>> target = new LinkedHashMap<>(source.size());
		source.forEach((key, value) -> target.put(key, Collections.unmodifiableList(new ArrayList<>(value))));
		return Collections.unmodifiableMap(target);
	}

	/**
	 * Retrieves the complete list of policy entries as they appear in the JSON
	 * file.
	 *
	 * @return an unmodifiable list of policy entries
	 */
	public List<PolicyEntry> getEntries() {
		return entries;
	}

	/**
	 * Looks up the policy entries that originate from the specified source
	 * function name.
	 *
	 * @param sourceFunctionName the name of the source function
	 *
	 * @return an unmodifiable list of matching policy entries, or an empty list
	 *             if none match
	 */
	public List<PolicyEntry> getEntriesBySourceFunction(String sourceFunctionName) {
		return entriesBySourceName.getOrDefault(sourceFunctionName, Collections.emptyList());
	}

	/**
	 * Looks up the policy entries whose destination function matches the given
	 * name.
	 *
	 * @param destinationFunctionName the name of the destination function
	 *
	 * @return an unmodifiable list of matching policy entries, or an empty list
	 *             if none match
	 */
	public List<PolicyEntry> getEntriesByDestinationFunction(String destinationFunctionName) {
		return entriesByDestinationName.getOrDefault(destinationFunctionName, Collections.emptyList());
	}

	/**
	 * Retrieves the policy entries associated with a specific event emitted by
	 * a source function.
	 *
	 * @param eventName the name of the event
	 *
	 * @return an unmodifiable list of matching policy entries, or an empty list
	 *             if none match
	 */
	public List<PolicyEntry> getEntriesByEvent(String eventName) {
		return entriesByEvent.getOrDefault(eventName, Collections.emptyList());
	}

	/**
	 * Returns the set of different event names that appear in the policy.
	 *
	 * @return an unmodifiable set containing every event referenced in the
	 *             policy
	 */
	public Set<String> getKnownEvents() {
		return knownEvents;
	}

	/**
	 * Retrieves the set of event names associated with the specified
	 * destination function according to this policy.
	 *
	 * @param functionName the destination function name as declared in the
	 *                         policy
	 *
	 * @return an unmodifiable set containing all matching event names, or an
	 *             empty set if none are associated with {@code functionName}
	 */
	public Set<String> getEventsForFunction(String functionName) {
		if (functionName == null || functionName.isEmpty())
			return Collections.emptySet();

		LinkedHashSet<String> events = new LinkedHashSet<>();
		for (PolicyEntry entry : entries)
			if (entry.getDestinationFunction().getName().equalsIgnoreCase(functionName))
				events.addAll(entry.getSourceFunction().getEvents());

		return Collections.unmodifiableSet(events);
	}

	/**
	 * Checks whether the policy contains no entries.
	 *
	 * @return {@code true} if the policy is empty, {@code false} otherwise
	 */
	public boolean isEmpty() {
		return entries.isEmpty();
	}

	/**
	 * Returns the number of policy entries loaded in memory.
	 *
	 * @return the amount of entries contained in this policy
	 */
	public int size() {
		return entries.size();
	}

	/**
	 * Serializes the in-memory representation of this policy into a
	 * {@link JSONObject} that mirrors the original input format.
	 *
	 * @return the JSON serialization of the policy
	 */
	public JSONObject toJson() {
		JSONArray policyArray = new JSONArray();
		for (PolicyEntry entry : entries) {
			JSONObject sourceObject = new JSONObject(new LinkedHashMap<>());
			sourceObject.put("name", entry.getSourceFunction().getName());
			List<String> events = entry.getSourceFunction().getEvents();
			if (!events.isEmpty())
				sourceObject.put("events", new JSONArray(events));

			JSONObject destinationObject = new JSONObject(new LinkedHashMap<>());
			destinationObject.put("name", entry.getDestinationFunction().getName());
			List<String> destinationEvents = entry.getDestinationFunction().getEvents();
			if (!destinationEvents.isEmpty())
				destinationObject.put("events", new JSONArray(destinationEvents));

			JSONObject entryObject = new JSONObject(new LinkedHashMap<>());
			entryObject.put("sourceFunction", sourceObject);
			entryObject.put("destinationFunction", destinationObject);
			policyArray.put(entryObject);
		}

		JSONObject root = new JSONObject(new LinkedHashMap<>());
		root.put("policy", policyArray);
		return root;
	}

	@Override
	public String toString() {
		return toJson().toString(4);
	}

	/**
	 * Describes a policy entry composed of a source and a destination function.
	 */
	public static final class PolicyEntry {

		private final FunctionSpec sourceFunction;
		private final FunctionSpec destinationFunction;

		/**
		 * Builds an immutable policy entry from the provided source and
		 * destination specifications.
		 *
		 * @param sourceFunction      the source function descriptor
		 * @param destinationFunction the destination function descriptor
		 */
		private PolicyEntry(FunctionSpec sourceFunction, FunctionSpec destinationFunction) {
			this.sourceFunction = Objects.requireNonNull(sourceFunction, "sourceFunction cannot be null");
			this.destinationFunction = Objects.requireNonNull(destinationFunction,
					"destinationFunction cannot be null");
		}

		/**
		 * Provides the source function descriptor as defined in the policy.
		 *
		 * @return the source function descriptor
		 */
		public FunctionSpec getSourceFunction() {
			return sourceFunction;
		}

		/**
		 * Provides the destination function descriptor as defined in the
		 * policy.
		 *
		 * @return the destination function descriptor
		 */
		public FunctionSpec getDestinationFunction() {
			return destinationFunction;
		}
	}

	/**
	 * Immutable description of a policy entry function. For source functions
	 * the descriptor may also carry the list of emitted events.
	 */
	public static final class FunctionSpec {

		private final String name;
		private final List<String> events;

		/**
		 * Creates a function specification with the supplied name and list of
		 * events.
		 *
		 * @param name   the function name
		 * @param events the events associated with the function descriptor
		 */
		private FunctionSpec(String name, List<String> events) {
			this.name = name;
			this.events = Collections.unmodifiableList(new ArrayList<>(events));
		}

		/**
		 * Returns the function name exactly as written in the policy file.
		 *
		 * @return the function name
		 */
		public String getName() {
			return name;
		}

		/**
		 * Provides the list of events associated with this function descriptor.
		 * Destination functions might not have any events, in which case this
		 * method returns an empty list.
		 *
		 * @return an unmodifiable list of event names
		 */
		public List<String> getEvents() {
			return events;
		}

		/**
		 * Returns a human-readable representation of this function descriptor,
		 * useful for debugging.
		 *
		 * @return a string representation of the function specification
		 */
		@Override
		public String toString() {
			return "FunctionSpec{" + "name='" + name + '\'' + ", events=" + events + '}';
		}
	}
}
