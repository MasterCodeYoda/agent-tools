# Clean Architecture PDF Build

This directory contains tools to generate a comprehensive PDF from the Clean Architecture skill documentation.

## Prerequisites

### Required
- **Python 3.8+** - For the preprocessing script
- **Pandoc 2.10+** - Document converter ([pandoc.org](https://pandoc.org/installing.html))
- **XeLaTeX** - PDF engine (part of TeX Live or MacTeX)

### Installing on macOS
```bash
# Install Pandoc
brew install pandoc

# Install MacTeX (full installation, ~4GB)
brew install --cask mactex

# Or install BasicTeX (smaller, ~100MB) + required packages
brew install --cask basictex
sudo tlmgr update --self
sudo tlmgr install collection-fontsrecommended fancyhdr titlesec xcolor framed fancyvrb enumitem microtype etoolbox booktabs longtable float
```

### Installing on Ubuntu/Debian
```bash
sudo apt-get install pandoc texlive-xetex texlive-fonts-recommended texlive-latex-extra
```

## Building the PDF

### Quick Build
```bash
./build.sh
```

### Build with Cleanup
```bash
./build.sh --clean
```

This removes the intermediate `combined.md` file after PDF generation.

## Output

The generated PDF will be at:
```
output/clean-architecture-guide.pdf
```

Expected output:
- **Pages**: ~150-200
- **Size**: ~2-4 MB
- **Features**: Table of contents, syntax highlighting, numbered sections

## Directory Structure

```
pdf-build/
├── build.sh           # Build script
├── metadata.yaml      # Pandoc configuration (title, fonts, etc.)
├── header.tex         # LaTeX styling (chapters, headers, code blocks)
├── preprocess.py      # Combines markdown files, converts links
├── output/            # Generated files
│   ├── combined.md    # Intermediate combined markdown (optional)
│   └── clean-architecture-guide.pdf
└── README.md          # This file
```

## Customization

### Changing Fonts
Edit `metadata.yaml`:
```yaml
mainfont: "Georgia"
monofont: "Fira Code"
```

### Changing Colors
Edit `header.tex`:
```latex
\definecolor{chaptercolor}{RGB}{0,100,150}
```

### Adding/Removing Content
Edit the `structure` list in `preprocess.py` to change which files are included and their order.

## Troubleshooting

### "Font not found" Error
Install the required fonts or change to system-available fonts in `metadata.yaml`.

### "Package not found" Error
Install missing LaTeX packages:
```bash
sudo tlmgr install <package-name>
```

### Large File Size
The PDF includes syntax highlighting which increases size. For a smaller file:
```bash
# Add to pandoc command in build.sh:
--highlight-style=monochrome
```

### Missing pdfinfo
Page count display requires poppler-utils:
```bash
# macOS
brew install poppler

# Ubuntu/Debian
sudo apt-get install poppler-utils
```
