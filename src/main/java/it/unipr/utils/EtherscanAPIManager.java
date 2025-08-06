package it.unipr.utils;

import io.github.cdimascio.dotenv.Dotenv;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class EtherscanAPIManager {
	private static final Logger log = LogManager.getLogger(EtherscanAPIManager.class);
	private static String API_KEY;
	private static final String API_URL = "https://api.etherscan.io/v2/api";
	private static final String CHAIN_ID = "1"; // Ethereum mainnet

	/**
	 * Sets the Etherscan API key for making requests to the Etherscan API.
	 *
	 * @param apiKey the API key to use for Etherscan requests. Must not be null
	 *                   or empty.
	 * 
	 * @throws IllegalArgumentException if the provided API key is null or empty
	 */
	public static void setAPIKey(String apiKey) {
		if (apiKey == null || apiKey.isEmpty()) {
			System.err.println(JSONManager
					.throwNewError("ETHERSCAN_API_KEY cannot be null or empty."));
			System.exit(1);
		}

		API_KEY = apiKey;
	}

	/**
	 * Loads the Etherscan API key from environment if not already set. The
	 * method first checks if the API key is already available in memory. If
	 * not, it attempts to load it from the ETHERSCAN_API_KEY environment
	 * variable.
	 *
	 * @return the loaded API key
	 * 
	 * @throws RuntimeException if the environment variable is not found or is
	 *                              empty
	 */
	private static String loadAPIKey() {
		if (API_KEY == null || API_KEY.isEmpty()) {
			String apiKey = Dotenv.load().get("ETHERSCAN_API_KEY");
			// Check if API key was retrieved correctly from the environment
			if (apiKey == null || apiKey.isEmpty()) {
				System.err.println(JSONManager
						.throwNewError("Couldn't retrieve ETHERSCAN_API_KEY environment variable from your system."));
				System.exit(1);
			}
			EtherscanAPIManager.setAPIKey(apiKey);
		}

		return API_KEY;
	}

	/**
	 * Makes a request to the Etherscan API with the specified parameters.
	 * Constructs a GET request URL with the provided module, action, position,
	 * and address parameters. Automatically appends the API key and chain ID to
	 * the request.
	 *
	 * @param module   the Etherscan API module to call
	 * @param action   the specific action to perform within the module
	 * @param position the position parameter for certain API calls
	 * @param address  the Ethereum address to query
	 * 
	 * @return the response from the Etherscan API as a String, or null if the
	 *             request failed or returned an error
	 * 
	 * @throws IOException if there's an issue with the HTTP connection or
	 *                         reading the response
	 */
	public static String etherscanRequest(String module,
			String action,
			String position,
			String address) throws IOException {

		StringBuilder requestBuilder = new StringBuilder(API_URL + "?");
		requestBuilder.append("chainId=").append(CHAIN_ID);

		if (module != null)
			requestBuilder.append("&").append("module=").append(module);
		if (action != null)
			requestBuilder.append("&").append("action=").append(action);
		if (address != null)
			requestBuilder.append("&").append("address=").append(address);
		if (position != null)
			requestBuilder.append("&").append("position=").append(position);

		log.info("Request to etherscan: {}", requestBuilder.toString());

		requestBuilder.append("&").append("apikey=").append(loadAPIKey());

		String request = requestBuilder.toString();

		URL requestUrl = null;
		try {
			requestUrl = new URI(request).toURL();
		} catch (URISyntaxException e) {
			System.err.println(JSONManager
					.throwNewError("URISyntaxException in " + request));
			System.exit(1);
		}

		HttpURLConnection connection = (HttpURLConnection) requestUrl.openConnection();
		connection.setRequestMethod("GET");
		connection.setRequestProperty("User-Agent", "Mozilla/5.0");

		if (connection.getResponseCode() == HttpURLConnection.HTTP_OK) {
			BufferedReader in = new BufferedReader(new InputStreamReader(connection.getInputStream()));
			StringBuilder sb = new StringBuilder();
			String readLine;

			while ((readLine = in.readLine()) != null)
				sb.append(readLine);

			in.close();
			String result = sb.toString();

			return errorInResponse(result) ? null : result;
		} else {
			return null;
		}
	}

	/**
	 * Checks if the Etherscan API response contains an error. Examines the
	 * response content for common error patterns such as generic errors and
	 * invalid API key errors. If an error is detected, appropriate error
	 * messages are logged and the application is terminated.
	 *
	 * @param content the response content from the Etherscan API
	 * 
	 * @return true if an error was found in the response, false otherwise
	 */
	private static boolean errorInResponse(String content) {
		final String EtherscanGenericErrorMsg = "\"message\":\"NOTOK\"";
		final String EtherscanInvalidAPIKeyErrorMsg = "\"result\":\"Invalid API Key\"";

		if (content.contains(EtherscanGenericErrorMsg)) {
			if (content.contains(EtherscanInvalidAPIKeyErrorMsg)) {
				System.err.println(JSONManager.throwNewError("Invalid Etherscan API key."));
				System.exit(1);
			} else {
				System.err.println(JSONManager.throwNewError("Generic Etherscan API error."));
				System.exit(1);
			}

			return true;
		} else {
			return false;
		}
	}

}
