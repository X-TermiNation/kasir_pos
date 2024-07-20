const axios = require("axios");
const qr = require("qr-image");

// Set up your Xendit secret key
const secretKey =
  "xnd_development_JSlkCGdSmkrw5ONcdvW6xsCdDEX33sV8aWVmcWOpKCNFbUwGyZXhnCBDwWaEq";

async function createInvoice(external_id, amount, payer_email, description) {
  const invoiceData = {
    external_id,
    amount,
    payer_email,
    description,
  };
  try {
    const invoice = await axios.post(
      "https://api.xendit.co/v2/invoices",
      JSON.stringify(invoiceData),
      {
        auth: {
          username: secretKey,
          password: "",
        },
        headers: {
          "Content-Type": "application/json",
          Authorization: `Basic ${secretKey}`,
        },
      }
    );
    console.log("Invoice created successfully:", invoice);
    return invoice.data;
  } catch (error) {
    throw new Error(error.message);
  }
}

const handleCallback = (callbackData) => {
  console.log("Callback received:", callbackData);
  // Process the callback data here
};

module.exports = {
  createInvoice,
  handleCallback,
};
