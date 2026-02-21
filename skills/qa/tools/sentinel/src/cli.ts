#!/usr/bin/env node

import { Command } from "commander";
import * as fs from "node:fs";
import * as path from "node:path";
import { findConfigFile, loadAndResolve } from "./config.js";
import { parseAllSpecs, validateAllSpecs, validateSpecFile, findSpecFiles } from "./specs.js";
import { createRunDirectory, listRunDirectories, cleanupOldRuns, getLatestRunDirectory } from "./evidence.js";
import { parseRunDirectory, computeAreaCoverage, computeOverallCoverage } from "./coverage.js";
import { generateReport, writeReport } from "./report.js";

const program = new Command();

program
  .name("sentinel")
  .description("Spec-driven QA harness CLI")
  .version("0.1.0");

// ── sentinel init ──────────────────────────────────────────────────────

program
  .command("init")
  .description("Initialize Sentinel project directory structure")
  .action(() => {
    const baseDir = path.join(process.cwd(), "tests", "qa-sentinel");
    const dirs = [
      path.join(baseDir, "specs"),
      path.join(baseDir, "runs"),
      path.join(baseDir, "reports", "history"),
    ];

    for (const dir of dirs) {
      fs.mkdirSync(dir, { recursive: true });
      console.log(`  Created: ${path.relative(process.cwd(), dir)}/`);
    }

    // Copy config template
    const configDest = path.join(baseDir, "sentinel.config.yaml");
    if (!fs.existsSync(configDest)) {
      const templatePath = path.resolve(
        import.meta.dirname,
        "../../..", // skills/qa/tools/sentinel/src -> skills/qa
        "sentinel/templates/config-template.yaml",
      );
      if (fs.existsSync(templatePath)) {
        fs.copyFileSync(templatePath, configDest);
        console.log(`  Created: ${path.relative(process.cwd(), configDest)}`);
      } else {
        // Write a minimal config if template not found
        const minimalConfig = `# Sentinel Configuration
app:
  base_url: http://localhost:3000
  name: My Application

auth:
  strategy: none

browser:
  headless: true
  viewport:
    width: 1280
    height: 720
  timeout: 30000

evidence:
  screenshots: on_failure
  traces: on_failure
  dom_snapshots: on_failure

paths:
  specs_dir: ./specs
  runs_dir: ./runs
  reports_dir: ./reports
`;
        fs.writeFileSync(configDest, minimalConfig, "utf-8");
        console.log(`  Created: ${path.relative(process.cwd(), configDest)}`);
      }
    } else {
      console.log(`  Exists:  ${path.relative(process.cwd(), configDest)} (skipped)`);
    }

    // Create .gitignore
    const gitignorePath = path.join(baseDir, ".gitignore");
    if (!fs.existsSync(gitignorePath)) {
      const gitignoreContent = `# Sentinel QA
# Keep specs and reports in version control
# Exclude run data (evidence screenshots, traces, etc.)
runs/*/evidence/
runs/*/results/

# Keep directory structure
!runs/.gitkeep
!runs/*/.gitkeep
`;
      fs.writeFileSync(gitignorePath, gitignoreContent, "utf-8");
      console.log(`  Created: ${path.relative(process.cwd(), gitignorePath)}`);
    }

    // Create .gitkeep files so empty dirs are tracked
    const gitkeeps = [
      path.join(baseDir, "specs", ".gitkeep"),
      path.join(baseDir, "runs", ".gitkeep"),
    ];
    for (const gk of gitkeeps) {
      if (!fs.existsSync(gk)) {
        fs.writeFileSync(gk, "", "utf-8");
      }
    }

    console.log(`\nSentinel initialized at ${path.relative(process.cwd(), baseDir)}/`);
    console.log(`Edit sentinel.config.yaml to configure your application.`);
  });

// ── sentinel validate ──────────────────────────────────────────────────

program
  .command("validate")
  .description("Validate spec files for correctness")
  .argument("[path]", "Path to a specific spec file (validates all if omitted)")
  .action((specPath?: string) => {
    const { paths } = loadAndResolve();

    if (specPath) {
      const absPath = path.resolve(specPath);
      if (!fs.existsSync(absPath)) {
        console.error(`Error: File not found: ${absPath}`);
        process.exit(1);
      }
      // Gather all spec IDs for dependency validation
      const allSpecs = parseAllSpecs(paths.specsDir);
      const allSpecIds = new Set(allSpecs.map((s) => s.frontmatter.id));
      const { spec, errors } = validateSpecFile(absPath, allSpecIds);
      printValidationResults([spec.frontmatter.id || absPath], errors);
    } else {
      const { specs, errors } = validateAllSpecs(paths.specsDir);
      if (specs.length === 0) {
        console.log("No spec files found in " + paths.specsDir);
        return;
      }
      printValidationResults(
        specs.map((s) => s.frontmatter.id || s.filePath),
        errors,
      );
    }
  });

