const express = require("express");
const router = express.Router();
const fs = require("fs");
const pdf = require("pdf-creator-node");
const path = require("path");
const option = require("./helpers/options");

// Generate PDF function
const generatePdf = async (req, res, next) => {
  try {
    console.log("ini jalan");
    const data = req.body;
    const html = fs.readFileSync(
      path.join(path.resolve("./lib/View/invoice/invoice.html")),
      "utf-8"
    );
    const filename = "Cust_" + Math.random() + ".pdf";
    let array = [];
    data.items.forEach((d) => {
      const prod = {
        id_reference: d.id_reference,
        nama_barang: d.nama_barang,
        id_satuan: d.id_satuan,
        satuan_price: d.satuan_price,
        trans_qty: d.trans_qty,
        persentase_diskon: d.persentase_diskon,
        total_price: d.total_price,
      };
      array.push(prod);
    });

    let subtotal = 0;
    array.forEach((i) => {
      subtotal += i.total_price;
    });
    const tax = (subtotal * 11) / 100;
    const grandtotal = subtotal + tax;
    const obj = {
      prodlist: array,
      subtotal,
      tax,
      gtotal: grandtotal,
      nama_cabang: data.nama_cabang,
      alamat: data.alamat,
      no_telp: data.no_telp,
      currentDate: data.date_trans, // Example date
      invoiceCode: "INV" + Math.random(), // Example invoice code
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

    const filepath = "http://10.0.2.2:3001/docs/" + filename;
    res.status(200).json({ downloadUrl: filepath });
  } catch (error) {
    console.log("Error generating PDF: " + error);
    res.status(500).json({ message: "Error generating PDF" });
  }
};

router.post("/generate-invoice", generatePdf);

module.exports = router;
