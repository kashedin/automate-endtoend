#!/bin/bash
# App Tier User Data Script - Sandbox Optimized
# This script sets up a Node.js application server that connects to the RDS database

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
  "name": "sandbox-3tier-app",
  "version": "1.0.0",
  "description": "AWS Academy Sandbox 3-Tier Architecture Demo Application",
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
    connectTimeout: 30000,
    acquireTimeout: 30000,
    timeout: 30000,
};

// Database connection pool
let pool;

async function initializeDatabase() {
    try {
        console.log('Initializing database connection...');
        pool = mysql.createPool(dbConfig);
        
        // Test connection with retry logic
        let retries = 10;
        while (retries > 0) {
            try {
                const connection = await pool.getConnection();
                console.log('Database connected successfully');
                
                // Create sample table if it doesn't exist
                await connection.execute(`
                    CREATE TABLE IF NOT EXISTS health_checks (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                        status VARCHAR(50),
                        instance_id VARCHAR(100),
                        instance_type VARCHAR(50),
                        availability_zone VARCHAR(50),
                        message TEXT
                    )
                `);
                
                // Create sample data table
                await connection.execute(`
                    CREATE TABLE IF NOT EXISTS sample_data (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                        data_type VARCHAR(50),
                        value VARCHAR(255),
                        description TEXT
                    )
                `);
                
                // Insert initial health check
                const instanceId = await getInstanceId();
                const instanceType = await getInstanceType();
                const az = await getAvailabilityZone();
                
                await connection.execute(
                    'INSERT INTO health_checks (status, instance_id, instance_type, availability_zone, message) VALUES (?, ?, ?, ?, ?)',
                    ['healthy', instanceId, instanceType, az, 'Sandbox-optimized application tier started successfully']
                );
                
                // Insert sample data
                const sampleData = [
                    ['user_count', '150', 'Number of active users'],
                    ['order_count', '45', 'Orders processed today'],
                    ['revenue', '2340.50', 'Daily revenue in USD'],
                    ['server_load', '0.65', 'Current server load average']
                ];
                
                for (const [type, value, desc] of sampleData) {
                    await connection.execute(
                        'INSERT INTO sample_data (data_type, value, description) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE value = VALUES(value), created_at = NOW()',
                        [type, value, desc]
                    );
                }
                
                connection.release();
                console.log('Database initialized successfully');
                break;
            } catch (error) {
                retries--;
                console.log(`Database connection attempt failed. Retries left: ${retries}. Error:`, error.message);
                if (retries === 0) throw error;
                await new Promise(resolve => setTimeout(resolve, 5000));
            }
        }
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

async function getInstanceType() {
    try {
        const response = await fetch('http://169.254.169.254/latest/meta-data/instance-type');
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
        const instanceType = await getInstanceType();
        const az = await getAvailabilityZone();
        
        res.json({
            status: 'healthy',
            tier: 'application',
            environment: '${environment}',
            instanceId: instanceId,
            instanceType: instanceType,
            availabilityZone: az,
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            nodeVersion: process.version,
            sandboxOptimized: true,
            databaseConnected: pool ? true : false
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
        const instanceType = await getInstanceType();
        
        // Log this health check
        const healthConnection = await pool.getConnection();
        await healthConnection.execute(
            'INSERT INTO health_checks (status, instance_id, instance_type, availability_zone, message) VALUES (?, ?, ?, ?, ?)',
            ['healthy', instanceId, instanceType, await getAvailabilityZone(), 'Database connection test successful']
        );
        healthConnection.release();
        
        res.json({
            status: 'connected',
            database: {
                host: dbConfig.host,
                database: dbConfig.database,
                version: versionRows[0].version,
                connections: statusRows[0].Value,
                instanceClass: 'db.t3.micro (Sandbox Optimized)'
            },
            recentHealthChecks: healthRows,
            sandboxOptimized: true,
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

app.get('/data', async (req, res) => {
    try {
        if (!pool) {
            throw new Error('Database pool not initialized');
        }
        
        const connection = await pool.getConnection();
        
        // Get sample data
        const [dataRows] = await connection.execute('SELECT * FROM sample_data ORDER BY created_at DESC');
        
        // Get health check summary
        const [healthSummary] = await connection.execute(`
            SELECT 
                COUNT(*) as total_checks,
                COUNT(DISTINCT instance_id) as unique_instances,
                MAX(timestamp) as last_check
            FROM health_checks
        `);
        
        connection.release();
        
        res.json({
            sampleData: dataRows,
            healthSummary: healthSummary[0],
            metadata: {
                environment: '${environment}',
                tier: 'application',
                sandboxOptimized: true,
                instanceType: 't3.micro',
                databaseType: 'db.t3.micro'
            },
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

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        message: 'AWS Academy Sandbox 3-Tier Application Tier',
        status: 'running',
        environment: '${environment}',
        sandboxOptimized: true,
        endpoints: [
            '/health - Health check endpoint',
            '/db-status - Database connectivity status',
            '/data - Sample application data'
        ],
        timestamp: new Date().toISOString()
    });
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
    console.log('Sandbox-optimized application server running on port ' + PORT);
    console.log('Environment: ${environment}');
    console.log('Database endpoint: ${db_endpoint}');
    console.log('Instance type: t3.micro (Sandbox Optimized)');
    
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
Description=Sandbox 3-Tier Application Server
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
Description=Sandbox 3-Tier Application Server
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

# Wait for application to be available (with timeout)
echo "Waiting for application server to be available..."
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
echo "Instance type: t3.micro (Sandbox Optimized)" >> /var/log/deployment.log
echo "Service status: $(systemctl is-active app-server)" >> /var/log/deployment.log