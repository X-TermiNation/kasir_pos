const express = require("express");
const bodyParser = require("body-parser");
const router = express.Router();
const Redis = require("ioredis");
const redis = new Redis();
const Realm = require("realm");

const {
  addTrans,
  ShowAllTransfromCabang,
  addDelivery,
  showDelivery,
  ShowAllDeliveryfromCabang,
  showTransById,
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

router.get("/translist/:id_cabang/:trans_id", async (req, res) => {
  const id_cabang = req.params.id_cabang;
  const trans_id = req.params.trans_id;

  if (res.req.accepts("application/json")) {
    res.setHeader("Content-Type", "application/json");
  }

  try {
    const Trans = await showTransById(id_cabang, trans_id);

    if (Trans != null) {
      res.status(200).json({
        status: 200,
        data: Trans,
        message: "Data retrieved from the database",
      });
    } else {
      res.status(404).json({
        status: 404,
        message: "Data not found",
      });
    }
  } catch (err) {
    console.error("Error retrieving transaction:", err);
    res.status(500).json({
      status: 500,
      message: "Internal Server Error",
    });
  }
});

router.post("/addtrans/:id_cabang", async (req, res) => {
  const id_cabang = req.params.id_cabang;
  try {
    if (res.req.accepts("application/json")) {
      res.setHeader("Content-Type", "application/json");
    }
    const trans = await addTrans(id_cabang, req.body);
    await redis.del("data_trans_" + id_cabang);
    console.log(`Deleted key: data_trans_${id_cabang}`);
    const trans2 = await ShowAllTransfromCabang(id_cabang);
    res.status(200).json({
      status: 200,
      data: trans,
      message: "Data Transaction Inserted",
    });

    // Store the data in Redis for future use
    redis.set("data_trans_" + id_cabang, JSON.stringify(trans2));
  } catch (err) {
    console.error("Error inserting Transaction:", err);
    res.status(500).json({ message: "Internal Server Error" });
  }
});

router.post("/addDelivery/:id_cabang", async (req, res) => {
  const id_cabang = req.params.id_cabang;
  const { alamat_tujuan, transaksi_id } = req.body;
  try {
    if (res.req.accepts("application/json")) {
      res.setHeader("Content-Type", "application/json");
    }
    const delivery = await addDelivery(id_cabang, alamat_tujuan, transaksi_id);
    await redis.del("data_delivery_" + id_cabang);
    console.log(`Deleted key: data_delivery_${id_cabang}`);
    const DeliveryAll = await ShowAllDeliveryfromCabang(id_cabang);
    res.status(200).json({
      status: 200,
      data: delivery,
      message: "Data Transaction Inserted",
    });

    // Store the data in Redis for future use
    redis.set("data_trans_" + id_cabang, JSON.stringify(DeliveryAll));
  } catch (err) {
    console.error("Error inserting Transaction:", err);
    res.status(500).json({ message: "Internal Server Error" });
  }
});

router.get("/showDelivery/:id_cabang", async (req, res) => {
  const id_cabang = req.params.id_cabang;
  try {
    if (res.req.accepts("application/json")) {
      res.setHeader("Content-Type", "application/json");
    }

    // Fetch the delivery data where status is "In Progress"
    const inProgressDeliveries = await showDelivery(id_cabang);

    // Check if there are any deliveries in progress
    if (inProgressDeliveries.length > 0) {
      res.status(200).json({
        status: 200,
        data: inProgressDeliveries,
        message: "Deliveries In Progress Retrieved",
      });
    } else {
      res.status(404).json({
        status: 404,
        message: "No Deliveries In Progress found for the given branch",
      });
    }
  } catch (err) {
    console.error("Error fetching Delivery:", err);
    res.status(500).json({ message: "Internal Server Error" });
  }
});

module.exports = router;
