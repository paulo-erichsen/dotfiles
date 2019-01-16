#!/usr/bin/env python3

r"""
find_broken_mkv_subs.py

this program finds all the mkv files with at least one
  subtitle or audio that doesn't have a language set

the idea behind this is that some systems such as plex
  needs to know the language of videos before it can
  correctly select the subtitles of choice

once this program identifies which files needs fixing,
  you could go to the directory of files and check which
  languages are used and then run a command similar to as
  follows:

# set audio tracks 1 and 2 to a language and also
# set subtitle track 1 to the given language
find . -type f -iname '*.mkv' -exec mkvpropedit {} \
      --edit track:a1 --set language=jpn \
      --edit track:a2 --set language=eng \
      --edit track:s1 --set language=eng \;
"""

import argparse
import os
import json
import shutil
import subprocess
from typing import List


def check_prereqs() -> None:
    """
    checks if mkvmerge (from mkvtoolnix) exists
    """
    if not shutil.which("mkvmerge"):
        raise FileNotFoundError("mkvmerge not found")


def find_mkv_files(path: str) -> List[str]:
    """
    returns a list of all mkv files for the given path
    """
    mkv_files: List[str] = []
    for root, _dir, files in os.walk(path):
        for file in files:
            if file.endswith(".mkv"):
                mkv_files.append(os.path.join(root, file))
    return mkv_files if mkv_files else [path]


def display_no_lang_mkv_files(files: List[str], search_audio: bool) -> None:
    """
    displays a list of all mkv files that contains language undefined

    by default, this function only returns files with subtitles undefined
    but if search_audio is true, then search for both subtitles and audio tracks
    """
    # und_lang_files = []
    for file in files:
        process = subprocess.run(["mkvmerge", "-J", file], capture_output=True)
        if process.returncode == 0:
            j = json.loads(process.stdout)
            name = j["file_name"]
            for track in j["tracks"]:
                # id = track["id"]
                track_type = track["type"]
                # codec = track["codec"]
                if (search_audio and track_type != "video") or track_type == "subtitles":
                    lang = track["properties"]["language"]
                    if lang == "und":
                        # und_lang_files.append(name)
                        print(type, search_audio, name, track)
                        break
        else:
            print("failed to parse: ", file, " - ret_code: ", process.returncode)
    # return und_lang_files


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        "Search mkv files for subtiles [and videos] with languages undefined"
    )
    parser.add_argument(
        "--audio",
        action="store_true",
        help="search for audio tracks as well (by default only subtitles are checked)",
    )
    parser.add_argument("path", type=str, help="path for mkv files")
    ARGS = parser.parse_args()
    check_prereqs()
    FILES = find_mkv_files(ARGS.path)
    display_no_lang_mkv_files(FILES, ARGS.audio)
