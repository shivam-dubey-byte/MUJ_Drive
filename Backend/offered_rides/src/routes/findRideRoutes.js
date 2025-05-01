// routes/findRideRoutes.js

const express = require('express');
const { findRides } = require('../controllers/findRideController');

const router = express.Router();

// POST /rides/find-ride
router.post('/find-ride', findRides);

module.exports = router;
