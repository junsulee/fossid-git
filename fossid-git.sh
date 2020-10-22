#! /bin/bash
# FossID GIT Integration Script v0.9.1 (beta)
# ----------------------------------------
# Copyright (c) 2020 OSBC / junsulee
# jslee@osbc.co.kr
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

url=$1
id=$2
key=$3
pname=$4
sname=$5
git_url=$6
git_branch=$7
path=$8

print_usage() {
	echo "Usage: please use appropriate params. see README.md"
	exit 2
}

function main() {

	cat << "EOF"

                 ./oyhhhhyo/.                                                   
   -++++++++   -sds+//:`.-/sds-     -/+++/-    .:+++/:`    :/-   -/////:-.      
   od+------  ods:+oo/-     .sd+  `yh+:-:+hy  odo:--/yd.  `sso   oso///+oso/`   
   od:       +do:o+.          sd/ :ds     ``  hd`     `   `sso   os+     .oso   
   odo/////` hd.oo`           .dh  /yyo/-.    -shs/:.     `sso   os+      -ss-  
   odo:::::` hd.              .dh    `-:+yh+    `.:/shs.  `sso   os+      -ss-  
   od:       +ds              sd+         od:        -ds  `sso   os+     .oso   
   od:        ods.          .sd+  /s+/::/ohy`.so/:::+yh:  `sso   oso///+oso:    
   -/`         -sdy/-.``.-/ydd+    -:/++/:.   .:/+++/-     -/.   -/////:-.      
                 ./oyhhhhyo/-/hhyo.                                             
                              +dddds-                                           
                               `+hddds`               GIT INTEGRATION by OSBC                                      
                                 `+hds`

EOF

create_project

if [ $# > 7 ];
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
	$url | jq 'if .error != null then "(WARN) " + .error elif .message != null then "(INFO) " + .message else .error , .message end' -r
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
	$url | jq 'if .error != null then "(WARN) " + .error elif .message != null then "(INFO) " + .message else .error , .message end' -r
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
	$url | jq 'if .error != null then "(WARN) " + .error elif .message != null then "(INFO) " + .message else .error , .message end' -r
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
	$url | jq 'if .error != null then "(WARN) " + .error elif .message != null then "(INFO) " + .message else .error , .message end' -r
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
	$url | jq 'if .error != null then "(WARN) " + .error elif .message != null then "(INFO) " + .message else .error , .message end' -r
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
