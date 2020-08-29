# Shell scripts
![ShellCheck](https://github.com/fmdlc/shell-scripts/workflows/ShellCheck/badge.svg)

Personal collection of Shell scripts

## Installation

Most of the scripts run in Python 3 or Bash shell.

```bash
$: bash ./script_name <ARGUMENTS>
```

## Scripts
|Name|Language|Function|
|---|---|---|
|`arping-scan-net.sh` | Shell Script | Scans network for live hosts.
|`check-ssl.sh` | Shell Script | Checks SSL certificate and dumps it.
|`checksec.sh` | Shell Script | Check security configuration (Deprecated).
|`create_ami_bastion.sh` | Shell Script | Creates an AMI from a given instance.
|`create_vpn_client.sh` | Shell Script | Creates VPN certificate using EasyRSA.
|`del_snapshot.py` | Shell Script | Delete EBS Snapshot.
|`delete_older_ami.py` | Python 2.7 | Deletes an old AMI.
|`es_dump.sh` | Shell Script | Dumps ElasticSearch cluster indexes.
|`LINUXexplo.sh` | Shell Script | Solaris' explorer kind script (Deprecated).
|`mail.py` | Python 2.7 | Connects to STMP server to send email (Deprecated).
|`makesc.sh`| Shell Script | Checks environment security configuration (Deprecated).
|`pillar_encrypt.sh`| Shell Script | Helps to encrypt Salt Pillar data.
|`ps_mem.py` | Python 2.7 | Dumps system processes memory usage.
|`revoke-ssh.sh` | Shell Script | Revokes a compromised SSH key.
|`security-group-cleanup.py`| Python 2.7 | Script to clean up AWS VPC Security Groups
|`seekbin.sh`| Shell Script | Seeks for modified binaries in the Operating System.
|`swap.sh` | Shell Script | Analyzes swap utilization.
|`tf-pre-commit.sh` | Shell Script | Git pre-commit hook (fmt).
|`tcpping.py` | Python 2.7 | Executes a TCP ping to determine if host is alive.
|`udpping.py`| Python 2.7 | Executes an UDP ping to determine if host is alive.
|`upgrade_repo.sh` | Shell Script | Upgrade an RPM based repo.
|`vmdump.sh` | Shell Script | Checks Virtual Memory utilization.
|`x509-remote.sh` | Shell Script | Output remote x.509 certificate details

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[Apache 2.](./LICENSE)
