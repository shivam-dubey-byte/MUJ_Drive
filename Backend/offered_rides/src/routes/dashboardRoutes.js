// src/routes/dashboardRoutes.js

const express            = require('express');
const authMiddleware     = require('../middleware/authMiddleware');
const { getDashboard }   = require('../controllers/dashboardController');
const router = express.Router();

// GET /rides/dashboard (protected)
router.get('/dashboard', authMiddleware, getDashboard);

module.exports = router;
