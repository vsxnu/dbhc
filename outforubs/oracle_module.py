import subprocess
import os
import re

class OracleModule:
    def run_health_check(self, fqdn_list):
        output_file_path = os.path.join(os.getcwd(), 'output.txt')
        with open(output_file_path, 'w') as f:
            f.write("")
        
        with open('servername_list.txt', 'w') as f:
            for fqdn in fqdn_list:
                f.write(fqdn + '\n')
        
        report = ""
        
        for fqdn in fqdn_list:
            script_path = os.path.join(os.getcwd(), '..', 'scripts', 'health_check_oracle.ps1')
            try:
                subprocess.run(["pwsh", "-File", script_path, fqdn], check=True)
                report += self._read_and_format_output(fqdn)
            except subprocess.CalledProcessError as e:
                report += f"Error for {fqdn}: {e}\n"
        
        with open(output_file_path, 'w') as f:
            f.write(report)
        
        return report

    def _read_and_format_output(self, fqdn):
        try:
            with open(os.path.join(os.getcwd(), 'output.txt'), 'r') as f:
                content = f.read()
            
            sections = re.split(r'\n(?=\w+:)', content)
            formatted_report = f"Report for {fqdn}:\n"
            formatted_report += "=" * (len(formatted_report) - 1) + "\n"
            
            for section in sections:
                if ':' in section:
                    title, data = section.split(':', 1)
                    formatted_report += f"\n{title.strip()}:\n"
                    formatted_report += "-" * len(title.strip()) + "\n"
                    formatted_report += self._format_table(data.strip()) + "\n"
            
            return formatted_report
        except IOError as e:
            return f"Failed to read output file for {fqdn}: {e}\n"

    def _format_table(self, content):
        lines = content.split('\n')
        if len(lines) < 2:
            return content
        
        # Split lines by '|' and find the maximum width for each column
        split_lines = [line.split('|') for line in lines]
        widths = [max(len(word.strip()) for word in col) for col in zip(*split_lines)]
        
        # Format each line
        formatted_lines = []
        for line in split_lines:
            padded = [word.strip().ljust(width) for word, width in zip(line, widths)]
            formatted_lines.append("  ".join(padded))
        
        return "\n".join(formatted_lines)