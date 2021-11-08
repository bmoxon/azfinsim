#!/bin/bash -e

# init-hn.sh
# init the environment for the headnode

echo "pulling azfinsim/run from github"

mkdir -p azfinsim-run
pushd azfinsim-run
git init
git config core.sparsecheckout true
echo config/ >> .git/info/sparse-checkout
echo run/bin/ >> .git/info/sparse-checkout
echo run/src/ >> .git/info/sparse-checkout
rem=$(git remote)
if [ "$rem" != "origin" ]; then
  git remote add -f origin https://github.com/bmoxon/azfinsim.git
fi
git pull origin cloudshell-noep
popd

echo "prepping the runvm (ubuntu)"
./azfinsim-run/run/bin/prep_ubuntu.sh
