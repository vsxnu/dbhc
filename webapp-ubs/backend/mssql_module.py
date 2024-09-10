import subprocess
import os
import logging
import html
import re

logger = logging.getLogger(__name__)

class MSSQLModule:
    def __init__(self):
        self.output_file_path = os.path.join(os.getcwd(), 'output.txt')
        self.script_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'scripts', 'health_check.ps1')

    def run_health_check(self, fqdn: str) -> tuple:
        self._clear_output_file()
        
        try:
            self._run_powershell_script(fqdn)
            result = self._read_output_file(fqdn)
            status = self._determine_status(result)
            return result, status
        except subprocess.CalledProcessError as e:
            logger.error(f"Error running PowerShell script for {fqdn}: {e}")
            return f"<div class='error'><h3>{html.escape(fqdn)}</h3><p>Failed to run health check script: {html.escape(str(e))}</p></div>", "Status: RED"
        except IOError as e:
            logger.error(f"IO Error for {fqdn}: {e}")
            return f"<div class='error'><h3>{html.escape(fqdn)}</h3><p>Failed to read output file: {html.escape(str(e))}</p></div>", "Status: RED"

    def _determine_status(self, result: str) -> str:
        if "error" in result.lower() or "failed" in result.lower():
            return "RED"
        # Check for specific indicators of a healthy system
        if "This is a simulated health check report." in result and "No actual database queries were performed." in result:
            return "GREEN"
        # Add more conditions here if needed to determine a GREEN status
        return "RED"  # Default to RED if no positive indicators are found

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
                content = f.read()
                escaped_content = html.escape(content)
                html_content = escaped_content.replace('\n', '<br>')
                return f"<div class='server-report'><h3>{html.escape(fqdn)}</h3><pre>{html_content}</pre></div>"
        except IOError as e:
            logger.error(f"Failed to read output file: {e}")
            return f"<div class='error'><h3>{html.escape(fqdn)}</h3><p>Failed to read output file: {html.escape(str(e))}</p></div>"