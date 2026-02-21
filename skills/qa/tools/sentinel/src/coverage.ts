import * as fs from "node:fs";
import matter from "gray-matter";
import type {
  RunFile,
  RunFrontmatter,
  ScenarioResult,
  Spec,
  SpecCoverage,
  AreaCoverage,
  Regression,
  ResolvedPaths,
} from "./types.js";
import { getLatestRunDirectory, getPreviousRunDirectory, findRunFiles } from "./evidence.js";

/**
 * Parse a single .run.md file.
 */
export function parseRunFile(filePath: string): RunFile {
  const raw = fs.readFileSync(filePath, "utf-8");
  const { data, content } = matter(raw);

  const frontmatter = data as RunFrontmatter;
  const results: ScenarioResult[] = [];

  // Parse the markdown table for scenario results
  const lines = content.split("\n");
  for (const line of lines) {
    // Match table row: | SCENARIO-ID | STATUS | DURATION | NOTES |
    const match = line.match(/^\|\s*([A-Z][\w-]+(?:-\d+)?)\s*\|\s*(PASS|FAIL|SKIP)\s*\|\s*([^|]*)\s*\|\s*([^|]*)\s*\|$/);
    if (match) {
      results.push({
        scenarioId: match[1].trim(),
        status: match[2].trim() as ScenarioResult["status"],
        duration: match[3].trim(),
        notes: match[4].trim(),
      });
    }
  }

  return { frontmatter, filePath, results };
}

/**
 * Parse all run files in a run directory.
 */
export function parseRunDirectory(runDir: string): RunFile[] {
  return findRunFiles(runDir).map(parseRunFile);
}

/**
 * Compute coverage for a single spec based on its most recent run file.
 */
export function computeSpecCoverage(spec: Spec, runFiles: RunFile[]): SpecCoverage {
  const runFile = runFiles.find((r) => r.frontmatter.spec === spec.frontmatter.id);

  if (!runFile) {
    return {
      specId: spec.frontmatter.id,
      area: spec.frontmatter.area,
      passed: 0,
      failed: 0,
      skipped: 0,
      total: spec.scenarios.length,
      coverage: 0,
      neverTested: true,
    };
  }

  const passed = runFile.frontmatter.passed;
  const failed = runFile.frontmatter.failed;
  const skipped = runFile.frontmatter.skipped;
  const total = passed + failed + skipped;

  return {
    specId: spec.frontmatter.id,
    area: spec.frontmatter.area,
    passed,
    failed,
    skipped,
    total: total || spec.scenarios.length,
    coverage: total > 0 ? passed / total : 0,
    neverTested: false,
  };
}

/**
 * Compute coverage grouped by area.
 */
export function computeAreaCoverage(specs: Spec[], runFiles: RunFile[]): AreaCoverage[] {
  const specCoverages = specs.map((s) => computeSpecCoverage(s, runFiles));

  const areaMap = new Map<string, SpecCoverage[]>();
  for (const sc of specCoverages) {
    const existing = areaMap.get(sc.area) || [];
    existing.push(sc);
    areaMap.set(sc.area, existing);
  }

  const areas: AreaCoverage[] = [];
  for (const [area, specCovers] of areaMap) {
    const passed = specCovers.reduce((sum, s) => sum + s.passed, 0);
    const failed = specCovers.reduce((sum, s) => sum + s.failed, 0);
    const skipped = specCovers.reduce((sum, s) => sum + s.skipped, 0);
    const total = passed + failed + skipped;

    areas.push({
      area,
      passed,
      failed,
      skipped,
      total,
      coverage: total > 0 ? passed / total : 0,
      specs: specCovers,
    });
  }

  return areas.sort((a, b) => a.area.localeCompare(b.area));
}

/**
 * Compute overall coverage across all specs.
 */
export function computeOverallCoverage(areas: AreaCoverage[]): { passed: number; failed: number; skipped: number; total: number; coverage: number } {
  const passed = areas.reduce((sum, a) => sum + a.passed, 0);
  const failed = areas.reduce((sum, a) => sum + a.failed, 0);
  const skipped = areas.reduce((sum, a) => sum + a.skipped, 0);
  const total = passed + failed + skipped;

  return {
    passed,
    failed,
    skipped,
    total,
    coverage: total > 0 ? passed / total : 0,
  };
}

/**
 * Detect regressions by comparing the two most recent runs.
 */
export function detectRegressions(paths: ResolvedPaths): Regression[] {
  const latestDir = getLatestRunDirectory(paths);
  const previousDir = getPreviousRunDirectory(paths);

  if (!latestDir || !previousDir) {
    return [];
  }

  const latestRuns = parseRunDirectory(latestDir);
  const previousRuns = parseRunDirectory(previousDir);

  const regressions: Regression[] = [];

  for (const current of latestRuns) {
    const previous = previousRuns.find((r) => r.frontmatter.spec === current.frontmatter.spec);
    if (!previous) continue;

    // Build lookup of previous results
    const previousResults = new Map<string, ScenarioResult>();
    for (const r of previous.results) {
      previousResults.set(r.scenarioId, r);
    }

    // Check for PASS -> FAIL transitions
    for (const result of current.results) {
      const prev = previousResults.get(result.scenarioId);
      if (prev && prev.status === "PASS" && result.status === "FAIL") {
        regressions.push({
          specId: current.frontmatter.spec,
          scenarioId: result.scenarioId,
          previousStatus: "PASS",
          currentStatus: "FAIL",
          notes: result.notes,
        });
      }
    }
  }

  return regressions;
}
