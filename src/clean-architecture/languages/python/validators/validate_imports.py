#!/usr/bin/env python3
"""
Validate that imports follow Clean Architecture dependency rules.

Dependencies must flow inward:
Frameworks → Infrastructure → Application → Domain

Usage:
    python validate_imports.py [path_to_src]
"""

import ast
import sys
import os
from pathlib import Path
from typing import List, Tuple, Set, Dict


class ImportValidator:
    """Validates imports follow Clean Architecture rules."""

    LAYERS = {
        'domain': 0,
        'application': 1,
        'infrastructure': 2,
        'frameworks': 3,
        'framework': 3,  # Alternative naming
        'adapters': 2,   # Alternative naming
        'use_cases': 1,  # Alternative naming
        'entities': 0,   # Alternative naming
    }

    def __init__(self, root_path: Path):
        self.root_path = root_path
        self.violations: List[Tuple[str, str, str]] = []

    def validate(self) -> bool:
        """Validate all Python files in the project."""
        print(f"Validating imports in: {self.root_path}")
        print("-" * 50)

        for py_file in self._find_python_files():
            self._validate_file(py_file)

        if self.violations:
            self._report_violations()
            return False
        else:
            print("✅ All imports follow Clean Architecture rules!")
            return True

    def _find_python_files(self) -> List[Path]:
        """Find all Python files in the project."""
        return list(self.root_path.rglob("*.py"))

    def _validate_file(self, file_path: Path) -> None:
        """Validate imports in a single file."""
        # Skip test files and __pycache__
        if '__pycache__' in str(file_path) or 'test' in str(file_path):
            return

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                tree = ast.parse(f.read(), filename=str(file_path))

            file_layer = self._get_layer(file_path)
            if file_layer is None:
                return  # File not in a recognized layer

            imports = self._extract_imports(tree)
            for import_path in imports:
                self._check_import(file_path, file_layer, import_path)

        except Exception as e:
            print(f"Warning: Could not parse {file_path}: {e}")

    def _get_layer(self, file_path: Path) -> int:
        """Determine which layer a file belongs to."""
        relative_path = file_path.relative_to(self.root_path)
        parts = relative_path.parts

        for part in parts:
            layer_name = part.lower()
            if layer_name in self.LAYERS:
                return self.LAYERS[layer_name]

        return None

    def _extract_imports(self, tree: ast.AST) -> Set[str]:
        """Extract all imports from an AST."""
        imports = set()

        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    imports.add(alias.name)
            elif isinstance(node, ast.ImportFrom):
                if node.module:
                    imports.add(node.module)

        return imports

    def _check_import(self, file_path: Path, file_layer: int, import_path: str) -> None:
        """Check if an import violates dependency rules."""
        # Skip standard library and third-party imports
        if not self._is_project_import(import_path):
            return

        import_layer = self._get_import_layer(import_path)
        if import_layer is None:
            return

        # Check dependency rule: can only import from same or inner layers
        if import_layer > file_layer:
            violation = (
                str(file_path.relative_to(self.root_path)),
                self._get_layer_name(file_layer),
                self._get_layer_name(import_layer)
            )
            self.violations.append(violation)

    def _is_project_import(self, import_path: str) -> bool:
        """Check if an import is from the project (not stdlib or third-party)."""
        # Check if import matches any layer name
        first_part = import_path.split('.')[0].lower()
        return first_part in self.LAYERS

    def _get_import_layer(self, import_path: str) -> int:
        """Get the layer of an imported module."""
        parts = import_path.split('.')
        for part in parts:
            layer_name = part.lower()
            if layer_name in self.LAYERS:
                return self.LAYERS[layer_name]
        return None

    def _get_layer_name(self, layer_index: int) -> str:
        """Get the name of a layer by its index."""
        for name, index in self.LAYERS.items():
            if index == layer_index:
                # Return the primary name (not alternatives)
                if name in ['domain', 'application', 'infrastructure', 'frameworks']:
                    return name
        return f"Layer {layer_index}"

    def _report_violations(self) -> None:
        """Report all dependency violations."""
        print("❌ Dependency Rule Violations Found:")
        print("-" * 50)

        for file_path, from_layer, to_layer in self.violations:
            print(f"  {file_path}")
            print(f"    → {from_layer} layer imports from {to_layer} layer")
            print(f"    ✗ Dependencies must flow inward!")
            print()

        print(f"Total violations: {len(self.violations)}")
        print("\nHow to fix:")
        print("- Domain should not import from any outer layer")
        print("- Application should only import from Domain")
        print("- Infrastructure should only import from Domain and Application")
        print("- Frameworks can import from any inner layer")


