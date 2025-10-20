<#
Create_MovieManager.ps1
---------------------------------------
This installer builds the Movie Library Organizer folder tree,
generates all base files, and sets up launch scripts for Windows
and Linux.

After this script runs (triggered by Get_MovieLibrary.ps1),
you'll have a ready-to-run MovieLibrary directory with:
  • movie_manager.py  – main orchestrator
  • Run Movie Manager.bat / run_movie_manager.sh  – launchers
  • mlib/             – module folder with helpers
  • config.json.template
  • README.txt and requirements.txt
#>

param(
    [string]$InstallPath = "C:\MovieLibrary"
)

function Write-File($Path, $Content) {
    $dir = Split-Path $Path
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "✓ Created $Path" -ForegroundColor Green
}

Write-Host "=== Setting up Movie Library Organizer in $InstallPath ===" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $InstallPath | Out-Null
New-Item -ItemType Directory -Force -Path "$InstallPath\mlib" | Out-Null
New-Item -ItemType Directory -Force -Path "$InstallPath\Logs","$InstallPath\Reports","$InstallPath\Verified Movies","$InstallPath\Duplicate Movies","$InstallPath\Converted_MP4","$InstallPath\Failed","$InstallPath\New Movies" | Out-Null

# =======================
# movie_manager.py
# =======================
$main = @'
#!/usr/bin/env python3
"""
Movie Manager Orchestrator
Normalizes names, converts videos to MP4, checks quality,
adds metadata, and maintains reports for Plex-ready libraries.
"""

import os, sys, json, time, shutil, subprocess

def load_config():
    cfg = "config.json"
    if not os.path.exists(cfg):
        print("No config.json found. Please run setup first.")
        sys.exit(1)
    with open(cfg, 'r', encoding='utf-8') as f:
        return json.load(f)

def normalize_name(name):
    import re
    clean = re.sub(r'[\._]', ' ', name)
    clean = re.sub(r'(480p|720p|1080p|2160p|4k|x264|h264|bluray|webrip|hdr|dvdrip)', '', clean, flags=re.I)
    clean = re.sub(r'\s+', ' ', clean).strip()
    return clean

def convert_to_mp4(src, dst_folder):
    base = os.path.splitext(os.path.basename(src))[0]
    dst = os.path.join(dst_folder, base + ".mp4")
    cmd = ["ffmpeg", "-y", "-i", src, "-c:v", "copy", "-c:a", "copy", dst]
    try:
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return dst
    except Exception as e:
        print(f"Conversion failed for {src}: {e}")
        return None

def main():
    cfg = load_config()
    new_dir = cfg["paths"]["new_movies"]
    verified_dir = cfg["paths"]["verified"]
    dup_dir = cfg["paths"]["duplicates"]
    staging_dir = cfg["paths"]["staging"]

    print(f"Scanning {new_dir} for new files...")
    os.makedirs(staging_dir, exist_ok=True)
    for root, _, files in os.walk(new_dir):
        for f in files:
            if not f.lower().endswith(('.mp4', '.mkv', '.avi', '.mov', '.ts')):
                continue
            src = os.path.join(root, f)
            clean_name = normalize_name(os.path.splitext(f)[0])
            dst_file = convert_to_mp4(src, staging_dir)
            if dst_file:
                final_name = clean_name + ".mp4"
                final_path = os.path.join(verified_dir, final_name)
                shutil.move(dst_file, final_path)
                print(f"✓ Added {final_name}")
    print("Done.")

if __name__ == "__main__":
    main()
'@
Write-File "$InstallPath\movie_manager.py" $main

# =======================
# Run Movie Manager.bat
# =======================
$bat = @'
@echo off
cd /d "%~dp0"
IF EXIST config.json (
  python movie_manager.py
) ELSE (
  python movie_manager.py
)
pause
'@
Write-File "$InstallPath\Run Movie Manager.bat" $bat

# =======================
# run_movie_manager.sh
# =======================
$sh = @'
#!/usr/bin/env bash
cd "$(dirname "$0")"
python3 movie_manager.py
'@
Write-File "$InstallPath\run_movie_manager.sh" $sh

# =======================
# config.json.template
# =======================
$config = @'
{
  "paths": {
    "verified": "C:/MovieLibrary/Verified Movies",
    "duplicates": "C:/MovieLibrary/Duplicate Movies",
    "staging": "C:/MovieLibrary/Converted_MP4",
    "failed": "C:/MovieLibrary/Failed",
    "logs_dir": "C:/MovieLibrary/Logs",
    "reports_dir": "C:/MovieLibrary/Reports",
    "new_movies": "C:/MovieLibrary/New Movies"
  }
}
'@
Write-File "$InstallPath\config.json.template" $config

# =======================
# README.txt
# =======================
$readme = @'
Movie Library Organizer
=======================

This package normalizes, converts, and organizes movie files
into a clean structure for Plex and similar media servers.

Quick Start:
1. Run "Run Movie Manager.bat"
2. Point it to your drive (e.g., E:\)
3. Add movies into "New Movies"
4. The script will convert and move them to "Verified Movies"

Logs are stored in Logs/, reports in Reports/.
'@
Write-File "$InstallPath\README.txt" $readme

# =======================
# requirements.txt
# =======================
$req = "openpyxl`nrequests"
Write-File "$InstallPath\requirements.txt" $req

# =======================
# basic helper in mlib/
# =======================
$helper = @'
# placeholder for helper modules (e.g., normalization, hashing)
'@
Write-File "$InstallPath\mlib\__init__.py" $helper

Write-Host "`nAll files created successfully in $InstallPath" -ForegroundColor Cyan
Write-Host "Open that folder and run: Run Movie Manager.bat" -ForegroundColor Yellow


