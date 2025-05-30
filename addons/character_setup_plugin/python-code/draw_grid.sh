#!/bin/bash

INPUT_FILE="Grass-01.png"
OUTPUT_FILE="Grass-01-grid.png"
TILE_HEIGHT=32
NUM_ROWS=8
IMAGE_WIDTH=512 # (16 columns * 32px)

# Line color and thickness
STROKE_COLOR="red"
STROKE_WIDTH=1

# Build the draw commands
DRAW_COMMANDS=""
MAX_Y=$(( (NUM_ROWS - 1) * TILE_HEIGHT )) # Last line y-coordinate

for (( y_coord=TILE_HEIGHT; y_coord<=MAX_Y; y_coord+=TILE_HEIGHT )); do
    DRAW_COMMANDS+=" -draw \"line 0,${y_coord} $((IMAGE_WIDTH - 1)),${y_coord}\""
done

# Execute ImageMagick command
if [ -f "$INPUT_FILE" ]; then
    # Note: for `magick` (IM v7+), use `magick` instead of `convert`
    convert "$INPUT_FILE" \
        -stroke "$STROKE_COLOR" -strokewidth "$STROKE_WIDTH" \
        $DRAW_COMMANDS \
        "$OUTPUT_FILE"
    echo "Generated $OUTPUT_FILE with horizontal lines using bash script."
else
    echo "Error: Input file $INPUT_FILE not found."
fi