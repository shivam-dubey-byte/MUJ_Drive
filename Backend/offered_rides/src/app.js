// src/app.js

const express      = require('express');
const cors         = require('cors');
const { connectDB } = require('./config/connectDB');  // your Mongo connection helper

// Existing feature routes
const offerRoutes        = require('./routes/offeredRideRoutes');
const findRoutes         = require('./routes/findRideRoutes');

// New booking & request workflow
const bookingRoutes      = require('./routes/bookingRoutes');

// Existing notification routes
const notificationRoutes = require('./routes/notificationRoutes');

const dashboardRoutes    = require('./routes/dashboardRoutes');

const offeredHistoryRoutes = require('./routes/offeredHistoryRoutes');

const driverRoutes = require('./routes/driverRoutes');

const app = express();

// 1. Connect to MongoDB
connectDB();

// 2. Global middleware
app.use(cors());
app.use(express.json());

// 3. Route mounting
//  3.a Students offer rides
app.use('/rides', offerRoutes);
//  3.b Students find rides
app.use('/rides', findRoutes);
//  3.c Booking lifecycle (book, list, accept/reject, cancel)
app.use('/rides', bookingRoutes);

app.use('/rides', dashboardRoutes);

//  3.d In-app notifications
app.use('/notifications', notificationRoutes);

app.use('/rides', offeredHistoryRoutes);

app.use('/api/drivers', driverRoutes);


// 4. Global error handler
app.use((err, req, res, next) => {
  res.status(res.statusCode || 500).json({ message: err.message });
});

module.exports = app;
