import subprocess
import os

class MSSQLModule:
    def run_health_check(self, fqdn_list):
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
            script_path = os.path.join(os.getcwd(), '..', 'scripts', 'health_check.ps1')
            try:
                subprocess.run(["pwsh", "-File", script_path, fqdn], check=True)
            except subprocess.CalledProcessError as e:
                report += f"Error for {fqdn}: {e}\n"
                continue
            
            # Read output file
            output_file_path = os.path.join(os.getcwd(), 'output.txt')
            with open(output_file_path, 'r') as f:
                report += f"{fqdn}:\n{f.read()}\n"
        
        return report
