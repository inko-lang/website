#!/usr/bin/env bash

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
        info 'Configuring SSH'

        mkdir -p ~/.ssh
        echo "$SSH_PUBLIC_KEY" > ~/.ssh/id_ed25519.pub
        echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_ed25519

        chmod 700 ~/.ssh
        chmod 644 ~/.ssh/id_ed25519.pub
        chmod 600 ~/.ssh/id_ed25519

        eval "$(ssh-agent -s)"

        ssh-add ~/.ssh/id_ed25519

        info 'Configuring Git'

        git config --global user.email noreply@inko-lang.org
        git config --global user.name 'Inko bot'
        git remote add ssh git@gitlab.com:inko-lang/website.git >/dev/null 2>&1 || true
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

            git push ssh master && return

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
