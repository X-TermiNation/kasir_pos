const express = require("express");
const router = express.Router();
const fs = require("fs");
const pdf = require("pdf-creator-node");
const path = require("path");
const option = require("./helpers/options");
const { SearchSatuanByID } = require("../view-model-realm/realm_database");
const nodeMailer = require("nodemailer");

function formatNumber(number) {
  return number.toLocaleString("id-ID"); // Indonesian number format
}
// Generate PDF function
const generatePdf = async (req, res, next) => {
  try {
    const data = req.body;
    const html = fs.readFileSync(
      path.join(path.resolve("./lib/View/invoice/invoice.html")),
      "utf-8"
    );
    const filename =
      "Cust_" + Math.random().toString(36).substring(2, 15) + ".pdf";
    let array = [];
    for (const d of data.items) {
      try {
        const satuan_data = await SearchSatuanByID(d.id_satuan);
        const prod = {
          id_reference: d.id_reference,
          nama_barang: d.nama_barang,
          nama_satuan: satuan_data.nama_satuan,
          satuan_price: formatNumber(d.satuan_price),
          trans_qty: d.trans_qty,
          persentase_diskon: d.persentase_diskon,
          total_price: formatNumber(d.total_price),
        };
        array.push(prod);
      } catch (error) {
        console.error("Error fetching Satuan data:", error);
        // Handle individual item errors if needed
      }
    }

    let subtotal = array.reduce(
      (sum, item) => sum + parseFloat(item.total_price.replace(/[^0-9]/g, "")),
      0
    );
    subtotal = formatNumber(subtotal);
    const tax = formatNumber(
      (parseFloat(subtotal.replace(/[^0-9]/g, "")) * 11) / 100
    );
    const grandtotal = formatNumber(
      parseFloat(subtotal.replace(/[^0-9]/g, "")) +
        parseFloat(tax.replace(/[^0-9]/g, ""))
    );
    const obj = {
      prodlist: array,
      subtotal,
      tax,
      gtotal: grandtotal,
      nama_cabang: data.nama_cabang,
      alamat: data.alamat,
      no_telp: data.no_telp,
      currentDate: data.date_trans, // Example date
      invoiceCode: "INV" + Math.random().toString(36).substring(2, 15), // Example invoice code
      paymentMethod: data.payment_method,
      delivery: data.delivery,
    };
    const document = {
      html: html,
      data: {
        products: obj,
      },
      path: path.resolve("./lib/View/doc_invoice/" + filename),
    };

    await pdf
      .create(document, option)
      .then((res) => {
        console.log(res);
      })
      .catch((err) => {
        console.log(err);
      });
    res.status(200).json({ downloadUrl: document["path"] });
  } catch (error) {
    console.log("Error generating PDF: " + error);
    res.status(500).json({ message: "Error generating PDF" });
  }
};

const html = `
        <h1>Customer Invoice</h1>
        <p>Please Check Your Groceries. if there is a problem, please contact our contact number in the invoice. Thank You!</p>
    `;

const SendEmail = async (req, res) => {
  const { Invoicepath, receiveremail } = req.body;
  const transporter = nodeMailer.createTransport({
    host: "sandbox.smtp.mailtrap.io",
    port: 465,
    secure: false,
    auth: {
      user: "4a4bc16cf04ee8",
      pass: "ac95929e920773", // Use environment variables for security in production
    },
    tls: {
      rejectUnauthorized: false,
      minVersion: "TLSv1.2", // Ensure minimum TLS version is specified
    },
  });

  try {
    const pathtemp = path.basename(Invoicepath);
    var lastSlashIndex = pathtemp.lastIndexOf("\\");
    const fileName = pathtemp.substring(lastSlashIndex + 1);
    const info = await transporter.sendMail({
      from: "iamhandsome@examples.com",
      to: receiveremail,
      subject: "Your Shopping Invoice",
      html: html,
      attachments: [
        {
          filename: fileName,
          path: path.resolve(Invoicepath),
          cid: "Invoice",
          contentType: "application/pdf",
        },
      ],
    });

    console.log("Message sent:" + info.messageId);
    console.log(info.accepted);
    console.log(info.rejected);
    res.status(200).json({ message: "Email sent successfully" });
  } catch (error) {
    console.error("Error sending email:", error);
    res.status(500).json({ message: "Error sending email" });
  }
};

router.post("/generate-invoice", generatePdf);

router.post("/invoice-email", SendEmail);

module.exports = router;
