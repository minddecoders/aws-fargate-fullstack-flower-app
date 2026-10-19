const express = require('express');
const mysql = require('mysql2');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// 🛰️ DYNAMIC ENVIRONMENT INGRESS: Reads structural parameters injected from ECS Task Definition Secrets
const dbConfig = {
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DATABASE_PASSWORD, // 🔐 Injected securely from AWS Secrets Manager!
    database: process.env.DB_NAME,
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
//🎯 SYSTEM SYNCHRONIZED: Dedicated lightweight endpoint for cloud load balancer pings
app.get('/health', (req, res) => {
    res.status(200).json({ 
        status: 'healthy',
        timestamp: new Date().toISOString()
    });
});

// 🧪 LIVE DATABASE QUERY PROBE ROUTE: Verifies communication links to RDS MySQL are clear
//🔄 PATH CORRECTION: Prefixed with /api/ so it clears your ALB network rule filters smoothly
app.get('/api/db-check', (req, res) => {
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

// 🌸 PRODUCTS API
//🎯 COMPLIANT ENDPOINT: Perfectly exposes your beautiful flower asset lists
app.get('/api/products', (req, res) => {
    res.status(200).json([
        {
            id: 1,
            name: 'Velvet Sunset Rose Bouquet',
            category: 'roses',
            price: 64.99,
            rating: 4.9,
            reviews: 128,
            image: 'https://images.unsplash.com/photo-1561181286-d3fee7d55364?auto=format&fit=crop&q=80&w=800',
            description: 'Rich crimson and warm peach roses hand-tied with seeded eucalyptus.'
        },
        {
            id: 2,
            name: 'Blushing Spring Tulip Medley',
            category: 'tulips',
            price: 45.00,
            rating: 4.8,
            reviews: 94,
            image: 'https://images.unsplash.com/photo-1520763185298-1b434c919102?auto=format&fit=crop&q=80&w=800',
            description: 'Fresh Dutch tulips in soft pastel pinks and cheerful yellows.'
        }
    ]);
});

// 🚀 UNLEASH APPLICATION LISTENER
app.listen(PORT, () => {
    console.log(`🚀 Flight Control: Stateful application backend container listening live on port ${PORT}`);
});
