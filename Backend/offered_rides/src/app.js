const express = require('express');
const cors    = require('cors');
const connectDB = require('./config/connectDB');

const offeredRideRoutes = require('./routes/offeredRideRoutes');

const app = express();

// connect to MongoDB
connectDB();

app.use(cors());
app.use(express.json());

// mount our rides endpoint
app.use('/rides', offeredRideRoutes);

// global error handler
app.use((err, req, res, next) => {
  res.status(res.statusCode || 500).json({ message: err.message });
});

module.exports = app;
