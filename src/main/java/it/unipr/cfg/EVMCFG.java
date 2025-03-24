package it.unipr.cfg;

import it.unipr.analysis.Number;
import it.unipr.cfg.push.Push;
import it.unipr.utils.MyCache;
import it.unive.lisa.analysis.AbstractState;
import it.unive.lisa.analysis.AnalysisState;
import it.unive.lisa.analysis.AnalyzedCFG;
import it.unive.lisa.analysis.OptimizedAnalyzedCFG;
import it.unive.lisa.analysis.StatementStore;
import it.unive.lisa.analysis.heap.HeapDomain;
import it.unive.lisa.analysis.type.TypeDomain;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.conf.FixpointConfiguration;
import it.unive.lisa.conf.LiSAConfiguration.DescendingPhaseType;
import it.unive.lisa.interprocedural.InterproceduralAnalysis;
import it.unive.lisa.interprocedural.ScopeId;
import it.unive.lisa.program.ProgramValidationException;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeMemberDescriptor;
import it.unive.lisa.program.cfg.edge.Edge;
import it.unive.lisa.program.cfg.edge.TrueEdge;
import it.unive.lisa.program.cfg.fixpoints.CFGFixpoint.CompoundState;
import it.unive.lisa.program.cfg.fixpoints.OptimizedFixpoint;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.util.collections.workset.WorkingSet;
import it.unive.lisa.util.datastructures.graph.algorithms.Fixpoint;
import it.unive.lisa.util.datastructures.graph.algorithms.FixpointException;
import it.unive.lisa.util.datastructures.graph.code.NodeList;
import java.util.*;
import java.util.Map.Entry;
import java.util.stream.Collectors;
import org.apache.commons.lang3.tuple.Pair;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class EVMCFG extends CFG {
	private static final Logger log = LogManager.getLogger(EVMCFG.class);

	private Set<Statement> jumpDestsNodes;
	private Set<Statement> jumpNodes;
	private Set<Statement> pushedJumps;
	private Set<Statement> sstores;
	private Set<Number> jumpDestsNodesLocations;
	public Set<Statement> sha3s;
	public Set<Statement> logxs;
	public Set<Statement> calls;
	public Set<Statement> externalData;
	public Set<Statement> jumpI;

	/**
	 * Builds a EVMCFG starting from its description.
	 *
	 * @param cfgDesc the EVMCFG description
	 */
	public EVMCFG(CodeMemberDescriptor cfgDesc) {
		super(cfgDesc);
	}

	/**
	 * Identifies and categorizes key statements (hotspot nodes) within the
	 * control flow graph (CFG). This method initializes sets to store specific
	 * types of statements, such as storage operations (SSTORE), jump
	 * destinations (JUMPDEST), jump instructions (JUMP and JUMPI), and pushed
	 * jumps.
	 */
	public void computeHotspotNodes() {
		this.jumpDestsNodes = new HashSet<Statement>();
		this.jumpNodes = new HashSet<Statement>();
		this.pushedJumps = new HashSet<Statement>();
		this.sstores = new HashSet<Statement>();

		NodeList<CFG, Statement, Edge> cfgNodeList = this.getNodeList();

		for (Statement statement : cfgNodeList.getNodes()) {
			if (statement instanceof Sstore)
				sstores.add(statement);
			else if (statement instanceof Jumpdest)
				jumpDestsNodes.add(statement);
			else if ((statement instanceof Jump) || (statement instanceof Jumpi)) {
				jumpNodes.add(statement);
			}

		}

		for (Edge edge : cfgNodeList.getEdges())
			if ((edge.getDestination() instanceof Jump || edge.getDestination() instanceof Jumpi)
					&& (edge.getSource() instanceof Push))
				pushedJumps.add(edge.getDestination());
	}

	/**
	 * Returns a set of all the CALLDATA, CALLVALUE, CALLER and ORIGIN
	 * statements in the CFG.
	 *
	 * @return a set of all the CALLDATA, CALLVALUE, CALLER and ORIGIN
	 *             statements in the CFG
	 */
	public Set<Statement> getExternalData() {
		if (this.externalData == null) {
			NodeList<CFG, Statement, Edge> cfgNodeList = this.getNodeList();
			Set<Statement> externalData = new HashSet<>();

			for (Statement statement : cfgNodeList.getNodes()) {
				if (statement instanceof Calldataload) {
					externalData.add(statement);
				} else if (statement instanceof Callvalue) {
					externalData.add(statement);
				} else if (statement instanceof Origin) {
					externalData.add(statement);
				}
			}

			return this.externalData = externalData;
		}

		return this.externalData;
	}

	/**
	 * Returns a set of all the CALL, STATICCALL and DELEGATECALL statements in
	 * the CFG.
	 *
	 * @return a set of all the CALL, STATICCALL and DELEGATECALL statements in
	 *             the CFG
	 */
	public Set<Statement> getAllCall() {
		if (this.calls == null) {
			NodeList<CFG, Statement, Edge> cfgNodeList = this.getNodeList();
			Set<Statement> calls = new HashSet<>();

			for (Statement statement : cfgNodeList.getNodes()) {
				if (statement instanceof Call) {
					calls.add(statement);
				} else if (statement instanceof Staticcall) {
					calls.add(statement);
				} else if (statement instanceof Delegatecall) {
					calls.add(statement);
				}
			}

			return this.calls = calls;
		}

		return this.calls;
	}

	public Set<Statement> getAllJumpI() {
		if (this.jumpI == null) {
			NodeList<CFG, Statement, Edge> cfgNodeList = this.getNodeList();
			Set<Statement> jumpI = new HashSet<>();

			for (Statement statement : cfgNodeList.getNodes()) {
				if (statement instanceof Jumpi) {
					jumpI.add(statement);
				}
			}

			return this.jumpI = jumpI;
		}

		return this.jumpI;
	}

	/**
	 * Returns a set of all the LOGx statements in the CFG.
	 *
	 * @return a set of all the LOGx statements in the CFG
	 */
	public Set<Statement> getAllLogX() {
		if (logxs == null) {
			NodeList<CFG, Statement, Edge> cfgNodeList = this.getNodeList();
			Set<Statement> logxs = new HashSet<>();

			for (Statement statement : cfgNodeList.getNodes()) {
				if (statement instanceof Log0
						|| statement instanceof Log1
						|| statement instanceof Log2
						|| statement instanceof Log3
						|| statement instanceof Log4) {
					logxs.add(statement);
				}
			}

			return this.logxs = logxs;
		}

		return logxs;
	}

	/**
	 * Returns a set of all the SSTORE statements in the CFG.
	 *
	 * @return a set of all the SSTORE statements in the CFG
	 */
	public Set<Statement> getAllSstore() {
		if (sstores == null) {
			NodeList<CFG, Statement, Edge> cfgNodeList = this.getNodeList();
			Set<Statement> sstores = new HashSet<>();

			for (Statement statement : cfgNodeList.getNodes()) {
				if (statement instanceof Sstore) {
					sstores.add(statement);
				}
			}

			return this.sstores = sstores;
		}

		return sstores;
	}

	/**
	 * Returns a set of all the SHA3 statements in the CFG.
	 *
	 * @return a set of all the SHA3 statements in the CFG
	 */
	public Set<Statement> getAllSha3() {
		if (sha3s == null) {
			NodeList<CFG, Statement, Edge> cfgNodeList = this.getNodeList();
			Set<Statement> sha3s = new HashSet<>();

			for (Statement statement : cfgNodeList.getNodes()) {
				if (statement instanceof Sha3) {
					sha3s.add(statement);
				}
			}

			return this.sha3s = sha3s;
		}

		return sha3s;
	}

	/**
	 * Returns a set of all the JUMPDEST statements in the CFG.
	 *
	 * @return a set of all the JUMPDEST statements in the CFG
	 */
	public Set<Statement> getAllJumpdest() {
		return jumpDestsNodes;
	}

	/**
	 * Yields the program counters of all JUMPDEST statements.
	 *
	 * @return the program counters of all JUMPDEST statements
	 */
	public Set<Number> getAllJumpdestLocations() {
		if (jumpDestsNodesLocations == null)
			return jumpDestsNodesLocations = this.jumpDestsNodes.stream()
					.map(j -> new Number(((ProgramCounterLocation) j.getLocation()).getPc()))
					.collect(Collectors.toSet());
		else
			return jumpDestsNodesLocations;

	}

	/**
	 * Returns a set of all the JUMP and JUMPI statements in the CFG.
	 *
	 * @return a set of all the JUMP and JUMPI statements in the CFG
	 */
	public Set<Statement> getAllJumps() {
		return jumpNodes;
	}

	public int getOpcodeCount() {
		// -1 for the return statement, that it does not correspond to an actual
		// statement of the smart contract, but it is added by EVMLiSA
		return this.getNodesCount() - 1;
	}

	/**
	 * Returns a set of all the JUMP statements preceded by a PUSH statement in
	 * the CFG.
	 *
	 * @return a set of all the JUMP statements preceded by a PUSH statement in
	 *             the CFG
	 */
	public Set<Statement> getAllPushedJumps() {
		return pushedJumps;
	}

	@Override
	public <A extends AbstractState<A>> AnalyzedCFG<A> fixpoint(
			AnalysisState<A> singleton, Map<Statement, AnalysisState<A>> startingPoints,
			InterproceduralAnalysis<A> interprocedural, WorkingSet<Statement> ws,
			FixpointConfiguration conf,
			ScopeId id) throws FixpointException {
		// we disable optimizations for ascending phases if there is a
		// descending one: the latter will need full results to start applying
		// glbs/narrowings from a post-fixpoint
		boolean isOptimized = conf.optimize && conf.descendingPhaseType == DescendingPhaseType.NONE;
		Fixpoint<CFG, Statement, Edge, CompoundState<A>> fix = isOptimized
				? new OptimizedFixpoint<>(this, false, conf.hotspots)
				: new Fixpoint<>(this, false);
		EVMAscendingFixpoint<A> asc = new EVMAscendingFixpoint<>(this, interprocedural,
				conf.wideningThreshold);

		Map<Statement, CompoundState<A>> starting = new HashMap<>();
		StatementStore<A> bot = new StatementStore<>(singleton.bottom());
		startingPoints.forEach((st, state) -> starting.put(st, CompoundState.of(state, bot)));
		Map<Statement, CompoundState<A>> ascending = fix.fixpoint(starting, ws, asc);

		if (conf.descendingPhaseType == DescendingPhaseType.NONE)
			return flatten(isOptimized, singleton, startingPoints, interprocedural, id, ascending);

		fix = conf.optimize ? new OptimizedFixpoint<>(this, true, conf.hotspots) : new Fixpoint<>(this, true);
		Map<Statement, CompoundState<A>> descending;
		switch (conf.descendingPhaseType) {
		case GLB:
			// DescendingGLBFixpoint<A> dg = new DescendingGLBFixpoint<>(this,
			// conf.glbThreshold,
			// interprocedural);
			// descending = fix.fixpoint(starting, ws, dg, ascending);
			// break;
		case NARROWING:
			// DescendingNarrowingFixpoint<A> dn = new
			// DescendingNarrowingFixpoint<>(this, interprocedural);
			// descending = fix.fixpoint(starting, ws, dn, ascending);
			// break;
		case NONE:
		default:
			// should never happen
			descending = ascending;
			break;
		}

		return flatten(conf.optimize, singleton, startingPoints, interprocedural, id, descending);
	}

	private <V extends ValueDomain<V>,
			T extends TypeDomain<T>,
			A extends AbstractState<A>,
			H extends HeapDomain<H>> AnalyzedCFG<A> flatten(
					boolean isOptimized, AnalysisState<A> singleton,
					Map<Statement, AnalysisState<A>> startingPoints,
					InterproceduralAnalysis<A> interprocedural, ScopeId id,
					Map<Statement, CompoundState<A>> fixpointResults) {
		Map<Statement, AnalysisState<A>> finalResults = new HashMap<>(fixpointResults.size());
		for (Entry<Statement, CompoundState<A>> e : fixpointResults.entrySet()) {
			finalResults.put(e.getKey(), e.getValue().postState);
			for (Entry<Statement, AnalysisState<A>> ee : e.getValue().intermediateStates)
				finalResults.put(ee.getKey(), ee.getValue());
		}

		return isOptimized
				? new OptimizedAnalyzedCFG<A>(this, id, singleton, startingPoints, finalResults,
						interprocedural)
				: new AnalyzedCFG<>(this, id, singleton, startingPoints, finalResults);
	}

	@Override
	public void validate() throws ProgramValidationException {
		try {
			list.validate(entrypoints);
		} catch (ProgramValidationException e) {
			// we allow having nodes without incoming edges to not be entry
			// points
			if (!e.getMessage().contains("Unreachable node that is not marked as entrypoint:"))
				throw new ProgramValidationException("The matrix behind " + this + " is invalid", e);
		}

		// all entrypoints should be within the cfg
		if (!list.getNodes().containsAll(entrypoints))
			throw new ProgramValidationException(this + " has entrypoints that are not part of the graph: "
					+ new HashSet<>(entrypoints).retainAll(list.getNodes()));
	}

	/**
	 * Checks if the target statement is reachable from the start statement
	 * using depth-first search (DFS). Caches results to avoid redundant
	 * computations.
	 *
	 * @param start  The starting statement.
	 * @param target The target statement.
	 * 
	 * @return True if the target is reachable from the start, false otherwise.
	 */
	public boolean reachableFrom(Statement start, Statement target) {
		String key = this.hashCode() + "" + start.hashCode() + "" + target.hashCode();
		if (MyCache.getInstance().existsInReachableFrom(key)) {
			return MyCache.getInstance().isReachableFrom(key);
		}

		boolean result = dfs(start, target, new HashSet<>());
		MyCache.getInstance().addReachableFrom(key, result);
		return result;
	}

	public boolean reachableFromCrossingACrossChainEdge(Statement start, Statement target) {
		if (start.getCFG().equals(target.getCFG()))
			return false;
		return reachableFrom(start, target);
	}

	/**
	 * Performs a depth-first search (DFS) to determine if the target statement
	 * is reachable from the start statement.
	 *
	 * @param start   The starting statement.
	 * @param target  The target statement.
	 * @param visited A set of visited statements to avoid cycles.
	 * 
	 * @return True if the target is reachable from the start, false otherwise.
	 */
	private boolean dfs(Statement start, Statement target, Set<Statement> visited) {
		Deque<Statement> stack = new ArrayDeque<>();
		stack.push(start);

		while (!stack.isEmpty()) {
			Statement current = stack.pop();

			if (current.equals(target))
				return true;

			if (visited.add(current)) {
				for (Edge edge : list.getOutgoingEdges(current)) {
					Statement next = edge.getDestination();
					if (!visited.contains(next))
						stack.push(next);
				}
			}
		}

		return false;
	}

	/**
	 * Finds the furthest reachable SSTORE statements from a given start
	 * statement using BFS.
	 *
	 * @param start The starting statement.
	 * 
	 * @return A set of the furthest reachable SSTORE statements.
	 */
	public Set<Statement> getFurthestSstores(Statement start) {
		Deque<Statement> queue = new ArrayDeque<>();
		Set<Statement> visited = new HashSet<>();
		Set<Statement> last = new HashSet<>();

		queue.add(start);
		visited.add(start);

		while (!queue.isEmpty()) {
			Statement current = queue.poll();
			if (current instanceof Sstore) {
				last.add(current);
			}

			for (Edge edge : list.getOutgoingEdges(current)) {
				Statement next = edge.getDestination();
				if (visited.add(next)) {
					queue.add(next);
				}
			}
		}
		return last;
	}

	/**
	 * Checks if the target statement is reachable from the start statement
	 * following only sequential edges. Ignores jumps.
	 *
	 * @param start  The starting statement.
	 * @param target The target statement.
	 * 
	 * @return True if the target is sequentially reachable from the start,
	 *             false otherwise.
	 */
	public boolean reachableFromSequentially(Statement start, Statement target) {
		String key = this.hashCode() + "" + start.hashCode() + "" + target.hashCode() + "sequentially";
		if (MyCache.getInstance().existsInReachableFrom(key)) {
			return MyCache.getInstance().isReachableFrom(key);
		}

		boolean result = dfsSequential(start, target, new HashSet<>());
		MyCache.getInstance().addReachableFrom(key, result);
		return result;
	}

	/**
	 * Performs a depth-first search (DFS) to determine if the target statement
	 * is sequentially reachable from the start statement. Ignores jumps.
	 *
	 * @param start   The starting statement.
	 * @param target  The target statement.
	 * @param visited A set of visited statements to avoid cycles.
	 * 
	 * @return True if the target is sequentially reachable from the start,
	 *             false otherwise.
	 */
	private boolean dfsSequential(Statement start, Statement target, Set<Statement> visited) {
		Deque<Statement> stack = new ArrayDeque<>();
		stack.push(start);

		while (!stack.isEmpty()) {
			Statement current = stack.pop();

			if (current.equals(target))
				return true;

			if (visited.add(current)) {
				for (Edge edge : list.getOutgoingEdges(current)) {
					if (edge.getSource() instanceof Jumpi || edge.getSource() instanceof Jump)
						continue;
					Statement next = edge.getDestination();
					if (!visited.contains(next))
						stack.push(next);
				}
			}
		}

		return false;
	}

	/**
	 * The method performs a depth-first search (DFS) and identifies `Push`
	 * statements containing function selectors.
	 *
	 * @param start      The starting statement for the search.
	 * @param signatures A set of signatures and their corresponding function
	 *                       selectors.
	 *
	 * @return A set of pairs where each pair consists of a function signature
	 *             (from the ABI) and the corresponding statement in the CFG.
	 */
	public Set<Pair<String, Statement>> findMatchingStatements(Statement start,
			Set<Pair<String, String>> signatures) {
		Set<Pair<String, Statement>> matchingStatements = new HashSet<>();
		Set<Statement> visited = new HashSet<>();
		Stack<Statement> stack = new Stack<>();
		stack.push(start);

		while (!stack.isEmpty()) {
			Statement current = stack.pop();

			if (!visited.contains(current)) {
				visited.add(current);

				if (current instanceof Push)
					for (Pair<String, String> signature : signatures)
						if (current.toString().contains(signature.getRight()))
							matchingStatements.add(Pair.of(signature.getLeft(), current));

				Collection<Edge> outgoingEdges = list.getOutgoingEdges(current);
				for (Edge edge : outgoingEdges) {
					Statement next = edge.getDestination();
					if (!visited.contains(next))
						stack.push(next);
				}
			}
		}

		return matchingStatements;
	}

	public boolean reachableFromCrossing(Statement start, Statement target, Set<Statement> statements) {
		return dfsCrossing(start, target, new HashSet<>(), statements);
	}

	/**
	 * Check whether all paths from {@code start} to {@code target} contain at
	 * least one {@code statements} statement. This method explores all possible
	 * paths using a depth-first search (DFS). If there is at least one path
	 * where a required statement is missing, the method returns {@code false}.
	 *
	 * @param start      The starting statement of the search.
	 * @param target     The target statement.
	 * @param visited    A set of visited statements to avoid cycles.
	 * @param statements The set of statements that must be present in all
	 *                       paths.
	 *
	 * @return {@code true} if all paths contain all statements, otherwise
	 *             {@code false}.
	 */
	private boolean dfsCrossing(Statement start, Statement target, Set<Statement> visited, Set<Statement> statements) {
		boolean foundTarget = false;
		Set<Statement> pathStatements = new HashSet<>();

		Stack<List<Statement>> stack = new Stack<>();
		stack.push(Collections.singletonList(start));

		while (!stack.isEmpty()) {
			List<Statement> path = stack.pop();
			Statement current = path.get(path.size() - 1);

			if (visited.contains(current)) {
				continue;
			}

			visited.add(current);
			pathStatements.add(current);

			if (current.equals(target)) {
				foundTarget = true;

				// Check if this specific path contains at least a statement
				boolean contains = false;
				for (Statement statement : statements) {
					if (pathStatements.contains(statement)) {
						contains = true;
						break;
					}
				}
				if (!contains)
					return false;
			}

			Collection<Edge> outgoingEdges = list.getOutgoingEdges(current);
			for (Edge edge : outgoingEdges) {
				Statement next = edge.getDestination();
				if (!visited.contains(next)) {
					List<Statement> newPath = new ArrayList<>(path);
					newPath.add(next);
					stack.push(newPath);
				}
			}
		}

		return foundTarget;
	}

	/**
	 * Determines if the target statement is reachable from the start statement
	 * without triggering any of the specified statement types.
	 *
	 * @param start      the starting statement from which the reachability is
	 *                       checked
	 * @param target     the target statement to check for reachability
	 * @param avoidTypes the types of statements to avoid during traversal
	 * 
	 * @return true if the target statement is reachable from the start without
	 *             triggering any of the specified statement types, false
	 *             otherwise
	 */
	public boolean reachableFromWithoutTypes(Statement start, Statement target, Set<Class<?>> avoidTypes) {
		return dfsWithoutTypes(start, target, new HashSet<>(), avoidTypes);
	}

	/**
	 * Performs a depth-first search (DFS) to determine if a path exists from a
	 * start statement to a target statement in a graph, avoiding any paths that
	 * involve edges with a source node of the specified types.
	 *
	 * @param start      the starting statement for the DFS traversal
	 * @param target     the target statement to reach during the DFS traversal
	 * @param visited    a set of already visited statements to avoid cycles
	 *                       during the traversal
	 * @param avoidTypes the types of statements to avoid during traversal
	 * 
	 * @return true if a path exists from the start statement to the target
	 *             statement without traversing through edges originating from
	 *             nodes of the specified types, false otherwise
	 */
	private boolean dfsWithoutTypes(Statement start, Statement target, Set<Statement> visited,
			Set<Class<?>> avoidTypes) {
		Stack<Statement> stack = new Stack<>();
		stack.push(start);

		while (!stack.isEmpty()) {
			Statement current = stack.pop();

			if (current.equals(target))
				return true;

			if (!visited.contains(current)) {
				visited.add(current);

				Collection<Edge> outgoingEdges = list.getOutgoingEdges(current);

				for (Edge edge : outgoingEdges) {
					if (avoidTypes.stream().anyMatch(type -> type.isInstance(edge.getSource())))
						continue;
					Statement next = edge.getDestination();
					if (!visited.contains(next))
						stack.push(next);
				}
			}
		}

		return false;
	}

	public boolean reachableFromWithoutStatements(Statement start, Statement target, Set<Statement> avoidStatements) {
		return dfsWithoutStatements(start, target, new HashSet<>(), avoidStatements);
	}

	private boolean dfsWithoutStatements(Statement start, Statement target, Set<Statement> visited,
			Set<Statement> avoidStatements) {
		Stack<Statement> stack = new Stack<>();
		stack.push(start);

		while (!stack.isEmpty()) {
			Statement current = stack.pop();

			if (current.equals(target))
				return true;

			if (!visited.contains(current)) {
				visited.add(current);

				Collection<Edge> outgoingEdges = list.getOutgoingEdges(current);

				for (Edge edge : outgoingEdges) {
					if (avoidStatements.contains(edge.getDestination()))
						continue;
					Statement next = edge.getDestination();
					if (!visited.contains(next))
						stack.push(next);
				}
			}
		}

		return false;
	}

	/**
	 * Identifies all possible exit points for a function starting from a given
	 * statement. Performs a depth-first search from the start statement and
	 * collects statements that represent function exits based on their type and
	 * whether the function returns a value.
	 *
	 * @param start  The starting statement for the search, usually the function
	 *                   entry point.
	 * @param isVoid Whether the function has no return value.
	 * 
	 * @return A set of statements that represent function exit points.
	 */
	public Set<Statement> getFunctionExitPoints(Statement start, boolean isVoid) {
		Stack<Statement> stack = new Stack<>();
		Set<Statement> visited = new HashSet<>();
		Set<Statement> functionExitPoints = new HashSet<>();

		stack.push(start);

		while (!stack.isEmpty()) {
			Statement current = stack.pop();

			if (!visited.contains(current)) {
				visited.add(current);

				Collection<Edge> outgoingEdges = list.getOutgoingEdges(current);

				for (Edge edge : outgoingEdges) {
					Statement next = edge.getDestination();
					if (!visited.contains(next)) {
						stack.push(next);

						if (next instanceof Invalid
								|| next instanceof Revert)
							functionExitPoints.add(next);

						if (isVoid && next instanceof Stop)
							functionExitPoints.add(next);

						if (!isVoid && next instanceof Return)
							functionExitPoints.add(next);
					}
				}
			}
		}

		return functionExitPoints;
	}

	/**
	 * Finds the closest Jumpdest statement reachable from a given start
	 * statement. Performs a breadth-first search to find the nearest Jumpdest
	 * statement along a true edge.
	 *
	 * @param start The starting statement for the search.
	 * 
	 * @return The closest Jumpdest statement along a true edge, or null if none
	 *             is found.
	 */
	public Statement getCloserJumpdest(Statement start) {
		Deque<Statement> queue = new ArrayDeque<>();
		Set<Statement> visited = new HashSet<>();

		queue.add(start);

		while (!queue.isEmpty()) {
			Statement current = queue.poll();

			if (!visited.contains(current)) {
				visited.add(current);

				Collection<Edge> outgoingEdges = list.getOutgoingEdges(current);

				for (Edge edge : outgoingEdges) {
					Statement next = edge.getDestination();
					if (!visited.contains(next)) {
						queue.push(next);
						if (next instanceof Jumpdest && edge instanceof TrueEdge)
							return next;
					}
				}
			}
		}

		return null;
	}
}