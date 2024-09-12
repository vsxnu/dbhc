import subprocess
import os
import logging
import html

logger = logging.getLogger(__name__)

class SybaseModule:
    def __init__(self):
        self.output_file_path = os.path.join(os.getcwd(), 'output.html')
        self.script_path = os.path.join(os.getcwd(), '..', 'scripts', 'health_check_syb.ps1')

    def run_health_check(self, fqdn_list):
        self._clear_output_file()
        
        report = "<html><body><pre>"
        for fqdn in fqdn_list:
            try:
                self._run_powershell_script(fqdn)
                report += self._read_output_file(fqdn)
            except subprocess.CalledProcessError as e:
                logger.error(f"Error running PowerShell script for {fqdn}: {e}")
                report += f"<h2>Error for {fqdn}</h2><p>Failed to run health check script</p>"
            except IOError as e:
                logger.error(f"IO Error for {fqdn}: {e}")
                report += f"<h2>Error for {fqdn}</h2><p>Failed to read output file</p>"
        
        report += "</pre></body></html>"
        return report

    def _clear_output_file(self):
        try:
            with open(self.output_file_path, 'w') as f:
                f.write("")
        except IOError as e:
            logger.error(f"Failed to clear output file: {e}")
            raise

    def _run_powershell_script(self, fqdn):
        try:
            subprocess.run(["pwsh", "-File", self.script_path, fqdn], check=True)
        except subprocess.CalledProcessError as e:
            logger.error(f"PowerShell script execution failed for {fqdn}: {e}")
            raise

    def _read_output_file(self, fqdn):
        try:
            with open(self.output_file_path, 'r') as f:
                content = f.read()
                return html.escape(content)
        except IOError as e:
            logger.error(f"Failed to read output file: {e}")
            raise