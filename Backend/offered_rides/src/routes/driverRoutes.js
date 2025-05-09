// routes/driverRoutes.js

const express = require('express');
const router = express.Router();
const { addNewDriverData, getAllDriverData } = require('../models/driverDataModel');
const authMiddleware = require('../middleware/authMiddleware');

// GET /api/drivers - List all driver numbers from driverdata (secured, only for students)
router.get('/', authMiddleware, async (req, res) => {
    try {
        if (req.user.role !== "student") {
            return res.status(403).json({ error: "Access denied. Only students can access this resource." });
        }
        const drivers = await getAllDriverData();
        res.json(drivers);
    } catch (error) {
        console.error("Error fetching drivers:", error.message);
        res.status(500).json({ error: 'Failed to fetch drivers: ' + error.message });
    }
});

// POST /api/drivers - Add a new driver to driverdata (secured, only for students)
router.post('/', authMiddleware, async (req, res) => {
    const { name, phone } = req.body;
    if (!name || !phone) {
        return res.status(400).json({ error: 'Name and phone number are required' });
    }

    try {
        if (req.user.role !== "student") {
            return res.status(403).json({ error: "Access denied. Only students can add drivers." });
        }

        const newDriver = await addNewDriverData(name, phone);
        res.status(201).json({ message: 'Driver added successfully', driver: newDriver });
    } catch (error) {
        console.error("Error adding driver:", error.message);
        res.status(500).json({ error: 'Failed to add driver: ' + error.message });
    }
});

module.exports = router;
