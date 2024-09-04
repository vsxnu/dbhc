import re

class CommunicationModule:
    def process_request(self, db_type, hostnames):
        fqdn_list, errors = self.convert_to_fqdn(hostnames)
        if db_type == 'MSSQL':
            from mssql_module import MSSQLModule
            module = MSSQLModule()
        elif db_type == 'Sybase':
            # Placeholder for Sybase module
            return "Sybase module not implemented yet."
        elif db_type == 'Oracle':
            # Placeholder for Oracle module
            return "Oracle module not implemented yet."
        
        reports = []
        for hostname, fqdn in zip(hostnames, fqdn_list):
            report = module.run_health_check([fqdn])
            reports.append(f"{hostname}:\n{report}")
        
        # Add errors to the report
        for error in errors:
            reports.append(f"Error: {error}")
        
        # Update servername list file
        with open('servername_list.txt', 'w') as f:
            for fqdn in fqdn_list:
                f.write(fqdn + '\n')
        
        return "\n\n".join(reports)

    def convert_to_fqdn(self, hostname_list):
        # Placeholder for FQDN conversion logic
        fqdn_list = []
        errors = []
        for hostname in hostname_list:
            if re.search(r'[^a-zA-Z0-9.-]', hostname):
                # Invalid hostname with special characters
                errors.append(f"Invalid hostname: {hostname}")
            elif hostname.count('.') >= 2:
                # Assume it's already an FQDN
                fqdn_list.append(hostname)
            elif hostname.count('.') == 1:
                # Take only the character string into account
                fqdn_list.append(self.add_domain_name(hostname.split('.')[0]))
            else:
                # Convert to FQDN
                fqdn_list.append(self.add_domain_name(hostname))
        return fqdn_list, errors
    
    def add_domain_name(self, hostname):
        # Placeholder for adding domain name logic
        # For now, use example.com as the default domain
        return hostname + '.example.com'
