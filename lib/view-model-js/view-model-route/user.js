const express = require("express");

const bodyParser = require("body-parser");
const router = express.Router();
const jwt = require("jsonwebtoken");
router.use(bodyParser.json());
const secretKey = "PosTa";
const Redis = require("ioredis");
const redis = new Redis();
const Realm = require("realm");

const {
  insertUser,
  deleteUser,
  updateUser,
  searchCabangByID,
  showAllUserfromCabang,
  searchUsersByEmail,
  showAllCabang,
} = require("../view-model-realm/realm_database");

const checkResponseSentMiddleware = (req, res, next) => {
  if (res.headersSent) {
    // The response has been sent, so do nothing
    return;
  }

  // The response has not been sent, so call the next middleware function
  next();
};
router.use(checkResponseSentMiddleware);

var signcode = 0;

//buat add admin
const { insertOwner } = require("../view-model-realm/realm_database");
router.post("/addOwner", async (req, res) => {
  try {
    let owner = req.body;
    await insertOwner(owner);
    res.status(200).json({
      status: 200,
      data: owner,
    });
    redis.del("owner", function (err, reply) {
      if (err) {
        console.error(err);
      } else {
        console.log(`Deleted key: owner`);
      }
    });

    redis.set("owner", JSON.stringify(owner));
  } catch (err) {
    console.log("error insert data:" + err);
  }
});

//
router.post("/login", async (req, res) => {
  try {
    const email = req.body.email;
    const password = req.body.password;
    let userCabangId = null;
    let Userrole = null;
    let userfound = false;
    const cabangs = await showAllCabang();
    console.log(cabangs);
    for (const cabang of cabangs) {
      const user = await searchUsersByEmail(cabang._id, email);
      if (user && user.length > 0) {
        userfound = true;
        if (user[0].password === password) {
          userCabangId = cabang._id;
          Userrole = user[0].role;
          break;
        } else {
          return res.status(401).json({ message: "Invalid password" });
        }
      } else {
        return res.status(404).json({ message: "User not found" });
      }
    }

    if (!userfound) {
      return res.status(404).json({ message: "User not found" });
    }

    var signcode = 0;
    if (Userrole == "Kasir") {
      signcode = 1;
    }
    const token = jwt.sign({ userCabangId }, secretKey, { expiresIn: "24h" });
    res.status(200).send({
      token,
      signcode,
      userCabangId,
    });
  } catch (error) {
    console.log("login error occured:" + error);
  }
});

router.post("/verify", (req, res) => {
  const token = req.headers.token;
  jwt.verify(token, secretKey, (err, decoded) => {
    if (err) {
      return res.status(401).send({ error: "Unauthorized" });
    }
    res.send({ message: "Selamat Datang!" });
  });
});

const { SearchOwner } = require("../view-model-realm/realm_database");
router.get("/owner", async (req, res, next) => {
  try {
    let owner = await SearchOwner();
    if (owner) {
      res.setHeader("Content-Type", "application/json");
      res.status(200).json({
        status: 200,
        data: owner,
      });
    } else {
      res.status(400).json({
        status: 400,
        message: "No User found",
      });
    }
  } catch (err) {
    console.log("Error occurred:", err);
    next(err);
  }
});

