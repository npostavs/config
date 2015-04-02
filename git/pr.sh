#!/bin/bash

# Usage: fetch|merge <prnum1> <prnum2>...
#      | fetch

case "$1" in
    m*) op=merge;;
    f*) op=fetch;;
    *) echo "Don't know how to $1" >&2
        exit 1;;
esac
shift

prnums=($(eval "echo $*"))

refspecs=()
for prnum in "${prnums[@]}" ; do
    case "$op" in
        fetch) refspecs+=("refs/pull/$prnum/head:refs/remotes/upstream/pr/$prnum");;
        merge) refspecs+=("upstream/pr/$prnum");;
    esac
done

if [ $# -eq 0 ] ; then
    op=fetch-info
fi

case "$op" in
    fetch-info)
        user_repo=$(git config remote.upstream.url | cut -d: -f2 | cut -d. -f1)
        curl "https://api.github.com/repos/$user_repo/pulls" -o .git/info/pulls.json -D -
        ;;
    fetch) git fetch upstream "${refspecs[@]}";;
    merge)
        prnames=()
        for prnum in "${prnums[@]}" ; do
            prtitle=$(jq -r ".[] | select(.number == $prnum) | .title" .git/info/pulls.json)
            prname=$(jq -r ".[] | select(.number == $prnum) | .head.ref" .git/info/pulls.json)
            if [ "$prname" = master ] ; then
                prname=pr$prnum
            fi
            git branch -l "$prname" "upstream/pr/$prnum"
            git config --local "branch.$prname.description" "$prtitle"
            prnames+=("$prname")
        done
        git merge "${prnames[@]}"
        ;;
esac
