#!/bin/sh

# $1 = <user>:<branch> -- copied from top line of pull request
#    | https://github.com/<user>/<repo>/tree/<branch> -- web url

IFS=:
set -- $1
unset IFS

if [ "$1" = https ] ; then
    IFS=/
    set -- $2
    unset IFS
    # 1 [https:]
    # 2 []
    # 3 [github.com]
    # 4 [<user>]
    # 5 [<repo>]
    # 6 [tree]
    # 7 [<branch>]
    user=$4
    # repo=$5.git
    branch=$7
else
    user=$1
    branch=$2
fi
repo=$(basename $(git config remote.origin.url))

if ! git config "remote.$user.url" >/dev/null ; then
    git remote add "$user" "git://github.com/$user/$repo"
fi
git fetch "$user" "$branch:refs/remotes/$user/$branch"