function printValidationResults(specIds: string[], errors: import("./types.js").ValidationError[]) {
  const errorCount = errors.filter((e) => e.severity === "error").length;
  const warnCount = errors.filter((e) => e.severity === "warning").length;

  if (errors.length === 0) {
    console.log(`Validated ${specIds.length} spec(s) — no issues found.`);
    return;
  }

  for (const err of errors) {
    const prefix = err.severity === "error" ? "ERROR" : "WARN ";
    const location = err.line ? `${err.file}:${err.line}` : err.file;
    console.log(`  ${prefix}  ${path.relative(process.cwd(), location)}: ${err.message}`);
  }

  console.log(`\n${specIds.length} spec(s) checked: ${errorCount} error(s), ${warnCount} warning(s)`);
  if (errorCount > 0) {
    process.exit(1);
  }
}

// ── sentinel status ────────────────────────────────────────────────────

program
  .command("status")
  .description("Show coverage status summary")
  .action(() => {
    const { config, paths } = loadAndResolve();
    const specs = parseAllSpecs(paths.specsDir);

    if (specs.length === 0) {
      console.log("No specs found. Create spec files in " + paths.specsDir);
      return;
    }

    const latestDir = getLatestRunDirectory(paths);
    const runFiles = latestDir ? parseRunDirectory(latestDir) : [];
    const areas = computeAreaCoverage(specs, runFiles);
    const overall = computeOverallCoverage(areas);

    const totalScenarios = specs.reduce((sum, s) => sum + s.scenarios.length, 0);

    console.log(`Sentinel Status: ${config.app.name}`);
    console.log(`${"─".repeat(50)}`);
    console.log(`Specs: ${specs.length}  |  Scenarios: ${totalScenarios}`);

    if (latestDir) {
      console.log(`Latest run: ${path.basename(latestDir)}`);
      console.log(``);
      console.log(`Overall: ${pct(overall.coverage)}  (${overall.passed} pass / ${overall.failed} fail / ${overall.skipped} skip)`);
      console.log(``);

      for (const area of areas) {
        const neverTested = area.specs.filter((s) => s.neverTested).length;
        const nt = neverTested > 0 ? ` (${neverTested} never tested)` : "";
        console.log(`  ${area.area.padEnd(20)} ${pct(area.coverage).padStart(4)}  ${area.passed}/${area.total}${nt}`);
      }
    } else {
      console.log(`\nNo runs found. Run specs to generate coverage data.`);
    }
  });

function pct(n: number): string {
  return `${Math.round(n * 100)}%`;
}

// ── sentinel evidence collect ──────────────────────────────────────────

program
  .command("evidence")
  .description("Evidence management")
  .command("collect")
  .description("Create a new run directory for evidence collection")
  .option("--keep <n>", "Number of old runs to keep", "10")
  .action((opts) => {
    const { paths } = loadAndResolve();
    const runDir = createRunDirectory(paths);
    const keep = parseInt(opts.keep, 10);

    if (keep > 0) {
      const removed = cleanupOldRuns(paths, keep + 1); // +1 for the one we just created
      if (removed.length > 0) {
        console.error(`Cleaned up ${removed.length} old run(s)`);
      }
    }

    // Output just the path — easy for scripts/commands to capture
    console.log(runDir);
  });

// ── sentinel report generate ───────────────────────────────────────────

program
  .command("report")
  .description("Report generation")
  .command("generate")
  .description("Generate a coverage report from the latest run")
  .action(() => {
    const { config, paths } = loadAndResolve();
    const specs = parseAllSpecs(paths.specsDir);

    if (specs.length === 0) {
      console.error("No specs found. Create spec files in " + paths.specsDir);
      process.exit(1);
    }

    const reportContent = generateReport(specs, paths, { appName: config.app.name });
    const reportPath = writeReport(reportContent, paths);

    console.log(`Report written to ${path.relative(process.cwd(), reportPath)}`);
  });

program.parse();
