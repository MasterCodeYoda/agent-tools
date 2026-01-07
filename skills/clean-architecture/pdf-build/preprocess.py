#!/usr/bin/env python3
"""
Preprocess markdown files for Pandoc PDF generation.

Tasks:
1. Combine all markdown files in reading order
2. Strip YAML frontmatter from skill files
3. Convert internal .md links to readable references
4. Add LaTeX part breaks for organization
5. Normalize code fence languages
"""

import re
import sys
import os
from pathlib import Path


def strip_frontmatter(content: str) -> str:
    """Remove YAML frontmatter from markdown."""
    if content.startswith('---'):
        parts = content.split('---', 2)
        if len(parts) >= 3:
            return parts[2].lstrip('\n')
    return content


def convert_md_links(content: str) -> str:
    """
    Convert markdown file links to readable text.

    Examples:
    - [Domain Layer](domain.md) -> *Domain Layer*
    - [see patterns](references/layer-patterns.md#domain) -> *see patterns*
    """
    # Pattern: [text](path.md) or [text](path.md#anchor)
    link_pattern = r'\[([^\]]+)\]\(([^)]+\.md(?:#[^)]*)?)\)'

    def replace_link(match):
        text = match.group(1)
        # Just keep the link text in italics
        return f'*{text}*'

    return re.sub(link_pattern, replace_link, content)


def normalize_code_fences(content: str) -> str:
    """Normalize code fence language identifiers (map aliases to standard names)."""
    # Map common variations to standard names
    lang_map = {
        'ts': 'typescript',
        'js': 'javascript',
        'py': 'python',
        'cs': 'csharp',
        'sh': 'bash',
        'shell': 'bash',
        'yml': 'yaml',
    }

    def replace_fence(match):
        lang = match.group(1) or ''
        lang = lang.strip()
        if lang:
            # Only normalize if there's a language identifier
            lang = lang_map.get(lang.lower(), lang.lower())
            return f'```{lang}'
        # Leave empty fences as-is (they're closing fences)
        return '```'

    return re.sub(r'^```(\w*)$', replace_fence, content, flags=re.MULTILINE)


def process_file(filepath: Path) -> str:
    """Process a single markdown file."""
    content = filepath.read_text(encoding='utf-8')

    # Strip frontmatter if present
    content = strip_frontmatter(content)

    # Convert internal links
    content = convert_md_links(content)

    # Normalize code fences
    content = normalize_code_fences(content)

    return content


def add_part_break(title: str) -> str:
    """Generate LaTeX part break."""
    # Use raw LaTeX for part breaks
    return f'\n\n\\part{{{title}}}\n\n'


def main():
    """Main entry point."""
    if len(sys.argv) < 3:
        print("Usage: preprocess.py <input_dir> <output_file>")
        sys.exit(1)

    input_dir = Path(sys.argv[1])
    output_file = Path(sys.argv[2])

    # File order with part organization
    # Each tuple is (part_title, list_of_files)
    structure = [
        ("Foundation", [
            "SKILL.md",
            "references/primer.md",
            "references/core-concepts.md",
        ]),
        ("Layer Patterns", [
            "references/layer-patterns.md",
            "references/vertical-slicing.md",
            "references/implementation-strategy.md",
        ]),
        ("Language Guides", [
            "languages/python/guide.md",
            "languages/python/examples.md",
            "languages/typescript/guide.md",
            "languages/csharp/guide.md",
        ]),
        ("Practical Application", [
            "templates/decision-tree.md",
            "templates/user-story-checklist.md",
            "templates/architecture-review.md",
        ]),
        ("Complete Example", [
            "example-task-manager/README.md",
            "example-task-manager/domain.md",
            "example-task-manager/application.md",
            "example-task-manager/infrastructure.md",
            "example-task-manager/frameworks.md",
        ]),
        ("Resources", [
            "references/external-resources.md",
        ]),
    ]

    output_content = []
    files_processed = 0
    files_missing = 0

    for part_title, files in structure:
        output_content.append(add_part_break(part_title))

        for file_path in files:
            full_path = input_dir / file_path
            if full_path.exists():
                print(f"  Processing: {file_path}")
                content = process_file(full_path)
                output_content.append(content)
                output_content.append('\n\n')  # Separation between files
                files_processed += 1
            else:
                print(f"  Warning: File not found: {full_path}", file=sys.stderr)
                files_missing += 1

    # Write combined content
    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_text('\n'.join(output_content), encoding='utf-8')

    print(f"\nCombined {files_processed} files into {output_file}")
    if files_missing > 0:
        print(f"Warning: {files_missing} files were not found")


if __name__ == '__main__':
    main()
