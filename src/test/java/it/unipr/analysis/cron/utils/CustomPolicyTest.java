package it.unipr.analysis.cron.utils;

import it.unipr.utils.CustomPolicy;
import it.unipr.utils.CustomPolicy.PolicyEntry;
import java.io.IOException;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
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

		assert policy.getEntries().size() == 17;

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
}
