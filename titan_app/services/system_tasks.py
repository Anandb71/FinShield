from ..utils.helpers import run_cmd
import subprocess

def fetch_logs(query: str):
    # 1 hop to helper
    cmd = "cat /var/log/sys.log | grep " + query
    return run_cmd(cmd)

def run_legacy_job(payload: str):
    # 1 hop directly to subprocess but targeting a vulnerable JS file
    # Cross-language execution trace
    proc = subprocess.run(["node", "titan_app/legacy/old_api.js", payload], capture_output=True)
    return proc.stdout.decode()\n