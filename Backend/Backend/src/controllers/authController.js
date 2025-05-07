const asyncHandler = require('express-async-handler');
const crypto      = require('crypto');
const {
  createStudent, findStudentByEmail, compareStudentPassword
} = require('../models/studentModel');
const {
  createDriver, findDriverByEmail, compareDriverPassword
} = require('../models/driverModel');
const {
  saveOTP, getOTPRecord, verifyOTPRecord, deleteOTPRecord
} = require('../models/otpModel');
const { sendOtpEmail }    = require('../mail/otpMail');
const { generateToken, verifyToken } = require('../utils/jwt');
const { OTP_EXPIRES_MIN } = require('../config/config');

// — OTP endpoints —

// @route POST /auth/send-otp
exports.sendOtp = asyncHandler(async (req, res) => {
  const { email } = req.body;
  // generate 6-digit OTP
  const otp = ('000000' + Math.floor(Math.random() * 1000000)).slice(-6);
  const expiresAt = new Date(Date.now() + OTP_EXPIRES_MIN * 60 * 1000);
  await saveOTP(email, otp, expiresAt);
  console.log("saveOTP worked");
  await sendOtpEmail(email, otp);
  res.json({ message: 'OTP sent to email' });
});

// @route POST /auth/verify-otp
exports.verifyOtp = asyncHandler(async (req, res) => {
  const { email, otp } = req.body;
  const record = await getOTPRecord(email);
  if (!record) {
    res.status(400);
    throw new Error('No OTP request found');
  }
  if (record.verified) {
    res.status(400);
    throw new Error('OTP already verified');
  }
  if (new Date(record.expiresAt) < new Date()) {
    res.status(400);
    throw new Error('OTP expired');
  }
  if (record.otp !== otp) {
    res.status(400);
    throw new Error('Invalid OTP');
  }
  await verifyOTPRecord(email);
  res.json({ message: 'OTP verified' });
});

// — Student routes —

// @route POST /auth/student/signup
exports.registerStudent = asyncHandler(async (req, res) => {
  const { name, email, password, phone, registration } = req.body;

  // ensure OTP verification
  const otpRec = await getOTPRecord(email);
  if (!otpRec || !otpRec.verified) {
    res.status(400);
    throw new Error('Email not verified');
  }

  if (await findStudentByEmail(email)) {
    res.status(400);
    throw new Error('Student already exists');
  }

  const studentId = await createStudent(name, email, password, phone, registration);
  await deleteOTPRecord(email);      // clean up
  const token = generateToken({ userId: studentId, role: 'student',email:email });
  res.status(201).json({ message: 'Student registered', token });
});

// @route POST /auth/student/login
exports.loginStudent = asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  const student = await findStudentByEmail(email);
  if (!student || !(await compareStudentPassword(password, student.password))) {
    res.status(401);
    throw new Error('Invalid student credentials');
  }
  const token = generateToken({ userId: student._id, email:  student.email, role: 'student',email:student.email, });
  res.json({ message: 'Student logged in', token, name:student.name,phone:student.phone,registration:student.registration });
});

// — Driver routes —

// @route POST /auth/driver/signup
exports.registerDriver = asyncHandler(async (req, res) => {
  const { name, email, password, phone, vehicleDetails, drivingLicense } = req.body;

  // ensure OTP verification
  const otpRec = await getOTPRecord(email);
  if (!otpRec || !otpRec.verified) {
    res.status(400);
    throw new Error('Email not verified');
  }

  if (await findDriverByEmail(email)) {
    res.status(400);
    throw new Error('Driver already exists');
  }

  const driverId = await createDriver(name, email, password, phone, vehicleDetails, drivingLicense);
  await deleteOTPRecord(email);
  const token = generateToken({ userId: driverId, role: 'driver' });
  res.status(201).json({ message: 'Driver registered', token });
});

// @route POST /auth/driver/login
exports.loginDriver = asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  const driver = await findDriverByEmail(email);
  if (!driver || !(await compareDriverPassword(password, driver.password))) {
    res.status(401);
    throw new Error('Invalid driver credentials');
  }
  const token = generateToken({ userId: driver._id, email:  driver.email, role: 'driver' });
  res.json({ message: 'Driver logged in', token,name:driver.name,phone:driver.phone,vehicleDetails:driver.vehicleDetails,drivingLicense:driver.drivingLicense });
});
