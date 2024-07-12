const express = require("express");
const bodyParser = require("body-parser");
const router = express.Router();
router.use(bodyParser.json());
const Realm = require("realm");

const Redis = require("ioredis");
const redis = new Redis();

const {
  add_diskon,
  add_barang_diskon,
  AddItems,
  addJenis,
  addKategori,
  addsatuan,
  delbarang,
  deleteDiskon,
  getallCategory,
  getallJenis,
  getfirstkategori,
  getfirstJenis,
  ShowItemFromCabang,
  ShowDiskonByCabang,
  ShowDiskonByName,
  ShowDiskonBarangByID,
  ShowDiskonByBarang,
  ShowDiskonByID,
  SearchJenisByName,
  SearchItemByID,
  SearchKategoriByName,
  SearchSatuanByIdBarang,
  searchjenisBykategori,
} = require("../view-model-realm/realm_database");
const { BSON } = require("mongodb");

//
router.get("/baranglist/:id_gudang/:id_cabang", async (req, res) => {
  const id_gudang = Realm.BSON.ObjectId(req.params.id_gudang);
  const id_cabang = Realm.BSON.ObjectId(req.params.id_cabang);
  if (res.req.accepts("application/json")) {
    res.setHeader("Content-Type", "application/json");
  }
  try {
    const barang = await ShowItemFromCabang(id_cabang, id_gudang);
    // Try to retrieve data from Redis
    const cachedData = await redis.get("data_barang_" + id_gudang);
    if (!cachedData) {
      // If data is not in Redis, query the database
      if (barang != null) {
        res.status(200).json({
          status: 200,
          data: barang,
          message: "Data retrieved from the database",
        });

        // Store the data in Redis for future use
        redis.set("data_barang_" + id_gudang, JSON.stringify(barang));
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

//
router.post("/addbarang/:id_gudang/:id_cabang", async (req, res) => {
  const id_gudang = Realm.BSON.ObjectId(req.params.id_gudang);
  const id_cabang = Realm.BSON.ObjectId(req.params.id_cabang);
  try {
    if (res.req.accepts("application/json")) {
      res.setHeader("Content-Type", "application/json");
    }
    // const cabang = await Cabang.findById(id_cabang)
    // if (!cabang) {
    //   return res.status(404).json({ message: 'Cabang not found' })
    // }

    // const barang = new Barang(req.body)
    // const gudang = cabang.Gudang.id(id_gudang)
    // if (!gudang) {
    //   return res
    //     .status(404)
    //     .json({ message: 'Gudang not found within the Cabang' })
    // }
    // gudang.Barang.push(barang)
    // await cabang.save()
    const barang = await AddItems(id_cabang, id_gudang, req.body);
    await redis.del("data_barang_" + id_gudang);
    console.log(`Deleted key: data_barang_${id_gudang}`);

    const barang2 = await ShowItemFromCabang(id_cabang, id_gudang);
    res.status(200).json({
      status: 200,
      data: barang,
      message: "Data retrieved from the database",
    });

    // Store the data in Redis for future use
    redis.set("data_barang_" + id_gudang, JSON.stringify(barang2));
    console.log("All Barang in the Gudang:", barang2);
  } catch (err) {
    console.error("Error inserting Barang:", err);
    res.status(500).json({ message: "Internal Server Error" });
  }
});
//
router.delete(
  "/deletebarang/:id_gudang/:id_cabang/:id_barang",
  async (req, res) => {
    const id_cabang = Realm.BSON.ObjectId(req.params.id_cabang);
    const id_gudang = Realm.BSON.ObjectId(req.params.id_gudang);
    const id_barang = Realm.BSON.ObjectId(req.params.id_barang);
    try {
      const deleteBarangData = await delbarang(id_cabang, id_gudang, id_barang);
      // const cabang = await Cabang.findById(id_cabang)
      // if (!cabang) {
      //   return res.status(404).json({ message: 'Cabang not found' })
      // }

      // const gudang = cabang.Gudang.id(id_gudang)
      // if (!gudang) {
      //   return res
      //     .status(404)
      //     .json({ message: 'Gudang not found within the Cabang' })
      // }

      // const barangIndex = gudang.Barang.findIndex(
      //   (barang) => barang._id == id_barang
      // )
      // if (barangIndex === -1) {
      //   return res
      //     .status(404)
      //     .json({ message: 'Barang not found within the Gudang' })
      // }

      // // Remove the Barang subdocument
      // gudang.Barang.pull(gudang.Barang[barangIndex])
      // await cabang.save()

      // Delete the data_barang_ key from Redis
      await redis.del("data_barang_" + id_gudang);
      console.log(`Deleted key: data_barang_${id_gudang}`);
      res.status(200).json({ message: "Barang deleted successfully" });
    } catch (err) {
      console.error("Error deleting Barang:", err);
      res.status(500).json({ message: "Internal Server Error" });
    }
  }
);
//belum
router.put(
  "/updatebarang/:id_gudang/:id_cabang/:barangId",
  async (req, res) => {
    const { id_gudang, id_cabang, barangId } = req.params;
    try {
      const cabang = await Cabang.findById(id_cabang);
      if (!cabang) {
        return res.status(404).json({ message: "Cabang not found" });
      }

      const gudang = cabang.Gudang.id(id_gudang);
      if (!gudang) {
        return res
          .status(404)
          .json({ message: "Gudang tidak ditemukan dalam Cabang" });
      }

      const barang = gudang.Barang.id(barangId);
      if (!barang) {
        return res
          .status(404)
          .json({ message: "Barang tidak ditemukan dalam Gudang" });
      }

      // Update the properties of the Barang subdocument
      Object.assign(barang, req.body); // Assuming req.body contains the updated data

      await cabang.save();

      // Delete the data_barang_ key from Redis
      await redis.del("data_barang_" + id_gudang);
      console.log(`Deleted key: data_barang_${id_gudang}`);

      res.status(200).json({ message: "Barang updated successfully" });
    } catch (err) {
      console.error("Error updating Barang:", err);
      res.status(500).json({ message: "Internal Server Error" });
    }
  }
);

//satuan
//
router.get("/getsatuan/:id_barang/:id_cabang/:id_gudang", async (req, res) => {
  try {
    const id_barang = Realm.BSON.ObjectId(req.params.id_barang);
    const id_cabang = Realm.BSON.ObjectId(req.params.id_cabang);
    const id_gudang = Realm.BSON.ObjectId(req.params.id_gudang);

    const redisKey = `data_satuan_${id_barang}`;

    const cachedData = await redis.get(redisKey);

    if (!cachedData) {
      // const cabang = await Cabang.findById(id_cabang)
      // if (!cabang) {
      //   return res.status(404).json({ message: 'Cabang not Found' })
      // }

      // const gudang = cabang.Gudang[0]
      // if (!gudang) {
      //   return res
      //     .status(404)
      //     .json({ message: 'Gudang not Found in the Cabang' })
      // }

      // // Find the specific barang in the gudang
      // const barang = gudang.Barang.find(
      //   (item) => item._id.toString() === id_barang
      // )
      // if (!barang) {
      //   return res
      //     .status(404)
      //     .json({ message: 'Barang not Found in the Gudang' })
      // }

      // // Access the satuan array within the barang
      // const satuan = barang.Satuan
      // res.status(200).json({
      //   status: 200,
      //   data: satuan,
      //   message: 'Data retrieved from the database'
      // })
      const satuan = await SearchSatuanByIdBarang(
        id_cabang,
        id_gudang,
        id_barang
      );
      if (satuan === 0) {
        console.log("data satuan tidak ditemukan");
      } else {
        redis.set(redisKey, JSON.stringify(satuan));
        console.log("Redis cache is empty");
      }
    } else {
      // If data exists in Redis, send the cached data
      res.status(200).json({
        status: 200,
        data: JSON.parse(cachedData),
        message: "Data retrieved from Redis cache",
      });
      console.log("Redis cache is populated");
    }
  } catch (err) {
    res.status(400).json({
      status: 400,
      message: err.message,
    });
  }
});

//
router.post("/addsatuan/:id_barang/:id_cabang/:id_gudang", async (req, res) => {
  const id_barang = Realm.BSON.ObjectId(req.params.id_barang);
  const id_cabang = Realm.BSON.ObjectId(req.params.id_cabang);
  const id_gudang = Realm.BSON.ObjectId(req.params.id_gudang);
  try {
    const newSatuan = await addsatuan(
      id_cabang,
      id_gudang,
      id_barang,
      req.body
    );
    if (!newSatuan) {
      console.log("satuan gagal ditambahkan");
    } else {
      console.log("satuan berhasil ditambahkan");
    }
    // const cabang = await Cabang.findById(id_cabang)

    // if (!cabang) {
    //   return res.status(404).json({ message: 'Cabang not found' })
    // }

    // // Find the gudang containing the specified barang
    // const gudang = cabang.Gudang[0]

    // if (!gudang) {
    //   return res
    //     .status(404)
    //     .json({ message: 'Gudang not found with the specified Barang' })
    // }

    // // Find the specified barang within the gudang
    // const barang = gudang.Barang.find((b) => b._id.toString() === id_barang)

    // if (!barang) {
    //   return res.status(404).json({ message: 'Barang not found' })
    // }

    // // Push the new Satuan to the satuan array of the specified barang
    // const satuan = req.body
    // barang.Satuan.push(req.body)
    // await cabang.save()
    const redisKey = `data_satuan_` + id_barang;
    redis.del(redisKey, function (err, reply) {
      if (err) {
        console.error(err);
      } else {
        console.log(`Deleted key: ` + redisKey);
      }
    });
    //let satuan2 = await barang.Satuan
    let satuan2 = await SearchSatuanByIdBarang(id_cabang, id_gudang, id_barang);
    res.status(200).json({
      status: 200,
      data: satuan2,
      message: "Data retrieved from the database",
    });

    // Store the data in Redis for future use
    redis.set(redisKey, JSON.stringify(satuan2));
  } catch (err) {
    console.log("error insert satuan:" + err);
  }
});

//kategori dan jenis
router.get("/getkategori", async (req, res) => {
  try {
    const cachedData = await redis.get("data_kategori");
    if (!cachedData) {
      // let kategori = await Kategori.find()
      const kategori = await getallCategory();
      res.status(200).json({
        status: 200,
        data: kategori,
        message: "Data retrieved from the database",
      });
      redis.set("data_kategori", JSON.stringify(kategori));
      console.log("ini kosong redis");
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
    res.status(400).json({
      status: 400,
      message: err.message,
    });
  }
});

router.get("/getfirstkategori", async (req, res) => {
  try {
    let kategori = await getfirstkategori();
    res.status(200).json({
      status: 200,
      data: kategori,
    });
  } catch (err) {
    res.status(400).json({
      status: 400,
      message: err.message,
    });
  }
});
//
router.get("/getjenisfromkategori/:katakategori", async (req, res) => {
  const katakategori = req.params.katakategori;
  try {
    //let kategori = await Kategori.findOne({ nama_kategori: katakategori })
    // if (!kategori) {
    //   return res.status(404).json({
    //     status: 404,
    //     message: 'Kategori not found'
    //   })
    // }
    // //let jenis = await Jenis.findById(kategori.id_jenis)
    // if (!jenis) {
    //   return res.status(404).json({
    //     status: 404,
    //     message: 'Jenis not found'
    //   })
    // }
    let jenis = await searchjenisBykategori(katakategori);
    res.status(200).json({
      status: 200,
      data: jenis,
    });
  } catch (err) {
    res.status(400).json({
      status: 400,
      message: err.message,
    });
  }
});

router.get("/getjenis", async (req, res) => {
  try {
    const cachedData = await redis.get("data_jenis");
    if (!cachedData) {
      // If data is not in Redis, query the database
      let jenis = await getallJenis();

      // Send the data to the client
      res.status(200).json({
        status: 200,
        data: jenis,
        message: "Data retrieved from the database",
      });

      // Store the data in Redis for future use
      redis.set("data_jenis", JSON.stringify(jenis));
    } else {
      // If data exists in Redis, send the cached data
      res.status(200).json({
        status: 200,
        data: JSON.parse(cachedData),
        message: "Data retrieved from Redis cache",
      });
    }
  } catch (err) {
    res.status(400).json({
      status: 400,
      message: err.message,
    });
  }
});
router.get("/getfirstjenis", async (req, res) => {
  try {
    let jenis = await getfirstJenis();
    res.status(200).json({
      status: 200,
      data: jenis,
    });
  } catch (err) {
    res.status(400).json({
      status: 400,
      message: err.message,
    });
  }
});

//
router.post("/tambahkategori", async (req, res) => {
  try {
    let kategori = new Kategori(req.body);
    // let nmkategori = req.body.nama_kategori
    //const existingData = await Kategori.findOne({ nama_kategori: nmkategori })
    const existingData = await SearchKategoriByName(kategori);
    if (existingData) {
      return res.status(409).json({ message: "The data already exists." });
    } else {
      // kategori = await kategori.save()
      const newKategori = await addKategori(kategori);
      res.status(200).json({
        status: 200,
        data: newKategori,
      });
      redis.del("data_kategori", function (err, reply) {
        if (err) {
          console.error(err);
        } else {
          console.log(`Deleted key: data_kategori`);
        }
      });
      // let kategori2 = await Kategori.find()
      let kategori2 = await getallCategory();
      redis.set("data_kategori", JSON.stringify(kategori2));
    }
  } catch (err) {
    console.log("error insert: " + err);
  }
});

//
router.post("/tambahjenis", async (req, res) => {
  try {
    let jenis = new Jenis(req.body);
    // let nmjenis = req.body.nama_jenis
    // const existingData = await Jenis.findOne({ nama_jenis: nmjenis })
    const existingData = await SearchJenisByName(jenis);
    if (!existingData) {
      // jenis = await jenis.save()
      const newJenis = await addJenis(jenis);
      res.status(200).json({
        status: 200,
        data: newJenis,
      });
      redis.del("data_jenis", function (err, reply) {
        if (err) {
          console.error(err);
        } else {
          console.log(`Deleted key: data_jenis`);
        }
      });
      // let jenis2 = await Jenis.find()
      let jenis2 = await getallJenis();
      redis.set("data_jenis", JSON.stringify(jenis2));
    } else {
      return res.status(409).json({ message: "The data already exists." });
    }
  } catch (err) {
    console.log("error insert:" + err);
  }
});

//diskon
router.post("/tambahdiskon/:id_cabang", async (req, res) => {
  if (res.req.accepts("application/json")) {
    res.setHeader("Content-Type", "application/json");
  }
  const id_cabang = req.params.id_cabang;
  try {
    let diskon = await add_diskon(req.body);
    redis.del("data_diskon_" + id_cabang, function (err, reply) {
      if (err) {
        console.error(err);
      } else {
        console.log(`Deleted key: data_diskon_` + id_cabang);
      }
    });
    //let diskon2 = await Diskon.find()
    let diskon2 = await ShowDiskonByCabang(id_cabang);

    // Send the data to the client
    res.status(200).json({
      status: 200,
      data: diskon2,
      message: "Data retrieved from the database",
    });

    // Store the data in Redis for future use
    redis.set("data_diskon_" + id_cabang, JSON.stringify(diskon2));
  } catch (err) {
    console.log("error insert diskon:" + err);
  }
});

//show dari cabang tertentu
router.get("/diskonlist/:id_cabang", async (req, res) => {
  if (res.req.accepts("application/json")) {
    res.setHeader("Content-Type", "application/json");
  }
  try {
    const id_cabang = req.params.id_cabang;
    // Try to retrieve data from Redis
    const cachedData = await redis.get("data_diskon_" + id_cabang);
    if (!cachedData) {
      // If data is not in Redis, query the database
      const diskon = await ShowDiskonByCabang(id_cabang);
      redis.set("data_diskon_" + id_cabang, JSON.stringify(diskon));
      console.log("ini kosong redis");
      res.status(200).json({
        status: 200,
        data: diskon,
        message: "Data retrieved from Redis cache",
      });
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
    console.log("fetch diskon error:" + err);
    res.status(400).json({
      status: 400,
      message: err.message,
    });
  }
});

//diskonlist dengan nama diskon
router.get("/diskonlist/:id_cabang/:nama_diskon", async (req, res) => {
  if (res.req.accepts("application/json")) {
    res.setHeader("Content-Type", "application/json");
  }
  try {
    const nama_diskon = req.params.nama_diskon;
    let diskon = await ShowDiskonByName(nama_diskon);
    // Send the data to the client
    res.status(200).json({
      status: 200,
      data: diskon,
      message: "Data retrieved from the database",
    });
  } catch (err) {
    res.status(400).json({
      status: 400,
      message: err.message,
    });
  }
});

//menampilkan diskon yang memiliki barang tertentu
router.get(
  "/diskonlistBarangFilter/:id_reference/:id_cabang",
  async (req, res) => {
    if (res.req.accepts("application/json")) {
      res.setHeader("Content-Type", "application/json");
    }
    try {
      const id_referenced = req.params.id_reference;
      const id_cabangs = req.params.id_cabang;
      let diskon = await ShowDiskonByBarang(id_referenced, id_cabangs);
      // Send the data to the client
      res.status(200).json({
        status: 200,
        data: diskon,
        message: "Data retrieved from the database",
      });
    } catch (err) {
      res.status(400).json({
        status: 400,
        message: err.message,
      });
    }
  }
);

//
//search barang yang di playlist diskon berdasarkan diskon id
router.get("/listdiskonbarang/:id_diskon", async (req, res) => {
  if (res.req.accepts("application/json")) {
    res.setHeader("Content-Type", "application/json");
  }
  try {
    const id_diskon = Realm.BSON.ObjectId(req.params.id_diskon);

    let diskon = await ShowDiskonBarangByID(id_diskon);
    // Send the data to the client
    res.status(200).json({
      status: 200,
      data: diskon,
      message: "Data retrieved from the database",
    });
  } catch (err) {
    res.status(400).json({
      status: 400,
      message: err.message,
    });
  }
});

//
router.post(
  "/tambahdiskonbarang/:id_diskon/:id_barang/:id_cabang/:id_gudang",
  async (req, res) => {
    const id_diskon = Realm.BSON.ObjectId(req.params.id_diskon);
    const id_barang = Realm.BSON.ObjectId(req.params.id_barang);
    const id_cabang = Realm.BSON.ObjectId(req.params.id_cabang);
    const id_gudang = Realm.BSON.ObjectId(req.params.id_gudang);
    if (res.req.accepts("application/json")) {
      res.setHeader("Content-Type", "application/json");
    }
    try {
      const existingData = await SearchItemByID(
        id_cabang,
        id_gudang,
        id_barang
      );
      if (existingData) {
        const newbarang_diskon = await add_barang_diskon(id_diskon, req.body);

        // diskon.Barang.push(barang)
        // await diskon.save()

        redis.del("data_diskon_" + id_cabang, function (err, reply) {
          if (err) {
            console.error(err);
          } else {
            console.log(`Deleted key: data_diskon_` + id_cabang);
          }
        });
        let diskonbarang2 = await ShowDiskonByCabang(String(id_cabang));

        // Send the data to the client
        res.status(200).json({
          status: 200,
          data: diskonbarang2,
          message: "Data retrieved from the database",
        });
        // Store the data in Redis for future use
        redis.set("data_diskon_" + id_cabang, JSON.stringify(diskonbarang2));
        console.log("insert barang diskon suskses!!");
      } else {
        throw console.log("barang tidak ditemukan di gudang!");
      }
    } catch (err) {
      console.log("error insert diskon barang :" + err);
    }
  }
);

//
router.delete("/deletediskon/:_id/:id_cabang", async (req, res) => {
  const id_diskon = Realm.BSON.ObjectId(req.params._id);
  const id_cabang = req.params.id_cabang;
  try {
    const diskon = await deleteDiskon(id_diskon);
    redis.del("data_diskon_" + id_cabang, function (err, reply) {
      if (err) {
        console.error(err);
      } else {
        console.log(`Deleted key: data_diskon_` + id_cabang);
      }
    });
  } catch (err) {
    res.status(500).json({
      status: 500,
      message: err.message,
    });
  }
});

module.exports = router;
