from flask import Flask, request, jsonify, send_from_directory
from communication_module import CommunicationModule

app = Flask(__name__, static_folder='../frontend', static_url_path='')

# Initialize the CommunicationModule
comm_module = CommunicationModule()

@app.route('/')
def index():
    return send_from_directory('../frontend', 'index.html')

@app.route('/api/healthcheck', methods=['POST'])
def healthcheck():
    data = request.get_json()
    db_type = data['dbType']
    hostnames = data['hostnames']
    try:
        report = comm_module.process_request(db_type, hostnames)
        return jsonify({'report': report})
    except Exception as e:
        return jsonify({'report': f'Error: {str(e)}'})

if __name__ == '__main__':
    app.run(debug=True)
