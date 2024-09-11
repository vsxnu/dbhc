import http.server
import socketserver
import json
import os
from communication_module import CommunicationModule

PORT = 8001
FRONTEND_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'frontend')

class MyHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=FRONTEND_DIR, **kwargs)

    def do_POST(self):
        if self.path == '/api/healthcheck':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))

            # Input validation
            if not data or 'dbType' not in data or 'hostnames' not in data or not data['hostnames']:
                self.send_error(400, 'Invalid request: missing database type or hostnames')
                return

            comm_module = CommunicationModule()
            try:
                report = comm_module.process_request(data['dbType'], data['hostnames'])
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'report': report}).encode())
            except Exception as e:
                self.send_error(500, f"An error occurred: {str(e)}")

if __name__ == '__main__':
    with socketserver.TCPServer(("", PORT), MyHandler) as httpd:
        print(f"Serving at http://localhost:{PORT}")
        httpd.serve_forever()