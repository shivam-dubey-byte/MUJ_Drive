// routes/findRideRoutes.js

const express      = require('express');
const { findRides } = require('../controllers/findRideController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

// POST /rides/find-ride
router.post('/find-ride', authMiddleware, findRides);

module.exports = router;
