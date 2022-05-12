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
        git remote add https "https://project_7421203_bot:${SPONSORS_ACCESS_TOKEN}@gitlab.com/inko-lang/website.git" >/dev/null 2>&1 || true
    fi

    info 'Updating sponsors data'

    bundle exec rake sponsors:update sponsors:prune_logos

    info 'Committing changes (if any)'

    git checkout --quiet master
    git add --all source/images/sponsors data/sponsors.yml

    if git commit -m 'Update sponsors data'
    then
        for i in {1..3}
        do
            info 'Pushing to master'

            git push https master && return

            # A push might fail randomly, or because new commits are added. To
            # handle the latter, we'll try to update the local clone before
            # retrying.
            git pull --rebase origin master >/dev/null 2>&1

            info "Push attempt $i failed, retrying..."
        done

        error 'Failed to push the changes'
    else
        info 'Nothing to commit'
    fi
}

update
