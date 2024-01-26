package it.unipr.analysis.cron;

import org.junit.Before;
import org.junit.Ignore;
import org.junit.Test;

import it.unipr.analysis.EVMAbstractState;

import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Jump;
import it.unipr.cfg.Jumpi;
import it.unipr.checker.JumpChecker;
import it.unipr.frontend.EVMFrontend;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.conf.LiSAConfiguration.GraphType;
import it.unive.lisa.interprocedural.ModularWorstCaseAnalysis;
import it.unive.lisa.interprocedural.callgraph.RTACallGraph;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.statement.Statement;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.List;

public class EVMBytecodeTest extends EVMBytecodeAnalysisExecutor {
	/*
	 * Some examples of contract addresses: a. SafeMath:
	 * 0x7de33b2672efb11fde366dae96bd63b985bce186 b. ZipmexTokenP.:
	 * 0xaa602de53347579f86b996d2add74bb6f79462b2 c. ltdFDTfactory: // unknown opcode
	 * 0xf155152d838b7a023317ad8c1e8c02aab7e8f2a2 d. Dividend:
	 * 0xdb6f50cf0c521a98b6852839aa5cbea4e2430052 e. DharmaKeyR.:
	 * 0x0000000000bda2152794ac8c76b2dc86cba57cad f. DharmaT.R.:
	 * 0x8b028e2fad2dc99999fb784ca9d7267981c90b4d g. AltesF.G.:
	 * 0x8313675d1405f3f7aee3da9d63e0bf5c30c75832 h. SMRT16Ext:
	 * 0xdabb0c3f9a190b6fe4df6cb412ba66c3dd3e2ad1 i. FlashFloss:
	 * 0xfd4085e56a96787fb7acd9b49510f874c3d4afcb j. FoxInvSplit:
	 * 0xd69015163e250a70ee4a607812afda5372132cc4 k. BCN20: // loop
	 * 0x1964f2f3ce45ac518b18ef4aa4265f8aadcef4ae l. OneSplit: // unknown opcode
	 * 0x3a2d9db352580eb50018fc86eae32e19070a9982 m. EthexLoto:
	 * 0x0e26b2dc8ef577baf50891eac94f0def59b5da16 n. ManagedAccount:
	 * 0x0f4f45f2edba03d4590bd27cf4fd62e91a2a2d6a o. ERC20Salary:
	 * 0xcc2ba2eac448d60e0f943ebe378f409cb7d1b58a
	 */

	// Choose whether to generate the CFG or not
	private final static boolean GENERATE_CFG = true;
	
	// Append statistics in file
	private final static boolean APPEND = true;

	private final String FILENAME = ACTUAL_RESULTS_DIR + "/bytecodeBenchmark/statistics.xls";
	
	private final String[] smartContracts = new String[] {
			"0x6190a479cfafcb1637f5485366bcbce418a68a4d",
			"0x3af2aE62F0D3353C9F15B7fe678ccDAF2b2157C9",
			"0x000000000d38df53b45c5733c7b34000de0bdf52",
			"0x00cA62445B06a9aDc1879a44485B4eFdcB7b75F3",
			"0x5211fEbe5d129DFA871e004C39652E8254A73ef8",
			"0x6176A455b7F6741c84D9E3d479DebFCe0ba8443E",
			"0x59321ace77c8087ff8cb9f94c8384807e4fd8a3c",
			"0x732eBfefFDF57513f167b2d3D384E13246f60034",
			"0x251f752b85a9f7e1b3c42d802715b5d7a8da3165",
			"0xFF1F2B4ADb9dF6FC8eAFecDcbF96A2B351680455",
			"0x61CEAc48136d6782DBD83c09f51E23514D12470a",
			"0xcc2ba2eac448d60e0f943ebe378f409cb7d1b58a",
			"0x0f4f45f2edba03d4590bd27cf4fd62e91a2a2d6a",
			"0x0e26b2dc8ef577baf50891eac94f0def59b5da16",
			"0xd69015163e250a70ee4a607812afda5372132cc4",
			"0xdb6f50cf0c521a98b6852839aa5cbea4e2430052",
			"0x0000000000bda2152794ac8c76b2dc86cba57cad",
			"0x8313675d1405f3f7aee3da9d63e0bf5c30c75832",
			"0x8b028e2fad2dc99999fb784ca9d7267981c90b4d",
			"0xdabb0c3f9a190b6fe4df6cb412ba66c3dd3e2ad1",
			"0xfd4085e56a96787fb7acd9b49510f874c3d4afcb",
			"0xaa602de53347579f86b996d2add74bb6f79462b2",
			"0x576501abd98ce5472b03b7ab4f5980941db7ef37", 
			"0x6736077ae034e16f7fafd2d5ed1358370fda1f88",
			"0x6e08427f6f472342d0ce286c875956be232d6af4",
			"0x31179edfd7ef37b16c7643407321466cd0b33b53",
			"0x5cef8c37ab75fc56cd50e17692f39ac7bc189075",
			"0x679131f591b4f369acb8cd8c51e68596806c3916",
			"0x000000000d38df53b45c5733c7b34000de0bdf52",
			"0x0122db5fba163b123ebc047d735437c6a6677e6f"
	};
		
