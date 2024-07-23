const express = require("express");
const bodyParser = require("body-parser");
const router = express.Router();
const Redis = require("ioredis");
const redis = new Redis();
const Realm = require("realm");

const {
  addTrans,
  ShowAllTransfromCabang,
} = require("../view-model-realm/realm_database");
const { BSON } = require("mongodb");

//
router.get("/translist/:id_cabang", async (req, res) => {
  const id_cabang = req.params.id_cabang;
  if (res.req.accepts("application/json")) {
    res.setHeader("Content-Type", "application/json");
  }
  try {
    // Try to retrieve data from Redis
    const cachedData = await redis.get("data_trans_" + id_cabang);
    if (!cachedData) {
      // If data is not in Redis, query the database
      const Trans = await ShowAllTransfromCabang(id_cabang);
      if (Trans != null) {
        res.status(200).json({
          status: 200,
          data: Trans,
          message: "Data retrieved from the database",
        });

        // Store the data in Redis for future use
        redis.set("data_trans_" + id_cabang, JSON.stringify(Trans));
        console.log("ini kosong redis");
      } else {
        res.status(400).json({
          status: "Data Kosong",
        });
      }
    } else {
      // If data exists in Redis, send the cached data
      res.status(200).json({
        status: 200,
        data: JSON.parse(cachedData),
        message: "Data retrieved from Redis cache",
      });
      console.log("ini berisi redis");
    }
  } catch (err) {
    console.log("kesalahan ambil barang:" + err);
    res.status(400).json({
      status: 400,
      message: err.message,
    });
  }
});

router.post("/addtrans/:id_cabang", async (req, res) => {
  const id_cabang = req.params.id_cabang;
  console.log(req.body);
  try {
    if (res.req.accepts("application/json")) {
      res.setHeader("Content-Type", "application/json");
    }
    const trans = await addTrans(id_cabang, req.body).then((alldata) => {
      console.log("data transaksi:" + alldata);
    });
    await redis.del("data_trans_" + id_cabang);
    console.log(`Deleted key: data_trans_${id_cabang}`);

    const trans2 = await ShowAllTransfromCabang(id_cabang);
    res.status(200).json({
      status: 200,
      data: trans,
      message: "Data retrieved from the database",
    });

    // Store the data in Redis for future use
    redis.set("data_trans_" + id_cabang, JSON.stringify(trans2));
    console.log("All Transaction in the Gudang:", trans2);
  } catch (err) {
    console.error("Error inserting Transaction:", err);
    res.status(500).json({ message: "Internal Server Error" });
  }
});

module.exports = router;
