// Spec frontmatter fields
export interface SpecFrontmatter {
  id: string;
  feature: string;
  area: string;
  priority: "P1" | "P2" | "P3";
  dependencies?: string[];
}

// A single scenario parsed from a spec file
export interface Scenario {
  id: string;
  description: string;
  expected: string;
  status: "untested" | "pass" | "fail" | "skip";
  group: string; // e.g. "Happy Path", "Validation", "Edge Cases"
}

// A fully parsed spec file
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

// Run file frontmatter
export interface RunFrontmatter {
  spec: string;
  run_date: string;
  duration: string;
  passed: number;
  failed: number;
  skipped: number;
}

// A single scenario result from a run file
export interface ScenarioResult {
  scenarioId: string;
  status: "PASS" | "FAIL" | "SKIP";
  duration: string;
  notes: string;
}

// A fully parsed run file
export interface RunFile {
  frontmatter: RunFrontmatter;
  filePath: string;
  results: ScenarioResult[];
}

// Coverage stats for a single spec
export interface SpecCoverage {
  specId: string;
  area: string;
  passed: number;
  failed: number;
  skipped: number;
  total: number;
  coverage: number; // 0-1
  neverTested: boolean;
}

// Coverage stats for an area
export interface AreaCoverage {
  area: string;
  passed: number;
  failed: number;
  skipped: number;
  total: number;
  coverage: number; // 0-1
  specs: SpecCoverage[];
}

// A regression: a scenario that went from PASS to FAIL
export interface Regression {
  specId: string;
  scenarioId: string;
  previousStatus: "PASS";
  currentStatus: "FAIL";
  notes: string;
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
  evidence: {
    screenshots: "on_failure" | "always" | "never";
    traces: "on_failure" | "always" | "never";
    dom_snapshots: "on_failure" | "always" | "never";
  };
  paths: {
    specs_dir: string;
    runs_dir: string;
    reports_dir: string;
  };
}

// Resolved paths (absolute) computed from config
export interface ResolvedPaths {
  configDir: string;
  specsDir: string;
  runsDir: string;
  reportsDir: string;
}
