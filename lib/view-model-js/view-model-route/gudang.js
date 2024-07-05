const express = require("express");
const bodyParser = require("body-parser");
const router = express.Router();
const Redis = require("ioredis");
const redis = new Redis();
const Realm = require("realm");
const {
  insertGudang,
  searchCabangByName,
  searchCabangByID,
  searchGudangById,
} = require("../view-model-realm/realm_database");
router.use(bodyParser.json());

//
router.post("/tambahgudang/:idcabang", async (req, res) => {
  try {
    const idcabang = Realm.BSON.ObjectId(req.params.idcabang);
    const cabang = await searchCabangByID(idcabang);
    //const cabang = await Cabang.findOne({ _id: idcabang })
    const gudang = req.body;
    if (cabang.Gudang.length > 0) {
      return res.status(409).json({ message: "The data already exists." });
    } else {
      console.log("Cabang ID realm:", idcabang);
      await insertGudang(idcabang, gudang);
      // cabang.Gudang.push(gudang)
      // await cabang.save()
      res.status(200).json({
        status: 200,
        data: gudang,
      });
      redis.del("data_gudang", function (err, reply) {
        if (err) {
          console.error(err);
        } else {
          console.log(`Deleted key: data_gudang`);
        }
      });
      // let gudang2 = await cabang.Gudang.find()
      let gudang2 = await searchGudangById(idcabang);
      redis.set("data_gudang", JSON.stringify(gudang2));
    }
  } catch (err) {
    console.log("error occurred! :" + err);
  }
});

//
router.get("/:id_cabang", async (req, res, next) => {
  try {
    const id_cabang = Realm.BSON.ObjectId(req.params.id_cabang);
    const cabang = await searchCabangByID(id_cabang);
    if (cabang) {
      // Only set the Content-Type header if we are sending a JSON response
      res.setHeader("Content-Type", "application/json");
      let gudang = await cabang.Gudang;
      res.status(200).json({
        status: 200,
        data: gudang,
      });
    } else {
      res.status(400).json({
        status: 400,
        message: "Gudang tidak Ditemukan!",
      });
    }
  } catch (err) {
    res.status(400).json({
      status: 400,
      message: err.message,
    });
  }
  next();
});

module.exports = router;
