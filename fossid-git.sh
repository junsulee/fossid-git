#! /bin/bash

# FossID GIT Integration Script v1.0
# Copyright (c) 2020 OSBC
# jslee@osbc.co.kr
# Licensed under GPL v2+

# Release Note
# =====
# v0.1
# Initial release
# v0.2
# Structural improvement
# v0.3
# Improvement using jq
# v0.4
# Structural improvement
# v0.5
# Structural improvement
# v0.6
# create child scan if project already exists
# v0.7
# added support for git repository scanning
# v0.8
# added feature: check scan progress

url=$1
id=$2
key=$3
pname=$4
sname=$5
path=$6
git_url=$7
git_branch=$8

print_usage() {
	echo "Usage: use appropriate params"
	exit 2
}

function main() {
	result=$(\
		curl -s POST \
		-d '{"group": "projects", "action": "list_projects", "data": {"username": "$id", "key": "$key"}}' \
		-H "Content-Type: application/json" $url | jq '.data[] | select(.project_name == "") | .id' \
	)

	if [ -z "$result" ];
	then
		create_project
	fi

	if [ -z "$git_url" ];
	then
		create_scan
	else
		echo "create scan from git..."
		create_scan_from_git
		download_from_git
	fi

	run_scan

	scan_finished=$(get_scan_status)
	echo $scan_finished
	while [ ${scan_finished} -eq 0 ]; do
		echo "Scanning... $(get_scan_progress)"
		scan_finished=$(get_scan_status)
		sleep 2
		if [[ ${scan_finished} -eq 1 ]]; then
			break
		fi
	done

	echo "Finished."
}

function create_project()
{
curl -s POST \
-H "Content-Type: application/json" \
-d "$(cat <<EOT
{
"group": "projects", "action": "create", 
"data": {"username": "$id", "key": "$key", "project_code": "$pname", "project_name": "$pname"}
}
EOT
)" \
$url | jq "."
}

function create_scan()
{
curl -s POST \
-H "Content-Type: application/json" \
-d "$(cat <<EOT
{
"group": "scans", "action": "create", 
"data": {"username": "$id", "key": "$key", "project_code": "$pname", "scan_code": "$sname", "scan_name": "$sname", 
"target_path": "$path"}
}
EOT
)" \
$url | jq "."
}

function create_scan_from_git() {
curl -s POST \
-H "Content-Type: application/json" \
-d "$(cat <<EOT
{
"group": "scans", "action": "create", 
"data": {"username": "$id", "key": "$key", "project_code": "$pname", "scan_code": "$sname", "scan_name": "$sname", 
"git_repo_url": "$git_url", "git_branch": "$git_branch"}
}
EOT
)" \
$url -v | jq "."
}

function download_from_git() {
curl -X POST \
-H "Content-Type: application/json" \
-d "$(cat <<EOT

{
"group": "scans", "action": "download_content_from_git", 
"data": {"username": "$id", "key": "$key", "scan_code": "$sname"}
}

EOT
)" \
$url -v | jq "."
}

function run_scan() {
curl -s POST \
-H "Content-Type: application/json" \
-d "$(cat <<EOT
{
"group": "scans", "action": "run", 
"data": {"username": "$id", "key": "$key", "scan_code": "$sname"}
}
EOT
)" \
$url | jq "."
}

function get_scan_status() {
curl -s POST \
-H "Content-Type: application/json" \
-d "$(cat <<EOT
{
"group": "scans", "action": "check_status", 
"data": {"username": "$id", "key": "$key", "scan_code": "$sname", "type": "SCAN"}
}
EOT
)" \
$url -s | jq '.data | .is_finished' -r
return
}


function get_scan_progress() {
curl -s POST \
-H "Content-Type: application/json" \
-d "$(cat <<EOT
{
"group": "scans", "action": "check_status", 
"data": {"username": "$id", "key": "$key", "scan_code": "$sname", "type": "SCAN"}
}
EOT
)" \
$url -s | jq '.data | .percentage_done' -r
return
}

main