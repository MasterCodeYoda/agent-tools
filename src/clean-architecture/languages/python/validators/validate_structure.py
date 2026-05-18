#!/usr/bin/env python3
"""
Validate that project structure follows Clean Architecture patterns.

Checks:
- Proper layer organization
- Naming conventions
- File placement
- Encapsulation patterns

Usage:
    python validate_structure.py [path_to_src]
"""

import ast
import re
import sys
import os
from pathlib import Path
from typing import List, Dict, Set, Tuple, Optional


class NamingConventionValidator:
    """Validates naming conventions."""

    def __init__(self):
        self.issues: List[str] = []

    def validate_file(self, file_path: Path) -> None:
        """Validate naming in a single file."""
        # Skip test files
        if 'test' in str(file_path):
            return

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                tree = ast.parse(content, filename=str(file_path))

            self._check_classes(tree, file_path)
            self._check_functions(tree, file_path)
            self._check_constants(tree, file_path)

        except Exception as e:
            pass  # Silently skip files that can't be parsed

    def _check_classes(self, tree: ast.AST, file_path: Path) -> None:
        """Check class naming conventions."""
        for node in ast.walk(tree):
            if isinstance(node, ast.ClassDef):
                if not self._is_pascal_case(node.name):
                    self.issues.append(
                        f"{file_path}: Class '{node.name}' should use PascalCase"
                    )

    def _check_functions(self, tree: ast.AST, file_path: Path) -> None:
        """Check function naming conventions."""
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                # Skip dunder methods
                if node.name.startswith('__') and node.name.endswith('__'):
                    continue

                if not self._is_snake_case(node.name):
                    self.issues.append(
                        f"{file_path}: Function '{node.name}' should use snake_case"
                    )

    def _check_constants(self, tree: ast.AST, file_path: Path) -> None:
        """Check constant naming conventions."""
        for node in ast.walk(tree):
            if isinstance(node, ast.Assign):
                for target in node.targets:
                    if isinstance(target, ast.Name):
                        # If assigned at module level and all caps, it's likely a constant
                        if target.id.isupper() and '_' in target.id:
                            if not self._is_upper_snake_case(target.id):
                                self.issues.append(
                                    f"{file_path}: Constant '{target.id}' should use UPPER_SNAKE_CASE"
                                )

    @staticmethod
    def _is_pascal_case(name: str) -> bool:
        """Check if name is in PascalCase."""
        return re.match(r'^[A-Z][a-zA-Z0-9]*$', name) is not None

    @staticmethod
    def _is_snake_case(name: str) -> bool:
        """Check if name is in snake_case."""
        return re.match(r'^[a-z_][a-z0-9_]*$', name) is not None

    @staticmethod
    def _is_upper_snake_case(name: str) -> bool:
        """Check if name is in UPPER_SNAKE_CASE."""
        return re.match(r'^[A-Z][A-Z0-9_]*$', name) is not None

    def report(self) -> bool:
        """Report naming convention issues."""
        if self.issues:
            print("\n⚠️  Naming Convention Issues:")
            for issue in self.issues[:10]:  # Limit to first 10 issues
                print(f"  - {issue}")
            if len(self.issues) > 10:
                print(f"  ... and {len(self.issues) - 10} more")
            return False
        return True


