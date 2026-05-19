"""Generate a Quarto navbar version dropdown for multiversion altdoc sites.

Reads the current dev version from DESCRIPTION and all release tags from git,
then rewrites the "Versions" menu block in altdoc/quarto_website.yml so that:
  - The current stable release is labeled "vX.Y.Z (stable)" → root URL
  - The development build is labeled "<version> (dev)"      → /dev/ URL
  - A separator followed by each older tag links to /vX.Y.Z/ (previous versions)

This script is called by the docs GitHub Actions workflow before render_docs().
"""

import subprocess
import re
import sys

# Base URL for the deployed documentation site.
# Update this when adapting the template for a different repository.
BASE_URL = "https://d-morrison.github.io/gdl/"

# --- Helpers ---


def _parse_version(content):
    """Return the Version field from DESCRIPTION file content, or None."""
    for line in content.splitlines():
        m = re.match(r"^Version:\s+(.+)", line)
        if m:
            return m.group(1).strip()
    return None


def _run_git(*args):
    """Run a git command and return the CompletedProcess result.

    Calls sys.exit(1) with a descriptive message if the git executable
    cannot be launched (e.g. git not installed or permission denied).
    """
    try:
        return subprocess.run(["git", *args], capture_output=True, text=True)
    except OSError as e:
        print(f"Failed to execute git command: {e}", file=sys.stderr)
        sys.exit(1)


# --- Gather version information ---

# Get the development version from DESCRIPTION.
# On release builds the checked-out DESCRIPTION contains the release version
# (e.g. "1.0.0"), not the dev version.  Read origin/main:DESCRIPTION instead
# so the /dev/ link is always labeled with the actual development version.
# Fall back to the local file if the git command fails (e.g. no remote).
dev_version = None

result = _run_git("show", "origin/main:DESCRIPTION")
if result.returncode == 0:
    dev_version = _parse_version(result.stdout)

if dev_version is None:
    # Fallback: read local DESCRIPTION (works for non-release builds)
    try:
        with open("DESCRIPTION") as f:
            dev_version = _parse_version(f.read())
    except OSError as e:
        print(f"Could not open DESCRIPTION: {e}", file=sys.stderr)
        sys.exit(1)

if dev_version is None:
    print("Could not find Version field in DESCRIPTION", file=sys.stderr)
    sys.exit(1)

# Get release tags (vX.Y.Z only; tags with a dev component like v1.0.0.9000
# are excluded because they are not final releases)
result = _run_git("tag", "--sort=-version:refname")
if result.returncode != 0:
    print(f"git tag command failed:\n{result.stderr}", file=sys.stderr)
    sys.exit(1)
all_tags = result.stdout.strip().split("\n") if result.stdout.strip() else []
release_tags = [t for t in all_tags if re.match(r"^v\d+\.\d+\.\d+$", t)]
latest_tag = release_tags[0] if release_tags else None
prev_tags = release_tags[1:] if len(release_tags) > 1 else []

# --- Locate and replace the Versions block in quarto_website.yml ---

try:
    with open("altdoc/quarto_website.yml") as f:
        lines = f.readlines()
except OSError as e:
    print(f"Could not open altdoc/quarto_website.yml: {e}", file=sys.stderr)
    sys.exit(1)

# Find the "- text: Versions" line in the navbar configuration
start_idx = None
for i, line in enumerate(lines):
    if re.match(r'\s+- text: ["\']?Versions["\']?\s*$', line):
        start_idx = i
        break
if start_idx is None:
    print(
        'Could not find "- text: Versions" entry in altdoc/quarto_website.yml '
        "navbar configuration",
        file=sys.stderr,
    )
    sys.exit(1)

indent = len(lines[start_idx]) - len(lines[start_idx].lstrip())
base = " " * indent        # same indent level as "- text: Versions"
mi = " " * (indent + 2)    # menu: key
ii = " " * (indent + 4)    # individual menu items

# Find the end of the Versions block (first non-blank line at same or lower indent)
end_idx = start_idx + 1
while end_idx < len(lines):
    line = lines[end_idx]
    if line.strip() == "":
        end_idx += 1
        continue
    if len(line) - len(line.lstrip()) <= indent:
        break
    end_idx += 1

# --- Build the new Versions block ---

new_block = [
    f"{base}- text: Versions\n",
    f"{mi}menu:\n",
]

if latest_tag:
    new_block += [
        f'{ii}- text: "{latest_tag} (stable)"\n',
        f"{ii}  href: {BASE_URL}\n",
    ]

if dev_version:
    new_block += [
        f'{ii}- text: "{dev_version} (dev)"\n',
        f"{ii}  href: {BASE_URL}dev/\n",
    ]

if prev_tags:
    # "---" renders as a visual divider in the Quarto navbar dropdown
    new_block.append(f'{ii}- text: "---"\n')
    for tag in prev_tags:
        new_block += [
            f'{ii}- text: "{tag}"\n',
            f"{ii}  href: {BASE_URL}{tag}/\n",
        ]

# Write the updated file
new_lines = lines[:start_idx] + new_block + lines[end_idx:]
try:
    with open("altdoc/quarto_website.yml", "w") as f:
        f.writelines(new_lines)
except OSError as e:
    print(f"Could not write to altdoc/quarto_website.yml: {e}", file=sys.stderr)
    sys.exit(1)

print("Updated Versions dropdown:")
print("".join(new_block))
