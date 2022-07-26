package it.unipr;

import it.unipr.analysis.SymbolicStack;
import it.unipr.frontend.EVMFrontend;
import it.unive.lisa.AnalysisException;
import it.unive.lisa.LiSA;
import it.unive.lisa.LiSAConfiguration;
import it.unive.lisa.LiSAFactory;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.value.TypeDomain;
import it.unive.lisa.program.Program;
import java.io.IOException;

public class EVMLiSA {

	public static void main(String[] args) throws AnalysisException, IOException {
		Program program = EVMFrontend.processFile(args[0]);

		LiSAConfiguration conf = new LiSAConfiguration();
		conf.setDumpCFGs(true)
				.setAbstractState(
						new SimpleAbstractState<>(new MonolithicHeap(),
								new SymbolicStack(),
								LiSAFactory.getDefaultFor(TypeDomain.class)))
				.setJsonOutput(true)
				.setWorkdir("output")
				.setDumpAnalysis(true);

		LiSA lisa = new LiSA(conf);
		lisa.run(program);
	}
}
