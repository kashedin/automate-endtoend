#!/bin/bash
# Web Tier User Data Script for Amazon Linux 2023

# Update system
dnf update -y

# Install required packages
dnf install -y httpd aws-cli

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Configure Apache
systemctl start httpd
systemctl enable httpd

# Create a simple index page
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Web Tier - ${environment}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background-color: #232f3e; color: white; padding: 20px; }
        .content { padding: 20px; }
        .status { background-color: #d4edda; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Automated Cloud Infrastructure</h1>
        <h2>Web Tier - ${environment} Environment</h2>
    </div>
    <div class="content">
        <div class="status">
            <h3>✅ Web Server Status: Running</h3>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>Availability Zone:</strong> <span id="az">Loading...</span></p>
            <p><strong>Environment:</strong> ${environment}</p>
            <p><strong>Database Endpoint:</strong> ${db_endpoint}</p>
        </div>
        
        <h3>Health Check Endpoint</h3>
        <p><a href="/health">/health</a> - Application health status</p>
        
        <h3>Application Features</h3>
        <ul>
            <li>Load balanced across multiple availability zones</li>
            <li>Auto scaling based on demand</li>
            <li>Integrated with Aurora MySQL database</li>
            <li>CloudWatch monitoring and logging</li>
        </ul>
    </div>
    
    <script>
        // Fetch instance metadata
        fetch('/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(error => document.getElementById('instance-id').textContent = 'Unable to fetch');
            
        fetch('/latest/meta-data/placement/availability-zone')
            .then(response => response.text())
            .then(data => document.getElementById('az').textContent = data)
            .catch(error => document.getElementById('az').textContent = 'Unable to fetch');
    </script>
</body>
</html>
EOF

# Create health check endpoint
cat > /var/www/html/health << EOF
#!/bin/bash
echo "Content-Type: text/plain"
echo ""
echo "OK"
EOF

chmod +x /var/www/html/health

# Configure Apache for health check
cat >> /etc/httpd/conf/httpd.conf << EOF

# Health check configuration
<Location "/health">
    SetHandler cgi-script
    Options +ExecCGI
</Location>
EOF

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "metrics": {
        "namespace": "AutomatedInfra/${environment}/WebTier",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/httpd/access_log",
                        "log_group_name": "/aws/ec2/${environment}/web/httpd/access",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/httpd/error_log",
                        "log_group_name": "/aws/ec2/${environment}/web/httpd/error",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Restart Apache to apply configuration
systemctl restart httpd

# Enable services
systemctl enable amazon-cloudwatch-agent

# Log completion
echo "Web tier setup completed at $(date)" >> /var/log/user-data.log