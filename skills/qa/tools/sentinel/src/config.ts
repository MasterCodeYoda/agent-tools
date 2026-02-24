import * as fs from "node:fs";
import * as path from "node:path";
import { parse as parseYaml } from "yaml";
import type { SentinelConfig, ResolvedPaths } from "./types.js";

const CONFIG_FILENAME = "sentinel.config.yaml";

/**
 * Walk up from startDir looking for sentinel.config.yaml in the project root
 * or tests/qa-sentinel/. Returns the absolute path to the config file, or null if not found.
 */
export function findConfigFile(startDir: string = process.cwd()): string | null {
  let dir = path.resolve(startDir);
  const root = path.parse(dir).root;

  while (true) {
    // Check project root first
    const rootCandidate = path.join(dir, CONFIG_FILENAME);
    if (fs.existsSync(rootCandidate)) {
      return rootCandidate;
    }
    // Fall back to tests/qa-sentinel/
    const legacyCandidate = path.join(dir, "tests", "qa-sentinel", CONFIG_FILENAME);
    if (fs.existsSync(legacyCandidate)) {
      return legacyCandidate;
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
  const requiredKeys = ["app", "specs"] as const;
  for (const key of requiredKeys) {
    if (!parsed[key]) {
      throw new Error(`Missing required config section: "${key}" in ${configPath}`);
    }
  }

  if (!parsed.specs.nl_dir || !parsed.specs.tests_dir) {
    throw new Error(`Missing required path in config: specs.nl_dir and specs.tests_dir are both required`);
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
    nlSpecsDir: path.resolve(configDir, config.specs.nl_dir),
    testsDir: path.resolve(configDir, config.specs.tests_dir),
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
      `or ensure ${CONFIG_FILENAME} exists in the project root or tests/qa-sentinel/.`
    );
  }
  const config = loadConfig(configPath);
  const paths = resolvePaths(config, configPath);
  return { config, paths, configPath };
}
