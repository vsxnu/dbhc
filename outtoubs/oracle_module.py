import subprocess
import os

class OracleModule:
    def run_health_check(self, fqdn_list):
        output_file_path = os.path.join(os.getcwd(), 'output.html')
        with open(output_file_path, 'w') as f:
            f.write("")  # Clear the file content
        
        with open('servername_list.txt', 'w') as f:
            for fqdn in fqdn_list:
                f.write(fqdn + '\n')
        
        print("Current working directory:", os.getcwd())
        
        script_path = os.path.join(os.getcwd(), '..', 'scripts', 'health_check_oracle.ps1')
        try:
            subprocess.run(["pwsh", "-File", script_path] + fqdn_list, check=True)
        except subprocess.CalledProcessError as e:
            return f"<html><body><h1>Error</h1><p>Error running health check: {e}</p></body></html>"
        
        merged_report_path = os.path.join(os.getcwd(), '..', 'scripts', 'Oracle', 'orahc', 'reports', 'merged_report.html')
        with open(merged_report_path, 'r') as f:
            report = f.read()
        
        return report