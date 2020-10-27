# fossid-git
### FossID GIT Integration Script v0.9.3 (Beta)
##### A lightweight script that helps to integrate the FossID with various git-based CI/CD environments.

## Prerequisites
- Install FossID 2020.x or higher
- install jq package (https://stedolan.github.io/jq/)

```bash
#(debian/ubuntu)
sudo apt-get install jq
#(redhat/centos)
yum install jq
```

## Usage
```bash
./fossid-git.sh --fossid.scheme=https --fossid.host=fossid.mycompany.com --fossid.username=myuser \
--fossid.apikey=abcdefgh --fossid.project.name=myproject --fossid.scan.name=myscan \
--fossid.git.url=https://github.com/mycompany/myproject --fossid.git.branch=master
```
- Example of --fossid.git.url for private repository: git@bitbucket.org:mycompany/myproject.git
- Example of --fossid.git.url for public repository: https://github.com/mycompany/myproject.git
- *(Optional) --fossid.filesystem.path is an optional parameter that allows you to scan the code of a specific path in the FossID server's file system.

## Properties
```bash
--fossid.scheme				: (Required) http or https"
--fossid.host				: (Required) hostname of FossID webserver"
--fossid.username			: (Required) FossID username"
--fossid.apikey				: (Required) FossID apikey"
--fossid.project.name			: (Required) name for the FossID project"
--fossid.scan.name			: (Required) name for the FossID scan"
--fossid.git.url 			: git repository url"
--fossid.git.branch 			: branch name of git repository"
--fossid.filesystem.path 		: (Optional) specific path in the FossID server's file system for scanning."
--fossid.trust.cert 			: (Advanced) Trust self-signed certificates (true/false)"
--fossid.timeout 			: (Advanced) set operation timeout"
```
## Release Note
### v0.9.3
- support for trust certificate option, help menu added
### v0.9.2
- structural improvement and bug fixed
### v0.9.1
- output message handling improvement and bug fixed
### v0.9
- bug fixed / added feature: print scan info when finished
### v0.8
- added feature: check scan progress
### v0.7
- added support for git repository scanning
### v0.6
- create child scan if project already exists
### v0.5
- structural improvement
### v0.4
- structural improvement
### v0.3
- improvement using jq
### v0.2
- structural improvement
### v0.1
- initial release

## License
This project is licensed under the terms of the [GNU General Public License v2.0 or later](https://tldrlegal.com/license/gnu-general-public-license-v2)
