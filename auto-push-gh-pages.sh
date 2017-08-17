#!/bin/sh
set -e
set +x
if test "$(git config remote.origin.url)" != "https://github.com/jsmaniac/journal-article.git"; then
  echo "Not on official repo, will not deploy gh-pages."
elif test "$TRAVIS_PULL_REQUEST" != "false"; then
  echo "This is a Pull Request, will not deploy gh-pages."
elif test "$TRAVIS_BRANCH" != "master"; then
  echo "Not on master branch (TRAVIS_BRANCH = $TRAVIS_BRANCH), will not deploy gh-pages."
# A key can be created following the steps at https://docs.travis-ci.com/user/encrypting-files/ .
#     ssh-keygen -f travis-deploy-key-id_rsa -C 'Deploy key for travis-ci'
#     travis encrypt-file travis-deploy-key-id_rsa
elif test -z "${encrypted_264397dfc790_key:-}" -o -z "${encrypted_264397dfc790_iv:-}"; then
  echo "Travis CI secure environment variables are unavailable, will not deploy gh-pages."
else
  set -x
  echo "Automatic push to gh-pages"

  # Git configuration:
  git config --global user.name "$(git log --format="%aN" HEAD -1) (Travis CI automatic commit)"
  git config --global user.email "$(git log --format="%aE" HEAD -1)"

  # SSH configuration
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  set +x
  if openssl aes-256-cbc -K $encrypted_264397dfc790_key -iv $encrypted_264397dfc790_iv -in travis-deploy-key-id_rsa.enc -out travis-deploy-key-id_rsa -d >/dev/null 2>&1; then
    echo "Decrypted key successfully."
  else
    echo "Error while decrypting key."
  fi
  mv travis-deploy-key-id_rsa ~/.ssh/travis-deploy-key-id_rsa
  set -x
  chmod 600 ~/.ssh/travis-deploy-key-id_rsa
  set +x
  eval `ssh-agent -s`
  set -x
  ssh-add ~/.ssh/travis-deploy-key-id_rsa

  TRAVIS_GH_PAGES_DIR="$HOME/travis-gh-pages-$(date +%s)"
  if test -e $TRAVIS_GH_PAGES_DIR; then rm -rf $TRAVIS_GH_PAGES_DIR; fi
  mkdir -p "$TRAVIS_GH_PAGES_DIR"
  mv -i main.pdf $TRAVIS_GH_PAGES_DIR/main.pdf
  git init $TRAVIS_GH_PAGES_DIR
  touch $TRAVIS_GH_PAGES_DIR/.nojekyll
  (cd $TRAVIS_GH_PAGES_DIR && git add -A . && git commit -m "Auto-publish to gh-pages") > commit.log || (cat commit.log && exit 1)
  (cd $TRAVIS_GH_PAGES_DIR && git log --oneline --decorate --graph -10)
  echo '(cd '"$TRAVIS_GH_PAGES_DIR"'; git push --force --quiet "git@github.com/jsmaniac/journal-article-gh-pages.git" master:gh-pages)'
  (cd $TRAVIS_GH_PAGES_DIR; git push --force --quiet "git@github.com:jsmaniac/journal-article-gh-pages.git" master:gh-pages >/dev/null 2>&1) >/dev/null 2>&1 # redirect to /dev/null to avoid showing credentials.
fi