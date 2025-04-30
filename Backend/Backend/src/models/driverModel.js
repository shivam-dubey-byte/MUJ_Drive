const bcrypt = require('bcryptjs');
const { ObjectId } = require('mongodb');
const connectDB = require('../config/connectDB');

async function createDriver(name, email, password, phone, vehicleDetails, drivingLicense) {
  const db = await connectDB();
  const drivers = db.collection('driver');
  const hashed = await bcrypt.hash(password, 10);
  const { insertedId } = await drivers.insertOne({
    name, email, password: hashed, phone, vehicleDetails, drivingLicense
  });
  return insertedId;
}

async function findDriverByEmail(email) {
  const db = await connectDB();
  return db.collection('driver').findOne({ email });
}

async function compareDriverPassword(plain, hash) {
  return bcrypt.compare(plain, hash);
}

async function findDriverById(id) {
  const db = await connectDB();
  return db.collection('driver').findOne({ _id: new ObjectId(id) });
}

module.exports = {
  createDriver,
  findDriverByEmail,
  compareDriverPassword,
  findDriverById
};