class EncapsulationValidator:
    """Validates encapsulation patterns."""

    def __init__(self):
        self.issues: List[str] = []

    def validate_file(self, file_path: Path) -> None:
        """Validate encapsulation in a single file."""
        # Only check domain and application layers
        if 'domain' not in str(file_path) and 'application' not in str(file_path):
            return

        # Skip test files
        if 'test' in str(file_path):
            return

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                tree = ast.parse(content, filename=str(file_path))

            self._check_public_attributes(tree, file_path)
            self._check_property_usage(tree, file_path)

        except Exception:
            pass  # Silently skip files that can't be parsed

    def _check_public_attributes(self, tree: ast.AST, file_path: Path) -> None:
        """Check for public attributes that should be private."""
        for node in ast.walk(tree):
            if isinstance(node, ast.ClassDef):
                # Skip Protocol classes and dataclasses
                if self._is_protocol_or_dataclass(node):
                    continue

                for item in node.body:
                    if isinstance(item, ast.AnnAssign) and isinstance(item.target, ast.Name):
                        attr_name = item.target.id
                        # Check if it's a public mutable attribute
                        if not attr_name.startswith('_') and attr_name != attr_name.upper():
                            self.issues.append(
                                f"{file_path}: Class '{node.name}' has public attribute '{attr_name}'. "
                                "Consider making it private with underscore prefix."
                            )

    def _check_property_usage(self, tree: ast.AST, file_path: Path) -> None:
        """Check for proper use of properties for controlled access."""
        for node in ast.walk(tree):
            if isinstance(node, ast.ClassDef):
                has_private_attrs = False
                has_properties = False

                for item in node.body:
                    # Check for private attributes
                    if isinstance(item, ast.FunctionDef) and item.name == '__init__':
                        for stmt in ast.walk(item):
                            if isinstance(stmt, ast.Assign):
                                for target in stmt.targets:
                                    if isinstance(target, ast.Attribute):
                                        if target.attr.startswith('_'):
                                            has_private_attrs = True

                    # Check for properties
                    if isinstance(item, ast.FunctionDef):
                        for decorator in item.decorator_list:
                            if isinstance(decorator, ast.Name) and decorator.id == 'property':
                                has_properties = True

                # Suggest using properties for classes with private attributes
                if has_private_attrs and not has_properties and 'entity' in file_path.lower():
                    self.issues.append(
                        f"{file_path}: Class '{node.name}' has private attributes. "
                        "Consider using @property for controlled access."
                    )

    @staticmethod
    def _is_protocol_or_dataclass(node: ast.ClassDef) -> bool:
        """Check if class is a Protocol or dataclass."""
        # Check base classes
        for base in node.bases:
            if isinstance(base, ast.Name) and base.id in ['Protocol', 'BaseModel']:
                return True

        # Check decorators
        for decorator in node.decorator_list:
            if isinstance(decorator, ast.Name) and decorator.id == 'dataclass':
                return True
            if isinstance(decorator, ast.Call):
                if isinstance(decorator.func, ast.Name) and decorator.func.id == 'dataclass':
                    return True

        return False

    def report(self) -> bool:
        """Report encapsulation issues."""
        if self.issues:
            print("\n⚠️  Encapsulation Issues:")
            for issue in self.issues[:5]:  # Limit to first 5 issues
                print(f"  - {issue}")
            if len(self.issues) > 5:
                print(f"  ... and {len(self.issues) - 5} more")
            return False
        return True


class LayerContentValidator:
    """Validates that files are in appropriate layers."""

    PATTERNS = {
        'domain': {
            'allowed': [
                r'entity', r'entities', r'value_object', r'aggregate',
                r'service', r'repository', r'exception', r'event', r'specification'
            ],
            'forbidden': [
                r'controller', r'router', r'endpoint', r'api',
                r'database', r'sql', r'orm', r'http', r'request', r'response'
            ]
        },
        'application': {
            'allowed': [
                r'use_case', r'usecase', r'service', r'dto', r'port', r'view'
            ],
            'forbidden': [
                r'controller', r'router', r'endpoint', r'sql', r'orm', r'http'
            ]
        },
        'infrastructure': {
            'allowed': [
                r'repository', r'gateway', r'adapter', r'persistence',
                r'database', r'cache', r'message', r'email', r'storage'
            ],
            'forbidden': [
                r'use_case', r'usecase', r'entity', r'value_object'
            ]
        },
        'frameworks': {
            'allowed': [
                r'controller', r'router', r'endpoint', r'api', r'cli',
                r'middleware', r'config', r'dependencies', r'handler'
            ],
            'forbidden': []
        }
    }

    def __init__(self):
        self.issues: List[str] = []

    def validate_file(self, file_path: Path) -> None:
        """Check if file is in the appropriate layer."""
        # Determine which layer the file is in
        layer = self._get_layer(file_path)
        if not layer:
            return

        file_name = file_path.stem.lower()
        patterns = self.PATTERNS.get(layer, {})

        # Check forbidden patterns
        for pattern in patterns.get('forbidden', []):
            if re.search(pattern, file_name):
                self.issues.append(
                    f"{file_path}: File '{file_path.name}' contains '{pattern}' "
                    f"which shouldn't be in {layer} layer"
                )

    @staticmethod
    def _get_layer(file_path: Path) -> Optional[str]:
        """Determine which layer a file belongs to."""
        parts = file_path.parts
        for part in parts:
            if part.lower() in ['domain', 'application', 'infrastructure', 'frameworks', 'framework']:
                return part.lower() if part.lower() != 'framework' else 'frameworks'
        return None

    def report(self) -> bool:
        """Report layer content issues."""
        if self.issues:
            print("\n⚠️  Layer Content Issues:")
            for issue in self.issues[:5]:
                print(f"  - {issue}")
            if len(self.issues) > 5:
                print(f"  ... and {len(self.issues) - 5} more")
            return False
        return True


