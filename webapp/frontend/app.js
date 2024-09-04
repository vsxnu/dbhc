document.getElementById('submitBtn').addEventListener('click', function() {
    const dbType = document.getElementById('dbType').value;
    const hostnames = document.getElementById('hostnames').value.split('\n');

    fetch('/api/healthcheck', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ dbType, hostnames })
    })
    .then(response => response.json())
    .then(data => {
        document.getElementById('response').textContent = data.report;
    })
    .catch(error => {
        document.getElementById('response').textContent = 'Error: ' + error.message;
    });
});
