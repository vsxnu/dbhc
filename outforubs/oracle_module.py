import subprocess
import os

class OracleModule:
    def run_health_check(self, fqdn_list):
        # Clear the output file before writing new content
        output_file_path = os.path.join(os.getcwd(), 'output.txt')
        with open(output_file_path, 'w') as f:
            f.write("")  # Clear the file content
        
        # Update servername list file
        with open('servername_list.txt', 'w') as f:
            for fqdn in fqdn_list:
                f.write(fqdn + '\n')
        
        # Print the current working directory
        print("Current working directory:", os.getcwd())
        
        # Initialize report
        report = ""
        
        # Invoke PowerShell script for each server entry
        for fqdn in fqdn_list:
            script_path = os.path.join(os.getcwd(), '..', 'scripts', 'health_check_oracle.ps1')
            try:
                subprocess.run(["pwsh", "-File", script_path, fqdn], check=True)
            except subprocess.CalledProcessError as e:
                report += f"Error for {fqdn}: {e}\n"
                continue
            
            # Read output file and append to report
            with open(output_file_path, 'r') as f:
                report += f"{fqdn}:\n{f.read()}\n"
        
        # Write the report to the output file
        with open(output_file_path, 'w') as f:
            f.write(report)
        
        return report