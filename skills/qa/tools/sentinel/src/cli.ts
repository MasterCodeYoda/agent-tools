#!/usr/bin/env node

import { Command } from "commander";
import * as fs from "node:fs";
import * as path from "node:path";
import { loadAndResolve } from "./config.js";
import { parseAllSpecs, validateAllSpecs, validateSpecFile, parseAllNlSpecs, validateNlSpec, parseNlSpec } from "./specs.js";
import { findTestFiles, computeAuditCoverage, printAuditReport } from "./coverage.js";

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
      path.join(baseDir, "tests"),
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

playwright:
  config_path: ./playwright.config.ts

specs:
  nl_dir: ./specs
  tests_dir: ./tests
`;
        fs.writeFileSync(configDest, minimalConfig, "utf-8");
        console.log(`  Created: ${path.relative(process.cwd(), configDest)}`);
      }
    } else {
      console.log(`  Exists:  ${path.relative(process.cwd(), configDest)} (skipped)`);
    }

    // Create .gitkeep files so empty dirs are tracked
    const gitkeeps = [
      path.join(baseDir, "specs", ".gitkeep"),
      path.join(baseDir, "tests", ".gitkeep"),
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
  .option("--nl", "Validate NL spec files instead of legacy .spec.md files")
  .action((specPath?: string, opts?: { nl?: boolean }) => {
    const { paths } = loadAndResolve();

    if (opts?.nl) {
      // NL spec validation
      if (specPath) {
        const absPath = path.resolve(specPath);
        if (!fs.existsSync(absPath)) {
          console.error(`Error: File not found: ${absPath}`);
          process.exit(1);
        }
        const spec = parseNlSpec(absPath);
        const errors = validateNlSpec(spec);
        printValidationResults([spec.frontmatter.id || absPath], errors);
      } else {
        const nlSpecs = parseAllNlSpecs(paths.nlSpecsDir);
        if (nlSpecs.length === 0) {
          console.log("No NL spec files found in " + paths.nlSpecsDir);
          return;
        }
        const allErrors = nlSpecs.flatMap((s) => validateNlSpec(s));
        printValidationResults(
          nlSpecs.map((s) => s.frontmatter.id || s.filePath),
          allErrors,
        );
      }
    } else {
      // Legacy .spec.md validation
      if (specPath) {
        const absPath = path.resolve(specPath);
        if (!fs.existsSync(absPath)) {
          console.error(`Error: File not found: ${absPath}`);
          process.exit(1);
        }
        // Gather all spec IDs for dependency validation
        const allSpecs = parseAllSpecs(paths.nlSpecsDir);
        const allSpecIds = new Set(allSpecs.map((s) => s.frontmatter.id));
        const { spec, errors } = validateSpecFile(absPath, allSpecIds);
        printValidationResults([spec.frontmatter.id || absPath], errors);
      } else {
        const { specs, errors } = validateAllSpecs(paths.nlSpecsDir);
        if (specs.length === 0) {
          console.log("No spec files found in " + paths.nlSpecsDir);
          return;
        }
        printValidationResults(
          specs.map((s) => s.frontmatter.id || s.filePath),
          errors,
        );
      }
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
  .description("Show NL spec inventory and test coverage summary")
  .action(() => {
    const { config, paths } = loadAndResolve();
    const nlSpecs = parseAllNlSpecs(paths.nlSpecsDir);

    if (nlSpecs.length === 0) {
      console.log("No NL specs found. Create spec files in " + paths.nlSpecsDir);
      return;
    }

    const testFiles = findTestFiles(paths.testsDir);
    const totalScenarios = nlSpecs.reduce((sum, s) => sum + s.scenarios.length, 0);
    const specsWithTests = nlSpecs.filter((s) => {
      const base = path.basename(s.filePath, ".md");
      return testFiles.some((tf) => path.basename(tf, ".spec.ts") === base);
    });

    console.log(`Sentinel Status: ${config.app.name}`);
    console.log(`${"─".repeat(50)}`);
    console.log(`NL Specs: ${nlSpecs.length}  |  Scenarios: ${totalScenarios}`);
    console.log(`Test files: ${testFiles.length}  |  Specs with tests: ${specsWithTests.length}/${nlSpecs.length}`);
    console.log(``);

    // Group by area
    const areaMap = new Map<string, typeof nlSpecs>();
    for (const spec of nlSpecs) {
      const area = spec.frontmatter.area || "Unknown";
      const existing = areaMap.get(area) || [];
      existing.push(spec);
      areaMap.set(area, existing);
    }

    for (const [area, specs] of [...areaMap.entries()].sort()) {
      const areaScenarios = specs.reduce((sum, s) => sum + s.scenarios.length, 0);
      const areaWithTests = specs.filter((s) => {
        const base = path.basename(s.filePath, ".md");
        return testFiles.some((tf) => path.basename(tf, ".spec.ts") === base);
      }).length;
      console.log(`  ${area.padEnd(20)} ${areaWithTests}/${specs.length} specs  (${areaScenarios} scenarios)`);
    }
  });

// ── sentinel audit ─────────────────────────────────────────────────────

program
  .command("audit")
  .description("Audit coverage: NL specs vs generated .spec.ts tests")
  .option("--area <name>", "Filter to a specific area")
  .action((opts) => {
    const { config, paths } = loadAndResolve();
    const nlSpecs = parseAllNlSpecs(paths.nlSpecsDir);

    if (nlSpecs.length === 0) {
      console.log("No NL specs found in " + paths.nlSpecsDir);
      return;
    }

    const testFiles = findTestFiles(paths.testsDir);
    const result = computeAuditCoverage(nlSpecs, testFiles, opts.area);

    printAuditReport(result, config.app.name);
  });

program.parse();
