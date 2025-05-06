// app.js

const express      = require('express');
const cors         = require('cors');
const { connectDB } = require('./config/connectDB');  // ← destructured

const offerRoutes  = require('./routes/offeredRideRoutes');
const findRoutes   = require('./routes/findRideRoutes');
const bookingRoutes= require('./routes/bookingRoutes');
const notificationRoutes = require('./routes/notificationRoutes');

const app = express();

// connect to MongoDB
connectDB();

app.use(cors());
app.use(express.json());

// existing offer-ride endpoint
app.use('/rides', offerRoutes);

// new find-ride endpoint
app.use('/rides', findRoutes);

app.use('/rides', bookingRoutes);

// ── add notifications endpoint ──────────────────
app.use('/notifications', notificationRoutes);
// now GET  /notifications  and  PUT  /notifications/:id/read  will work

// global error handler
app.use((err, req, res, next) => {
  res.status(res.statusCode || 500).json({ message: err.message });
});

module.exports = app;
