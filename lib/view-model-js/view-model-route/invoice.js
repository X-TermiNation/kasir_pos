const express = require("express");
const router = express.Router();
const fs = require("fs");
const pdf = require("pdf-creator-node");
const path = require("path");
const option = require("./helpers/options");

// Generate PDF function
const generatePdf = async (req, res, next) => {
  try {
    const data = req.body;
    const html = fs.readFileSync(
      path.join(__dirname, "../lib/View/invoice/invoice.html"),
      "utf-8"
    );
    const filename = "Cust_" + Math.random() + ".pdf";
    let array = [];
    data.items.forEach((d) => {
      const prod = {
        name: d.name,
        description: d.description,
        unit: d.unit,
        quantity: d.quantity,
        price: d.price,
        total: d.quantity * d.price,
      };
      array.push(prod);
    });

    let subtotal = 0;
    array.forEach((i) => {
      subtotal += i.total;
    });
    const tax = (subtotal * 11) / 100;
    const grandtotal = subtotal + tax;
    const obj = {
      prodlist: array,
      subtotal,
      tax,
      gtotal: grandtotal,
    };
    const document = {
      html: html,
      data: {
        products: obj,
      },
      path: "./docs/" + filename,
    };

    await pdf.create(document, option);

    const filepath = "http://10.0.2.2:3000/docs/" + filename;
    res.status(200).json({ downloadUrl: filepath });
  } catch (error) {
    console.log("Error generating PDF: " + error);
    res.status(500).json({ message: "Error generating PDF" });
  }
};

// Define a route to generate the PDF
router.post("/generate-invoice", generatePdf);

module.exports = router;
