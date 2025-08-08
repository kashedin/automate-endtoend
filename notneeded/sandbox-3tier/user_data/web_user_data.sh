#!/bin/bash
# Web Tier User Data Script - Sandbox Optimized
# This script sets up Apache web server that proxies to the app tier

# Update system
yum update -y

# Install Apache web server
yum install -y httpd

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create a simple index page
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>3-Tier Architecture Demo - Web Tier</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f0f8ff;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .tier {
            background: #e6f3ff;
            padding: 15px;
            margin: 10px 0;
            border-left: 4px solid #007acc;
            border-radius: 5px;
        }
        .status {
            color: #28a745;
            font-weight: bold;
        }
        .info {
            background: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            margin: 10px 0;
        }
        button {
            background: #007acc;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            margin: 5px;
        }
        button:hover {
            background: #005999;
        }
        #response {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-top: 15px;
            min-height: 50px;
        }
        .sandbox-info {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            padding: 15px;
            border-radius: 5px;
            margin: 15px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏗️ AWS Academy Sandbox 3-Tier Architecture</h1>
        <p>Welcome to the <strong>Web Tier</strong> of our sandbox-optimized 3-tier architecture!</p>
        
        <div class="sandbox-info">
            <h4>🎓 AWS Academy Sandbox Optimized</h4>
            <p>This deployment is specifically designed to work within AWS Academy sandbox constraints:</p>
            <ul>
                <li>✅ t3.micro instances (sandbox compliant)</li>
                <li>✅ Single NAT Gateway (cost optimized)</li>
                <li>✅ RDS db.t3.micro (sandbox compliant)</li>
                <li>✅ LabInstanceProfile usage</li>
                <li>✅ Conservative scaling limits</li>
            </ul>
        </div>
        
        <div class="tier">
            <h3>📱 Web Tier (Current Layer)</h3>
            <p class="status">✅ Status: Active</p>
            <p>You are currently viewing this page from the <strong>Web Tier</strong> running on Apache HTTP Server.</p>
            <div class="info">
                <strong>Server Info:</strong><br>
                Environment: ${environment}<br>
                Instance: <span id="instance-id">Loading...</span><br>
                Availability Zone: <span id="az">Loading...</span><br>
                Instance Type: t3.micro (Sandbox Optimized)
            </div>
        </div>

        <div class="tier">
            <h3>⚙️ Application Tier</h3>
            <p>Test connectivity to the Application Tier via internal load balancer:</p>
            <button onclick="testAppTier()">Test App Tier Health</button>
            <button onclick="testDatabase()">Test Database Connection</button>
            <button onclick="testAppData()">Get App Data</button>
        </div>

        <div class="tier">
            <h3>🗄️ Database Tier</h3>
            <p>MySQL RDS db.t3.micro instance running in private subnets, accessible only from the Application Tier.</p>
        </div>

        <div id="response"></div>

        <div class="info">
            <h4>Architecture Overview:</h4>
            <ul>
                <li><strong>Public ALB:</strong> Distributes traffic across web servers</li>
                <li><strong>Web Tier:</strong> Apache servers in private subnets (current layer)</li>
                <li><strong>Internal ALB:</strong> Load balances app tier requests</li>
                <li><strong>App Tier:</strong> Node.js servers in private subnets</li>
                <li><strong>Database Tier:</strong> MySQL RDS in isolated private subnets</li>
                <li><strong>NAT Gateway:</strong> Provides internet access for private subnets</li>
            </ul>
        </div>
    </div>

    <script>
        // Load instance metadata
        fetch('/instance-info')
            .then(response => response.json())
            .then(data => {
                document.getElementById('instance-id').textContent = data.instanceId || 'Unknown';
                document.getElementById('az').textContent = data.availabilityZone || 'Unknown';
            })
            .catch(error => {
                document.getElementById('instance-id').textContent = 'Error loading';
                document.getElementById('az').textContent = 'Error loading';
            });

        function testAppTier() {
            document.getElementById('response').innerHTML = '<p>🔄 Testing Application Tier health...</p>';
            
            fetch('/api/health')
                .then(response => response.json())
                .then(data => {
                    document.getElementById('response').innerHTML = 
                        '<h4>✅ Application Tier Health Response:</h4>' +
                        '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
                })
                .catch(error => {
                    document.getElementById('response').innerHTML = 
                        '<h4>❌ Application Tier Error:</h4>' +
                        '<p>Could not connect to application tier: ' + error.message + '</p>' +
                        '<p><em>Note: App tier may still be initializing. Please wait a few minutes and try again.</em></p>';
                });
        }

        function testDatabase() {
            document.getElementById('response').innerHTML = '<p>🔄 Testing Database connection via App Tier...</p>';
            
            fetch('/api/db-status')
                .then(response => response.json())
                .then(data => {
                    document.getElementById('response').innerHTML = 
                        '<h4>✅ Database Connection Status:</h4>' +
                        '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
                })
                .catch(error => {
                    document.getElementById('response').innerHTML = 
                        '<h4>❌ Database Connection Error:</h4>' +
                        '<p>Could not connect to database via app tier: ' + error.message + '</p>' +
                        '<p><em>Note: Database may still be initializing. Please wait a few minutes and try again.</em></p>';
                });
        }

        function testAppData() {
            document.getElementById('response').innerHTML = '<p>🔄 Fetching data from App Tier...</p>';
            
            fetch('/api/data')
                .then(response => response.json())
                .then(data => {
                    document.getElementById('response').innerHTML = 
                        '<h4>✅ App Tier Data Response:</h4>' +
                        '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
                })
                .catch(error => {
                    document.getElementById('response').innerHTML = 
                        '<h4>❌ App Tier Data Error:</h4>' +
                        '<p>Could not fetch data from app tier: ' + error.message + '</p>';
                });
        }
    </script>
</body>
</html>
EOF

# Create a simple PHP script to get instance metadata
cat > /var/www/html/instance-info << 'EOF'
#!/bin/bash
echo "Content-Type: application/json"
echo ""

# Get instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unknown")
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null || echo "unknown")
INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || echo "unknown")

