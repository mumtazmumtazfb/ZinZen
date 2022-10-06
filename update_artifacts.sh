#!/bin/bash
echo Updating artifacts
echo Checking if jq is installed...
if ! command -v jq &> /dev/null
then
    echo "Installing jq - needed for parsing json..."
    sudo apt-get -y install jq > /dev/null
fi

local_artifact_id=$(cat artifact_id.txt)
echo Last artifact id is $local_artifact_id
echo Fetching latest artifact id from ZinZen Scheduler repo...
token=$(echo $GITHUB_TOKEN)

while read artifact
do
    if [ $(jq -r ".name" <<< $artifact) = wasm-build-pkg ]
    then
        latest_artifact_id=$(jq -r ".id" <<< $artifact)
        break
    fi
done < <(curl -s -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $token" https://api.github.com/repos/tijlleenders/ZinZen-scheduler/actions/artifacts | jq ".artifacts" | jq -c ".[]")

echo Latest artifact id: $latest_artifact_id
if [ $latest_artifact_id = $local_artifact_id ]
then
    echo No new build found.
else
    echo A new WASM build detected....
    echo $latest_artifact_id > artifact_id.txt
    git checkout -b update-build
    echo Requesting download url...
    line=$(curl -s -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $token" https://api.github.com/repos/tijlleenders/zinzen-scheduler/actions/artifacts/$latest_artifact_id/zip -I | grep location) &> /dev/null
    download_url=${line:10}
    echo Successfully received download url
    echo Using wget to download artifacts...
    wget -O wasm-build-pkg.zip $download_url > /dev/null
    echo Unzipping into pkg directory...
    unzip -o wasm-build-pkg.zip -d pkg
    git add pkg/*
    git add artifact_id.txt
    git commit -m "Update artifacts."
    git push origin update-build
    gh pr create --title "Update artifacts (from script)" --body "This PR was automatically generated by the `update_artifacts.sh` script."
    echo Cleaning up...
    git checkout main
    git branch -D update-build
    echo Ok
fi
