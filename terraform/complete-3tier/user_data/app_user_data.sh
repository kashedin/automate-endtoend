#!/bin/bash
# App Tier User Data Script
# This script sets up a simple Node.js application server that connects to the database

# Update system
yum update -y

# Install Node.js and npm
curl -sL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Create application directory
mkdir -p /opt/app
cd /opt/app

# Create package.json
cat > package.json << 'EOF'
{
  "name": "3tier-app",
  "version": "1.0.0",
  "description": "3-Tier Architecture Demo Application",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.0",
    "cors": "^2.8.5"
  }
}
EOF

# Install dependencies
npm install

# Create the main application server
cat > server.js << 'EOF'
const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');

const app = express();
const PORT = 8080;

// Middleware
app.use(cors());
app.use(express.json());

// Database configuration
const dbConfig = {
    host: '${db_endpoint}'.split(':')[0],
    user: '${db_username}',
    password: '${db_password}',
    database: '${db_name}',
    connectTimeout: 10000,
    acquireTimeout: 10000,
    timeout: 10000,
};

// Database connection pool
let pool;

async function initializeDatabase() {
    try {
        pool = mysql.createPool(dbConfig);
        
        // Test connection
        const connection = await pool.getConnection();
        console.log('Database connected successfully');
        
        // Create sample table if it doesn't exist
        await connection.execute(`
            CREATE TABLE IF NOT EXISTS health_checks (
                id INT AUTO_INCREMENT PRIMARY KEY,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                status VARCHAR(50),
                instance_id VARCHAR(100),
                message TEXT
            )
        `);
        
        // Insert initial health check
        const instanceId = await getInstanceId();
        await connection.execute(
            'INSERT INTO health_checks (status, instance_id, message) VALUES (?, ?, ?)',
            ['healthy', instanceId, 'Application tier started successfully']
        );
        
        connection.release();
        console.log('Database initialized successfully');
    } catch (error) {
        console.error('Database initialization failed:', error);
    }
}

// Get instance metadata
async function getInstanceId() {
    try {
        const response = await fetch('http://169.254.169.254/latest/meta-data/instance-id');
        return await response.text();
    } catch (error) {
        return 'unknown';
    }
}

async function getAvailabilityZone() {
    try {
        const response = await fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone');
        return await response.text();
    } catch (error) {
        return 'unknown';
    }
}

// Routes
app.get('/health', async (req, res) => {
    try {
        const instanceId = await getInstanceId();
        const az = await getAvailabilityZone();
        
        res.json({
            status: 'healthy',
            tier: 'application',
            environment: '${environment}',
            instanceId: instanceId,
            availabilityZone: az,
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            nodeVersion: process.version
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

app.get('/db-status', async (req, res) => {
    try {
        if (!pool) {
            throw new Error('Database pool not initialized');
        }
        
        const connection = await pool.getConnection();
        
        // Test database connectivity
        const [rows] = await connection.execute('SELECT 1 as test');
        
        // Get database info
        const [versionRows] = await connection.execute('SELECT VERSION() as version');
        const [statusRows] = await connection.execute('SHOW STATUS LIKE "Threads_connected"');
        
        // Get recent health checks
        const [healthRows] = await connection.execute(
            'SELECT * FROM health_checks ORDER BY timestamp DESC LIMIT 5'
        );
        
        connection.release();
        
        const instanceId = await getInstanceId();
        
        // Log this health check
        const healthConnection = await pool.getConnection();
        await healthConnection.execute(
            'INSERT INTO health_checks (status, instance_id, message) VALUES (?, ?, ?)',
            ['healthy', instanceId, 'Database connection test successful']
        );
        healthConnection.release();
        
        res.json({
            status: 'connected',
            database: {
                host: dbConfig.host,
                database: dbConfig.database,
                version: versionRows[0].version,
                connections: statusRows[0].Value
            },
            recentHealthChecks: healthRows,
            timestamp: new Date().toISOString()
        });
        
    } catch (error) {
        console.error('Database status check failed:', error);
        res.status(500).json({
            status: 'error',
            message: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

app.get('/api/data', async (req, res) => {
    try {
        if (!pool) {
            throw new Error('Database pool not initialized');
        }
        
        const connection = await pool.getConnection();
        const [rows] = await connection.execute('SELECT * FROM health_checks ORDER BY timestamp DESC LIMIT 10');
        connection.release();
        
        res.json({
            data: rows,
            count: rows.length,
            timestamp: new Date().toISOString()
        });
        
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('Unhandled error:', error);
    res.status(500).json({
        status: 'error',
        message: 'Internal server error',
        timestamp: new Date().toISOString()
    });
});

// Start server
app.listen(PORT, '0.0.0.0', async () => {
    console.log(`Application server running on port ${PORT}`);
    console.log(`Environment: ${environment}`);
    console.log(`Database endpoint: ${db_endpoint}`);
    
    // Initialize database connection
    await initializeDatabase();
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    console.log('SIGTERM received, shutting down gracefully');
    if (pool) {
        await pool.end();
    }
    process.exit(0);
});

process.on('SIGINT', async () => {
    console.log('SIGINT received, shutting down gracefully');
    if (pool) {
        await pool.end();
    }
    process.exit(0);
});
EOF

# Create systemd service for the application
cat > /etc/systemd/system/app-server.service << 'EOF'
[Unit]
Description=3-Tier Application Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/app
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Set permissions
chown -R ec2-user:ec2-user /opt/app

# Enable and start the service
systemctl daemon-reload
systemctl enable app-server
systemctl start app-server

# Install and configure log rotation
cat > /etc/logrotate.d/app-server << 'EOF'
/var/log/app-server.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 ec2-user ec2-user
    postrotate
        systemctl reload app-server
    endscript
}
EOF

# Create log file
touch /var/log/app-server.log
chown ec2-user:ec2-user /var/log/app-server.log

# Redirect application logs to log file
systemctl edit app-server --full << 'EOF'
[Unit]
Description=3-Tier Application Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/app
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
StandardOutput=append:/var/log/app-server.log
StandardError=append:/var/log/app-server.log

[Install]
WantedBy=multi-user.target
EOF

# Restart with new configuration
systemctl daemon-reload
systemctl restart app-server

# Wait for database to be available (with timeout)
echo "Waiting for database to be available..."
timeout=300
counter=0

while [ $counter -lt $timeout ]; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "Application server is responding"
        break
    fi
    echo "Waiting for application server... ($counter/$timeout)"
    sleep 10
    counter=$((counter + 10))
done

# Log deployment completion
echo "$(date): App tier deployment completed successfully" >> /var/log/deployment.log
echo "Environment: ${environment}" >> /var/log/deployment.log
echo "Database endpoint: ${db_endpoint}" >> /var/log/deployment.log
echo "Service status: $(systemctl is-active app-server)" >> /var/log/deployment.log