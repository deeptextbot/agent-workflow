#!/bin/sh
# Installs the skills, protocol and settings into a project. Safe to re-run:
# skills and protocol are refreshed, an existing workflow.yaml is kept.
set -eu

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
    echo "usage: install.sh <project-dir>" >&2
    exit 1
fi

source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target=$(CDPATH= cd -- "$1" && pwd)

mkdir -p "$target/.agents/skills" "$target/docs/features" "$target/docs/_wip"

for skill in feature plan code review; do
    rm -rf "$target/.agents/skills/$skill"
    cp -R "$source_dir/skills/$skill" "$target/.agents/skills/$skill"
done

cp "$source_dir/protocol.md" "$target/.agents/protocol.md"

if [ ! -e "$target/.agents/workflow.yaml" ]; then
    cp "$source_dir/workflow.yaml" "$target/.agents/workflow.yaml"
fi

touch "$target/.gitignore"
if ! grep -qxF 'docs/_wip/' "$target/.gitignore"; then
    # A file without a trailing newline would merge with the appended line.
    if [ -s "$target/.gitignore" ] && [ -n "$(tail -c 1 "$target/.gitignore")" ]; then
        echo >> "$target/.gitignore"
    fi
    echo 'docs/_wip/' >> "$target/.gitignore"
fi

echo "Installed into $target/.agents. Set rigor and check_command in .agents/workflow.yaml."
