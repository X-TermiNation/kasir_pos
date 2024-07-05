const BarangSchema = {
  name: 'Barang',
  embedded: true,
  properties: {
    _id: 'objectId',
    id_reference: 'string',
    insert_date: 'date',
    exp_date: { type: 'date', optional: true },
    jenis_barang: 'string',
    kategori_barang: 'string',
    nama_barang: 'string'
  }
}

const DiskonSchema = {
  name: 'Diskon',
  properties: {
    _id: 'objectId',
    Barang: 'Barang[]',
    __v: 'int?',
    id_cabang_reference: 'string',
    end_date: 'date',
    nama_diskon: 'string',
    persentase_diskon: 'int',
    start_date: 'date'
  },
  primaryKey: '_id'
}

module.exports = { BarangSchema, DiskonSchema }
