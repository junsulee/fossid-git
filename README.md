# fossid-git
### FossID GIT Integration Script (Beta)
##### A lightweight script that helps to integrate the FossID with various git-based CI/CD environments.

## Prerequisites
- install jq package (https://stedolan.github.io/jq/) - Licensed under MIT License

```bash
sudo apt-get install jq
yum install jq
```

## Usage
> ex) ./fossid-git.sh https://yourfossidurl/webapp/api.php username userapikey projectname scanname giturl gitbranchname path*
*(Optional) path is an optional parameter that allows you to scan the code of a specific path in the FossID server's file system.

## Release Note
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

[GNU General Public License v2.0 or later](https://tldrlegal.com/license/gnu-general-public-license-v2)
