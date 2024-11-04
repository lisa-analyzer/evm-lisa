package it.unipr.checker;

import it.unipr.analysis.*;
import it.unipr.cfg.Call;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.ProgramCounterLocation;
import it.unipr.cfg.Sstore;
import it.unive.lisa.analysis.AnalysisState;
import it.unive.lisa.analysis.AnalyzedCFG;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.checks.semantic.CheckToolWithAnalysisResults;
import it.unive.lisa.checks.semantic.SemanticCheck;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.statement.Statement;
import java.util.Set;
import java.util.stream.Collectors;
import org.apache.commons.lang3.tuple.ImmutablePair;
import org.apache.commons.lang3.tuple.Pair;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class ReentrancyChecker implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(ReentrancyChecker.class);

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		if (node instanceof Call) {
			EVMCFG cfg = ((EVMCFG) graph);
			Call call = (Call) node;
			ProgramCounterLocation callLoc = (ProgramCounterLocation) call.getLocation();

			
			for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, EVMAbstractState,
					TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
				AnalysisState<SimpleAbstractState<MonolithicHeap, EVMAbstractState,
						TypeEnvironment<InferredTypes>>> analysisResult = null;

				try {
					analysisResult = result.getAnalysisStateBefore(call);
				} catch (SemanticException e1) {
					e1.printStackTrace();
				}

				// Retrieve the symbolic stack from the analysis result
				EVMAbstractState valueState = analysisResult.getState().getValueState();

				Set<Statement> ns = cfg.getNodes().stream()
						.filter(n -> n instanceof Sstore)
						.collect(Collectors.toSet());

				// If the value state is bottom, the jump is definitely
				// unreachable
				if (valueState.isBottom()) {
					// Nothing to do
					continue;
				} else {
					if (valueState.isTop()) {
						for (Statement sstore : ns) {
							Pair<Object, Object> myPair = new ImmutablePair<>(call, sstore);

							

							ProgramCounterLocation sstoreLoc = (ProgramCounterLocation) sstore.getLocation();
							if (MyCache.getInstance().existsStmtReachableFrom(myPair)) {
								if (MyCache.getInstance().isStmtReachableFrom(myPair)) {
									
									for (Statement otherSstore : ns)
										if (!otherSstore.equals(sstore)) 
											if (otherSstore.getLocation().compareTo(sstoreLoc) > 0 && cfg.reachableFromSequentially(sstore, otherSstore))
												sstoreLoc = (ProgramCounterLocation) otherSstore.getLocation();
										
									log.debug("Reentrancy attack at "
											+ sstoreLoc.getPc() + "at line no. "
											+ sstoreLoc.getSourceCodeLine()
											+ "coming from line "
											+ callLoc.getSourceCodeLine());
									String warn = "Reentrancy attack at "
											+ sstoreLoc.getPc();
									tool.warn(warn);
									UniqueItemCollector.getInstance().add(warn); // TODO
									// to
									// optimize,
									// temp
									// solution
								}
							} else {
								if (cfg.reachableFrom(call, sstore)) {
									
									
									MyCache.getInstance().setStmtReachableFrom(myPair, true);
									
									
									for (Statement otherSstore : ns)
										if (!otherSstore.equals(sstore)) 
											if (otherSstore.getLocation().compareTo(sstoreLoc) > 0 && cfg.reachableFromSequentially(sstore, otherSstore))
												sstoreLoc = (ProgramCounterLocation) otherSstore.getLocation();
									
									
									log.debug("Reentrancy attack at "
											+ sstoreLoc.getPc() + "at line no. "
											+ sstoreLoc.getSourceCodeLine()
											+ "coming from line "
											+ callLoc.getSourceCodeLine());
									String warn = "Reentrancy attack at "
											+ sstoreLoc.getPc();
									tool.warn(warn);
									UniqueItemCollector.getInstance().add(warn); // TODO
																					// to
																					// optimize,
																					// temp
																					// solution

								} else {
									MyCache.getInstance().setStmtReachableFrom(myPair, false);
								}
							}
						}
					} else {
						AbstractStackSet stacks = valueState.getStacks();
						for (AbstractStack stack : stacks) {
							StackElement topStack = stack.getSecondElement();

							if (topStack.isTop() || topStack.isTopNotJumpdest()) {
								for (Statement sstore : ns) {

									Pair<Object, Object> myPair = new ImmutablePair<>(call, sstore);

									ProgramCounterLocation sstoreLoc = (ProgramCounterLocation) sstore.getLocation();
									if (MyCache.getInstance().existsStmtReachableFrom(myPair)) {
										if (MyCache.getInstance().isStmtReachableFrom(myPair)) {
											
											for (Statement otherSstore : ns)
												if (!otherSstore.equals(sstore)) 
													if (otherSstore.getLocation().compareTo(sstoreLoc) > 0 && cfg.reachableFromSequentially(sstore, otherSstore))
														sstoreLoc = (ProgramCounterLocation) otherSstore.getLocation();
											
											log.debug("Reentrancy attack at "
													+ sstoreLoc.getPc() + "at line no. "
													+ sstoreLoc.getSourceCodeLine()
													+ "coming from line "
													+ callLoc.getSourceCodeLine());
											String warn = "Reentrancy attack at "
													+ sstoreLoc.getPc();
											tool.warn(warn);
											UniqueItemCollector.getInstance().add(warn); // TODO
																							// to
																							// optimize,
																							// temp
																							// solution
										}
									} else {
										if (cfg.reachableFrom(call, sstore)) {
											
											
											for (Statement otherSstore : ns)
												if (!otherSstore.equals(sstore)) 
													if (otherSstore.compareTo(sstore) > 0 && cfg.reachableFromSequentially(sstore, otherSstore))
														sstoreLoc = (ProgramCounterLocation) otherSstore.getLocation();
											
										
											MyCache.getInstance().setStmtReachableFrom(myPair, true);
											log.debug("Reentrancy attack at "
													+ sstoreLoc.getPc() + "at line no. "
													+ sstoreLoc.getSourceCodeLine()
													+ "coming from line "
													+ callLoc.getSourceCodeLine());
											String warn = "Reentrancy attack at "
													+ sstoreLoc.getPc();
											tool.warn(warn);
											UniqueItemCollector.getInstance().add(warn); // TODO
											// to
											// optimize,
											// temp
											// solution

										} else {
											MyCache.getInstance().setStmtReachableFrom(myPair, false);
										}
									}
								}
							}
						}
					}
				}
			}
		}

		return true;
	}
}