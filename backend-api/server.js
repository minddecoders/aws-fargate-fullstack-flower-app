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
app.get('/health', (req, res) => {
    res.status(200).json({ 
        status: 'healthy',
        timestamp: new Date().toISOString()
    });
});

// 🧪 LIVE DATABASE QUERY PROBE ROUTE: Verifies communication links to RDS MySQL are clear
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

// 🌸 PRODUCTS API (Expanded to match frontend categories completely)
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
        },
        {
            id: 3,
            name: 'Ethereal White Orchid',
            category: 'orchids',
            price: 78.50,
            rating: 5.0,
            reviews: 62,
            image: 'https://images.unsplash.com/photo-1521334884684-d80222895322?auto=format&fit=crop&q=80&w=800',
            description: 'Pristine potted Phalaenopsis orchid in a modern ceramic planter.'
        },
        {
            id: 4,
            name: 'Golden Sunflower & Daisy Charm',
            category: 'seasonal',
            price: 52.00,
            rating: 4.7,
            reviews: 81,
            image: 'https://images.unsplash.com/photo-1597848212624-a19eb35e2651?auto=format&fit=crop&q=80&w=800',
            description: 'Bright sunflowers paired with wild daisies to instantly warm up any room.'
        },
        {
            id: 5,
            name: 'Lavish Romance Luxury Bundle',
            category: 'bundles',
            price: 120.00,
            rating: 4.9,
            reviews: 215,
            image: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&q=80&w=800',
            description: 'Two dozen premium red roses accompanied by artisan dark chocolate and soy candle.'
        },
        {
            id: 6,
            name: 'Lavender Dream Hydrangea',
            category: 'seasonal',
            price: 58.00,
            rating: 4.8,
            reviews: 73,
            image: 'https://images.unsplash.com/photo-1508784411985-c424d0cfef8f?auto=format&fit=crop&q=80&w=800',
            description: 'Lush blue and purple hydrangeas designed with delicate baby’s breath.'
        }
    ]);
});

// 🚀 UNLEASH APPLICATION LISTENER
app.listen(PORT, () => {
    console.log(`🚀 Flight Control: Stateful application backend container listening live on port ${PORT}`);
});