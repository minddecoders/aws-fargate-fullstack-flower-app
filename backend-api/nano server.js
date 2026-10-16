const express = require('express');
const mysql = require('mysql2');

const app = express();
const PORT = process.env.PORT || 80;

app.use(express.json());

// 🛰️ DYNAMIC ENVIRONMENT INGRESS: Reads structural parameters injected from ECS Task Definition Secrets
const dbConfig = {
    host: process.env.DB_HOST,
    user: process.env.DB_USER || 'sidradbadmin',
    password: process.env.DATABASE_PASSWORD, // 🔐 Injected securely from AWS Secrets Manager!
    database: process.env.DB_NAME || 'sidrabackenddb',
    port: 3306,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
};

// 🏁 INITIALIZE RESILIENT DATABASE CONNECTION POOLING
let pool;

try {
    pool = mysql.createPool(dbConfig);
    console.log('📡 System Status: Initializing database connection pooling matrix...');
} catch (error) {
    console.error('🚨 Critical initialization failure establishing pool:', error.message);
}

// 🩺 HEALTH CHECK INGRESS ROUTE: Used by AWS ALB target groups to verify task viability
app.get('/', (req, res) => {
    res.status(200).json({
        status: "HEALTHY",
        region: process.env.AWS_REGION || "eu-west-1",
        timestamp: new Date().toISOString(),
        message: "Welcome to Sidra's Full-Stack Stateful Microservice Backend Engine!"
    });
});

// 🧪 LIVE DATABASE QUERY PROBE ROUTE: Verifies communication links to RDS MySQL are clear
app.get('/db-check', (req, res) => {
    if (!pool) {
        return res.status(500).json({ status: "UNHEALTHY", error: "Database connection pool not initialized." });
    }

    pool.query('SELECT 1 + 1 AS solution', (error, results) => {
        if (error) {
            console.error('🚨 RDS Connectivity Probing Failure:', error.message);
            return res.status(500).json({
                status: "UNHEALTHY",
                database: "DISCONNECTED",
                error: error.message
            });
        }
        
        res.status(200).json({
            status: "HEALTHY",
            database: "CONNECTED",
            message: "Fargate container successfully communicated with Amazon RDS MySQL over the private subnet!",
            probe_result: results[0].solution
        });
    });
});

// 🚀 UNLEASH APPLICATION LISTENER
app.listen(PORT, () => {
    console.log(`🚀 Flight Control: Stateful application backend container listening live on port ${PORT}`);
});