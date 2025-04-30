const express    = require('express');
const cors       = require('cors');
const connectDB  = require('./config/connectDB');
const authRoutes = require('./routes/authRoutes');

const app = express();

app.use(express.json());
app.use(cors());

app.use('/auth', authRoutes);

app.get('/', (req, res) => res.json({ message: 'API is up' }));

connectDB();

module.exports = app;
