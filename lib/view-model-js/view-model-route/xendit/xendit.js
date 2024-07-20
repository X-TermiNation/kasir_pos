const express = require("express");
const axios = require("axios");
const qr = require("qr-image");
const bodyParser = require("body-parser");
const { v4: uuidv4 } = require("uuid");
const { createInvoice, handleCallback } = require("./xendit_config");
const router = express.Router();
router.use(bodyParser.json());

// Endpoint to create an invoice
router.post("/create-invoice", async (req, res) => {
  const { external_id, amount, payer_email, description } = req.body;
  try {
    const invoice = await createInvoice(
      external_id,
      amount,
      payer_email,
      description
    );
    res.json(invoice);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Endpoint to create QRIS
router.post("/create-qris", async (req, res) => {
  const secretKey =
    "xnd_development_JSlkCGdSmkrw5ONcdvW6xsCdDEX33sV8aWVmcWOpKCNFbUwGyZXhnCBDwWaEq";
  const { amount, callback_url } = req.body;
  const external_id = uuidv4();
  const qrData = {
    external_id: external_id,
    type: "DYNAMIC",
    amount: amount,
  };

  if (callback_url) {
    qrData.callback_url = callback_url;
  }
  try {
    // Buat QR Code dengan Xendit
    const response = await axios.post(
      "https://api.xendit.co/qr_codes",
      qrData,
      {
        auth: {
          username: secretKey,
          password: "",
        },
        headers: {
          "Content-Type": "application/json",
        },
      }
    );
    console.log(response.data);
    const qrCodeUrl = response.data.qr_string;
    res.status(200).json({ qrCodeUrl });
    // const qrImage = qr.image(qrCodeUrl, { type: "png" });
    // res.setHeader("Content-type", "image/png");
    // qrImage.pipe(res);
  } catch (error) {
    if (error.response) {
      console.error("Error response data:", error.response.data);
      console.error("Error response status:", error.response.status);
      console.error("Error response headers:", error.response.headers);
      res.status(500).json({
        message: "Xendit API error",
        error: error.response.data,
      });
    } else if (error.request) {
      console.error("Error request data:", error.request);
      res.status(500).json({
        message: "No response received from Xendit API",
        error: error.message,
      });
    } else {
      console.error("Error message:", error.message);
      res.status(500).json({
        message: "Error in setting up the request to Xendit API",
        error: error.message,
      });
    }
  }
});

// Endpoint to handle callbacks from Xendit
router.post("/callback", (req, res) => {
  const callbackData = req.body;
  handleCallback(callbackData);
  res.sendStatus(200);
});

module.exports = router;