class UseCaseStructureValidator:
    """Validates use case structure (Request, Response, UseCase in same file)."""

    def __init__(self):
        self.issues: List[str] = []

    def validate_file(self, file_path: Path) -> None:
        """Validate use case file structure."""
        # Only check application layer use case files
        if 'application' not in str(file_path) or 'use_case' not in file_path.stem.lower():
            return

        # Skip test files
        if 'test' in str(file_path):
            return

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                tree = ast.parse(content, filename=str(file_path))

            classes = self._get_class_names(tree)
            self._check_use_case_pattern(classes, file_path)

        except Exception:
            pass

    @staticmethod
    def _get_class_names(tree: ast.AST) -> Set[str]:
        """Get all class names in the file."""
        return {node.name for node in ast.walk(tree) if isinstance(node, ast.ClassDef)}

    def _check_use_case_pattern(self, classes: Set[str], file_path: Path) -> None:
        """Check if use case follows the pattern."""
        use_case_classes = [c for c in classes if 'UseCase' in c]

        if use_case_classes:
            for use_case in use_case_classes:
                base_name = use_case.replace('UseCase', '')

                # Check for corresponding Request and Response
                expected_request = f"{base_name}Request"
                expected_response = f"{base_name}Response"

                if expected_request not in classes:
                    self.issues.append(
                        f"{file_path}: UseCase '{use_case}' missing '{expected_request}' class"
                    )
                if expected_response not in classes:
                    self.issues.append(
                        f"{file_path}: UseCase '{use_case}' missing '{expected_response}' class"
                    )

    def report(self) -> bool:
        """Report use case structure issues."""
        if self.issues:
            print("\n⚠️  Use Case Structure Issues:")
            for issue in self.issues[:5]:
                print(f"  - {issue}")
            if len(self.issues) > 5:
                print(f"  ... and {len(self.issues) - 5} more")
            return False
        return True


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
            print("Usage: python validate_structure.py [path_to_src]")
            sys.exit(1)

    if not root_path.exists():
        print(f"Error: Path '{root_path}' does not exist.")
        sys.exit(1)

    print("=" * 50)
    print("Clean Architecture Structure Validator")
    print("=" * 50)
    print(f"Validating: {root_path}")
    print("-" * 50)

    all_valid = True

    # Find all Python files
    py_files = list(root_path.rglob("*.py"))
    print(f"Found {len(py_files)} Python files to validate")

    # Run validators
    validators = [
        ("Naming Conventions", NamingConventionValidator()),
        ("Encapsulation", EncapsulationValidator()),
        ("Layer Content", LayerContentValidator()),
        ("Use Case Structure", UseCaseStructureValidator())
    ]

    for validator_name, validator in validators:
        print(f"\nValidating {validator_name}...")
        for py_file in py_files:
            validator.validate_file(py_file)

        if not validator.report():
            all_valid = False

    print("\n" + "=" * 50)
    if all_valid:
        print("✅ All structure validations passed!")
        sys.exit(0)
    else:
        print("❌ Structure validation found issues. Consider fixing them.")
        sys.exit(1)


if __name__ == "__main__":
    main()