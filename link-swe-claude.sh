#!/usr/bin/env bash
# link-swe-claude.sh - install swe-claude's Claude scaffolding into another project.
#
# Usage: link-swe-claude.sh [-n] [-c FILE] [-r DIR] TARGET_DIR
#   -n        dry run: report what would happen, change nothing
#   -c FILE   import this directory's FILE (default planning-rules.md) into
#             TARGET_DIR/CLAUDE.md
#   -r DIR    records mode: keep the project's ai-docs, ai-plans and CLAUDE.md in
#             DIR (e.g. one project's folder in a private records repo) and link
#             them into TARGET_DIR; see "Records mode" below
#
# Default mode. Links .claude from this directory into TARGET_DIR, imports this
# directory's planning rules into the project's own CLAUDE.md, and COPIES ai-docs
# and ai-plans from template/ (each project keeps its own requirements, ADRs, bugs,
# tasks and plans, with its own ID sequences, committed in that project):
#   ai-docs, ai-plans  copied from template/ when TARGET_DIR has none; a project
#                      that already has its own is left alone; a link to this
#                      directory (made by an older version) is replaced by a copy
#   .claude            if TARGET_DIR already has one, report it and leave it alone
#   CLAUDE.md          the project keeps its own; an '@~/.../planning-rules.md' import line
#                      is appended to it. A project with none gets template/CLAUDE.md
#                      (with {{...}} fields to fill in) and then the import line.
#                      A CLAUDE.md that is a link here (made by an older version) is
#                      removed and CLAUDE.md.orig, if any, is moved back first
# If TARGET_DIR is in a git work tree, the .claude link is added to that repo's
# .git/info/exclude so it never shows up in 'git status'; ai-docs and ai-plans are
# NOT excluded (commit them, with CLAUDE.md), and exclude entries left by older
# versions for docs, plans, ai-docs, ai-plans, CLAUDE.md or CLAUDE.md.orig are
# taken out -- except where that path is now a symlink (e.g. made by -r).
#
# Records mode (-r DIR). The records live in DIR, never in the project's git:
#   DIR                created if missing. DIR must not be TARGET_DIR, inside it, or
#                      inside this directory
#   DIR/ai-docs, DIR/ai-plans
#                      copied from template/ only when missing; never overwritten
#   DIR/CLAUDE.md      copied from template/CLAUDE.md when missing; the import line
#                      is appended when absent
#   TARGET_DIR/ai-docs, ai-plans, CLAUDE.md
#                      linked to the three above
#   TARGET_DIR/.claude a real directory (created if missing); inside it, commands,
#                      agents and rules are linked to this directory's. Anything else
#                      in it (plans/, skills/, settings.json, ...) is left alone, and
#                      settings.json is never linked
# Anything already in TARGET_DIR under one of those six names that is not the
# expected link is reported and left alone. All six links go in
# .git/info/exclude. This script never runs git in DIR: commit there yourself. On a
# second machine, clone the records repo to the same path and run the same command.
#
# Either mode: the copies come from template/ in this directory's working tree,
# which holds only the _EXAMPLE_ entries and plan templates. The top-level ai-docs
# and ai-plans are swe-claude's own records and are never copied.
# Links made by older versions of this script (docs or ai-docs -> $SRC/docs, and
# the same for plans) are removed.
# Safe to re-run: links that already point where they should are left as they are.
# Exit status is 1 if anything could not be linked or copied (e.g. the project has
# its own .claude in default mode).
#
# Written for bash 3.2 (macOS) and later.

set -u

prog=$(basename "$0")
SRC=$(cd "$(dirname "$0")" && pwd -P)

usage() { echo "usage: $prog [-n] [-c FILE] [-r DIR] TARGET_DIR" >&2; exit 2; }
say()   { printf '%s\n' "$*"; }
warn()  { printf '%s: %s\n' "$prog" "$*" >&2; }
run()   { if [ "$dry_run" -eq 1 ]; then say "  (dry run) $*"; else "$@"; fi; }

# exists PATH: true for files, dirs, and symlinks (including broken ones)
exists() { [ -e "$1" ] || [ -L "$1" ]; }

