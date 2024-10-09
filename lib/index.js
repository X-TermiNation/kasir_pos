const express = require("express");
const app = express();
const cors = require("cors");
const bodyParser = require("body-parser");
const logger = require("morgan");
const jwt = require("jsonwebtoken");
const Realm = require("realm");
const path = require("path");
const expressLayouts = require("express-ejs-layouts");

const port = 3001;
// const config = require('./config')

const UserRouter = require("./view-model-js/view-model-route/user");
const BarangRouter = require("./view-model-js/view-model-route/barang");
const CabangRouter = require("./view-model-js/view-model-route/cabang");
const GudangRouter = require("./view-model-js/view-model-route/gudang");
const TransaksiRouter = require("./view-model-js/view-model-route/transaksi");
const XenditRouter = require("./view-model-js/view-model-route/xendit/xendit");
const InvoiceRouter = require("./view-model-js/view-model-route/invoice");
app.use(logger("dev"));
app.use(expressLayouts);
app.set("view engine", "ejs");
app.use(express.static(path.join(__dirname, "public")));
var options = {
  keepAlive: 1,
  connectTimeoutMS: 30000,
  useNewUrlParser: true,
  useUnifiedTopology: true,
};

app.use(cors());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

const authRouter = require("./user_auth");
app.use("/auth", authRouter);
app.use("/user", UserRouter);
app.use("/barang", BarangRouter);
app.use("/cabang", CabangRouter);
app.use("/gudang", GudangRouter);
app.use("/transaksi", TransaksiRouter);
app.use("/auth", authRouter);
app.use("/xendit", XenditRouter);
app.use("/Invoice", InvoiceRouter);

app.use((req, res, next) => {
  console.log(`Received request: ${req.method} ${req.url}`);
  next();
});

app.use((err, req, res, next) => {
  console.error("Error handling request:", err);
  res.status(500).send("Internal Server Error");
});

const {
  initializeRealm,
} = require("./view-model-js/view-model-realm/realm_database");
const { default: Xendit } = require("xendit-node");

initializeRealm()
  .then(() => {
    app.listen(port, function () {
      console.log("Runnning on " + port);
    });
  })
  .catch((err) => {
    console.error("Failed to connect to Realm MongoDB:", err);
  });

module.exports = app;
