import re
import logging
from typing import List, Tuple
import html
import os
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
        report = f"<div class='health-check-report'><h2>{html.escape(db_type)} Health Check Report</h2>"

        for hostname, fqdn, error in zip(hostnames, fqdn_list, errors):
            if error is None:
                try:
                    result, status = module.run_health_check(fqdn)
                    status_class = 'status-green' if status == 'GREEN' else 'status-red'
                    report += f"<div class='server-report'><h3>{html.escape(hostname)}</h3>"
                    report += f"<p class='{status_class}'>Status: {status}</p>"
                    report += result
                    report += "</div>"
                except Exception as e:
                    logger.error(f"Error running health check for {hostname}: {str(e)}")
                    report += f"<div class='error'><h3>{html.escape(hostname)}</h3><p>Error: Failed to run health check</p></div>"
            else:
                report += f"<div class='error'><h3>{html.escape(hostname)}</h3><p>Error: {html.escape(error)}</p></div>"
        
        report += "</div>"
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