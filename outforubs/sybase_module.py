import subprocess
import os
import logging

logger = logging.getLogger(__name__)

class SybaseModule:
    def __init__(self):
        self.output_file_path = os.path.join(os.getcwd(), 'output.txt')
        self.script_path = os.path.join(os.getcwd(), '..', 'scripts', 'health_check_syb.ps1')

    def run_health_check(self, fqdn_list):
        self._clear_output_file()
        
        report = ""
        for fqdn in fqdn_list:
            try:
                self._run_powershell_script(fqdn)
                report += self._read_and_format_output(fqdn)
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

    def _run_powershell_script(self, fqdn):
        try:
            subprocess.run(["pwsh", "-File", self.script_path, fqdn], check=True)
        except subprocess.CalledProcessError as e:
            logger.error(f"PowerShell script execution failed for {fqdn}: {e}")
            raise

    def _read_and_format_output(self, fqdn):
        try:
            with open(self.output_file_path, 'r') as f:
                content = f.read()
            
            formatted_content = self._format_output(content)
            return f"Report for {fqdn}:\n{formatted_content}\n"
        except IOError as e:
            logger.error(f"Failed to read output file: {e}")
            raise

    def _format_output(self, content):
        sections = content.split('\n\n')
        formatted_sections = []
        
        for section in sections:
            lines = section.split('\n')
            if len(lines) > 2:
                header = lines[0]
                data = lines[1:]
                formatted_sections.append(f"{header}\n{'-' * len(header)}")
                formatted_sections.append(self._format_table(data))
            else:
                formatted_sections.append(section)
        
        return "\n\n".join(formatted_sections)

    def _format_table(self, lines):
        if not lines:
            return ""
        
        # Split lines and find the maximum width for each column
        split_lines = [line.split() for line in lines]
        widths = [max(len(word) for word in col) for col in zip(*split_lines)]
        
        # Format each line
        formatted_lines = []
        for line in split_lines:
            padded = [word.ljust(width) for word, width in zip(line, widths)]
            formatted_lines.append("  ".join(padded))
        
        return "\n".join(formatted_lines)