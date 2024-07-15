const TransaksiSchema = {
  name: "DiskonItems",
  properties: {
    _id: "objectId",
    id_cabang: "string",
    Items: { type: "list", objectType: "Barang" },
    trans_date: { type: "date", optional: true },
    Payment_method: "string",
    Desc: { type: "string", optional: true },
  },
  primaryKey: "_id",
};

module.exports = { DiskonSchema, DiskonItemsSchema };
