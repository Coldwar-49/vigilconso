require('dotenv').config();
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT),
  secure: false, // Ne pas activer SSL pour le port 587
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

async function sendRappelEmail(toEmail, rappelList) {
  const rappelContent = rappelList.map((rappel, index) => 
    `<li><strong>${rappel.nom}</strong> (${rappel.date})<br>${rappel.description}</li>`
  ).join('');

  const mailOptions = {
    from: process.env.FROM_EMAIL,
    to: toEmail,
    subject: 'Derniers rappels produits - VigilConso',
    html: `<p>Bonjour,</p>
           <p>Voici les derniers rappels produits :</p>
           <ul>${rappelContent}</ul>
           <p>Restez vigilant !<br>L'équipe VigilConso</p>`
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log('Email envoyé avec succès à', toEmail);
    return true;
  } catch (err) {
    console.error('Erreur lors de l\'envoi de l\'email:', err);
    return false;
  }
}

// Exemple d’utilisation :
/*
sendRappelEmail('utilisateur@email.com', [
  { nom: 'Yaourt fraise', date: '2025-05-01', description: 'Présence de verre.' },
  { nom: 'Bouteille d\'eau XYZ', date: '2025-04-30', description: 'Risque bactérien.' },
]);
*/

module.exports = sendRappelEmail;
