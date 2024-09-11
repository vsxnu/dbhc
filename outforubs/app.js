document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('healthCheckForm');
    const responseElement = document.getElementById('response');
    const downloadBtn = document.getElementById('downloadBtn');

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const dbType = document.getElementById('dbType').value;
        const hostnames = document.getElementById('hostnames').value.trim().split(/\n+/).filter(Boolean);

        if (hostnames.length === 0) {
            alert('Please enter at least one hostname.');
            hideDownloadButton();
            return;
        }

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
            if (responseData.report && responseData.report.trim()) {
                showResponse(responseData.report);
                showDownloadButton();
            } else {
                showError('No data received from the server.');
                hideDownloadButton();
            }
        } catch (error) {
            showError(`Error: ${error.message}`);
            hideDownloadButton();
        } finally {
            hideLoading();
        }
    });

    function showError(message) {
        responseElement.innerHTML = `<p style="color: red;">${message}</p>`;
        responseElement.classList.add('error');
        hideDownloadButton();
    }

    function showResponse(report) {
        // Create a new div to contain the report
        const reportContainer = document.createElement('div');
        reportContainer.innerHTML = report;

        // Clear the response element and append the new container
        responseElement.innerHTML = '';
        responseElement.appendChild(reportContainer);

        responseElement.classList.remove('error');
    }

    function showLoading() {
        responseElement.innerHTML = '<p>Loading...</p>';
        responseElement.classList.add('loading');
        document.getElementById('submitBtn').disabled = true;
        hideDownloadButton();
    }

    function hideLoading() {
        responseElement.classList.remove('loading');
        document.getElementById('submitBtn').disabled = false;
    }

    function showDownloadButton() {
        downloadBtn.style.display = 'inline-block';
    }

    function hideDownloadButton() {
        downloadBtn.style.display = 'none';
    }

    downloadBtn.addEventListener('click', () => {
        const reportContent = responseElement.innerHTML;
        if (reportContent && reportContent.trim()) {
            const fullHtml = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Health Check Report</title>
    <style>
        body { font-family: Arial, sans-serif; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    ${reportContent}
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