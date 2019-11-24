#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import argparse
from pathlib import Path

PROJECT_DIR = os.path.realpath(os.path.join(
    os.path.dirname(os.path.realpath(__file__)), ".."))


def replace_keep_case(word, replacement, text):
    # https://stackoverflow.com/questions/24893977/whats-the-best-way-to-regex-replace-a-string-in-python-but-keep-its-case
    def func(match):
        g = match.group()
        if g.islower():
            return replacement.lower()
        if g.istitle():
            return replacement.title()
        if g.isupper():
            return replacement.upper()
        return replacement
    return re.sub(word, func, text, flags=re.I)


def process(path, source, target):
    if path.is_file():
        # Replace file content
        with open(path) as f:
            old_text = f.read()
        new_text = replace_keep_case(source, target, old_text)
        if old_text != new_text:
            print("- Replacing content of {}".format(path.name))
            with open(path, "w") as f:
                f.write(new_text)
    # Rename both files and folders
    new_path = path.with_name(replace_keep_case(source, target, path.name))
    if new_path.name != path.name:
        print("- Renaming {} -> {}".format(path.name, new_path.name))
        path.rename(new_path)


def bootstrap(source, target):
    # Process files fist
    for folder in ['src', 'cmake', 'tests']:
        for path in Path(os.path.join(PROJECT_DIR, folder)).rglob('*'):
            if path.is_file():
                process(path, source, target)
    for file in ['CMakeLists.txt', 'README.md']:
        path = Path(os.path.join(PROJECT_DIR, file))
        process(path, source, target)
    # Process folders afterwards
    for folder in ['src', 'cmake', 'tests']:
        for path in Path(os.path.join(PROJECT_DIR, folder)).rglob('*'):
            if path.is_dir():
                process(path, source, target)


def parse_args():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("target", help="target project name to rename into")
    parser.add_argument("-s", "--source", default="@Project_Name@", help="source project name to rename from")
    return parser.parse_args()


def main():
    args = parse_args()
    bootstrap(args.source, args.target)


if __name__ == "__main__":
    main()
