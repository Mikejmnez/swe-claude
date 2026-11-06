#!/usr/bin/env bash
# link-swe-claude.sh - install swe-claude's Claude scaffolding into another project.
#
# Usage: link-swe-claude.sh [-n] [-c FILE] TARGET_DIR
#   -n        dry run: report what would happen, change nothing
#   -c FILE   import this directory's FILE (default CLAUDE.md) into TARGET_DIR/CLAUDE.md,
#             e.g. -c CLAUDE-myproject.md
#
# Links .claude from this directory into TARGET_DIR, imports this directory's CLAUDE
# file into the project's own CLAUDE.md, and COPIES ai-docs and ai-plans (each project keeps its own requirements, ADRs, bugs, tasks
# and plans, with its own ID sequences, committed in that project):
#   ai-docs, ai-plans  copied from this directory when TARGET_DIR has none; a project
#                      that already has its own is left alone; a link to this
#                      directory (made by an older version) is replaced by a copy
#   .claude            if TARGET_DIR already has one, report it and leave it alone
#   CLAUDE.md          the project keeps its own; an '@~/.../CLAUDE.md' import line
#                      is appended to it (or it is created holding just that line).
#                      A CLAUDE.md that is a link here (made by an older version) is
#                      removed and CLAUDE.md.orig, if any, is moved back first
# The copies come from this directory's working tree: copy from a checkout of main,
# whose ai-docs holds only the _EXAMPLE_ entries.
# Links made by older versions of this script (docs or ai-docs -> $SRC/docs, and
# the same for plans) are removed.
# If TARGET_DIR is in a git work tree, the .claude link is added to that repo's
# .git/info/exclude so they never show up in 'git status'; ai-docs and ai-plans are
# NOT excluded (commit them, with CLAUDE.md), and exclude entries left by older
# versions for docs, plans, ai-docs, ai-plans, CLAUDE.md or CLAUDE.md.orig are
# taken out.
# Safe to re-run: links that already point here are left as they are.
# Exit status is 1 if anything could not be linked or copied (e.g. the project has
# its own .claude).
#
# Written for bash 3.2 (macOS) and later.

set -u

prog=$(basename "$0")
SRC=$(cd "$(dirname "$0")" && pwd -P)

usage() { echo "usage: $prog [-n] [-c FILE] TARGET_DIR" >&2; exit 2; }
say()   { printf '%s\n' "$*"; }
warn()  { printf '%s: %s\n' "$prog" "$*" >&2; }
run()   { if [ "$dry_run" -eq 1 ]; then say "  (dry run) $*"; else "$@"; fi; }

# exists PATH: true for files, dirs, and symlinks (including broken ones)
exists() { [ -e "$1" ] || [ -L "$1" ]; }

# is_our_link PATH NAME: true if PATH is a symlink to $SRC/NAME
is_our_link() { [ -L "$1" ] && [ "$(readlink "$1")" = "$SRC/$2" ]; }

# is_swe_link PATH: true if PATH is a symlink to anything in $SRC
is_swe_link() { [ -L "$1" ] && case $(readlink "$1") in "$SRC"/*) true ;; *) false ;; esac; }

dry_run=0
claude_md=CLAUDE.md
while getopts nc: opt; do
    case $opt in
        n) dry_run=1 ;;
        c) claude_md=$OPTARG ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))
[ $# -eq 1 ] || usage

case $claude_md in
    */*|"") warn "-c takes a file name in $SRC, not a path: $claude_md"; exit 1 ;;
esac
[ -f "$SRC/$claude_md" ] || { warn "no such file in $SRC: $claude_md"; exit 1; }

TARGET=$(cd "$1" 2>/dev/null && pwd -P) || { warn "not a directory: $1"; exit 1; }
[ "$TARGET" != "$SRC" ] || { warn "target is swe-claude itself"; exit 1; }

say "Installing $SRC into $TARGET"

excludes=""        # space-separated names to add to .git/info/exclude
stale_excludes=""  # names of removed old links to take out of .git/info/exclude
removed=""         # names of old links removed (matters only in a dry run)
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

