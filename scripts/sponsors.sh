#!/usr/bin/env bash
set -e

function info() {
    echo -e "\\033[1m\\033[32m>>>\\033[0m\\033[0m ${1}"
}

function error() {
    echo -e "\\033[1m\\033[31m!!!\\033[0m\\033[0m ${1}"
    exit 1
}

function update() {
    if [[ -v CI ]]
    then
        info 'Configuring Git'

        git config --global user.email noreply@inko-lang.org
        git config --global user.name 'Inko bot'
    fi

    info 'Updating sponsors data'
    make setup sponsors
    info 'Committing changes (if any)'

    git checkout --quiet main
    git add --all source/data/sponsors.json

    if git commit -m 'Update sponsors data'
    then
        for i in {1..3}
        do
            info 'Pushing to main'

            git push origin main && return

            # A push might fail randomly, or because new commits are added. To
            # handle the latter, we'll try to update the local clone before
            # retrying.
            git pull --rebase origin main >/dev/null 2>&1

            info "Push attempt $i failed, retrying..."
        done

        error 'Failed to push the changes'
    else
        info 'Nothing to commit'
    fi
}

update
