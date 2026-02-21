const nodemailer = require('nodemailer');
require('dotenv').config();  // Assure-toi d'avoir chargé les variables d'environnement

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: false,  // False car on utilise le port 587 (pas un port TLS)
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

const mailOptions = {
  from: process.env.FROM_EMAIL,
  to: 'destinataire@example.com',  // Remplace par l'email du destinataire
  subject: 'Test de l\'email',
  text: 'Ceci est un test.',
};

transporter.sendMail(mailOptions, (error, info) => {
  if (error) {
    console.log('Erreur lors de l\'envoi de l\'email: ', error);
  } else {
    console.log('Email envoyé: ' + info.response);
  }
});
