//item dalam cart
const ItemsTransSchema = {
  name: "ItemTrans",
  embedded: true,
  properties: {
    _id: "objectId",
    id_reference: "string",
    nama_barang: "string",
    id_satuan: "string",
    satuan_price: "double", //harga satuan
    trans_qty: "int", //jumlah dalam cart per item
    persentase_diskon: { type: "int", optional: true },
    total_price: "double",
  },
};

const TransaksiSchema = {
  name: "Transaksi",
  properties: {
    _id: "objectId",
    id_cabang: "string",
    Items: { type: "list", objectType: "ItemTrans" }, //kumpulan item dalam cart yang dibeli
    trans_date: "date",
    payment_method: "string",
    delivery: "bool", //jika true akan membuat tabel delivery
    desc: { type: "string", optional: true },
    status: "string", //pending,confirm
  },
  primaryKey: "_id",
};

const DeliverySchema = {
  name: "Delivery",
  properties: {
    _id: "objectId",
    status: "string", //status pengiriman (Delivered/In Progress)
    alamat_tujuan: "string",
    transaksi_id: "string",
    //+bukti_pengiriman: "pic"
  },
  primaryKey: "_id",
};

module.exports = { TransaksiSchema, ItemsTransSchema, DeliverySchema };
