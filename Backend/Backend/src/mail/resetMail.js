const nodemailer = require('nodemailer');

const sendResetEmail = async (email, resetUrl) => {
  const transporter = nodemailer.createTransport({
    host: 'smtp-relay.brevo.com',
    port: 587,
    secure: false,
    auth: {
      user: '850fee001@smtp-brevo.com',
      pass: 'nUzmwcTGpCSv60O7'
    }
  });

  await transporter.sendMail({
    from: 'KnowledgeSun <dubeyshivam1911@gmail.com>',
    to: email,
    subject: 'Password Reset',
    text: `You requested a password reset. Click the link below:\n\n${resetUrl}\n\nIf you didn’t request this, please ignore.`
  });
};

module.exports = { sendResetEmail };
