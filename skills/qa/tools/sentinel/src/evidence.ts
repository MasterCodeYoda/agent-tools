import * as fs from "node:fs";
import * as path from "node:path";
import type { SentinelConfig, ResolvedPaths } from "./types.js";

/**
 * Generate a timestamp string in YYYY-MM-DD-HHmmss format.
 */
function makeTimestamp(date: Date = new Date()): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return [
    date.getFullYear(),
    "-",
    pad(date.getMonth() + 1),
    "-",
    pad(date.getDate()),
    "-",
    pad(date.getHours()),
    pad(date.getMinutes()),
    pad(date.getSeconds()),
  ].join("");
}

/**
 * Create a new timestamped run directory with results/ and evidence/ subdirectories.
 * Returns the absolute path to the run directory.
 */
export function createRunDirectory(paths: ResolvedPaths): string {
  const timestamp = makeTimestamp();
  const runDir = path.join(paths.runsDir, timestamp);
  const resultsDir = path.join(runDir, "results");
  const evidenceDir = path.join(runDir, "evidence");

  fs.mkdirSync(resultsDir, { recursive: true });
  fs.mkdirSync(evidenceDir, { recursive: true });

  return runDir;
}

/**
 * List all run directories sorted by timestamp (newest first).
 */
export function listRunDirectories(paths: ResolvedPaths): string[] {
  if (!fs.existsSync(paths.runsDir)) {
    return [];
  }

  return fs
    .readdirSync(paths.runsDir)
    .filter((entry) => {
      const full = path.join(paths.runsDir, entry);
      return fs.statSync(full).isDirectory() && /^\d{4}-\d{2}-\d{2}-\d{6}$/.test(entry);
    })
    .sort()
    .reverse()
    .map((entry) => path.join(paths.runsDir, entry));
}

/**
 * Get the most recent run directory, or null if none exist.
 */
export function getLatestRunDirectory(paths: ResolvedPaths): string | null {
  const dirs = listRunDirectories(paths);
  return dirs.length > 0 ? dirs[0] : null;
}

/**
 * Get the second most recent run directory (for regression comparison), or null.
 */
export function getPreviousRunDirectory(paths: ResolvedPaths): string | null {
  const dirs = listRunDirectories(paths);
  return dirs.length > 1 ? dirs[1] : null;
}

/**
 * Clean up old run directories, keeping only the most recent `keep` count.
 */
export function cleanupOldRuns(paths: ResolvedPaths, keep: number): string[] {
  const dirs = listRunDirectories(paths);
  const toRemove = dirs.slice(keep);

  for (const dir of toRemove) {
    fs.rmSync(dir, { recursive: true, force: true });
  }

  return toRemove;
}

/**
 * Find all .run.md files in a run directory's results/ subdirectory.
 */
export function findRunFiles(runDir: string): string[] {
  const resultsDir = path.join(runDir, "results");
  if (!fs.existsSync(resultsDir)) {
    return [];
  }

  return fs
    .readdirSync(resultsDir)
    .filter((f) => f.endsWith(".run.md"))
    .map((f) => path.join(resultsDir, f))
    .sort();
}
