import * as fs from "node:fs";
import * as path from "node:path";
import { parse as parseYaml } from "yaml";
import type { SentinelConfig, ResolvedPaths } from "./types.js";

const CONFIG_FILENAME = "sentinel.config.yaml";
const CONFIG_RELATIVE_DIR = "tests/qa-sentinel";

/**
 * Walk up from startDir looking for tests/qa-sentinel/sentinel.config.yaml.
 * Returns the absolute path to the config file, or null if not found.
 */
export function findConfigFile(startDir: string = process.cwd()): string | null {
  let dir = path.resolve(startDir);
  const root = path.parse(dir).root;

  while (true) {
    const candidate = path.join(dir, CONFIG_RELATIVE_DIR, CONFIG_FILENAME);
    if (fs.existsSync(candidate)) {
      return candidate;
    }
    const parent = path.dirname(dir);
    if (parent === dir || dir === root) {
      return null;
    }
    dir = parent;
  }
}

/**
 * Load and parse the sentinel config file.
 */
export function loadConfig(configPath: string): SentinelConfig {
  const raw = fs.readFileSync(configPath, "utf-8");
  const parsed = parseYaml(raw) as SentinelConfig;

  // Validate required top-level keys
  const requiredKeys = ["app", "paths"] as const;
  for (const key of requiredKeys) {
    if (!parsed[key]) {
      throw new Error(`Missing required config section: "${key}" in ${configPath}`);
    }
  }

  if (!parsed.paths.specs_dir || !parsed.paths.runs_dir || !parsed.paths.reports_dir) {
    throw new Error(`Missing required path in config: specs_dir, runs_dir, and reports_dir are all required`);
  }

  return parsed;
}

/**
 * Resolve relative paths in config to absolute paths based on the config file location.
 */
export function resolvePaths(config: SentinelConfig, configPath: string): ResolvedPaths {
  const configDir = path.dirname(configPath);
  return {
    configDir,
    specsDir: path.resolve(configDir, config.paths.specs_dir),
    runsDir: path.resolve(configDir, config.paths.runs_dir),
    reportsDir: path.resolve(configDir, config.paths.reports_dir),
  };
}

/**
 * Load config and resolve paths in one step. Throws if config not found.
 */
export function loadAndResolve(startDir?: string): { config: SentinelConfig; paths: ResolvedPaths; configPath: string } {
  const configPath = findConfigFile(startDir);
  if (!configPath) {
    throw new Error(
      `Could not find ${CONFIG_FILENAME}. Run "sentinel init" to set up a project, ` +
      `or ensure tests/qa-sentinel/${CONFIG_FILENAME} exists in the current directory or an ancestor.`
    );
  }
  const config = loadConfig(configPath);
  const paths = resolvePaths(config, configPath);
  return { config, paths, configPath };
}