	@Before
	public void clean() {
	        try {
	            Files.walkFileTree(Paths.get("evm-outputs/bytecodeBenchmark"), new SimpleFileVisitor<Path>() {
	                @Override
	                public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
	                    Files.delete(file);
	                    return FileVisitResult.CONTINUE;
	                }

	                @Override
	                public FileVisitResult postVisitDirectory(Path dir, IOException exc) throws IOException {
	                    Files.delete(dir);
	                    return FileVisitResult.CONTINUE;
	                }
	            });
	        } catch (IOException e) {
	            e.printStackTrace();
	        }
	}
	
	@Ignore
	public void testSCFromEtherscan() throws Exception {
		String SC_ADDRESS = "0xc3761EB917CD790B30dAD99f6Cc5b4Ff93C4F9eA";
		toFile(newAnalysis(SC_ADDRESS));
	}
	
	@Ignore
	public void testSCWithProblems() throws Exception {
		// There are a lot of INVALID
		String[] smartContractsWithErrors = new String[] {
			"0x576501abd98ce5472b03b7ab4f5980941db7ef37"
		};
		
		String stats = "";
		
		for(int i = 0; i < smartContractsWithErrors.length; i++) {
			stats += newAnalysis(smartContractsWithErrors[i]);
			stats += " \n";
		}
		
		System.err.println("\n\n\n");
		System.err.println("[PREVIEW] Final results");
		System.out.println(stats);
	}
	
	@Ignore
	public void testEVMBytecodeAnalysisSingleThread() throws Exception {
	
		String stats = "";

		for (int i = 0; i < smartContracts.length; i++) {
			stats += newAnalysis(smartContracts[i]);
		}

		System.err.println("\n\n\n");
		System.err.println("[PREVIEW] Final results");
		System.out.println(stats);

		toFile(stats);
		System.out.println("Stats successfully written in " + FILENAME);
	}
	
	@Test
	public void testEVMBytecodeAnalysisMultiThread() throws Exception {
		Object guardia = new Object();

		Thread[] threads = new Thread[smartContracts.length];
		
		List<String> smartContractsTerminated = new ArrayList<String>();
		
		Runnable runnableHandler = new Runnable() {
			private int counter = 0;
			private Object mutex = new Object();
			
			@Override
			public void run() {
				
				synchronized (mutex) {
					for (int i = 0; i < smartContracts.length; i++) {
						String address = smartContracts[i];
						
						Runnable runnable = () -> {
							String myStats = "";
							
							try {
								
								myStats = newAnalysis(address);
								
								synchronized (mutex) {
									toFile(myStats);
									mutex.notifyAll();
									smartContractsTerminated.add(address);
								}
								
							} catch (Exception e) {
								synchronized (mutex) {
									toFile(address + ", , , , , , failure: " + e + " - " + Thread.currentThread().getName() + " \n");
									mutex.notifyAll();
								}
							}
						};
						
						threads[i] = new Thread(runnable);	
						threads[i].start();
					}
					
					try {
						while(counter < smartContracts.length) {
							mutex.wait();
							counter++;
						}
						
					} catch (InterruptedException e) {
							e.printStackTrace();
					}
					
					synchronized (guardia) {
						guardia.notifyAll(); // All tests are finished
					}
					
				}

			} // ! run()
		}; // ! Runnable
		
		synchronized (guardia) {
			Thread handler = new Thread(runnableHandler);
			handler.start();
			
			int timeToWait = smartContracts.length * 1500 + 10000;
			
			guardia.wait(timeToWait);
			
			for(int i = 0; i < smartContracts.length; i++)
				threads[i].interrupt();
		}
		
		for(int i = 0; i < smartContracts.length; i++) {
			if(!smartContractsTerminated.contains(smartContracts[i])) {
				toFile(smartContracts[i] + ", , , , , , failed \n");
			}
		}
		
		System.out.println("Stats successfully written in " + FILENAME);

	}
	
	private void toFile(String stats) {
		String init = "Smart Contract, Total Opcodes, Total Jumps, Solved Jumps, % Solved, Time (millis), Notes \n";
		try {
			File idea = new File(FILENAME);
			if (!idea.exists()) {
				FileWriter myWriter = new FileWriter(idea, APPEND);
				myWriter.write(init + stats);
				myWriter.close();

			} else {
				FileWriter myWriter = new FileWriter(idea, APPEND);
				myWriter.write(stats);
				myWriter.close();
			}

		} catch (IOException e) {
			System.err.println("An error occurred.");
			e.printStackTrace();
		}
	}

	private String newAnalysis(String CONTRACT_ADDR) throws Exception {
		long start = System.currentTimeMillis();
		
		String BYTECODE_FULLPATH = EXPECTED_RESULTS_DIR + "/bytecodeBenchmark/" + CONTRACT_ADDR + "/" + CONTRACT_ADDR
				+ ".sol";

		// Directory setup and bytecode retrieval
		Files.createDirectories(Paths.get(EXPECTED_RESULTS_DIR + "/" + "bytecodeBenchmark/" + CONTRACT_ADDR));
		EVMFrontend.parseContractFromEtherscan(CONTRACT_ADDR, BYTECODE_FULLPATH);

		// Config and test run
		CronConfiguration conf = new CronConfiguration();
		conf.serializeResults = true;
		conf.abstractState = new SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>(
				new MonolithicHeap(), new EVMAbstractState(),
				new TypeEnvironment<>(new InferredTypes()));
		conf.testDir = "bytecodeBenchmark/" + CONTRACT_ADDR;
		conf.callGraph = new RTACallGraph();
		JumpChecker checker = new JumpChecker();
		conf.semanticChecks.add(checker);
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		conf.serializeInputs = true;
		if (GENERATE_CFG) {
			conf.analysisGraphs = GraphType.HTML_WITH_SUBNODES;
		}
		conf.programFile = CONTRACT_ADDR + ".sol";
		perform(conf);

		// Print the results
		EVMCFG baseCfg = (EVMCFG) getCFGFromFile(BYTECODE_FULLPATH);
		int solvedJumps = dumpStatistics(baseCfg);
		double solvedJumpsPercent = ((double) solvedJumps / baseCfg.getAllJumps().size());
		
		long finish = System.currentTimeMillis();
		
		String stats = CONTRACT_ADDR + ", " +
				baseCfg.getNodesCount() + ", " +
				baseCfg.getAllJumps().size() + ", " +
				solvedJumps + ", " +
				(double) solvedJumpsPercent + ", " +  
				(finish - start) + ", " +
				Thread.currentThread().getName() + " \n";
		
		return stats;
	}

	private static CFG getCFGFromFile(String filename) {
		CFG cfg = null;
		try {
			for (CFG c : EVMFrontend.generateCfgFromFile(filename).getAllCFGs()) {
				cfg = c;
			}
		} catch (IOException e) {
			System.err.println("Incorrect contract filename");
		}
		return cfg;
	}

	private int dumpStatistics(EVMCFG cfg) {
		System.err.println("##############");
		System.err.println("Total opcodes: " + cfg.getNodesCount());
		System.err.println("Total jumps: " + cfg.getAllJumps().size());

		int solvedJumps = 0;
		for (Statement st : cfg.getNodes())
			if (st instanceof Jump && cfg.getOutgoingEdges(st).size() == 1)
				solvedJumps++;
			else if (st instanceof Jumpi && cfg.getOutgoingEdges(st).size() == 2)
				solvedJumps++;

		System.err.println("Solved jumps: " + solvedJumps);
		System.err.println("##############");

		return solvedJumps;
	}
	
}
