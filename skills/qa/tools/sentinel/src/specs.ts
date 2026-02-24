import * as fs from "node:fs";
import * as path from "node:path";
import matter from "gray-matter";
import type {
  Spec,
  SpecFrontmatter,
  Scenario,
  ValidationError,
  NlSpec,
  NlSpecFrontmatter,
  NlScenario,
} from "./types.js";

const VALID_PRIORITIES = ["P1", "P2", "P3"];
const SCENARIO_REGEX = /^- \[([ x!\-])\] `([^`]+)`\s+(.+)$/;

// ── Legacy .spec.md parser ──────────────────────────────────────────────

/**
 * Find all .spec.md files in a directory (non-recursive).
 */
export function findSpecFiles(specsDir: string): string[] {
  if (!fs.existsSync(specsDir)) {
    return [];
  }
  return fs
    .readdirSync(specsDir)
    .filter((f) => f.endsWith(".spec.md"))
    .map((f) => path.join(specsDir, f))
    .sort();
}

/**
 * Parse a single spec file into a Spec object.
 */
export function parseSpec(filePath: string): Spec {
  const raw = fs.readFileSync(filePath, "utf-8");
  const { data, content } = matter(raw);

  const frontmatter = data as SpecFrontmatter;
  const lines = content.split("\n");

  let context = "";
  let preconditions: string[] = [];
  let scenarios: Scenario[] = [];
  let testData = "";
  let notes = "";

  // Simple section-based parser
  let currentSection = "";
  let currentGroup = "";
  let sectionLines: string[] = [];

  const flushSection = () => {
    const text = sectionLines.join("\n").trim();
    switch (currentSection) {
      case "context":
        context = text;
        break;
      case "preconditions":
        preconditions = text
          .split("\n")
          .filter((l) => l.startsWith("- "))
          .map((l) => l.slice(2).trim());
        break;
      case "test data":
        testData = text;
        break;
      case "notes":
        notes = text;
        break;
      // scenarios are parsed inline
    }
    sectionLines = [];
  };

  for (const line of lines) {
    // H2 section headers
    const h2Match = line.match(/^## (.+)$/);
    if (h2Match) {
      flushSection();
      currentSection = h2Match[1].trim().toLowerCase();
      continue;
    }

    // H3 within scenarios = group name
    const h3Match = line.match(/^### (.+)$/);
    if (h3Match && currentSection === "scenarios") {
      currentGroup = h3Match[1].trim();
      continue;
    }

    // Scenario lines
    if (currentSection === "scenarios") {
      const scenarioMatch = line.match(SCENARIO_REGEX);
      if (scenarioMatch) {
        const [, marker, id, rest] = scenarioMatch;
        const arrowIdx = rest.lastIndexOf("→");
        const description = arrowIdx >= 0 ? rest.slice(0, arrowIdx).trim() : rest.trim();
        const expected = arrowIdx >= 0 ? rest.slice(arrowIdx + 1).trim() : "";

        let status: Scenario["status"] = "untested";
        if (marker === "x") status = "pass";
        else if (marker === "!") status = "fail";
        else if (marker === "-") status = "skip";

        scenarios.push({ id, description, expected, status, group: currentGroup });
        continue;
      }
    }

    sectionLines.push(line);
  }
  flushSection();

  return { frontmatter, filePath, context, preconditions, scenarios, testData, notes };
}

/**
 * Parse all specs in a directory.
 */
export function parseAllSpecs(specsDir: string): Spec[] {
  return findSpecFiles(specsDir).map(parseSpec);
}

/**
 * Validate a single spec and return any errors.
 */
export function validateSpec(spec: Spec, allSpecIds: Set<string>): ValidationError[] {
  const errors: ValidationError[] = [];
  const file = spec.filePath;
  const fm = spec.frontmatter;

  // Required frontmatter fields
  if (!fm.id) {
    errors.push({ file, message: "Missing required frontmatter field: id", severity: "error" });
  }
  if (!fm.feature) {
    errors.push({ file, message: "Missing required frontmatter field: feature", severity: "error" });
  }
  if (!fm.area) {
    errors.push({ file, message: "Missing required frontmatter field: area", severity: "error" });
  }
  if (!fm.priority) {
    errors.push({ file, message: "Missing required frontmatter field: priority", severity: "error" });
  } else if (!VALID_PRIORITIES.includes(fm.priority)) {
    errors.push({
      file,
      message: `Invalid priority "${fm.priority}". Must be one of: ${VALID_PRIORITIES.join(", ")}`,
      severity: "error",
    });
  }

  // Validate dependencies reference existing spec IDs
  if (fm.dependencies) {
    for (const dep of fm.dependencies) {
      if (!allSpecIds.has(dep)) {
        errors.push({
          file,
          message: `Dependency "${dep}" does not match any known spec ID`,
          severity: "warning",
        });
      }
    }
  }

  // Validate scenario IDs are unique within the spec
  const scenarioIds = new Set<string>();
  for (const scenario of spec.scenarios) {
    if (scenarioIds.has(scenario.id)) {
      errors.push({
        file,
        message: `Duplicate scenario ID "${scenario.id}" within spec ${fm.id}`,
        severity: "error",
      });
    }
    scenarioIds.add(scenario.id);
  }

  // Warn if no scenarios found
  if (spec.scenarios.length === 0) {
    errors.push({
      file,
      message: "No scenarios found in spec",
      severity: "warning",
    });
  }

  // Warn if scenarios lack expected results
  for (const scenario of spec.scenarios) {
    if (!scenario.expected) {
      errors.push({
        file,
        message: `Scenario "${scenario.id}" has no expected result (missing "→")`,
        severity: "warning",
      });
    }
  }

  return errors;
}

/**
 * Validate all specs in a directory.
 */
export function validateAllSpecs(specsDir: string): { specs: Spec[]; errors: ValidationError[] } {
  const specs = parseAllSpecs(specsDir);
  const allSpecIds = new Set(specs.map((s) => s.frontmatter.id));

  // Check for duplicate spec IDs across files
  const seenIds = new Map<string, string>();
  const errors: ValidationError[] = [];

  for (const spec of specs) {
    const id = spec.frontmatter.id;
    if (id && seenIds.has(id)) {
      errors.push({
        file: spec.filePath,
        message: `Duplicate spec ID "${id}" — also defined in ${seenIds.get(id)}`,
        severity: "error",
      });
    } else if (id) {
      seenIds.set(id, spec.filePath);
    }

    errors.push(...validateSpec(spec, allSpecIds));
  }

  return { specs, errors };
}

/**
 * Validate a single spec file by path.
 */
export function validateSpecFile(filePath: string, allSpecIds: Set<string>): { spec: Spec; errors: ValidationError[] } {
  const spec = parseSpec(filePath);
  const errors = validateSpec(spec, allSpecIds);
  return { spec, errors };
}

// ── NL spec parser ─────────────────────────────────────────────────────

const VALID_NL_PRIORITIES = ["P0", "P1", "P2", "P3"];
const VALID_PERSONAS = ["new-user", "power-user", "returning-user"];

/**
 * Find all NL spec files (.md, excluding .spec.md) in a directory.
 */
export function findNlSpecFiles(nlSpecsDir: string): string[] {
  if (!fs.existsSync(nlSpecsDir)) {
    return [];
  }
  return fs
    .readdirSync(nlSpecsDir)
    .filter((f) => f.endsWith(".md") && !f.endsWith(".spec.md") && !f.startsWith("_"))
    .map((f) => path.join(nlSpecsDir, f))
    .sort();
}

/**
 * Parse a single NL spec file.
 */
export function parseNlSpec(filePath: string): NlSpec {
  const raw = fs.readFileSync(filePath, "utf-8");
  const { data, content } = matter(raw);
  const frontmatter = data as NlSpecFrontmatter;

  const lines = content.split("\n");
  let overview = "";
  let preconditions: string[] = [];
  let scenarios: NlScenario[] = [];
  let testData = "";
  let notes = "";

  let currentSection = "";
  let sectionLines: string[] = [];
  let currentScenario: NlScenario | null = null;

  const flushSection = () => {
    const text = sectionLines.join("\n").trim();
    switch (currentSection) {
      case "overview":
        overview = text;
        break;
      case "preconditions":
        preconditions = text
          .split("\n")
          .filter((l) => l.startsWith("- "))
          .map((l) => l.slice(2).trim());
        break;
      case "test data":
        testData = text;
        break;
      case "notes":
        notes = text;
        break;
    }
    sectionLines = [];
  };

  const flushScenario = () => {
    if (currentScenario) {
      scenarios.push(currentScenario);
      currentScenario = null;
    }
  };

  for (const line of lines) {
    // H2 section headers
    const h2Match = line.match(/^## (.+)$/);
    if (h2Match) {
      flushScenario();
      flushSection();
      currentSection = h2Match[1].trim().toLowerCase();
      continue;
    }

    // H3 within scenarios = numbered scenario
    if (currentSection === "scenarios") {
      const h3Match = line.match(/^### (\d+)\.\s+(.+)$/);
      if (h3Match) {
        flushScenario();
        currentScenario = {
          number: parseInt(h3Match[1], 10),
          title: h3Match[2].trim(),
          steps: [],
          expected: "",
        };
        continue;
      }

      if (currentScenario) {
        // Expected line
        const expectedMatch = line.match(/^-\s+\*\*Expected:\*\*\s*(.+)$/);
        if (expectedMatch) {
          currentScenario.expected = expectedMatch[1].trim();
          continue;
        }
        // Step line
        const stepMatch = line.match(/^-\s+(.+)$/);
        if (stepMatch) {
          currentScenario.steps.push(stepMatch[1].trim());
          continue;
        }
      }
    }

    sectionLines.push(line);
  }

  flushScenario();
  flushSection();

  return { frontmatter, filePath, overview, preconditions, scenarios, testData, notes };
}

/**
 * Parse all NL specs in a directory.
 */
export function parseAllNlSpecs(nlSpecsDir: string): NlSpec[] {
  return findNlSpecFiles(nlSpecsDir).map(parseNlSpec);
}

/**
 * Validate a single NL spec and return any errors.
 */
export function validateNlSpec(spec: NlSpec): ValidationError[] {
  const errors: ValidationError[] = [];
  const file = spec.filePath;
  const fm = spec.frontmatter;

  if (!fm.id) {
    errors.push({ file, message: "Missing required frontmatter field: id", severity: "error" });
  }
  if (!fm.area) {
    errors.push({ file, message: "Missing required frontmatter field: area", severity: "error" });
  }
  if (!fm.priority) {
    errors.push({ file, message: "Missing required frontmatter field: priority", severity: "error" });
  } else if (!VALID_NL_PRIORITIES.includes(fm.priority)) {
    errors.push({ file, message: `Invalid priority "${fm.priority}". Must be one of: ${VALID_NL_PRIORITIES.join(", ")}`, severity: "error" });
  }
  if (!fm.persona) {
    errors.push({ file, message: "Missing required frontmatter field: persona", severity: "warning" });
  } else if (!VALID_PERSONAS.includes(fm.persona)) {
    errors.push({ file, message: `Invalid persona "${fm.persona}". Must be one of: ${VALID_PERSONAS.join(", ")}`, severity: "warning" });
  }
  if (spec.scenarios.length === 0) {
    errors.push({ file, message: "No scenarios found in NL spec", severity: "warning" });
  }
  for (const scenario of spec.scenarios) {
    if (!scenario.expected) {
      errors.push({ file, message: `Scenario ${scenario.number} ("${scenario.title}") has no **Expected:** line`, severity: "warning" });
    }
  }

  return errors;
}
