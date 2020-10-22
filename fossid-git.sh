#! /bin/bash

# FossID GIT Integration Script v0.9 (beta)
# ----------------------------------------
# Copyright (c) 2020 OSBC
# jslee@osbc.co.kr
# Licensed under GPL v2+
# ----------------------------------------

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
	create_project

	if [ -z "$git_url" ];
	then
		create_scan
	else
		echo "Create scan from git..."
		create_scan_from_git
		download_from_git
		echo "Download finished."
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

	echo -e "----------\n"
	get_finished_information
	echo "----------"
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
$url | jq "."
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
$url | jq "."
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
$url | jq '.data | .is_finished' -r
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
$url | jq '.data | .percentage_done' -r
return
}

function get_finished_information() {
curl -s POST \
-H "Content-Type: application/json" \
-d "$(cat <<EOT
{
"group": "scans", "action": "get_scan_log",
"data": {"username": "$id", "key": "$key", "scan_code": "$sname"}
}
EOT
)" \
$url | jq '.data[0] | .date + "\n" + .action + "\n" + .reference + "\n" + .description + "\n" + .comment' -r
return
}

if [ $# -eq 0 ]; then
    print_usage
else
	main
fi
