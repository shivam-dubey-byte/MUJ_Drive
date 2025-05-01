const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../config/config');

const generateToken = payload =>
  jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' });

const verifyToken = token =>
  jwt.verify(token, JWT_SECRET);

module.exports = { generateToken, verifyToken };
