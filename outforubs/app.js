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
        // Create a new iframe to contain the report
        const iframe = document.createElement('iframe');
        iframe.srcdoc = report;
        iframe.style.width = '100%';
        iframe.style.height = '500px';
        iframe.style.border = 'none';

        // Clear the response element and append the new iframe
        responseElement.innerHTML = '';
        responseElement.appendChild(iframe);

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
        const reportContent = responseElement.querySelector('iframe').srcdoc;
        if (reportContent && reportContent.trim()) {
            const blob = new Blob([reportContent], { type: 'text/html;charset=utf-8' });
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