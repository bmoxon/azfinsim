#!/bin/bash -e

# init-hn.sh
# init the environment for the headnode

echo "pulling azfinsim/run from github"

mkdir -p azfinsim-run
pushd azfinsim-run
git init
git config core.sparsecheckout true
echo run/bin/ >> .git/info/sparse-checkout
echo run/src/ >> .git/info/sparse-checkout
git remote add -f origin https://github.com/bmoxon/azfinsim.git
git pull origin cloudshell-noep

mkdir -p run/config
popd

echo "prepping the runvm (ubuntu)"
./azfinsim-run/run/bin/prep_ubuntu.sh