# is_our_link PATH NAME: true if PATH is a symlink to $SRC/NAME
is_our_link() { [ -L "$1" ] && [ "$(readlink "$1")" = "$SRC/$2" ]; }

# is_swe_link PATH: true if PATH is a symlink to anything in $SRC
is_swe_link() { [ -L "$1" ] && case $(readlink "$1") in "$SRC"/*) true ;; *) false ;; esac; }

# in_list WORD LIST: true if WORD is one of the space-separated words in LIST
in_list() { case " $2 " in *" $1 "*) true ;; *) false ;; esac; }

# resolve PATH: absolute path with symlinks resolved in the part that exists; the
# part that does not exist yet is appended as given (no . or .. allowed in it)
resolve() {
    local p=$1 rest="" base
    case $p in /*) ;; *) p="$PWD/$p" ;; esac
    p=${p%/}; [ -n "$p" ] || p=/
    while [ ! -d "$p" ]; do
        exists "$p" && return 1                  # exists but is not a directory
        base=$(basename "$p")
        case $base in .|..) return 1 ;; esac
        rest="/$base$rest"
        p=$(dirname "$p")
    done
    p=$(cd "$p" && pwd -P) || return 1
    printf '%s%s\n' "${p%/}" "$rest"
}

dry_run=0
claude_md=planning-rules.md
records=""
while getopts nc:r: opt; do
    case $opt in
        n) dry_run=1 ;;
        c) claude_md=$OPTARG ;;
        r) records=$OPTARG; [ -n "$records" ] || usage ;;
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

DIR=""
if [ -n "$records" ]; then
    DIR=$(resolve "$records") || { warn "-r: not a directory, or a path with . or ..: $records"; exit 1; }
    case $DIR in
        "$TARGET"|"$TARGET"/*) warn "-r: $DIR is the target or inside it"; exit 1 ;;
        "$SRC"|"$SRC"/*)       warn "-r: $DIR is inside swe-claude"; exit 1 ;;
    esac
    say "Installing $SRC into $TARGET, records in $DIR"
else
    say "Installing $SRC into $TARGET"
fi

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

# link_record NAME: link $DIR/NAME as $TARGET/NAME (records mode)
link_record() {
    local name=$1 path="$TARGET/$1"
    if [ -L "$path" ] && [ "$(readlink "$path")" = "$DIR/$name" ]; then
        say "ok:   $name already links to $DIR/$name"
    elif exists "$path" && ! in_list "$name" "$removed"; then
        warn "$name already exists in $TARGET and is not a link to $DIR/$name; leaving it alone"
        status=1
        return 1
    else
        say "link: $name -> $DIR/$name"
        run ln -s "$DIR/$name" "$path" || { status=1; return 1; }
    fi
    excludes="$excludes $name"
}

# The import line appended to CLAUDE.md.
case $SRC in
    "$HOME"/*) imp_path="~${SRC#"$HOME"}/$claude_md" ;;
    *)         imp_path="$SRC/$claude_md" ;;
esac
import_line="@$imp_path"

# append_import FILE LABEL: append the import line to FILE, shown as LABEL (not in
# a dry run)
append_import() {
    say "import: append $import_line to $2"
    [ "$dry_run" -eq 0 ] || return 0
    {
        [ -s "$1" ] && printf '\n'
        printf '%s\n%s\n' "<!-- swe-claude planning rules, added by link-swe-claude.sh -->" "$import_line"
    } >> "$1" || status=1
}

in_git=0
git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1 && in_git=1

is_tracked() {
    [ "$in_git" -eq 1 ] && git -C "$TARGET" ls-files --error-unmatch -- "$1" >/dev/null 2>&1
}

# .claude
if [ -n "$DIR" ]; then
    # Records mode: a real .claude, with swe-claude's subfolders linked inside it.
    if exists "$TARGET/.claude" && { [ -L "$TARGET/.claude" ] || [ ! -d "$TARGET/.claude" ]; }; then
        warn ".claude in $TARGET is a link or a file, not a directory; leaving it alone (commands, agents, rules NOT linked)"
        status=1
    else
        if ! exists "$TARGET/.claude"; then
            say "mkdir: .claude"
            run mkdir "$TARGET/.claude" || status=1
        fi
        for sub in commands agents rules; do
            make_link ".claude/$sub" ".claude/$sub"
        done
    fi
else
    # Default mode: never renamed; an existing one is reported and left alone.
    if exists "$TARGET/.claude" && ! is_our_link "$TARGET/.claude" .claude; then
        warn ".claude already exists in $TARGET; leaving it alone (swe-claude's .claude is NOT linked)"
        status=1
    else
        make_link .claude .claude
    fi
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

if [ -n "$DIR" ]; then
    # Records mode: seed DIR where it lacks something, then link it in.
    if [ ! -d "$DIR" ]; then
        say "mkdir: $DIR"
        run mkdir -p "$DIR" || { warn "cannot create $DIR"; exit 1; }
    fi
    for name in ai-docs ai-plans; do
        if exists "$DIR/$name"; then
            say "ok:   $DIR/$name already exists; keeping it"
        else
            say "copy: $SRC/template/$name -> $DIR/$name"
            run cp -R "$SRC/template/$name" "$DIR/$name" || status=1
        fi
        link_record "$name"
    done
    dc="$DIR/CLAUDE.md"
    if ! exists "$dc"; then
        say "copy: $SRC/template/CLAUDE.md -> $dc (fill in its {{...}} fields)"
        run cp "$SRC/template/CLAUDE.md" "$dc" || status=1
        append_import "$dc" "$dc"
    elif grep -qxF "$import_line" "$dc"; then
        say "ok:   $dc already imports $imp_path"
    else
        append_import "$dc" "$dc"
    fi
    link_record CLAUDE.md
else
    # ai-docs, ai-plans: each project gets its own copy, never a shared link.
    for name in ai-docs ai-plans; do
        path="$TARGET/$name"
        stale_excludes="$stale_excludes $name"      # older versions excluded the link
        if in_list "$name" "$removed"; then was_removed=1; else was_removed=0; fi
        if is_our_link "$path" "$name"; then
            say "remove: $name (link to $SRC/$name; replacing it with a copy)"
            run rm "$path" || { status=1; continue; }
            removed="$removed $name"
            was_removed=1
        fi
        if [ "$was_removed" -eq 0 ] && exists "$path"; then
            say "ok:   $name already exists in $TARGET; keeping the project's own copy"
            continue
        fi
        say "copy: $SRC/template/$name -> $name"
        run cp -R "$SRC/template/$name" "$path" || status=1
    done

    # CLAUDE.md: the project keeps its own; swe-claude's rules come in through an
    # @-import line appended to it. A link made by an older version is undone first.
    c="$TARGET/CLAUDE.md"
    stale_excludes="$stale_excludes CLAUDE.md CLAUDE.md.orig"
    check="$c"                                    # the file that will end up as CLAUDE.md
    if is_swe_link "$c"; then
        say "remove: CLAUDE.md (link to $(readlink "$c"))"
        run rm "$c" || status=1
        removed="$removed CLAUDE.md"
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
        if [ -z "$check" ] || [ ! -e "$check" ]; then
            say "copy: $SRC/template/CLAUDE.md -> CLAUDE.md (fill in its {{...}} fields)"
            run cp "$SRC/template/CLAUDE.md" "$c" || status=1
        fi
        append_import "$c" CLAUDE.md
    fi
fi

# Keep the links out of the project's git status.
if [ "$in_git" -eq 1 ] && [ -n "$excludes$stale_excludes" ]; then
    ex=$(git -C "$TARGET" rev-parse --git-path info/exclude)
    case $ex in /*) ;; *) ex="$TARGET/$ex" ;; esac
    prefix=$(git -C "$TARGET" rev-parse --show-prefix)
    for name in $stale_excludes; do
        # A path that is a symlink now (e.g. made by -r, or by hand) keeps its
        # entry, unless it is an old link this run is removing.
        [ -L "$TARGET/$name" ] && ! in_list "$name" "$removed" && continue
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
