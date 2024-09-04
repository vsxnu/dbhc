document.getElementById('submitBtn').addEventListener('click', async () => {
    const dbTypeSelect = document.getElementById('dbType');
    const hostnamesTextarea = document.getElementById('hostnames');

    const dbType = dbTypeSelect.value;
    const hostnames = hostnamesTextarea.value.trim().split(/\n+/);

    try {
        const response = await fetch('/api/healthcheck', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ dbType, hostnames })
        });

        const responseData = await response.json();
        document.getElementById('response').textContent = responseData.report;
    } catch (error) {
        document.getElementById('response').textContent = `Error: ${error.message}`;
    }
});