class LayerStructureValidator:
    """Validates that files are in the correct layers."""

    EXPECTED_CONTENTS = {
        'domain': [
            'entities', 'value_objects', 'services', 'repositories',
            'exceptions', 'events', 'specifications'
        ],
        'application': [
            'use_cases', 'services', 'dtos', 'ports', 'views'
        ],
        'infrastructure': [
            'repositories', 'gateways', 'services', 'persistence',
            'messaging', 'cache'
        ],
        'frameworks': [
            'web', 'cli', 'api', 'controllers', 'routers',
            'middleware', 'config', 'dependencies'
        ]
    }

    def __init__(self, root_path: Path):
        self.root_path = root_path
        self.issues: List[str] = []

    def validate(self) -> bool:
        """Validate layer structure."""
        print("\nValidating layer structure...")
        print("-" * 50)

        for layer_name in ['domain', 'application', 'infrastructure', 'frameworks']:
            layer_path = self.root_path / layer_name
            if layer_path.exists():
                self._check_layer_contents(layer_name, layer_path)

        if self.issues:
            print("⚠️  Structure warnings:")
            for issue in self.issues:
                print(f"  - {issue}")
            return False
        else:
            print("✅ Layer structure looks good!")
            return True

    def _check_layer_contents(self, layer_name: str, layer_path: Path) -> None:
        """Check if layer contains appropriate subdirectories."""
        subdirs = [d.name for d in layer_path.iterdir() if d.is_dir() and not d.name.startswith('__')]

        # Check for suspicious directories
        if layer_name == 'domain':
            suspicious = ['controllers', 'routers', 'api', 'database', 'orm']
            for subdir in subdirs:
                if subdir.lower() in suspicious:
                    self.issues.append(
                        f"Domain layer contains '{subdir}' - this might belong in an outer layer"
                    )

        elif layer_name == 'application':
            suspicious = ['models', 'database', 'orm', 'api', 'controllers']
            for subdir in subdirs:
                if subdir.lower() in suspicious:
                    self.issues.append(
                        f"Application layer contains '{subdir}' - this might belong in another layer"
                    )


def main():
    """Main entry point."""
    if len(sys.argv) > 1:
        root_path = Path(sys.argv[1])
    else:
        # Try common source directory names
        for dirname in ['src', 'app', '.']:
            root_path = Path(dirname)
            if root_path.exists():
                break
        else:
            print("Error: Could not find source directory.")
            print("Usage: python validate_imports.py [path_to_src]")
            sys.exit(1)

    if not root_path.exists():
        print(f"Error: Path '{root_path}' does not exist.")
        sys.exit(1)

    print("=" * 50)
    print("Clean Architecture Import Validator")
    print("=" * 50)

    # Validate imports
    import_validator = ImportValidator(root_path)
    import_valid = import_validator.validate()

    # Validate structure
    structure_validator = LayerStructureValidator(root_path)
    structure_valid = structure_validator.validate()

    print("\n" + "=" * 50)
    if import_valid and structure_valid:
        print("✅ All validations passed!")
        sys.exit(0)
    else:
        print("❌ Validation failed. Please fix the issues above.")
        sys.exit(1)


if __name__ == "__main__":
    main()