#!/bin/bash
  if  [[ $TRAVIS_OS_NAME = linux ]] && [[ $TRAVIS_RUST_VERSION = nightly ]] && [[ $TRAVIS_BRANCH = master ]] && [[ $TRAVIS_PULL_REQUEST = false ]]; then
    PROJECT_NAME=${TRAVIS_REPO_SLUG##*/};
    cargo doc &&
    echo "<meta http-equiv=refresh content=0;url=${PROJECT_NAME}/index.html>" > target/doc/index.html &&
    pip install --user ghp-import &&
    mkdir docs-stage &&
    COMMIT_MSG=$(git log -1 | tr '[:upper:]' '[:lower:]' | grep "version change to " | tr -d ' ') &&
    git clone https://github.com/${TRAVIS_REPO_SLUG}.git  docs-stage &&
    cd docs-stage &&
    git checkout gh-pages;
    rm -rf .git*;
    # lines 35 - 39 is a patch script for handling old gh-pages structure
    OLD_FILE=$(ls | grep "main.js");
    if [[ $OLD_FILE == main* ]]; then
      rm -rf * &&
      echo "<meta http-equiv=refresh content=0;url=master/${PROJECT_NAME}/index.html>" > index.html;
    fi
    if [[ $COMMIT_MSG == versionchangeto* ]];  then
      VERSION=${COMMIT_MSG##*to} &&
      mkdir -p $VERSION &&
      mkdir -p latest &&
      cp -rf ../target/doc/* $VERSION &&
      cp -rf ../target/doc/* latest &&
      git config --global user.email dev@miadsafe.net &&
      git config --global user.name maidsafe-jenkins &&
      git tag $VERSION -a -m "Version $VERSION" &&
      git push -q https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG} --tags;
    fi
    mkdir -p master
    cp -rf ../target/doc/* master &&
    cd .. &&
    ghp-import -n docs-stage &&
    git push -fq https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}.git gh-pages;
    sudo apt-get update -qq;
    sudo apt-get install -qq libcurl4-openssl-dev libelf-dev libdw-dev binutils-dev;
    wget https://github.com/SimonKagstrom/kcov/archive/master.tar.gz &&
    tar xzf master.tar.gz &&
    mkdir kcov-master/build &&
    cd kcov-master/build &&
    cmake .. -DCMAKE_INSTALL_PREFIX=~/ &&
    make &&
    mkdir ~/bin
    mkdir ~/lib
    make install &&
    cd ../.. &&
    ~/bin/kcov --coveralls-id=$TRAVIS_JOB_ID --exclude-pattern=/.cargo target/kcov target/debug/$PROJECT_NAME-*;
  fi
