const express = require('express');
const bodyParser = require('body-parser');
const Realm = require('realm');
const router = express.Router();
router.use(bodyParser.json());

// Initialize MongoDB Realm
const appConfig = {
    id: 'posta-jctyi',
};
const client = new Realm.App(appConfig);



router.post('/reset-password-email-subject', async (req, res) => {
    const { subject } = req.body;

    try {
        // Access the email/password authentication provider
        const emailPasswordAuth = client.auth.emailPassword;
        
        // Set the subject of the reset password email
        await emailPasswordAuth.setResetPasswordEmailSubject(subject);

        // If successful, return success message
        return res.status(200).json({ message: 'Reset password email subject updated successfully' });
    } catch (error) {
        console.error('Error setting reset password email subject:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
});

router.post('/reset-password/:email/:newPassword', async (req, res) => {
    const { email, newPassword } = (req.params);
    try {
        // Reset the user's password
        await client.emailPasswordAuth.sendResetPasswordEmail(email);

        // Update the user's password with the new one
        await client.emailPasswordAuth.resetPassword(email, newPassword);

        // If password reset is successful, return success message
        return res.status(200).json({ message: 'Password reset successfully' });
    } catch (error) {
        console.error('Error resetting password:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;