# Remove links made by older versions of this script, when swe-claude's
# directories were docs and plans (linked as docs/plans or ai-docs/ai-plans).
for old in docs plans; do
    for dest in "$old" "ai-$old"; do
        is_our_link "$TARGET/$dest" "$old" || continue
        say "remove: $dest (old link to $SRC/$old)"
        if run rm "$TARGET/$dest"; then
            removed="$removed $dest"
            [ "$dest" = "$old" ] && stale_excludes="$stale_excludes $dest"
        else
            status=1
        fi
    done
done

# ai-docs, ai-plans: each project gets its own copy, never a shared link.
for name in ai-docs ai-plans; do
    path="$TARGET/$name"
    stale_excludes="$stale_excludes $name"      # older versions excluded the link
    case " $removed " in *" $name "*) was_removed=1 ;; *) was_removed=0 ;; esac
    if is_our_link "$path" "$name"; then
        say "remove: $name (link to $SRC/$name; replacing it with a copy)"
        run rm "$path" || { status=1; continue; }
        was_removed=1
    fi
    if [ "$was_removed" -eq 0 ] && exists "$path"; then
        say "ok:   $name already exists in $TARGET; keeping the project's own copy"
        continue
    fi
    say "copy: $SRC/$name -> $name"
    run cp -R "$SRC/$name" "$path" || status=1
done

# CLAUDE.md: the project keeps its own; swe-claude's rules come in through an
# @-import line appended to it. A link made by an older version is undone first.
case $SRC in
    "$HOME"/*) imp_path="~${SRC#"$HOME"}/$claude_md" ;;
    *)         imp_path="$SRC/$claude_md" ;;
esac
import_line="@$imp_path"
c="$TARGET/CLAUDE.md"
stale_excludes="$stale_excludes CLAUDE.md CLAUDE.md.orig"
check="$c"                                    # the file that will end up as CLAUDE.md
if is_swe_link "$c"; then
    say "remove: CLAUDE.md (link to $(readlink "$c"))"
    run rm "$c" || status=1
    if exists "$c.orig"; then
        say "restore: CLAUDE.md.orig -> CLAUDE.md"
        run mv "$c.orig" "$c" || status=1
        [ "$dry_run" -eq 1 ] && check="$c.orig"   # nothing really moved
    else
        check=""
    fi
fi
if [ -L "$c" ] && ! is_swe_link "$c"; then
    warn "CLAUDE.md in $TARGET is a link to $(readlink "$c"); not appending to it (swe-claude's rules NOT imported)"
    status=1
elif [ -n "$check" ] && [ -f "$check" ] && grep -qxF "$import_line" "$check"; then
    say "ok:   CLAUDE.md already imports $imp_path"
else
    say "import: append $import_line to CLAUDE.md"
    if [ "$dry_run" -eq 0 ]; then
        {
            [ -s "$c" ] && printf '\n'
            printf '%s\n%s\n' "<!-- swe-claude planning rules, added by link-swe-claude.sh -->" "$import_line"
        } >> "$c" || status=1
    fi
fi

# Keep the links out of the project's git status.
if [ "$in_git" -eq 1 ] && [ -n "$excludes$stale_excludes" ]; then
    ex=$(git -C "$TARGET" rev-parse --git-path info/exclude)
    case $ex in /*) ;; *) ex="$TARGET/$ex" ;; esac
    prefix=$(git -C "$TARGET" rev-parse --show-prefix)
    for name in $stale_excludes; do
        pat="/$prefix$name"
        grep -qxF "$pat" "$ex" 2>/dev/null || continue
        say "git:  remove $pat from $ex"
        if [ "$dry_run" -eq 0 ]; then
            { grep -vxF "$pat" "$ex" > "$ex.tmp.$$"; [ $? -le 1 ]; } &&
                mv "$ex.tmp.$$" "$ex" || { rm -f "$ex.tmp.$$"; status=1; }
        fi
    done
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

exit $status
