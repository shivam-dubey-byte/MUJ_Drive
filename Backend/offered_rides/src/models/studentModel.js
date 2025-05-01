// models/studentModel.js

const { getClient } = require('../config/connectDB');

async function findStudentByEmail(email) {
  const client  = await getClient();
  const usersDb = client.db('Users');          // explicitly “Users”
  return usersDb
    .collection('student')
    .findOne({ email }, { projection: { name:1, phone:1, _id:0 } });
}

module.exports = { findStudentByEmail };
