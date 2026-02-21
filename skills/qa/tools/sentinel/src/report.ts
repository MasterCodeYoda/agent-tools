import * as fs from "node:fs";
import * as path from "node:path";
import type { Spec, ResolvedPaths, AreaCoverage, Regression, SpecCoverage } from "./types.js";
import { getLatestRunDirectory, parseRunDirectory } from "./evidence.js";
import { computeAreaCoverage, computeOverallCoverage, detectRegressions } from "./coverage.js";

function pct(n: number): string {
  return `${Math.round(n * 100)}%`;
}

function coverageBar(coverage: number, width: number = 20): string {
  const filled = Math.round(coverage * width);
  return "█".repeat(filled) + "░".repeat(width - filled);
}

/**
 * Generate the full coverage report as a markdown string.
 */
export function generateReport(
  specs: Spec[],
  paths: ResolvedPaths,
  config: { appName: string },
): string {
  const latestDir = getLatestRunDirectory(paths);
  const runFiles = latestDir ? parseRunDirectory(latestDir) : [];
  const areas = computeAreaCoverage(specs, runFiles);
  const overall = computeOverallCoverage(areas);
  const regressions = detectRegressions(paths);

  const runTimestamp = latestDir ? path.basename(latestDir) : "N/A";
  const now = new Date().toISOString();

  const lines: string[] = [];

  // Header
  lines.push(`# Sentinel Coverage Report`);
  lines.push(``);
  lines.push(`**Application:** ${config.appName}`);
  lines.push(`**Generated:** ${now}`);
  lines.push(`**Latest Run:** ${runTimestamp}`);
  lines.push(``);

  // Overall summary
  lines.push(`## Overall Coverage`);
  lines.push(``);
  lines.push(`${coverageBar(overall.coverage)} ${pct(overall.coverage)}`);
  lines.push(``);
  lines.push(`| Metric | Count |`);
  lines.push(`|--------|-------|`);
  lines.push(`| Total Scenarios | ${overall.total} |`);
  lines.push(`| Passed | ${overall.passed} |`);
  lines.push(`| Failed | ${overall.failed} |`);
  lines.push(`| Skipped | ${overall.skipped} |`);
  lines.push(``);

  // Area breakdown
  lines.push(`## Coverage by Area`);
  lines.push(``);
  lines.push(`| Area | Coverage | Passed | Failed | Skipped | Total |`);
  lines.push(`|------|----------|--------|--------|---------|-------|`);
  for (const area of areas) {
    lines.push(
      `| ${area.area} | ${pct(area.coverage)} | ${area.passed} | ${area.failed} | ${area.skipped} | ${area.total} |`,
    );
  }
  lines.push(``);

  // Spec detail per area
  for (const area of areas) {
    lines.push(`### ${area.area}`);
    lines.push(``);
    lines.push(`| Spec | Coverage | Passed | Failed | Skipped | Status |`);
    lines.push(`|------|----------|--------|--------|---------|--------|`);
    for (const spec of area.specs) {
      const status = specStatus(spec);
      lines.push(
        `| ${spec.specId} | ${pct(spec.coverage)} | ${spec.passed} | ${spec.failed} | ${spec.skipped} | ${status} |`,
      );
    }
    lines.push(``);
  }

  // Regressions
  if (regressions.length > 0) {
    lines.push(`## Regressions`);
    lines.push(``);
    lines.push(`| Spec | Scenario | Previous | Current | Notes |`);
    lines.push(`|------|----------|----------|---------|-------|`);
    for (const r of regressions) {
      lines.push(`| ${r.specId} | ${r.scenarioId} | ${r.previousStatus} | ${r.currentStatus} | ${r.notes} |`);
    }
    lines.push(``);
  }

  // Never-tested specs
  const neverTested = areas.flatMap((a) => a.specs).filter((s) => s.neverTested);
  if (neverTested.length > 0) {
    lines.push(`## Never Tested`);
    lines.push(``);
    lines.push(`The following specs have no run data:`);
    lines.push(``);
    for (const s of neverTested) {
      lines.push(`- **${s.specId}** (${s.area})`);
    }
    lines.push(``);
  }

  return lines.join("\n");
}

function specStatus(spec: SpecCoverage): string {
  if (spec.neverTested) return "Never Tested";
  if (spec.failed > 0) return "Failing";
  if (spec.coverage === 1) return "Fully Covered";
  return "Partial";
}

/**
 * Write the report to disk, archiving the previous latest.md.
 */
export function writeReport(reportContent: string, paths: ResolvedPaths): string {
  const reportsDir = paths.reportsDir;
  const historyDir = path.join(reportsDir, "history");
  const latestPath = path.join(reportsDir, "latest.md");

  fs.mkdirSync(historyDir, { recursive: true });

  // Archive existing latest.md
  if (fs.existsSync(latestPath)) {
    const stat = fs.statSync(latestPath);
    const timestamp = stat.mtime.toISOString().replace(/[:.]/g, "-").slice(0, 19);
    const archivePath = path.join(historyDir, `report-${timestamp}.md`);
    fs.renameSync(latestPath, archivePath);
  }

  fs.writeFileSync(latestPath, reportContent, "utf-8");
  return latestPath;
}
