import http.server
import socketserver
import json
import os
import uuid
import time
import threading
from communication_module import CommunicationModule

PORT = 8000
FRONTEND_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'frontend')
TEMP_DIR = 'temp_files'
MAX_FILE_AGE = 3600  # 1 hour in seconds

class ThreadedHTTPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True

class MyHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=FRONTEND_DIR, **kwargs)

    def do_POST(self):
        if self.path == '/api/healthcheck':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))

            request_id = str(uuid.uuid4())

            comm_module = CommunicationModule()
            try:
                report = comm_module.process_request(data['dbType'], data['hostnames'], request_id)
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'report': report}).encode())
            except Exception as e:
                self.send_error(500, str(e))
            finally:
                # Clean up the temporary files for this request
                cleanup_files(request_id)

def cleanup_files(request_id):
    patterns = [f'output_{request_id}.txt', f'servername_list_{request_id}.txt']
    for pattern in patterns:
        try:
            os.remove(os.path.join(TEMP_DIR, pattern))
        except OSError:
            pass  # File might not exist, which is fine

def cleanup_old_files():
    while True:
        time.sleep(3600)  # Run every hour
        current_time = time.time()
        for filename in os.listdir(TEMP_DIR):
            file_path = os.path.join(TEMP_DIR, filename)
            if os.path.isfile(file_path):
                if current_time - os.path.getmtime(file_path) > MAX_FILE_AGE:
                    try:
                        os.remove(file_path)
                        print(f"Removed old file: {filename}")
                    except OSError as e:
                        print(f"Error removing {filename}: {e}")

if __name__ == '__main__':
    # Ensure temp directory exists
    os.makedirs(TEMP_DIR, exist_ok=True)
    
    # Start the cleanup thread
    cleanup_thread = threading.Thread(target=cleanup_old_files, daemon=True)
    cleanup_thread.start()

    with ThreadedHTTPServer(("", PORT), MyHandler) as httpd:
        print(f"Serving at http://localhost:{PORT}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down the server...")
            httpd.shutdown()
