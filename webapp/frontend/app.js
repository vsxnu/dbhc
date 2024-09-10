document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('healthCheckForm');
    const responseElement = document.getElementById('response');
    const downloadBtn = document.getElementById('downloadBtn');
    const submitBtn = document.getElementById('submitBtn');

    form.addEventListener('submit', handleSubmit);

    function handleSubmit(e) {
        e.preventDefault();
        
        const dbType = document.getElementById('dbType').value;
        const hostnames = document.getElementById('hostnames').value.trim().split(/\n+/).filter(Boolean);

        if (hostnames.length === 0) {
            showError('Please enter at least one hostname.');
            return;
        }

        performHealthCheck(dbType, hostnames);
    }

    async function performHealthCheck(dbType, hostnames) {
        try {
            showLoading();
            const response = await fetch('/api/healthcheck', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ dbType, hostnames })
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const responseData = await response.json();

            if (responseData.html && responseData.html.trim()) {
                showResponse(responseData.html);
                showDownloadButton();
            } else {
                showError('No data received from the server.');
            }
        } catch (error) {
            console.error("Error in fetch:", error);
            showError(`Error: ${error.message}`);
        } finally {
            hideLoading();
        }
    }

    function showError(message) {
        responseElement.innerHTML = `<p class="error"><i class="fas fa-exclamation-circle"></i> ${message}</p>`;
        hideDownloadButton();
    }

    function showResponse(html) {
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');
        
        const serverReports = doc.querySelectorAll('.server-report');
        serverReports.forEach(report => {
            const statusElement = report.querySelector('.status-green, .status-red');
            if (statusElement) {
                const status = statusElement.textContent.includes('GREEN') ? 'GREEN' : 'RED';
                const newStatusElement = document.createElement('div');
                newStatusElement.className = `status-indicator status-${status.toLowerCase()}`;
                newStatusElement.innerHTML = `
                    <div class="status-dot"></div>
                    <span>${statusElement.textContent}</span>
                `;
                report.insertBefore(newStatusElement, report.firstChild);
                statusElement.remove();
            }
        });
        
        responseElement.innerHTML = doc.body.innerHTML;
    }

    function showLoading() {
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Processing...';
        responseElement.innerHTML = '<p class="loading"><i class="fas fa-spinner fa-spin"></i> Running health checks...</p>';
        hideDownloadButton();
    }

    function hideLoading() {
        submitBtn.disabled = false;
        submitBtn.innerHTML = 'Run Health Check';
    }

    function showDownloadButton() {
        downloadBtn.style.display = 'inline-block';
    }

    function hideDownloadButton() {
        downloadBtn.style.display = 'none';
    }

    downloadBtn.addEventListener('click', () => {
        const report = responseElement.innerHTML;
        if (report && report.trim()) {
            const fullHtml = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Health Check Report</title>
    <style>
        body { font-family: 'Inter', sans-serif; line-height: 1.6; color: #333; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1, h2, h3 { color: #1a2a3a; }
        .server-report { border-bottom: 1px solid #d1d8e0; padding-bottom: 15px; margin-bottom: 15px; }
        .server-report:last-child { border-bottom: none; }
        pre { background-color: #f5f7fa; border: 1px solid #d1d8e0; border-radius: 4px; padding: 15px; white-space: pre-wrap; }
        .error { color: #e74c3c; font-weight: 500; }
        .status-indicator { display: flex; align-items: center; font-weight: bold; margin-bottom: 10px; }
        .status-dot { width: 12px; height: 12px; border-radius: 50%; margin-right: 8px; box-shadow: 0 0 5px rgba(0, 0, 0, 0.3); }
        .status-green .status-dot { background-color: #28a745; box-shadow: 0 0 5px #28a745; }
        .status-red .status-dot { background-color: #dc3545; box-shadow: 0 0 5px #dc3545; }
        .status-green { color: #28a745; }
        .status-red { color: #dc3545; }
    </style>
</head>
<body>
    <h1>Database Health Check Report</h1>
    ${report}
</body>
</html>`;
            const blob = new Blob([fullHtml], { type: 'text/html' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'health_check_report.html';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        }
    });
});