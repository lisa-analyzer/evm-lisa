package it.unipr.utils;

import java.util.*;
import java.util.concurrent.*;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class EVMLiSAExecutor {
	private static final Logger log = LogManager.getLogger(EVMLiSAExecutor.class);

	private static int CORES = (Runtime.getRuntime().availableProcessors() > 1)
			? Runtime.getRuntime().availableProcessors() - 1
			: 1;
	private static final ConcurrentMap<Class<?>, ExecutorService> ownerExecutors = new ConcurrentHashMap<>();

	private static long tasksInQueue = 0;
	private static long tasksExecuted = 0;
	private static long tasksTimedOut = 0;

	/**
	 * Waits for the completion of all provided CompletableFutures.
	 *
	 * @param futures the list of CompletableFutures to wait for
	 */
	public static void awaitCompletionCompletableFutures(List<CompletableFuture<Void>> futures) {
		CompletableFuture.allOf(futures.toArray(new CompletableFuture[0])).join();
	}

	/**
	 * Waits for the completion of all provided {@code CompletableFuture<Void>},
	 * applying a timeout to each future.
	 *
	 * @param futures the list of {@code CompletableFuture<Void>} instances to
	 *                    await
	 * @param timeout the maximum time to wait for each future to complete
	 * @param unit    the time unit of the {@code timeout} parameter
	 */
	public static void awaitCompletionCompletableFutures(List<CompletableFuture<Void>> futures, long timeout,
			TimeUnit unit) {
		CompletableFuture.allOf(futures.stream()
				.map(f -> f.orTimeout(timeout, unit)
						.exceptionally(ex -> {
							log.warn("Future timed out after {} {}. Skipping this task.", timeout, unit);

							synchronized (EVMLiSAExecutor.class) {
								++tasksTimedOut;
							}

							return null;
						}))
				.toArray(CompletableFuture[]::new)).join();
	}

	/**
	 * Waits for the completion of all provided {@code Future} objects.
	 *
	 * @param futures the list of {@code Future} objects to wait for
	 */
	public static void awaitCompletionFutures(List<Future<?>> futures) {
		for (Future<?> future : futures) {
			try {
				future.get();
			} catch (ExecutionException e) {
				System.err.println(JSONManager.throwNewError("Error during task execution: " + e.getMessage()));
				System.exit(1);
			} catch (InterruptedException ie) {
				System.err.println(JSONManager.throwNewError("Interrupted during task execution: " + ie.getMessage()));
				System.exit(1);
			}
		}
	}

	/**
	 * Waits for the completion of all provided futures with a timeout for each.
	 * If a future does not complete within the specified timeout, it is
	 * skipped.
	 *
	 * @param futures the list of futures to wait for
	 * @param timeout the maximum time to wait for each future
	 * @param unit    the time unit of the timeout argument
	 */
	public static void awaitCompletionFutures(List<Future<?>> futures, long timeout, TimeUnit unit) {
		for (Future<?> future : futures) {
			try {
				future.get(timeout, unit);
			} catch (TimeoutException te) {
				log.warn("Future timed out after {} {}. Skipping this task.", timeout, unit);
			} catch (ExecutionException e) {
				System.err.println(JSONManager.throwNewError("Error during task execution: " + e.getMessage()));
				System.exit(1);
			} catch (InterruptedException ie) {
				System.err.println(JSONManager.throwNewError("Interrupted during task execution: " + ie.getMessage()));
				System.exit(1);
			}
		}
	}

	/**
	 * Creates (if absent) and returns an ExecutorService associated with the
	 * given owner class. The created executor will have {@code threads} worker
	 * threads. If an executor is already present for the owner, it is returned
	 * unchanged.
	 *
	 * @param owner   the class that will own the executor
	 * @param threads number of threads for the executor (min 1)
	 *
	 * @return the ExecutorService associated with the owner
	 */
	public static ExecutorService createExecutorFor(Class<?> owner, int threads) {
		int t = Math.max(1, threads);
		return ownerExecutors.computeIfAbsent(owner, k -> Executors.newFixedThreadPool(t));
	}

	/**
	 * Returns the ExecutorService associated with the owner class, creating a
	 * default single-threaded executor if none exists.
	 *
	 * @param owner the class that will own the executor
	 *
	 * @return the ExecutorService associated with the owner
	 */
	public static ExecutorService getExecutorFor(Class<?> owner) {
		return ownerExecutors.computeIfAbsent(owner, k -> Executors.newFixedThreadPool(CORES));
	}

	/**
	 * Submits a task to the executor associated with the given owner class. If
	 * no executor exists for the owner, a default one is created.
	 *
	 * @param owner the class owning the executor
	 * @param task  the runnable task to submit
	 *
	 * @return a Future representing pending completion of the task
	 */
	public static Future<?> submit(Class<?> owner, Runnable task) {
		ExecutorService ex = getExecutorFor(owner);
		return ex.submit(new EVMLiSAExecutorTask(task));
	}

	/**
	 * Shuts down the executor associated with the given owner class. This
	 * removes the executor from the internal map and calls shutdown on it. If
	 * no executor is present, this is a no-op.
	 *
	 * @param owner the class whose executor should be shutdown
	 */
	public static void shutdown(Class<?> owner) {
		ExecutorService ex = ownerExecutors.remove(owner);
		if (ex != null)
			ex.shutdown();
	}

	/**
	 * Shuts down all owner-bound executors.
	 */
	public static void shutdownAllOwners() {
		for (Map.Entry<Class<?>, ExecutorService> e : ownerExecutors.entrySet()) {
			executorShutdownQuiet(e.getValue());
		}
		ownerExecutors.clear();
	}

	/**
	 * Attempts to shut down the provided executor quietly, ignoring any
	 * exceptions. This is a private helper used when shutting down multiple
	 * executors.
	 *
	 * @param ex the executor service to shut down
	 */
	private static void executorShutdownQuiet(ExecutorService ex) {
		try {
			ex.shutdown();
		} catch (Exception ignored) {
		}
	}

	/**
	 * Updates the number of cores available for per-owner executors. If the
	 * provided value differs from the current configuration, all owner-bound
	 * executors are shutdown and the internal core count is updated.
	 *
	 * @param cores desired number of cores (will be clamped to a minimum of 1
	 *                  and at most the number of available processors - 1)
	 */
	public static void setCoresAvailable(int cores) {
		if (cores > Runtime.getRuntime().availableProcessors())
			cores = Runtime.getRuntime().availableProcessors() - 1;

		if (CORES == cores)
			return;

		shutdownAllOwners();
		CORES = Math.max(cores, 1);
	}

	/**
	 * Gets the current number of cores configured for owner executors.
	 *
	 * @return the configured core count
	 */
	public static int getCoresAvailable() {
		return CORES;
	}

	/**
	 * A private static class that wraps a {@link Runnable} task and manages
	 * task execution tracking. It increments the count of tasks in the queue
	 * upon creation and decrements it upon completion.
	 */
	private static class EVMLiSAExecutorTask implements Runnable {
		private final Runnable task;

		/**
		 * Creates a new {@code MyTask} instance wrapping the given task. It
		 * increments the count of tasks in the queue upon instantiation.
		 *
		 * @param task the {@code Runnable} task to be executed.
		 */
		public EVMLiSAExecutorTask(Runnable task) {
			this.task = task;

			synchronized (EVMLiSAExecutor.class) {
				++tasksInQueue;
				++tasksExecuted;
			}
		}

		/**
		 * Executes the wrapped task and updates the task queue count.
		 */
		@Override
		public void run() {
			task.run();

			synchronized (EVMLiSAExecutor.class) {
				--tasksInQueue;
			}

			if (tasksInQueue % 10 == 0 || tasksInQueue < 100)
				log.debug("{} tasks in progress, {} tasks in queue to be analyzed.",
						((tasksInQueue - CORES) > 0 ? CORES : tasksInQueue),
						((tasksInQueue - CORES) > 0 ? (tasksInQueue - CORES) : 0));
		}
	}

}