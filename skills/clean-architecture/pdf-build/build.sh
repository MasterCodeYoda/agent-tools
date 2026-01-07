#!/bin/bash
set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$SCRIPT_DIR/output"
COMBINED_MD="$OUTPUT_DIR/combined.md"
OUTPUT_PDF="$OUTPUT_DIR/clean-architecture-guide.pdf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Clean Architecture PDF Build ===${NC}"
echo "Source: $SOURCE_DIR"
echo "Output: $OUTPUT_DIR"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Step 1: Preprocess markdown files
echo -e "${YELLOW}[1/3] Preprocessing markdown files...${NC}"
python3 "$SCRIPT_DIR/preprocess.py" "$SOURCE_DIR" "$COMBINED_MD"
echo ""

# Step 2: Run Pandoc
echo -e "${YELLOW}[2/3] Running Pandoc...${NC}"
pandoc "$COMBINED_MD" \
    --metadata-file="$SCRIPT_DIR/metadata.yaml" \
    --include-in-header="$SCRIPT_DIR/header.tex" \
    --pdf-engine=xelatex \
    --toc \
    --toc-depth=3 \
    --number-sections \
    --syntax-highlighting=tango \
    --top-level-division=chapter \
    -V colorlinks=true \
    -V linkcolor=NavyBlue \
    -V urlcolor=NavyBlue \
    -f markdown+smart+pipe_tables+fenced_code_blocks+backtick_code_blocks+fenced_code_attributes+definition_lists+footnotes \
    -o "$OUTPUT_PDF"
echo ""

# Step 3: Verify output
echo -e "${YELLOW}[3/3] Verifying output...${NC}"
if [ -f "$OUTPUT_PDF" ]; then
    FILE_SIZE=$(ls -lh "$OUTPUT_PDF" | awk '{print $5}')

    # Try to get page count (pdfinfo may not be available)
    if command -v pdfinfo &> /dev/null; then
        PAGE_COUNT=$(pdfinfo "$OUTPUT_PDF" 2>/dev/null | grep Pages | awk '{print $2}' || echo "unknown")
    else
        PAGE_COUNT="(install poppler-utils for page count)"
    fi

    echo -e "${GREEN}Success!${NC}"
    echo "Output: $OUTPUT_PDF"
    echo "Size: $FILE_SIZE"
    echo "Pages: $PAGE_COUNT"
else
    echo -e "${RED}Error: PDF generation failed${NC}"
    exit 1
fi

# Optional: Clean up intermediate files
if [ "$1" = "--clean" ]; then
    echo ""
    echo -e "${YELLOW}Cleaning intermediate files...${NC}"
    rm -f "$COMBINED_MD"
    echo "Removed: $COMBINED_MD"
fi

echo ""
echo -e "${GREEN}=== Build Complete ===${NC}"
