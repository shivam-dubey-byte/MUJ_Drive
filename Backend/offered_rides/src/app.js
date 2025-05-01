// app.js

const express    = require('express');
const cors       = require('cors');
const connectDB  = require('./config/connectDB');

const offerRoutes = require('./routes/offeredRideRoutes');  // keeps /rides/offer-ride unchanged
const findRoutes  = require('./routes/findRideRoutes');     // adds /rides/find-ride

const app = express();

// connect to MongoDB
connectDB();

app.use(cors());
app.use(express.json());

// existing offer-ride endpoint
app.use('/rides', offerRoutes);   // mounts POST /rides/offer-ride :contentReference[oaicite:0]{index=0}&#8203;:contentReference[oaicite:1]{index=1}

// new find-ride endpoint
app.use('/rides', findRoutes);    // mounts POST /rides/find-ride :contentReference[oaicite:2]{index=2}&#8203;:contentReference[oaicite:3]{index=3}

// global error handler
app.use((err, req, res, next) => {
  res.status(res.statusCode || 500).json({ message: err.message });
});

module.exports = app;
