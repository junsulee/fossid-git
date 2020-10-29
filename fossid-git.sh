#! /bin/bash
# FossID GIT Integration Script
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

version="v0.9.4 (beta)"

function main() {
show_splash
display_version
echo
echo "FossID API Endpoint: ${url}"
echo "Username: ${username}"
echo "Project Name: ${pname}"
echo "Scan Name: ${sname}"
echo "Git URL: ${git_url}"
echo "Git branch: ${git_branch}"
echo "*Target Path (Filesystem): ${path}"
echo "*Trust all certificates: ${trustcert}"
echo "================================================================================"
create_project

if [[ ! -z ${git_url} ]]; then
	echo "(INFO) Create scan from git..."
	create_scan_from_git
	download_from_git
	echo "(INFO) Download finished."
else
	echo "(INFO) Create scan from local filesystem..."
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

echo -e "--------------------------------------------------------------------------------\n"
get_finished_information
echo "--------------------------------------------------------------------------------"
echo "(INFO) Finished."

}

function create_project()
{
	curl --connect-timeout ${timeout} ${proxy} -s${secureoption} POST \
		-H "Content-Type: application/json" \
		-d "$(cat <<EOT
{
"group": "projects", "action": "create", 
"data": {"username": "$username", "key": "$key", "project_code": "$pname", "project_name": "$pname", "description": "Created by FossID Git Integration Script"}
}
EOT
)" \
	$url | jq 'if .error != null then "(WARN) " + .error elif .message != null then "(INFO) " + .message else .error , .message end' -r
}

function create_scan()
{
	curl --connect-timeout ${timeout} ${proxy} -s${secureoption} POST \
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
	curl --connect-timeout ${timeout} ${proxy} -s${secureoption} POST \
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
	curl --progress-bar --connect-timeout ${timeout} ${proxy} -${secureoption}X POST \
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
	curl --connect-timeout ${timeout} ${proxy} -s${secureoption} POST \
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
	curl --connect-timeout ${timeout} ${proxy} -s${secureoption} POST \
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
	curl --connect-timeout ${timeout} ${proxy} -s${secureoption} POST \
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
	curl --connect-timeout ${timeout} ${proxy} -s${secureoption} POST \
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

show_splash() {
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

================================================================================
EOF
}

display_version() {
	echo "FossID GIT Integration Script version ${version}"
}

display_help() {
    echo "Usage: $0 [option...]=" >&2
    echo
    echo "	[!] At least 7 (or 8) properties are required depending on the option."
    echo
    echo "	--fossid.scheme				: (Required) protocol (http or https)"
    echo "	--fossid.host				: (Required) hostname of FossID webserver"
    echo "	--fossid.username			: (Required) FossID username"
    echo "	--fossid.apikey				: (Required) FossID apikey"
    echo "	--fossid.project.name			: (Required) name for the FossID project"
    echo "	--fossid.scan.name			: (Required) name for the FossID scan"
    echo "	--fossid.git.url 			: git repository url"
    echo "	--fossid.git.branch 			: branch name of git repository"
    echo "	--fossid.filesystem.path 		: (Optional) target path in the FossID server's file system"
    echo
    echo "	(Advanced)"
    echo "	--fossid.trust.cert 			: Trust self-signed certificates (true/false)"
    echo "	--fossid.timeout 			: set operation timeout (default:0 - unlimited)"
    echo "	--fossid.proxy.scheme 			: set proxy protocol (http or https)"
    echo "	--fossid.proxy.host 			: set proxy host for connnection"
    echo "	--fossid.proxy.port 			: set proxy port"
    echo "	--fossid.proxy.username 		: set proxy username"
    echo "	--fossid.proxy.password 		: set proxy password"
    echo
    exit 0
}

if [ $# -gt 1 ] && [ $# -lt 7 ]; then
	display_help
else
	timeout=0
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
			--fossid.trust.cert=*)
				if [ "${1#*=}" = true ]; then
					trustcert="true"
					secureoption="k"
				else
					trustcert="false"
					secureoption=""
				fi
				;;
			--fossid.timeout=*)
				if [ -n "${1#*=}" ]; then
					timeout="${1#*=}"
				fi
				;;
			--fossid.proxy.scheme=*)
				proxyscheme="${1#*=}"
				;;
			--fossid.proxy.host=*)
				proxyhost="${1#*=}"
				;;
			--fossid.proxy.port=*)
				proxyport="${1#*=}"
				;;
			--fossid.proxy.username=*)
				proxyusername="${1#*=}"
				;;
			--fossid.proxy.password=*)
				proxypassword="${1#*=}"
				;;
			-h | --help)
				display_help
				;;
			-v | --version)
				show_splash
				display_version
				echo "> https://github.com/junsulee/fossid-git"
				echo "> License: GNU General Public License v2.0 or later"
				exit 0
				;;
			-* | --*)
				echo "Error: Unknown option"
				exit 1
				;;
			*)
				break
				display_help
				;;
		esac
		shift
	done
fi
url="${scheme}""://""${host}""/webapp/api.php"
if [[ -n $proxyscheme && $proxyuser && proxypassword && proxyhost && proxyport ]]; then
	proxy="-proxy ""${proxyscheme}""://""${proxyuser}"":""${proxypassword}""@""${proxyhost}"":""${proxyport}"
else
	proxy=""
fi
main