cat << JSON
{
    "instanceId": "$INSTANCE_ID",
    "availabilityZone": "$AZ",
    "instanceType": "$INSTANCE_TYPE",
    "tier": "web",
    "environment": "${environment}",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON
EOF

chmod +x /var/www/html/instance-info

# Configure Apache to handle API requests (proxy to app tier via internal load balancer)
cat > /etc/httpd/conf.d/proxy.conf << EOF
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so

# Proxy API requests to app tier internal load balancer
ProxyPreserveHost On
ProxyPass /api/ http://${app_internal_lb_dns}/
ProxyPassReverse /api/ http://${app_internal_lb_dns}/

# Handle instance-info requests
ScriptAlias /instance-info /var/www/html/instance-info
EOF

# Create health check endpoint
cat > /var/www/html/health << 'EOF'
#!/bin/bash
echo "Content-Type: application/json"
echo ""
echo '{"status": "healthy", "tier": "web", "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}'
EOF

chmod +x /var/www/html/health

# Restart Apache to apply configuration
systemctl restart httpd

# Create a simple log rotation for access logs
cat > /etc/logrotate.d/httpd-custom << 'EOF'
/var/log/httpd/*log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 apache apache
    postrotate
        systemctl reload httpd
    endscript
}
EOF

# Log deployment completion
echo "$(date): Web tier deployment completed successfully" >> /var/log/deployment.log
echo "Environment: ${environment}" >> /var/log/deployment.log
echo "App Internal LB DNS: ${app_internal_lb_dns}" >> /var/log/deployment.log
echo "Instance Type: t3.micro (Sandbox Optimized)" >> /var/log/deployment.log