package it.unipr.analysis.contract;

import it.unive.lisa.program.cfg.statement.Statement;
import java.util.*;
import org.json.JSONArray;
import org.json.JSONObject;

/**
 * Represents a function or event signature in a smart contract. Contains
 * information about the name, type, parameters, and associated entry/exit
 * points.
 */
public class Signature {
	private final String _name;
	private final String _type;
	private final List<String> _inputParamTypes;
	private final List<String> _outputParamTypes;
	private final String _fullSignature;
	private final String _selector;
	private final String _stateMutability;
	private final List<String> _modifiers;
	private Set<Statement> _entryPoints;
	private Set<Statement> _exitPoints;
	private boolean _isProtected;

	/**
	 * Constructs a Signature with the specified properties.
	 *
	 * @param name             the name of the function or event
	 * @param type             the type (e.g., "function", "event")
	 * @param inputParamTypes  the list of input parameter types
	 * @param outputParamTypes the list of output parameter types
	 * @param fullSignature    the full signature string
	 * @param selector         the selector (first 4 bytes of the Keccak-256
	 *                             hash)
	 * @param stateMutability  the state mutability of the signature
	 * @param modifiers        the list of modifiers applied to the function
	 */
	public Signature(String name, String type, List<String> inputParamTypes, List<String> outputParamTypes,
			String fullSignature, String selector, String stateMutability, List<String> modifiers) {
		this._name = name;
		this._type = type;
		this._inputParamTypes = inputParamTypes;
		this._outputParamTypes = outputParamTypes;
		this._fullSignature = fullSignature;
		this._selector = selector;
		this._entryPoints = new HashSet<>();
		this._exitPoints = new HashSet<>();
		this._isProtected = false;
		this._stateMutability = stateMutability;
		this._modifiers = modifiers != null ? modifiers : new ArrayList<>();
	}

	/**
	 * Constructs a Signature with the specified properties.
	 *
	 * @param name             the name of the function or event
	 * @param type             the type (e.g., "function", "event")
	 * @param inputParamTypes  the list of input parameter types
	 * @param outputParamTypes the list of output parameter types
	 * @param fullSignature    the full signature string
	 * @param selector         the selector (first 4 bytes of the Keccak-256
	 *                             hash)
	 */
	public Signature(String name, String type, List<String> inputParamTypes, List<String> outputParamTypes,
			String fullSignature, String selector) {
		this(name, type, inputParamTypes, outputParamTypes, fullSignature, selector, "view", new ArrayList<>());
	}

	/**
	 * Constructs a Signature with the specified properties.
	 *
	 * @param name             the name of the function or event
	 * @param type             the type (e.g., "function", "event")
	 * @param inputParamTypes  the list of input parameter types
	 * @param outputParamTypes the list of output parameter types
	 * @param fullSignature    the full signature string
	 * @param selector         the selector (first 4 bytes of the Keccak-256
	 *                             hash)
	 * @param stateMutability  the state mutability of the signature
	 */
	public Signature(String name, String type, List<String> inputParamTypes, List<String> outputParamTypes,
			String fullSignature, String selector, String stateMutability) {
		this(name, type, inputParamTypes, outputParamTypes, fullSignature, selector, stateMutability,
				new ArrayList<>());
	}

	/**
	 * Gets the name of the function or event.
	 *
	 * @return the name
	 */
	public String getName() {
		return _name;
	}

	/**
	 * Gets the type of the signature (e.g., "function", "event").
	 *
	 * @return the type
	 */
	public String getType() {
		return _type;
	}

	/**
	 * Gets the number of input parameters.
	 *
	 * @return the input parameter count
	 */
	public int getParamCount() {
		return _inputParamTypes.size();
	}

	/**
	 * Gets the number of output parameters.
	 *
	 * @return the output parameter count
	 */
	public int getOutputParamCount() {
		return _outputParamTypes.size();
	}

	/**
	 * Gets the list of input parameter types.
	 *
	 * @return the list of parameter types
	 */
	public List<String> getParamTypes() {
		return _inputParamTypes;
	}

	/**
	 * Gets the full signature string.
	 *
	 * @return the full signature
	 */
	public String getFullSignature() {
		return _fullSignature;
	}

	/**
	 * Gets the selector (first 4 bytes of the Keccak-256 hash).
	 *
	 * @return the selector
	 */
	public String getSelector() {
		return _selector;
	}