//
router.get("/list/:id_cabang", async (req, res) => {
  const id_cabang = Realm.BSON.ObjectId(req.params.id_cabang);
  if (res.req.accepts("application/json")) {
    res.setHeader("Content-Type", "application/json");
  }

  try {
    const cachedData = await redis.get("data_user_" + id_cabang);
    if (!cachedData) {
      let cabang = await searchCabangByID(id_cabang);
      const users = cabang.Users;
      res.status(200).json({
        status: 200,
        data: users,
      });
      // Store the data in Redis for future use
      redis.set("data_user_" + id_cabang, JSON.stringify(users));
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

//
router.put("/updateuser/:userId/:cabangId", async (req, res) => {
  const id_cabang = Realm.BSON.ObjectId(req.params.cabangId);
  const id_user = Realm.BSON.ObjectId(req.params.userId);
  try {
    if (res.req.accepts("application/json")) {
      res.setHeader("Content-Type", "application/json");
    }
    let cabang = await searchCabangByID(Realm.BSON.ObjectId(id_cabang));
    if (!cabang) {
      res.status(404).send("Cabang Tidak Ditemukan!");
      throw console.log("Cabang Tidak Ditemukan");
    }
    // Object.assign(user, req.body)
    // await cabang.save()
    let updatedata = req.body;
    let updateduser = await updateUser(id_cabang, id_user, updatedata);
    if (updateduser) {
      res.status(200).json({
        status: 200,
        data: updateduser,
      });
      redis.del("data_user_" + req.params.cabangId, function (err) {
        if (err) {
          console.error(err);
        } else {
          console.log(`Deleted key: data_user_` + req.params.cabangId);
        }
      });
    } else {
      console.log("no user found");
    }
  } catch (err) {
    console.log("something went wrong:" + err);
  }
});

//
router.delete("/deleteuser/:id/:id_cabang", async (req, res) => {
  try {
    const id_cabang = Realm.BSON.ObjectId(req.params.id_cabang);
    const id = Realm.BSON.ObjectId(req.params.id);
    let cabang = await searchCabangByID(id_cabang);
    if (!cabang) {
      return res.status(401).send("Cabang Tidak Ditemukan!");
    }
    const deleteuser = await deleteUser(id_cabang, id);
    // cabang.Users.pull(id)
    // await cabang.save()
    redis.del("data_user_" + id_cabang, function (err, reply) {
      if (err) {
        console.error(err);
      } else {
        console.log(`Deleted key: data_user_` + id_cabang);
      }
    });
    if (deleteuser.match("success")) {
      res.status(200).json({
        status: 200,
        message: "User deleted successfully",
      });
    } else {
      res.status(404).json({
        status: 404,
        message: "No User found",
      });
    }
  } catch (err) {
    throw console.log("error hapus data user:" + err);
  }
});

//add user
router.post("/addUser/:id_cabang", async (req, res) => {
  try {
    const id_cabang = Realm.BSON.ObjectId(req.params.id_cabang);
    if (res.req.accepts("application/json")) {
      res.setHeader("Content-Type", "application/json");
    }
    const cabang = await searchCabangByID(id_cabang);
    if (cabang.length === 0) {
      return res.status(404).json({ message: "Cabang tidak ditemukan" });
    }
    let user = req.body;
    redis.del("data_user_" + id_cabang, function (err, reply) {
      if (err) {
        console.error(err);
      } else {
        console.log(`Deleted key: data_user_` + id_cabang);
      }
    });
    const existingUser = await searchUsersByEmail(id_cabang, user.email);
    const ArrayExistingUser = Array.from(existingUser);
    if (ArrayExistingUser.length > 0) {
      return res.status(400).json({ message: "Email sudah ada!" });
    } else {
      await insertUser(id_cabang, user);
      // cabang.Users.push(user)
      // await cabang.save()
      res.status(200).json({
        status: 200,
        data: user,
      });
      let user2 = await showAllUserfromCabang(id_cabang);
      redis.set("data_user_" + id_cabang, JSON.stringify(user2));
    }
  } catch (err) {
    console.log("error insert data:" + err);
  }
});

//gk dipake
router.get("/cariUserbyEmail/:id_cabang/:email", async (req, res, next) => {
  try {
    let cabang = await Cabang.findById(req.params.id_cabang);
    if (!cabang) {
      return res.status(404).json({
        status: 404,
        message: "Cabang not found",
      });
    }
    let user = cabang.Users.find((user) => user.email === req.params.email);
    if (user) {
      // Only set the Content-Type header if we are sending a JSON response
      res.setHeader("Content-Type", "application/json");

      return res.status(200).json({
        status: 200,
        data: user,
      });
    } else {
      return res.status(400).json({
        status: 400,
        message: "No User found with the specified email",
      });
    }
  } catch (err) {
    return res.status(500).json({
      status: 500,
      message: err.message,
    });
  }
});

module.exports = router;
