from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import os
from communication_module import CommunicationModule

app = Flask(__name__)
CORS(app)
comm_module = CommunicationModule()

@app.route('/')
def serve_index():
    return send_from_directory('../frontend', 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    return send_from_directory('../frontend', path)

@app.route('/api/healthcheck', methods=['POST'])
def health_check():
    data = request.json
    db_type = data.get('dbType')
    hostnames = data.get('hostnames', [])
    
    try:
        report_html = comm_module.process_request(db_type, hostnames)
        response = jsonify({'html': report_html})
        print(f"Sending response: {response.get_data(as_text=True)}")  # Add this line
        return response
    except Exception as e:
        error_response = jsonify({'error': str(e)})
        print(f"Sending error response: {error_response.get_data(as_text=True)}")  # Add this line
        return error_response, 500

if __name__ == '__main__':
    app.run(debug=True, port=5000)