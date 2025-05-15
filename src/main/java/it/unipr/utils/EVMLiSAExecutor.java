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
	private static ExecutorService _executor = Executors.newFixedThreadPool(CORES);

	private static long tasksInQueue = 0;
	private static long tasksExecuted = 0;
	private static long tasksTimedOut = 0;

	/**
	 * Submits a task for execution in the thread pool.
	 *
	 * @param task the task to be executed
	 * 
	 * @return a Future representing the pending result of the task
	 */
	public static Future<?> submit(Runnable task) {
		return _executor.submit(new EVMLiSAExecutorTask(task));
	}

	/**
	 * Submits a list of tasks for execution in the thread pool.
	 *
	 * @param tasks the list of tasks to be executed
	 * 
	 * @return a list of Future objects representing the pending results of the
	 *             tasks
	 */
	public static List<Future<?>> submitAll(List<Runnable> tasks) {
		List<Future<?>> futures = new ArrayList<>();

		for (Runnable task : tasks)
			futures.add(submit(new EVMLiSAExecutorTask(task)));

		return futures;
	}

	/**
	 * Executes a main task asynchronously and schedules additional tasks upon
	 * its completion.
	 *
	 * @param mainTask       the main task to execute
	 * @param secondaryTasks additional tasks to execute after the main task
	 * 
	 * @return a CompletableFuture that completes when all tasks are finished
	 */
	public static CompletableFuture<Void> runAsync(Runnable mainTask, Runnable... secondaryTasks) {
		return runAsync(mainTask, Set.of(secondaryTasks));
	}

	/**
	 * Executes a main task asynchronously and schedules additional tasks upon
	 * its completion.
	 *
	 * @param mainTask       the main task to execute
	 * @param secondaryTasks additional tasks to execute after the main task
	 * 
	 * @return a CompletableFuture that completes when all tasks are finished
	 */
	public static CompletableFuture<Void> runAsync(Runnable mainTask, Set<Runnable> secondaryTasks) {
		return CompletableFuture.runAsync(new EVMLiSAExecutorTask(mainTask), _executor)
				.thenCompose(ignored -> {
					List<CompletableFuture<Void>> checkerFutures = new ArrayList<>();
					for (Runnable secondaryTask : secondaryTasks)
						checkerFutures
								.add(CompletableFuture.runAsync(new EVMLiSAExecutorTask(secondaryTask), _executor));
					return CompletableFuture.allOf(checkerFutures.toArray(new CompletableFuture[0]));
				});
	}

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
				e.printStackTrace();
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
	 * Shuts down the executor service, preventing new tasks from being
	 * submitted.
	 */
	public static void shutdown() {
		_executor.shutdown();
	}

	public static void setCoresAvailable(int cores) {
		if (cores > Runtime.getRuntime().availableProcessors())
			cores = Runtime.getRuntime().availableProcessors() - 1;

		if (CORES == cores)
			return;

		shutdown();
		CORES = Math.max(cores, 1);
		_executor = Executors.newFixedThreadPool(CORES);
	}

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