	/**
	 * Gets the list of modifiers for this signature.
	 *
	 * @return the list of modifiers
	 */
	public List<String> getModifiers() {
		return _modifiers;
	}

	/**
	 * Gets the set of entry points (statements) for this signature.
	 *
	 * @return the set of entry points
	 */
	public Set<Statement> getEntryPoints() {
		return _entryPoints;
	}

	/**
	 * Gets the state mutability for this signature.
	 *
	 * @return the state mutability
	 */
	public String getStateMutability() {
		return _stateMutability;
	}

	/**
	 * Sets the entry points for this signature.
	 *
	 * @param entryPoints the set of entry points to set
	 */
	public void setEntryPoints(Set<Statement> entryPoints) {
		this._entryPoints = entryPoints;
	}

	/**
	 * Adds an entry point to this signature.
	 *
	 * @param entryPoint the entry point statement to add
	 */
	public void addEntryPoint(Statement entryPoint) {
		if (entryPoint != null)
			this._entryPoints.add(entryPoint);
	}

	/**
	 * Gets the set of exit points (statements) for this signature.
	 *
	 * @return the set of exit points
	 */
	public Set<Statement> getExitPoints() {
		return _exitPoints;
	}

	/**
	 * Sets the exit points for this signature.
	 *
	 * @param exitPoints the set of exit points to set
	 */
	public void setExitPoints(Set<Statement> exitPoints) {
		this._exitPoints = exitPoints;
	}

	/**
	 * Adds an exit point to this signature.
	 *
	 * @param exitPoints the exit point statement to add
	 */
	public void addExitPoint(Statement exitPoints) {
		if (exitPoints != null)
			this._exitPoints.add(exitPoints);
	}

	/**
	 * Gets whether this signature is protected (i.e., has a "onlyOwner"
	 * modifier).
	 *
	 * @return true if the signature is protected, false otherwise
	 */
	public boolean isProtected() {
		return _isProtected;
	}

	/**
	 * Sets whether this signature is protected (i.e., has a "onlyOwner"
	 * modifier).
	 *
	 * @param isProtected true to mark this signature as protected, false
	 *                        otherwise
	 */
	public void setProtected(boolean isProtected) {
		this._isProtected = isProtected;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null || getClass() != obj.getClass())
			return false;
		Signature other = (Signature) obj;
		return Objects.equals(_name, other._name) &&
				Objects.equals(_type, other._type) &&
				Objects.equals(_fullSignature, other._fullSignature) &&
				Objects.equals(_selector, other._selector) &&
				Objects.equals(_modifiers, other._modifiers) &&
				_isProtected == other._isProtected &&
				Objects.equals(_stateMutability, other._stateMutability);
	}

	@Override
	public int hashCode() {
		return Objects.hash(_name, _type, _fullSignature, _selector, _modifiers, _isProtected, _stateMutability);
	}

	/**
	 * Converts this signature to a JSON object representation.
	 *
	 * @return the JSON representation of this signature
	 */
	public JSONObject toJson() {
		JSONObject json = new JSONObject();

		json.put("name", _name);
		json.put("type", _type);
		json.put("input_param_count", _inputParamTypes.size());

		JSONArray inputTypesArray = new JSONArray();
		for (String type : _inputParamTypes)
			inputTypesArray.put(type);
		json.put("input_param_types", inputTypesArray);

		json.put("output_param_count", _outputParamTypes.size());

		JSONArray outputTypesArray = new JSONArray();
		for (String type : _outputParamTypes)
			outputTypesArray.put(type);
		json.put("output_param_types", outputTypesArray);

		json.put("full_signature", _fullSignature);
		json.put("selector", _selector);

		JSONArray entryPointsArray = new JSONArray();
		for (Statement stmt : _entryPoints)
			entryPointsArray.put(stmt.toString());
		json.put("entry_points", entryPointsArray);

		JSONArray exitPointsArray = new JSONArray();
		for (Statement stmt : _exitPoints)
			exitPointsArray.put(stmt.toString());

		json.put("exit_points", exitPointsArray);

		json.put("is_protected", _isProtected);

		json.put("state_mutability", _stateMutability);

		JSONArray modifiersArray = new JSONArray();
		for (String m : _modifiers)
			modifiersArray.put(m);
		json.put("modifiers", modifiersArray);

		return json;
	}

	@Override
	public String toString() {
		return toJson().toString(4);
	}
}