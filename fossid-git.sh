#! /bin/bash
# FossID GIT Integration Script v0.9.2 (beta)
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

function main() {
	cat << "EOF"

  .:/++++/:.    .:/+++/:. .-------.`    `.-:::--.`                    
`/+++:---/+++. -++/..-:-  .::-...:::  `-::-....-.                     
/++/      -+++`-+++-.`    .::.``.::-  :::.                            
+++-      `+++. .:/++++:` .::----:-. `:::`                            
:+++.    `/++/  ``  `/++: .::.   -::. -::-`    `                      
 -+++//:/+++:` -++:::+++. .::----::-`  .-::----:-`                    
  `.-://::.`   `.::/::-`  `.......`     ``.---..`                     
                                                                      
                ``.```                                                
            `:+ssssssso:.                                             
/o++++++` `/yyo+++-`.-/sho.   `:+ooo+-   ./oooo/.   `//`  .//////:-`  
dh...... `sh+/+/:.`     :hh- .hy-.../y- :ho...-os`  .oo.  :oo---:/oo/`
dh       od+/o-          -dy .hy.`   `  /d+.    `   .oo.  :oo     .oo/
dhooooo- yd.--            hd. .+osso/-   :ooso+:.   .oo.  :oo      /oo
dh`````` od/             .dh`    ``-+ho    ``.-sh:  .oo.  :oo     `+o/
dh       `yh:           -yh: `-`   `-dy ..`   `+d/  .oo.  :oo-..-:+o/`
ys        `ohy/.`    .:ohy.  -ossssso/` :ossssso:   .++`  -+++++//:.  
            ./syhyyyhys++yoo:`  ````       ```                        
               ``...``   /dddh/`                                      
                          .ohddh+                                     
                            `+hho                                     


FossID GIT Integration v0.9.2 (beta)

-----
EOF
echo "FossID API Endpoint: ${url}"
echo "username: ${username}"
echo "Project Name: ${pname}"
echo "Scan Name: ${sname}"
echo "Git URL: ${git_url}"
echo "Git branch: ${git_branch}"
echo "Target Path (Filesystem): ${path}"
echo "-----"

create_project

if [[ ! -z ${git_url} ]]; then
	echo "Create scan from git..."
	create_scan_from_git
	download_from_git
	echo "Download finished."
else
	echo "Create scan from local filesystem..."
	create_scan
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
"data": {"username": "$username", "key": "$key", "project_code": "$pname", "project_name": "$pname"}
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
"data": {"username": "$username", "key": "$key", "project_code": "$pname", "scan_code": "$sname", "scan_name": "$sname", 
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
"data": {"username": "$username", "key": "$key", "project_code": "$pname", "scan_code": "$sname", "scan_name": "$sname", 
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
"data": {"username": "$username", "key": "$key", "scan_code": "$sname"}
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
"data": {"username": "$username", "key": "$key", "scan_code": "$sname"}
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
"data": {"username": "$username", "key": "$key", "scan_code": "$sname", "type": "SCAN"}
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
"data": {"username": "$username", "key": "$key", "scan_code": "$sname", "type": "SCAN"}
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
"data": {"username": "$username", "key": "$key", "scan_code": "$sname"}
}
EOT
)" \
	$url | jq '.data[0] | .date + "\n" + .action + "\n" + .reference + "\n" + .description + "\n" + .comment' -r
	return
}

print_usage() {
	echo "Usage: please use appropriate or required params. see README.md"
	exit 2
}

if [ $# -lt 7 ]; then
	print_usage
else
	while [ $# -gt 0 ];
		do
			case "$1" in
				--fossid.scheme=*)
				scheme="${1#*=}"
				;;
				--fossid.host=*)
				host="${1#*=}"
				;;
				--fossid.username=*)
				username="${1#*=}"
				;;
				--fossid.apikey=*)
				key="${1#*=}"
				;;
				--fossid.project.name=*)
				pname="${1#*=}"
				;;
				--fossid.scan.name=*)
				sname="${1#*=}"
				;;
				--fossid.git.url=*)
				git_url="${1#*=}"
				;;
				--fossid.git.branch=*)
				git_branch="${1#*=}"
				;;
				--fossid.filesystem.path=*)
				path="${1#*=}"
				;;
				*)
			esac
		shift
	done
fi

url="${scheme}""://""${host}""/webapp/api.php"

main