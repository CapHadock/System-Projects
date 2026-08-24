#!/usr/bin/env python3
"""
Automatic Downloads Organizer

This script organizes files inside a target folder (by default, the user's
Downloads folder) into subfolders based on file type/extension.

It can run in two modes:
  1. One-time mode: organizes existing files once and exits.
  2. Watch mode: keeps running and organizes new files as they appear.

Usage:
    python organize_downloads.py                 # organize once, default Downloads folder
    python organize_downloads.py --path /some/dir # organize once, custom folder
    python organize_downloads.py --watch          # keep watching for new files
"""

import argparse
import shutil
import sys
import time
from pathlib import Path

# Mapping of category name -> list of file extensions (lowercase, with dot)
CATEGORIES = {
    "Images": [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".svg", ".webp", ".heic"],
    "Documents": [".pdf", ".doc", ".docx", ".txt", ".rtf", ".odt", ".md"],
    "Spreadsheets": [".xls", ".xlsx", ".csv", ".ods"],
    "Presentations": [".ppt", ".pptx", ".odp"],
    "Audio": [".mp3", ".wav", ".flac", ".aac", ".ogg", ".m4a"],
    "Video": [".mp4", ".mov", ".avi", ".mkv", ".wmv", ".flv"],
    "Archives": [".zip", ".rar", ".7z", ".tar", ".gz", ".bz2"],
    "Installers": [".exe", ".msi", ".dmg", ".pkg", ".deb", ".rpm", ".apk"],
    "Code": [".py", ".js", ".ts", ".html", ".css", ".json", ".java", ".c", ".cpp", ".sh"],
}

# Files that don't match any category above will go here
DEFAULT_CATEGORY = "Others"


def get_category(extension: str) -> str:
    """Return the category name for a given file extension."""
    extension = extension.lower()
    for category, extensions in CATEGORIES.items():
        if extension in extensions:
            return category
    return DEFAULT_CATEGORY


def get_unique_destination(destination: Path) -> Path:
    """
    Avoid overwriting files with the same name by appending a counter
    (e.g. file.pdf -> file (1).pdf) if the destination already exists.
    """
    if not destination.exists():
        return destination

    stem = destination.stem
    suffix = destination.suffix
    parent = destination.parent
    counter = 1

    new_destination = parent / f"{stem} ({counter}){suffix}"
    while new_destination.exists():
        counter += 1
        new_destination = parent / f"{stem} ({counter}){suffix}"

    return new_destination


def organize_folder(folder: Path) -> int:
    """
    Organize all files directly inside `folder` into category subfolders.
    Returns the number of files moved.
    """
    if not folder.exists():
        print(f"Error: the folder '{folder}' does not exist.")
        sys.exit(1)

    moved_count = 0

    # Only look at files directly inside the folder (not subfolders)
    for item in folder.iterdir():
        if item.is_dir():
            continue  # skip folders, including the ones we create

        # Skip temporary/incomplete downloads
        if item.suffix.lower() in (".crdownload", ".part", ".tmp"):
            continue

        category = get_category(item.suffix)
        category_folder = folder / category
        category_folder.mkdir(exist_ok=True)

        destination = get_unique_destination(category_folder / item.name)

        try:
            shutil.move(str(item), str(destination))
            print(f"Moved: {item.name} -> {category}/")
            moved_count += 1
        except Exception as error:
            print(f"Could not move {item.name}: {error}")

    return moved_count


def watch_folder(folder: Path, interval: int = 5) -> None:
    """
    Continuously check the folder for new files every `interval` seconds
    and organize them. Stop with Ctrl+C.
    """
    print(f"Watching '{folder}' for new files (checking every {interval}s)...")
    print("Press Ctrl+C to stop.\n")

    try:
        while True:
            organize_folder(folder)
            time.sleep(interval)
    except KeyboardInterrupt:
        print("\nStopped watching.")


def get_default_downloads_folder() -> Path:
    """Return the default Downloads folder for the current user."""
    return Path.home() / "Downloads"


def main():
    parser = argparse.ArgumentParser(description="Automatically organize files in a Downloads folder by type.")
    parser.add_argument(
        "--path",
        type=str,
        default=None,
        help="Path to the folder to organize (default: ~/Downloads)",
    )
    parser.add_argument(
        "--watch",
        action="store_true",
        help="Keep running and organize new files as they appear",
    )
    parser.add_argument(
        "--interval",
        type=int,
        default=5,
        help="Seconds between checks in watch mode (default: 5)",
    )

    args = parser.parse_args()
    folder = Path(args.path) if args.path else get_default_downloads_folder()

    if args.watch:
        watch_folder(folder, args.interval)
    else:
        moved = organize_folder(folder)
        if moved == 0:
            print("No files needed organizing.")
        else:
            print(f"\nDone. {moved} file(s) organized.")


if __name__ == "__main__":
    main()