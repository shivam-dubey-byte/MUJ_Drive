const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: 'smtp-relay.brevo.com',
  port: 587,
  secure: false,
  auth: {
    user: '850fee001@smtp-brevo.com',
    pass: 'nUzmwcTGpCSv60O7'
  }
});

async function sendOtpEmail(email, otp) {
  console.log(email);
  await transporter.sendMail({
    from: 'MUJ Drive <dubeyshivam1911@gmail.com>',
    to: email,
    subject: 'Your Verification OTP',
    text: `Your OTP code is ${otp}. It will expire in 10 minutes.`
  });
}

module.exports = { sendOtpEmail };
