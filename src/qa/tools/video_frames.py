#!/usr/bin/env python3
"""Extract frames from a video at configurable intervals for QA inspection."""

import argparse
import os
import sys

import cv2


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Extract frames from a video at regular intervals."
    )
    parser.add_argument("video_path", help="Path to the video file")
    parser.add_argument(
        "--output-dir",
        default="/tmp/qa-frames/",
        help="Directory to save extracted frames (default: /tmp/qa-frames/)",
    )
    parser.add_argument(
        "--interval",
        type=float,
        default=2,
        help="Interval between frames in seconds (default: 2)",
    )
    parser.add_argument(
        "--format",
        choices=["png", "jpg", "webp"],
        default="png",
        help="Image format for saved frames (default: png)",
    )
    args = parser.parse_args()

    cap = cv2.VideoCapture(args.video_path)
    if not cap.isOpened():
        print(f"Error: could not open video '{args.video_path}'", file=sys.stderr)
        sys.exit(1)

    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    if fps <= 0 or total_frames <= 0:
        print(f"Error: could not read video properties from '{args.video_path}'", file=sys.stderr)
        cap.release()
        sys.exit(1)

    duration = total_frames / fps
    os.makedirs(args.output_dir, exist_ok=True)

    extracted = 0
    timestamp = 0.0
    while timestamp < duration:
        frame_number = int(timestamp * fps)
        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_number)
        ret, frame = cap.read()
        if not ret:
            break

        filename = f"frame_{timestamp:04.0f}s.{args.format}"
        filepath = os.path.join(args.output_dir, filename)
        cv2.imwrite(filepath, frame)
        print(filepath)
        extracted += 1
        timestamp += args.interval

    cap.release()

    video_name = os.path.basename(args.video_path)
    print(
        f"Extracted {extracted} frames from {video_name} "
        f"({duration:.0f}s total, every {args.interval}s)"
    )


if __name__ == "__main__":
    main()
