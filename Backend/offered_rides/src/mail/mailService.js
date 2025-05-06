// src/mail/mailService.js
const nodemailer = require('nodemailer');

// 🔥 same config as auth/src/mail/otpMail.js:
const transporter = nodemailer.createTransport({
  host: 'smtp-relay.brevo.com',
  port: 587,
  secure: false,
  auth: {
    user: '850fee001@smtp-brevo.com',
    pass: 'nUzmwcTGpCSv60O7'
  }
});

/**
 * Send a plain-text email.
 * @param {string} to      recipient address
 * @param {string} subject email subject
 * @param {string} text    plain-text body
 */
async function sendMail(to, subject, text) {
  await transporter.sendMail({
    from: 'MUJ Drive <dubeyshivam1911@gmail.com>',
    to,
    subject,
    text
  });
}

module.exports = { sendMail };
