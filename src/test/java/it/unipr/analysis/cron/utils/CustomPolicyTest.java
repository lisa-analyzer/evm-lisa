package it.unipr.analysis.cron.utils;

import it.unipr.analysis.contract.Signature;
import it.unipr.crosschain.xEVMLiSA;
import it.unipr.utils.CustomPolicy;
import it.unipr.utils.CustomPolicy.PolicyEntry;
import java.io.IOException;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import org.json.JSONObject;
import org.json.JSONTokener;
import org.junit.Test;

public class CustomPolicyTest {

	@Test
	public void loadsPolicyAndProvidesLookups() throws IOException {
		Path policyPath = Paths.get("evm-testcases", "cross-chain-custom-policy", "custom-policy.json");
		CustomPolicy policy = new CustomPolicy(policyPath);

		assert policy.size() == 17;
		assert !policy.isEmpty();

		List<PolicyEntry> transferOutEntries = policy.getEntriesBySourceFunction("transferOut");
		assert transferOutEntries.size() == 1;
		PolicyEntry transferOut = transferOutEntries.get(0);
		List<String> transferOutEvents = transferOut.getSourceFunction().getEvents();
		assert transferOutEvents.size() == 2;
		assert transferOutEvents.contains("TransferOut");
		assert transferOutEvents.contains("Outbound");

		List<PolicyEntry> depositedEntries = policy.getEntriesByEvent("Deposited");
		assert depositedEntries.size() == 3;

		Set<String> knownEvents = policy.getKnownEvents();
		assert knownEvents.contains("Deposit");
		assert knownEvents.contains("TransferOutAndCall");
		assert policy.getEntriesBySourceFunction("missing").isEmpty();
	}

	@Test
	public void toJsonRoundTripMatchesOriginal() throws IOException {
		Path policyPath = Paths.get("evm-testcases", "cross-chain-custom-policy", "custom-policy.json");
		CustomPolicy policy = new CustomPolicy(policyPath);

		JSONObject serialized = policy.toJson();
		JSONObject original;
		try (Reader reader = Files.newBufferedReader(policyPath, StandardCharsets.UTF_8)) {
			original = new JSONObject(new JSONTokener(reader));
		}

		assert original.similar(serialized);
	}

	@Test
	public void emptyPolicyProvidesEmptyCollections() {
		CustomPolicy emptyPolicy = new CustomPolicy();
		assert emptyPolicy.isEmpty();
		assert emptyPolicy.size() == 0;
		assert emptyPolicy.getEntries().isEmpty();
		assert emptyPolicy.getEntriesByEvent("any").isEmpty();
		assert emptyPolicy.getEntriesBySourceFunction("any").isEmpty();
		assert emptyPolicy.getKnownEvents().isEmpty();
		JSONObject json = emptyPolicy.toJson();
		assert json.has("policy");
		assert json.getJSONArray("policy").isEmpty();
	}

	@Test
	public void applyPolicyRespectsConfiguration() throws IOException {
		Path policyPath = Paths.get("evm-testcases", "cross-chain-custom-policy", "custom-policy.json");
		CustomPolicy policy = new CustomPolicy(policyPath);

		Signature depositEvent = new Signature("Deposit", "event", Collections.emptyList(), Collections.emptyList(),
				"Deposit(address)", "0x00000000");
		Signature depositFunction = new Signature("deposit", "function", Collections.emptyList(),
				Collections.emptyList(), "deposit(address)", "0x00000000");
		assert xEVMLiSA.applyPolicy(policy, depositEvent, depositFunction);

		Signature outboundEvent = new Signature("Outbound", "event", Collections.emptyList(), Collections.emptyList(),
				"Outbound(address)", "0x00000001");
		Signature transferOutFunction = new Signature("transferOut", "function", Collections.emptyList(),
				Collections.emptyList(), "transferOut(address)", "0x00000002");
		assert xEVMLiSA.applyPolicy(policy, outboundEvent, transferOutFunction);

		Signature randomEvent = new Signature("Random", "event", Collections.emptyList(), Collections.emptyList(),
				"Random()", "0x00000003");
		assert !xEVMLiSA.applyPolicy(policy, randomEvent, depositFunction);

		Signature fallbackEvent = new Signature("Foo", "event", Collections.emptyList(), Collections.emptyList(),
				"Foo()", "0x00000004");
		Signature fallbackFunction = new Signature("foo", "function", Collections.emptyList(), Collections.emptyList(),
				"foo()", "0x00000005");
		assert xEVMLiSA.applyPolicy(null, fallbackEvent, fallbackFunction);
		CustomPolicy emptyPolicy = new CustomPolicy();
		assert xEVMLiSA.applyPolicy(emptyPolicy, fallbackEvent, fallbackFunction);
		Signature mismatchFunction = new Signature("bar", "function", Collections.emptyList(), Collections.emptyList(),
				"bar()", "0x00000006");
		assert !xEVMLiSA.applyPolicy(emptyPolicy, fallbackEvent, mismatchFunction);
	}
}
