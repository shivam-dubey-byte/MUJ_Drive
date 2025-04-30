const express = require('express');
const {
  sendOtp, verifyOtp,
  registerStudent, loginStudent,
  registerDriver, loginDriver
} = require('../controllers/authController');

const router = express.Router();

// OTP verification flow
router.post('/send-otp',   sendOtp);
router.post('/verify-otp', verifyOtp);

// Student
router.post('/student/signup', registerStudent);
router.post('/student/login',  loginStudent);

// Driver
router.post('/driver/signup', registerDriver);
router.post('/driver/login',  loginDriver);

module.exports = router;
