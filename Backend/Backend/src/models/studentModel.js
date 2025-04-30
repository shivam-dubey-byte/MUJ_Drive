const bcrypt = require('bcryptjs');
const { ObjectId } = require('mongodb');
const connectDB = require('../config/connectDB');

async function createStudent(name, email, password, phone, registration) {
  const db = await connectDB();
  const students = db.collection('student');
  const hashed = await bcrypt.hash(password, 10);
  const { insertedId } = await students.insertOne({
    name, email, password: hashed, phone, registration
  });
  return insertedId;
}

async function findStudentByEmail(email) {
  const db = await connectDB();
  return db.collection('student').findOne({ email });
}

async function compareStudentPassword(plain, hash) {
  return bcrypt.compare(plain, hash);
}

async function findStudentById(id) {
  const db = await connectDB();
  return db.collection('student').findOne({ _id: new ObjectId(id) });
}

module.exports = {
  createStudent,
  findStudentByEmail,
  compareStudentPassword,
  findStudentById
};
