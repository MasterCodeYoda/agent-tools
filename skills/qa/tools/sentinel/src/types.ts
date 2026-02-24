// Spec frontmatter fields
/** @deprecated Use NlSpecFrontmatter for new NL spec format */
export interface SpecFrontmatter {
  id: string;
  feature: string;
  area: string;
  priority: "P1" | "P2" | "P3";
  dependencies?: string[];
}

// A single scenario parsed from a spec file
/** @deprecated Use NlScenario for new NL spec format */
export interface Scenario {
  id: string;
  description: string;
  expected: string;
  status: "untested" | "pass" | "fail" | "skip";
  group: string; // e.g. "Happy Path", "Validation", "Edge Cases"
}

// A fully parsed spec file
/** @deprecated Use NlSpec for new NL spec format */
export interface Spec {
  frontmatter: SpecFrontmatter;
  filePath: string;
  context: string;
  preconditions: string[];
  scenarios: Scenario[];
  testData: string;
  notes: string;
}

// Validation error for a spec file
export interface ValidationError {
  file: string;
  line?: number;
  message: string;
  severity: "error" | "warning";
}

// NL Spec frontmatter fields (new format)
export interface NlSpecFrontmatter {
  id: string;
  area: string;
  priority: "P0" | "P1" | "P2" | "P3";
  persona: "new-user" | "power-user" | "returning-user";
  tags: string[];
  seed: string;
}

// A single scenario from an NL spec (numbered, not ID-based)
export interface NlScenario {
  number: number;
  title: string;
  steps: string[];
  expected: string;
}

// A fully parsed NL spec file
export interface NlSpec {
  frontmatter: NlSpecFrontmatter;
  filePath: string;
  overview: string;
  preconditions: string[];
  scenarios: NlScenario[];
  testData: string;
  notes: string;
}

// Audit coverage for a single NL spec
export interface NlSpecCoverage {
  specId: string;
  area: string;
  totalScenarios: number;
  coveredScenarios: number;
  uncoveredScenarios: number;
  coverage: number; // 0-1
  matchedTests: string[]; // test file paths
}

// Audit area coverage
export interface AuditAreaCoverage {
  area: string;
  totalScenarios: number;
  coveredScenarios: number;
  coverage: number; // 0-1
  specs: NlSpecCoverage[];
}

// An orphaned test (exists in .spec.ts but no NL spec)
export interface OrphanedTest {
  testFile: string;
  testNames: string[];
}

// Audit result
export interface AuditResult {
  areas: AuditAreaCoverage[];
  orphanedTests: OrphanedTest[];
  overallCoverage: number;
  recommendations: string[];
}

// Sentinel configuration file
export interface SentinelConfig {
  app: {
    base_url: string;
    name: string;
  };
  auth: {
    strategy: "credentials" | "token" | "cookie" | "none";
    login_url?: string;
    credentials?: {
      username: string;
      password_env: string;
    };
  };
  browser: {
    headless: boolean;
    viewport: {
      width: number;
      height: number;
    };
    timeout: number;
  };
  bridge?: {
    shim_path: string;
    port: number;
    partitions?: Record<string, number>;
  };
  playwright: {
    config_path: string;
  };
  specs: {
    nl_dir: string;
    tests_dir: string;
  };
}

// Resolved paths (absolute) computed from config
export interface ResolvedPaths {
  configDir: string;
  nlSpecsDir: string;
  testsDir: string;
}
