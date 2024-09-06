import subprocess
import os
import logging
from typing import List

logger = logging.getLogger(__name__)
TEMP_DIR = 'temp_files'

class MSSQLModule:
    def __init__(self):
        self.script_path = os.path.join(os.getcwd(), '..', 'scripts', 'health_check.ps1')

    def run_health_check(self, fqdn_list: List[str], request_id: str) -> str:
        output_file_path = os.path.join(TEMP_DIR, f'output_{request_id}.txt')
        self._clear_output_file(output_file_path)
        
        report = ""
        for fqdn in fqdn_list:
            try:
                self._run_powershell_script(fqdn, request_id)
                report += self._read_output_file(fqdn, output_file_path)
            except subprocess.CalledProcessError as e:
                logger.error(f"Error running PowerShell script for {fqdn}: {e}")
                report += f"Error for {fqdn}: Failed to run health check script\n"
            except IOError as e:
                logger.error(f"IO Error for {fqdn}: {e}")
                report += f"Error for {fqdn}: Failed to read output file\n"
        
        return report

    def _clear_output_file(self, output_file_path: str):
        try:
            with open(output_file_path, 'w') as f:
                f.write("")
        except IOError as e:
            logger.error(f"Failed to clear output file: {e}")
            raise

    def _run_powershell_script(self, fqdn: str, request_id: str):
        try:
            subprocess.run([
                "pwsh", 
                "-File", 
                self.script_path, 
                fqdn, 
                os.path.join(TEMP_DIR, f'servername_list_{request_id}.txt'), 
                os.path.join(TEMP_DIR, f'output_{request_id}.txt')
            ], check=True)
        except subprocess.CalledProcessError as e:
            logger.error(f"PowerShell script execution failed for {fqdn}: {e}")
            raise

    def _read_output_file(self, fqdn: str, output_file_path: str) -> str:
        try:
            with open(output_file_path, 'r') as f:
                return f"{fqdn}:\n{f.read()}\n"
        except IOError as e:
            logger.error(f"Failed to read output file: {e}")
            raise
