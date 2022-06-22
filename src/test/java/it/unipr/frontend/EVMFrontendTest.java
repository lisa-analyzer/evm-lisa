package it.unipr.frontend;

import java.io.IOException;
import org.junit.Test;

public class EVMFrontendTest {

	@Test
	public void sm001() throws IOException {
		EVMFrontend.parseContract("evm-testcases/sm.sol");
	}
}
