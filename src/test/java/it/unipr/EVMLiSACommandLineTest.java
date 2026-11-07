package it.unipr;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import java.io.File;
import java.net.URI;
import java.net.URLClassLoader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

public class EVMLiSACommandLineTest {
	@Rule
	public TemporaryFolder temporaryFolder = new TemporaryFolder();

	@Test
	public void rejectsConflictingAnalysisOptions() throws Exception {
		Path output = temporaryFolder.newFile("cli.log").toPath();
		ClassLoader loader = EVMLiSA.class.getClassLoader();
		String classpath = loader instanceof URLClassLoader
				? Arrays.stream(((URLClassLoader) loader).getURLs())
						.map(url -> Path.of(URI.create(url.toExternalForm())).toString())
						.collect(Collectors.joining(File.pathSeparator))
				: System.getProperty("java.class.path");

		Process process = new ProcessBuilder(
				Path.of(System.getProperty("java.home"), "bin", "java").toString(),
				"-cp", classpath, EVMLiSA.class.getName(),
				"--bytecode", "0x600160020100",
				"--output-directory-path", temporaryFolder.getRoot().getPath(),
				"--use-live-storage", "--link-unsound-jumps-to-all-jumpdest")
				.redirectErrorStream(true)
				.redirectOutput(output.toFile())
				.start();
		try {
			assertTrue("EVMLiSA CLI timed out", process.waitFor(30, TimeUnit.SECONDS));
			String diagnostic = Files.readString(output);
			assertEquals(diagnostic, 1, process.exitValue());
			assertTrue(diagnostic, diagnostic.contains("has already been selected"));
		} finally {
			process.destroyForcibly();
		}
	}
}
