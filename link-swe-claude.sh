#!/usr/bin/env bash
# link-swe-claude.sh - symlink swe-claude's Claude scaffolding into another project.
#
# Usage: link-swe-claude.sh [-n] TARGET_DIR
#   -n   dry run: report what would happen, change nothing
#
# Links .claude, docs, plans and CLAUDE.md from this directory into TARGET_DIR:
#   docs, plans  if TARGET_DIR already has one, link it as ai-docs / ai-plans instead
#   .claude      if TARGET_DIR already has one, report it and leave it alone
#   CLAUDE.md    an existing CLAUDE.md is moved to CLAUDE.md.orig first
# If TARGET_DIR is in a git work tree, the new names are added to that repo's
# .git/info/exclude so they never show up in 'git status'.
# Safe to re-run: links that already point here are left as they are.
# Exit status is 1 if anything could not be linked (e.g. the project has its own .claude).
#
# Written for bash 3.2 (macOS) and later.

set -u

prog=$(basename "$0")
SRC=$(cd "$(dirname "$0")" && pwd -P)

usage() { echo "usage: $prog [-n] TARGET_DIR" >&2; exit 2; }
say()   { printf '%s\n' "$*"; }
warn()  { printf '%s: %s\n' "$prog" "$*" >&2; }
run()   { if [ "$dry_run" -eq 1 ]; then say "  (dry run) $*"; else "$@"; fi; }

# exists PATH: true for files, dirs, and symlinks (including broken ones)
exists() { [ -e "$1" ] || [ -L "$1" ]; }

# is_our_link PATH NAME: true if PATH is a symlink to $SRC/NAME
is_our_link() { [ -L "$1" ] && [ "$(readlink "$1")" = "$SRC/$2" ]; }

dry_run=0
while getopts n opt; do
    case $opt in
        n) dry_run=1 ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))
[ $# -eq 1 ] || usage

TARGET=$(cd "$1" 2>/dev/null && pwd -P) || { warn "not a directory: $1"; exit 1; }
[ "$TARGET" != "$SRC" ] || { warn "target is swe-claude itself"; exit 1; }

say "Linking $SRC into $TARGET"

excludes=""   # space-separated names to add to .git/info/exclude
renamed=""    # names that had to be linked under an ai- prefix
status=0

# make_link NAME DEST: link $SRC/NAME as $TARGET/DEST
make_link() {
    local name=$1 dest=$2 path="$TARGET/$2"
    if is_our_link "$path" "$name"; then
        say "ok:   $dest already links to $SRC/$name"
    elif exists "$path"; then
        warn "$dest already exists in $TARGET; not linking $name"
        status=1
        return 1
    else
        say "link: $dest -> $SRC/$name"
        run ln -s "$SRC/$name" "$path" || { status=1; return 1; }
    fi
    excludes="$excludes $dest"
}

in_git=0
git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1 && in_git=1

is_tracked() {
    [ "$in_git" -eq 1 ] && git -C "$TARGET" ls-files --error-unmatch -- "$1" >/dev/null 2>&1
}

# .claude: never renamed; an existing one is reported and left alone.
if exists "$TARGET/.claude" && ! is_our_link "$TARGET/.claude" .claude; then
    warn ".claude already exists in $TARGET; leaving it alone (swe-claude's .claude is NOT linked)"
    status=1
else
    make_link .claude .claude
fi

# docs, plans: fall back to ai-<name> when the project already has its own.
for name in docs plans; do
    if exists "$TARGET/$name" && ! is_our_link "$TARGET/$name" "$name"; then
        is_our_link "$TARGET/ai-$name" "$name" ||
            warn "$name already exists in $TARGET; linking swe-claude's $name as ai-$name"
        make_link "$name" "ai-$name" && renamed="$renamed $name"
    else
        make_link "$name" "$name"
    fi
done

# CLAUDE.md: move an existing one aside, then link.
c="$TARGET/CLAUDE.md"
if exists "$c" && ! is_our_link "$c" CLAUDE.md; then
    if exists "$c.orig"; then
        warn "CLAUDE.md and CLAUDE.md.orig both exist in $TARGET; leaving both alone (CLAUDE.md NOT linked)"
        status=1
    else
        if is_tracked CLAUDE.md; then
            warn "CLAUDE.md is tracked by git in $TARGET; git will now report it as changed"
            warn "  to hide that locally: git -C '$TARGET' update-index --skip-worktree CLAUDE.md"
        fi
        say "move: CLAUDE.md -> CLAUDE.md.orig"
        if run mv "$c" "$c.orig"; then
            excludes="$excludes CLAUDE.md.orig"
            if [ "$dry_run" -eq 1 ]; then      # nothing really moved, so don't re-check
                say "link: CLAUDE.md -> $SRC/CLAUDE.md"
                excludes="$excludes CLAUDE.md"
            else
                make_link CLAUDE.md CLAUDE.md
            fi
        else
            status=1
        fi
    fi
else
    make_link CLAUDE.md CLAUDE.md
fi

# Keep the links out of the project's git status.
if [ "$in_git" -eq 1 ] && [ -n "$excludes" ]; then
    ex=$(git -C "$TARGET" rev-parse --git-path info/exclude)
    case $ex in /*) ;; *) ex="$TARGET/$ex" ;; esac
    prefix=$(git -C "$TARGET" rev-parse --show-prefix)
    for name in $excludes; do
        is_tracked "$name" && continue          # excluding a tracked path does nothing
        # No trailing slash: git sees a symlink as a file, not a directory.
        pat="/$prefix$name"
        grep -qxF "$pat" "$ex" 2>/dev/null && continue
        say "git:  add $pat to $ex"
        if [ "$dry_run" -eq 0 ]; then
            mkdir -p "$(dirname "$ex")" && printf '%s\n' "$pat" >> "$ex"
        fi
    done
fi

for name in $renamed; do
    say "note: CLAUDE.md refers to $name/, which is ai-$name/ in this project"
done

exit $status
