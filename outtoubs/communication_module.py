import re
import logging
from typing import List, Tuple
from mssql_module import MSSQLModule
from sybase_module import SybaseModule
from oracle_module import OracleModule

logger = logging.getLogger(__name__)

class CommunicationModule:
    def __init__(self):
        self.modules = {
            'MSSQL': MSSQLModule(),
            'Sybase': SybaseModule(),
            'Oracle': OracleModule()
        }

    def process_request(self, db_type: str, hostnames: List[str]) -> str:
        if db_type not in self.modules:
            raise ValueError(f"Unsupported database type: {db_type}")

        fqdn_list, errors = self._convert_to_fqdn(hostnames)
        
        valid_fqdns = [fqdn for fqdn, error in zip(fqdn_list, errors) if error is None]
        self._update_servername_list(valid_fqdns)
        
        module = self.modules[db_type]
        report = module.run_health_check(valid_fqdns)

        # Wrap the report in HTML if it's not already
        if not report.strip().startswith('<!DOCTYPE html>'):
            report = f"""
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>{db_type} Health Check Report</title>
                <style>
                    body {{ font-family: Arial, sans-serif; }}
                    pre {{ background-color: #f4f4f4; padding: 10px; border-radius: 5px; white-space: pre-wrap; word-wrap: break-word; }}
                </style>
            </head>
            <body>
                <h1>{db_type} Health Check Report</h1>
                <pre>{report}</pre>
            </body>
            </html>
            """

        return report

    def _convert_to_fqdn(self, hostname_list: List[str]) -> Tuple[List[str], List[str]]:
        fqdn_list = []
        errors = []
        for hostname in hostname_list:
            if re.search(r'[^a-zA-Z0-9.-]', hostname):
                fqdn_list.append(None)
                errors.append(f"Invalid hostname: {hostname}")
            elif hostname.count('.') >= 2:
                fqdn_list.append(hostname)
                errors.append(None)
            elif hostname.count('.') == 1:
                fqdn_list.append(self._add_domain_name(hostname.split('.')[0]))
                errors.append(None)
            else:
                fqdn_list.append(self._add_domain_name(hostname))
                errors.append(None)
        return fqdn_list, errors
    
    def _add_domain_name(self, hostname: str) -> str:
        return f"{hostname}.example.com"

    def _update_servername_list(self, valid_fqdns: List[str]):
        with open('servername_list.txt', 'w') as f:
            for fqdn in valid_fqdns:
                f.write(f"{fqdn}\n")