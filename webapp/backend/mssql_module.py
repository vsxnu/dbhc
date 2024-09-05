import subprocess
import os
import logging
from typing import List

logger = logging.getLogger(__name__)

class MSSQLModule:
    def __init__(self):
        self.output_file_path = os.path.join(os.getcwd(), 'output.txt')
        self.script_path = os.path.join(os.getcwd(), '..', 'scripts', 'health_check.ps1')

    def run_health_check(self, fqdn_list: List[str]) -> str:
        self._clear_output_file()
        
        report = ""
        for fqdn in fqdn_list:
            try:
                self._run_powershell_script(fqdn)
                report += self._read_output_file(fqdn)
            except subprocess.CalledProcessError as e:
                logger.error(f"Error running PowerShell script for {fqdn}: {e}")
                report += f"Error for {fqdn}: Failed to run health check script\n"
            except IOError as e:
                logger.error(f"IO Error for {fqdn}: {e}")
                report += f"Error for {fqdn}: Failed to read output file\n"
        
        return report

    def _clear_output_file(self):
        try:
            with open(self.output_file_path, 'w') as f:
                f.write("")
        except IOError as e:
            logger.error(f"Failed to clear output file: {e}")
            raise

    def _run_powershell_script(self, fqdn: str):
        try:
            subprocess.run(["pwsh", "-File", self.script_path, fqdn], check=True)
        except subprocess.CalledProcessError as e:
            logger.error(f"PowerShell script execution failed for {fqdn}: {e}")
            raise

    def _read_output_file(self, fqdn: str) -> str:
        try:
            with open(self.output_file_path, 'r') as f:
                return f"{fqdn}:\n{f.read()}\n"
        except IOError as e:
            logger.error(f"Failed to read output file: {e}")
            raise