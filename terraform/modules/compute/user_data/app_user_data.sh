#!/bin/bash
# App Tier User Data Script for Amazon Linux 2023

# Update system
dnf update -y

# Install required packages
dnf install -y python3 python3-pip aws-cli mysql

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Create application user
useradd -m -s /bin/bash appuser

# Create application directory
mkdir -p /opt/app
chown appuser:appuser /opt/app

# Create a simple Python Flask application
cat > /opt/app/app.py << 'EOF'
#!/usr/bin/env python3
import os
import json
import boto3
from flask import Flask, jsonify, request
import mysql.connector
from datetime import datetime

app = Flask(__name__)

# AWS clients
ssm_client = boto3.client('ssm')

def get_parameter(parameter_name):
    """Get parameter from AWS Systems Manager Parameter Store"""
    try:
        response = ssm_client.get_parameter(
            Name=parameter_name,
            WithDecryption=True
        )
        return response['Parameter']['Value']
    except Exception as e:
        print(f"Error getting parameter {parameter_name}: {e}")
        return None

def get_db_connection():
    """Get database connection using parameters from Parameter Store"""
    try:
        db_host = "${db_endpoint}"
        db_user = get_parameter("/${environment}/database/username")
        db_password = get_parameter("/${environment}/database/password")
        db_name = get_parameter("/${environment}/database/name")
        
        if not all([db_host, db_user, db_password, db_name]):
            return None
            
        connection = mysql.connector.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            database=db_name
        )
        return connection
    except Exception as e:
        print(f"Database connection error: {e}")
        return None

@app.route('/health')
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'environment': '${environment}'
    })

@app.route('/db-health')
def db_health_check():
    """Database health check endpoint"""
    try:
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            cursor.close()
            conn.close()
            
            return jsonify({
                'status': 'healthy',
                'database': 'connected',
                'timestamp': datetime.now().isoformat()
            })
        else:
            return jsonify({
                'status': 'unhealthy',
                'database': 'disconnected',
                'timestamp': datetime.now().isoformat()
            }), 500
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'database': 'error',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/info')
def app_info():
    """Application information endpoint"""
    return jsonify({
        'application': 'Automated Cloud Infrastructure App Tier',
        'environment': '${environment}',
        'version': '1.0.0',
        'timestamp': datetime.now().isoformat()
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
EOF

# Install Python dependencies
pip3 install flask mysql-connector-python boto3

# Create systemd service for the application
cat > /etc/systemd/system/app.service << EOF
[Unit]
Description=Application Tier Service
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/opt/app
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=always
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# Set permissions
chown appuser:appuser /opt/app/app.py
chmod +x /opt/app/app.py

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "metrics": {
        "namespace": "AutomatedInfra/${environment}/AppTier",
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
                        "file_path": "/var/log/app.log",
                        "log_group_name": "/aws/ec2/${environment}/app/application",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    }
}
EOF

# Start services
systemctl daemon-reload
systemctl start app
systemctl enable app

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

systemctl enable amazon-cloudwatch-agent

# Log completion
echo "App tier setup completed at $(date)" >> /var/log/user-data.log