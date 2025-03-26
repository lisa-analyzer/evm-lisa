package it.unipr.utils;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.*;

public class EVMLiSAExecutor {
	private static final int CORES = Runtime.getRuntime().availableProcessors() - 1;
	private static final ExecutorService _executor = Executors.newFixedThreadPool(CORES);

	/**
	 * Submits a task for execution in the thread pool.
	 *
	 * @param task the task to be executed
	 * 
	 * @return a Future representing the pending result of the task
	 */
	public static Future<?> submit(Runnable task) {
		return _executor.submit(task);
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
			futures.add(submit(task));

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
		return CompletableFuture.runAsync(mainTask, _executor)
				.thenCompose(ignored -> {
					List<CompletableFuture<Void>> checkerFutures = new ArrayList<>();
					for (Runnable r : secondaryTasks) {
						checkerFutures.add(CompletableFuture.runAsync(r, _executor));
					}
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
	 * Shuts down the executor service, preventing new tasks from being
	 * submitted.
	 */
	public static void shutdown() {
		_executor.shutdown();
	}

}