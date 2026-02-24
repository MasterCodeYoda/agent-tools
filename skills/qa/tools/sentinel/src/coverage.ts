import * as fs from "node:fs";
import * as path from "node:path";
import type {
  NlSpec,
  NlSpecCoverage,
  AuditAreaCoverage,
  AuditResult,
  OrphanedTest,
} from "./types.js";

/**
 * Find all .spec.ts files in the tests directory.
 */
export function findTestFiles(testsDir: string): string[] {
  if (!fs.existsSync(testsDir)) {
    return [];
  }
  return fs
    .readdirSync(testsDir)
    .filter((f) => f.endsWith(".spec.ts"))
    .map((f) => path.join(testsDir, f))
    .sort();
}

/**
 * Extract test names from a .spec.ts file.
 * Looks for test('...') and test.describe('...') patterns.
 */
export function extractTestNames(testFile: string): string[] {
  const content = fs.readFileSync(testFile, "utf-8");
  const names: string[] = [];

  // Match test('name', ...) and test.describe('name', ...)
  const pattern = /test(?:\.describe)?\s*\(\s*['"`]([^'"`]+)['"`]/g;
  let match;
  while ((match = pattern.exec(content)) !== null) {
    names.push(match[1]);
  }

  return names;
}

/**
 * Match an NL spec to its corresponding test file by naming convention.
 * workspace-create.md → workspace-create.spec.ts
 */
export function findMatchingTestFile(spec: NlSpec, testFiles: string[]): string | null {
  const specBaseName = path.basename(spec.filePath, ".md");
  return testFiles.find((tf) => {
    const testBaseName = path.basename(tf, ".spec.ts");
    return testBaseName === specBaseName;
  }) || null;
}

/**
 * Compute coverage for a single NL spec against test files.
 */
export function computeNlSpecCoverage(spec: NlSpec, testFiles: string[]): NlSpecCoverage {
  const matchedFile = findMatchingTestFile(spec, testFiles);

  if (!matchedFile) {
    return {
      specId: spec.frontmatter.id,
      area: spec.frontmatter.area,
      totalScenarios: spec.scenarios.length,
      coveredScenarios: 0,
      uncoveredScenarios: spec.scenarios.length,
      coverage: 0,
      matchedTests: [],
    };
  }

  const testNames = extractTestNames(matchedFile);
  let covered = 0;

  for (const scenario of spec.scenarios) {
    // Check if any test name contains the scenario title (case-insensitive)
    const titleLower = scenario.title.toLowerCase();
    const isMatched = testNames.some((tn) => tn.toLowerCase().includes(titleLower));
    if (isMatched) {
      covered++;
    }
  }

  return {
    specId: spec.frontmatter.id,
    area: spec.frontmatter.area,
    totalScenarios: spec.scenarios.length,
    coveredScenarios: covered,
    uncoveredScenarios: spec.scenarios.length - covered,
    coverage: spec.scenarios.length > 0 ? covered / spec.scenarios.length : 0,
    matchedTests: [matchedFile],
  };
}

/**
 * Find orphaned tests — .spec.ts files with no corresponding NL spec.
 */
export function findOrphanedTests(specs: NlSpec[], testFiles: string[]): OrphanedTest[] {
  const specBaseNames = new Set(specs.map((s) => path.basename(s.filePath, ".md")));

  return testFiles
    .filter((tf) => {
      const testBaseName = path.basename(tf, ".spec.ts");
      return !specBaseNames.has(testBaseName);
    })
    .map((tf) => ({
      testFile: tf,
      testNames: extractTestNames(tf),
    }));
}

/**
 * Compute full audit coverage: NL specs vs test files.
 */
export function computeAuditCoverage(
  specs: NlSpec[],
  testFiles: string[],
  filterArea?: string,
): AuditResult {
  const filteredSpecs = filterArea
    ? specs.filter((s) => s.frontmatter.area === filterArea)
    : specs;

  const specCoverages = filteredSpecs.map((s) => computeNlSpecCoverage(s, testFiles));

  // Group by area
  const areaMap = new Map<string, NlSpecCoverage[]>();
  for (const sc of specCoverages) {
    const existing = areaMap.get(sc.area) || [];
    existing.push(sc);
    areaMap.set(sc.area, existing);
  }

  const areas: AuditAreaCoverage[] = [];
  for (const [area, specCovers] of areaMap) {
    const totalScenarios = specCovers.reduce((sum, s) => sum + s.totalScenarios, 0);
    const coveredScenarios = specCovers.reduce((sum, s) => sum + s.coveredScenarios, 0);

    areas.push({
      area,
      totalScenarios,
      coveredScenarios,
      coverage: totalScenarios > 0 ? coveredScenarios / totalScenarios : 0,
      specs: specCovers,
    });
  }

  areas.sort((a, b) => a.area.localeCompare(b.area));

  const orphanedTests = findOrphanedTests(filteredSpecs, testFiles);

  const totalScenarios = areas.reduce((sum, a) => sum + a.totalScenarios, 0);
  const coveredScenarios = areas.reduce((sum, a) => sum + a.coveredScenarios, 0);

  const recommendations: string[] = [];

  // Uncovered specs
  const uncovered = specCoverages.filter((s) => s.coverage === 0);
  if (uncovered.length > 0) {
    recommendations.push(
      `${uncovered.length} spec(s) have no generated tests. Run Playwright Generator for: ${uncovered.map((s) => s.specId).join(", ")}`,
    );
  }

  // Partial coverage
  const partial = specCoverages.filter((s) => s.coverage > 0 && s.coverage < 1);
  if (partial.length > 0) {
    recommendations.push(
      `${partial.length} spec(s) have partial test coverage. Review and regenerate: ${partial.map((s) => s.specId).join(", ")}`,
    );
  }

  // Orphaned tests
  if (orphanedTests.length > 0) {
    recommendations.push(
      `${orphanedTests.length} test file(s) have no corresponding NL spec. Write specs or delete: ${orphanedTests.map((t) => path.basename(t.testFile)).join(", ")}`,
    );
  }

  return {
    areas,
    orphanedTests,
    overallCoverage: totalScenarios > 0 ? coveredScenarios / totalScenarios : 0,
    recommendations,
  };
}

/**
 * Print a formatted audit report to stdout.
 */
export function printAuditReport(result: AuditResult, appName: string): void {
  console.log(`Sentinel Audit: ${appName}`);
  console.log(`${"─".repeat(50)}`);
  console.log(`Overall coverage: ${pct(result.overallCoverage)}`);
  console.log(``);

  for (const area of result.areas) {
    console.log(`  ${area.area}`);
    console.log(`    Coverage: ${pct(area.coverage)}  (${area.coveredScenarios}/${area.totalScenarios} scenarios)`);
    for (const spec of area.specs) {
      const bar = spec.matchedTests.length > 0 ? `[${pct(spec.coverage)}]` : "[no test file]";
      console.log(`      ${spec.specId.padEnd(30)} ${bar}`);
    }
    console.log(``);
  }

  if (result.orphanedTests.length > 0) {
    console.log(`Orphaned tests (no NL spec):`);
    for (const ot of result.orphanedTests) {
      console.log(`  ${ot.testFile}`);
    }
    console.log(``);
  }

  if (result.recommendations.length > 0) {
    console.log(`Recommendations:`);
    for (const rec of result.recommendations) {
      console.log(`  - ${rec}`);
    }
  }
}

function pct(n: number): string {
  return `${Math.round(n * 100)}%`;
}
