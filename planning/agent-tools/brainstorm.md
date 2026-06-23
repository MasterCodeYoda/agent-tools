# Brainstorm: Personify Skill

Status: Explored

## Seed Concept

Agents currently have no project-scoped, persistent, and easily-maintainable way to encode "how I should behave and communicate on this project." The result is generic, drifting, or repeatedly re-explained interpersonal style (tone, voice, structure preferences, humor level, reference habits) and loss of important persistent facts (user preferences, team norms, stakeholder context). The chosen direction is a new top-level user-invocable skill `/personify` (source at `src/personify/`) that authors and maintains a structured personality/voice/facts profile inside the target's `.agent-tools/personify/` (parallel to charter/ and swarm/). The skill both provides the management interface and the guidance agents use to consult and apply the profile for consistent, project-tuned inter-personal and communication behavior.

## The Itch

Teams and solo developers using agents across sessions and projects want the agent to "know how to be" with them on a specific codebase or collaboration — without having to paste the same instructions every new chat or watch the agent forget preferences. The charter captures *what the project is*; there is a gap for *how the agent should show up and talk* on it. Storing this in `.agent-tools/` makes it durable, git-trackable (where appropriate), and automatically loadable alongside other project memory.

## Directions Considered

- **Dedicated top-level `/personify` skill + data directory under `.agent-tools/`** — A first-class skill family with its own `SKILL.md`, invocable commands for init/view/edit, and a clear home for profile files. Compelling because it gives discoverability, dedicated surface area, and clean separation of concerns (charter = project identity, personify = agent persona/voice/facts). Mirrors the shape of swarm, workflow, product, etc. families. Risk: another thing to learn; potential for overlap with charter content.

- **Extend the existing charter system** (e.g. add `personality.md` or `communication.md` under `.agent-tools/charter/`). Compelling because it reuses `/swarm:init` bootstrap, the AGENTS.md loading mechanism, and the established "umbrella" pattern. Lower cognitive surface. Risk: muddies the charter's focus on project/engineering/workflow identity; makes the "how the *agent* behaves" concern harder to evolve independently; no natural `/personify` command.

- **Voice/rewrite-focused utility** (profile data is secondary or lighter). The skill emphasizes active use cases like "rewrite this plan/response in the project voice" with example pairs and rules. Compelling for immediate value and integration with review/compound flows. Risk: under-serves the "persistent facts" and steering/traits aspect; maintenance of the profile might be neglected if the skill is seen only as a rewriting tool.

- **Broader "agent relationship" profile** including decision biases, escalation rules, collaboration style beyond just speaking/writing. Compelling for deeper control. Risk: scope creep into general agent configuration; harder to keep focused and lightweight.

## Chosen Direction

Dedicated top-level `/personify` skill (src/personify/SKILL.md) that owns both the authoring UX and the profile storage convention inside `.agent-tools/`. 

Why it won: The user explicitly asked for a new skill at `src/personify` invocable as `/personify`. A distinct family gives it the same discoverability and structure as other successful additions (swarm, product, qa, etc.). It cleanly parallels the charter (project facts) with agent-specific interpersonal/voice facts. It also gives a natural place to document "how agents should use this profile" so it actually steers behavior.

## Deliberately Undecided

- Exact data format and schema for the profile (pure markdown sections? YAML frontmatter + examples? multiple files?).
- Command surface details (`/personify`, `/personify:init`, sub-skills, edit flows).
- Precise loading mechanism (extension to AGENTS.md block, explicit references, or both).
- Scope boundaries (pure communication/voice vs. some decision-making guidance; per-user vs. project-wide facts).
- Bootstrap story (does `/personify` do its own init like `/swarm:init`, or is it invoked after charter exists?).
- Relationship to existing "memory" or conversation analysis features.

## Open Questions for Refinement

- [ ] What is the minimal viable profile structure that delivers value without being burdensome to maintain?
- [ ] How should the profile be referenced/loaded so agents actually use it reliably (especially across different hosts)?
- [ ] Should there be a distinction between "agent personality" (how the agent presents itself) and "user/team preferences" (facts about how to treat the human)?
- [ ] Integration points with `/workflow:setup`, `/swarm:init`, and the charter precedence rules?
- [ ] Publishing and agent-specific markup needs for the skill itself (does behavior differ meaningfully between Claude/Grok/Factory)?
