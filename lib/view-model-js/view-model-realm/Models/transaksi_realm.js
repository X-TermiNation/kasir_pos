const TransaksiSchema = {
  name: "Transaksi",
  properties: {
    _id: "objectId",
    id_cabang: "string",
    Items: { type: "list", objectType: "Barang" },
    trans_date: { type: "date", optional: true },
    payment_method: "string",
    delivery: "bool",
    desc: { type: "string", optional: true },
  },
  primaryKey: "_id",
};

const DeliverySchema = {
  name: "Delivery",
  properties: {
    _id: "objectId",
    status: "string",
    alamat_tujuan: "string",
    transaksi_id: "string",
    //bukti_pengiriman: "pic"
  },
  primaryKey: "_id",
};

module.exports = { TransaksiSchema, DeliverySchema };
