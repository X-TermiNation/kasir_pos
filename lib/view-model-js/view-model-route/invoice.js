const express = require("express");
const router = express.Router();
const fs = require("fs");
const pdf = require("pdf-creator-node");
const path = require("path");
const option = require("./helpers/options");
const { SearchSatuanByID } = require("../view-model-realm/realm_database");

function formatNumber(number) {
  return number.toLocaleString("id-ID"); // Indonesian number format
}
// Generate PDF function
const generatePdf = async (req, res, next) => {
  try {
    console.log("ini jalan");
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

    const filepath = "http://10.0.2.2:3001/docs/" + filename;
    res.status(200).json({ downloadUrl: filepath });
  } catch (error) {
    console.log("Error generating PDF: " + error);
    res.status(500).json({ message: "Error generating PDF" });
  }
};

router.post("/generate-invoice", generatePdf);

module.exports = router;
