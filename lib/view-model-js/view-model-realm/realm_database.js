const Realm = require("realm");
const BSON = Realm.BSON;
const http = require("http");
const config = require("./config");
const path = require("path");
const realmId = "posta-jctyi";
const LogInEmail = config.email;
const LogInPassword = config.password;
let realms;
// Initialize Realm Sync with your Realm application ID
const apl = new Realm.App({
  id: realmId,
  baseFilePath: path.resolve("./lib/local_database.realm"),
});
const {
  SatuanSchema,
  BarangSchema,
  GudangSchema,
  UserSchema,
  CabangSchema,
} = require("./Models/cabang_realm");

const {
  TransaksiSchema,
  ItemsTransSchema,
  DeliverySchema,
} = require("./Models/transaksi_realm");

//kalau bisa ini dipindahkan file sendiri
const JenisSchema = {
  name: "Jenis",
  properties: {
    _id: "objectId",
    __v: "int?",
    nama_jenis: "string",
  },
  primaryKey: "_id",
};
const KategoriSchema = {
  name: "kategori",
  properties: {
    _id: "objectId",
    __v: "int?",
    id_jenis: "objectId",
    nama_kategori: "string",
  },
  primaryKey: "_id",
};
const OwnerSchema = {
  name: "Owner",
  properties: {
    _id: "objectId",
    __v: "int?",
    email: "string",
    fname: "string",
    lname: "string",
    password: "string",
  },
  primaryKey: "_id",
};

const { DiskonSchema, DiskonItemsSchema } = require("./Models/Diskon_realm");
const { response } = require("express");

async function isOnline() {
  return new Promise((resolve) => {
    http
      .get("http://google.com", (res) => {
        resolve(true);
      })
      .on("error", () => {
        resolve(false);
      });
  });
}
async function LogInRealm(email, password) {
  try {
    const online = await isOnline();
    let user;
    if (online) {
      // Log in with email and password
      user = await apl.logIn(Realm.Credentials.emailPassword(email, password));

      if (!user) {
        // Attempt to register a new user if login fails
        console.log("Attempting to register a new user...");
        await app.emailPasswordAuth.registerUser(email, password);
        console.log("Account registered!");

        // Log in the newly registered user
        user = await app.logIn(
          Realm.Credentials.emailPassword(email, password)
        );
      }
      return user;
    }
  } catch (error) {
    console.log("login problem:" + error);
  }
}

async function openRealm() {
  try {
    let user;
    const schema = [
      SatuanSchema,
      BarangSchema,
      GudangSchema,
      UserSchema,
      CabangSchema,
      DiskonItemsSchema,
      DiskonSchema,
      JenisSchema,
      KategoriSchema,
      OwnerSchema,
      ItemsTransSchema,
      TransaksiSchema,
      DeliverySchema,
    ];
    user = await LogInRealm(LogInEmail, LogInPassword);
    const realmpath = path.resolve("./lib/local_database");
    const initrealm = await Realm.open({
      path: realmpath,
      schema: schema,
      sync: {
        user: user,
        flexible: true,
        initialSubscriptions: {
          update: (subs, realms) => {
            subs.add(realms.objects("Cabang"));
            subs.add(realms.objects("Diskon"));
            subs.add(realms.objects("Owner"));
            subs.add(realms.objects("Transaksi"));
            subs.add(realms.objects("Delivery"));
            subs.add(realms.objects("kategori"));
            subs.add(realms.objects("Jenis"));
          },
          rerunOnOpen: true,
        },
      },
    });
    return initrealm;
  } catch (error) {
    console.log("Error opening realm: " + error);
    throw error;
  }
}

async function checkDataPresence() {
  try {
    const cabangObjects = realms.objects("Cabang");
    console.log("Number of Cabang objects locally:", cabangObjects.length);
    console.log("Cabang objects:", cabangObjects.toJSON());
  } finally {
    //realm.close()
  }
}

async function initializeRealm() {
  realms = await openRealm();
  try {
    //untuk hapus semua
    // realms.write(() => {
    //   realms.deleteAll();
    // });
    checkDataPresence();
    console.log("Realm Initialized Succesfully");
  } catch (error) {
    console.error("Error initializing Realm:", error);
    throw error;
  } finally {
    //realm.close()
  }
}

//controller realm

//cabang route
//insert cabang
async function insertCabang(cabangData) {
  try {
    realms.subscriptions.update((subs) => {
      subs.add(realms.objects("Cabang"));
    });
    realms.write(() => {
      realms.create("Cabang", {
        _id: new BSON.ObjectId(),
        alamat: cabangData.alamat,
        nama_cabang: cabangData.nama_cabang,
        no_telp: cabangData.no_telp,
      });
    });
  } finally {
    //realms.close();
  }
}
//cari cabang
async function showAllCabang() {
  try {
    const cabangDataAll = realms.objects("Cabang");
    console.log(cabangDataAll);
    return cabangDataAll;
  } catch (error) {
    console.log("error fetch all data cabang:" + error);
  } finally {
    //realm.close()
  }
}

async function searchCabangByName(namacabang) {
  try {
    const cabang = realms
      .objects("Cabang")
      .filtered("nama_cabang == $0", namacabang);
    const cabangdata = Array.from(cabang);
    return cabangdata;
  } catch (error) {
    console.error("Error searching for cabang:", error);
    throw error;
  } finally {
    //realm.close()
  }
}
async function searchCabangByID(idcabang) {
  const id = Realm.BSON.ObjectId(idcabang);
  try {
    const cabang = realms.objectForPrimaryKey("Cabang", id);
    return cabang;
  } catch (error) {
    console.error("Error searching for cabang:", error);
    throw error;
  } finally {
    //realm.close()
  }
}

async function searchCabangByIDfiltered(idcabang) {
  const id = Realm.BSON.ObjectId(idcabang);
  try {
    const cabang = realms.objects("Cabang").filtered("_id == $0", id);
    return cabang;
  } catch (error) {
    console.error("Error searching for cabang:", error);
    throw error;
  } finally {
    //realm.close()
  }
}

//gudang route
async function insertGudang(cabangId, gudangData) {
  try {
    const cabang = realms.objectForPrimaryKey("Cabang", cabangId);
    if (!cabang) {
      throw new Error("Cabang not found");
    }
    realms.write(() => {
      cabang.Gudang.push({
        alamat: gudangData.alamat,
        _id: new BSON.ObjectId(),
      });
    });
  } catch (error) {
    console.log("error insert gudang:" + error);
  } finally {
    //realm.close()
  }
}

async function searchGudangById(cabangId) {
  try {
    const cabang = realms.objectForPrimaryKey("Cabang", cabangId);
    if (!cabang) {
      throw new Error("Cabang not found");
    }
    const GudangCabang = cabang.Gudang;
    return GudangCabang;
  } catch (error) {
    console.log("Error searching for users by email:", error);
    throw error;
  } finally {
    // realm.close();
  }
}

//user route

async function insertUser(cabangId, userData) {
  try {
    const cabang = realms.objectForPrimaryKey("Cabang", cabangId);
    if (!cabang) {
      throw new Error("Cabang not found");
    }
    // realm.subscriptions.update((subs) => {
    //   subs.add(realm.objects('Users'))
    // })
    realms.write(() => {
      cabang.Users.push({
        _id: new BSON.ObjectId(),
        email: userData.email,
        password: userData.password,
        fname: userData.fname,
        lname: userData.lname,
        role: userData.role,
      }); // Add the new user data to the 'Users' array
    });
  } finally {
    //realm.close();
  }
}
//show all user
async function showAllUserfromCabang(idcabang) {
  try {
    const cabang = realms.objectForPrimaryKey("Cabang", idcabang);
    if (!cabang) {
      throw new Error("Cabang not found");
    }
    return cabang.Users;
  } catch (error) {
    console.log("error fetch all data cabang:" + error);
  } finally {
    //realm.close()
  }
}
//search user by email
async function searchUsersByEmail(cabangId, email) {
  try {
    const cabang = realms.objectForPrimaryKey("Cabang", cabangId);
    if (!cabang) {
      throw new Error("Cabang not found");
    }
    const usersCabang = cabang.Users.filtered("email == $0", email);
    return usersCabang;
  } catch (error) {
    console.log("Error searching for users by email:", error);
    throw error;
  } finally {
    // realm.close();
  }
}

//update user
async function updateUser(cabangId, userId, updatedUserData) {
  try {
    const cabang = realms.objectForPrimaryKey("Cabang", cabangId);
    if (!cabang) {
      throw console.log("Cabang not found");
    }
    const userIndex = cabang.Users.findIndex((user) => user._id.equals(userId));
    if (userIndex === -1) {
      throw console.log("User tidak ditemukan");
    }

    realms.write(() => {
      cabang.Users[userIndex].fname =
        updatedUserData.fname || cabang.Users[userIndex].fname;
      cabang.Users[userIndex].lname =
        updatedUserData.lname || cabang.Users[userIndex].lname;
      cabang.Users[userIndex].role =
        updatedUserData.role || cabang.Users[userIndex].role;
    });

    console.log("User updated successfully");
    return Array.from(cabang.Users[userIndex]);
  } catch (error) {
    console.error("Error updating user:", error);
    throw error;
  } finally {
    //realm.close()
  }
}
//delete user
async function deleteUser(cabangId, userId) {
  try {
    const cabang = realms.objectForPrimaryKey("Cabang", cabangId);
    if (!cabang) {
      throw new Error("Cabang not found");
    }

    const userIndex = cabang.Users.findIndex((user) => user._id.equals(userId));
    if (userIndex === -1) {
      throw new Error("User not found in cabang");
    }

    realms.write(() => {
      cabang.Users.splice(userIndex, 1);
    });
    console.log("User deleted successfully");
    return "success";
  } catch (error) {
    console.error("Error deleting user:", error);
    throw error;
  } finally {
    //realm.close()
  }
}

//owner route
async function insertOwner(ownerData) {
  try {
    if (isOnline) {
      realms.subscriptions.update((subs) => {
        subs.add(realms.objects("Owner"));
      });
    }

    await realms.write(() => {
      realms.create("Owner", {
        _id: new BSON.ObjectId(),
        email: ownerData.email,
        password: ownerData.password,
        fname: ownerData.fname,
        lname: ownerData.lname,
      });
    });
  } finally {
    //realm.close()
  }
}

async function SearchOwner() {
  try {
    const data = realms.objects("Owner");
    if (data.length > 0) {
      return realms.objects("Owner");
    } else {
      return console.log("data tidak ada");
    }
  } catch (error) {
    console.log("fetch data Owner failed: " + error);
  } finally {
    //realm.close()
  }
}

//barang
//get barang dari cabang
async function ShowItemFromCabang(id_cabang, id_gudang) {
  try {
    const cabang = realms.objectForPrimaryKey("Cabang", id_cabang);
    if (!cabang) {
      throw console.log("Cabang not found");
    }

    const gudang = cabang.Gudang.find((g) => g._id.equals(id_gudang));
    if (!gudang) {
      throw console.log("Gudang not found in cabang");
    }

    // Access the barang array in the gudang
    const barang = gudang.Barang;
    return barang;
  } catch (error) {
    console.log("gagal ambil data barang");
  }
}

async function SearchItemByID(id_cabang, id_gudang, id_barang) {
  try {
    const cabang = realms.objectForPrimaryKey("Cabang", id_cabang);
    if (!cabang) {
      throw console.log("Cabang not found");
    }

    const gudang = cabang.Gudang.find((g) => g._id.equals(id_gudang));
    if (!gudang) {
      throw console.log("Gudang not found in cabang");
    }
    const barang = gudang.Barang.find((b) => b._id.equals(id_barang));
    if (!barang) {
      throw new Error("Barang not found in gudang");
    }

    return barang;
  } catch (error) {
    console.log("gagal ambil data barang");
  }
}

//add barang
async function AddItems(id_cabang, id_gudang, BarangData) {
  try {
    const cabang = realms.objectForPrimaryKey("Cabang", id_cabang);
    if (!cabang) {
      throw new Error("Cabang not found");
    }
    const gudang = cabang.Gudang.find((g) => g._id.equals(id_gudang));
    if (!gudang) {
      throw new Error("Gudang not found in cabang");
    }
    realms.write(() => {
      gudang.Barang.push({
        _id: new BSON.ObjectId(),
        nama_barang: BarangData.nama_barang,
        jenis_barang: BarangData.jenis_barang,
        kategori_barang: BarangData.kategori_barang,
        insert_date: BarangData.insert_date,
        exp_date: BarangData.exp_date ? new Date(BarangData.exp_date) : null,
      });
    });
    console.log("Barang added successfully");
    return BarangData;
  } catch (error) {
    console.log("Gagal Tambah barang:", error);
    throw error;
  } finally {
    //realm.close()
  }
}

//delete barang
async function delbarang(id_cabang, id_gudang, id_barang) {
  try {
    const cabang = realms.objectForPrimaryKey("Cabang", id_cabang);
    if (!cabang) {
      throw console.log("Cabang tidak ditemukan!");
    }
    const gudangIndex = cabang.Gudang.findIndex((g) => g._id.equals(id_gudang));

    if (gudangIndex === -1) {
      throw console.log("gudang tidak ditemukan!");
    }

    const gudang = cabang.Gudang[gudangIndex];

    const barangIndex = gudang.Barang.findIndex((barang) =>
      barang._id.equals(id_barang)
    );

    if (barangIndex === -1) {
      return console.log("Barang tidak ditemukan dalam Gudang");
    }
    const BarangData = gudang.Barang[barangIndex];
    realms.write(() => {
      gudang.Barang.splice(barangIndex, 1);
    });
    return BarangData;
  } catch (error) {
    throw console.log("gagal hapus barang! :" + error);
  } finally {
    //realm.close()
  }
}

//satuan
async function addsatuan(id_cabang, id_gudang, id_barang, satuanData) {
  try {
    const cabang = realms.objectForPrimaryKey("Cabang", id_cabang);
    if (!cabang) {
      throw new Error("Cabang not found");
    }
    const gudang = cabang.Gudang.find((g) => g._id.equals(id_gudang));
    if (!gudang) {
      throw new Error("Gudang not found in cabang");
    }
    const barang = gudang.Barang.find((g) => g._id.equals(id_barang));
    if (!barang) {
      throw new Error("Barang not found in Gudang");
    }
    const convertedjumlah = BigInt(satuanData.jumlah_satuan);
    const convertedharga = BigInt(satuanData.harga_satuan);
    realms.write(() => {
      barang.Satuan.push({
        _id: new BSON.ObjectId(),
        nama_satuan: satuanData.nama_satuan,
        jumlah_satuan: convertedjumlah,
        harga_satuan: convertedharga,
      });
    });
    console.log("Satuan added successfully");
    return satuanData;
  } catch (error) {
    throw console.log("gagal insert satuan:" + error);
  } finally {
    //realm.close()
  }
}

async function SearchSatuanByIdBarang(id_cabang, id_gudang, id_barang) {
  try {
    const cabang = realms.objectForPrimaryKey("Cabang", id_cabang);
    if (!cabang) {
      throw new Error("Cabang not found");
    }
    const gudang = cabang.Gudang.find((g) => g._id.equals(id_gudang));
    if (!gudang) {
      throw new Error("Gudang not found in cabang");
    }
    const barang = gudang.Barang.find((g) => g._id.equals(id_barang));
    if (!barang) {
      throw new Error("Barang not found in Gudang");
    }
    const satuanResult = barang.Satuan;
    if (satuanResult) {
      return satuanResult;
    } else {
      console.log("data satuan tidak ditemukan");
      return 0;
    }
  } catch (error) {
    throw console.log("gagal fetch data satuan");
  }
}

async function SearchSatuanByID(id_satuan) {
  const id = Realm.BSON.ObjectID(id_satuan);
  try {
    const cabangs = realms.objects("Cabang");
    for (const cabang of cabangs) {
      for (const gudang of cabang.Gudang) {
        for (const barang of gudang.Barang) {
          const satuan = barang.Satuan.find((s) => s._id.equals(id));
          if (satuan) {
            return satuan;
          }
        }
      }
    }
    throw new Error("Satuan not found");
  } catch (error) {
    console.error("Error fetching Satuan data:", error);
    throw new Error("Failed to fetch Satuan data");
  }
}

//kategori
async function getallCategory() {
  try {
    const kategoriDataAll = realms.objects("kategori");
    return kategoriDataAll;
  } catch (error) {
    console.log("error fetch all data kategori:" + error);
  }
}

async function getfirstkategori() {
  try {
    const kategoriDataAll = realms.objects("kategori");
    if (kategoriDataAll.length > 0) {
      return kategoriDataAll[0]; // Return the first element
    } else {
      return null; // Return null if no data is found
    }
  } catch (error) {
    console.log("Error fetching the first category data:", error);
    throw error;
  } finally {
    //realm.close();
  }
}

async function SearchKategoriByName(datakategori) {
  try {
    const kategoriDataAll = realms
      .objects("kategori")
      .filtered("nama_kategori = $0", datakategori.nama_kategori);
    if (kategoriDataAll.length > 0) {
      return kategoriDataAll[0];
    } else {
      return null;
    }
  } catch (error) {
    console.log("Error fetching the first category data:", error);
    throw error;
  } finally {
    //realm.close();
  }
}

async function addKategori(datakategori) {
  try {
    if (isOnline) {
      realms.subscriptions.update((subs) => {
        subs.add(realms.objects("kategori"));
      });
    }
    reals.write(() => {
      realms.create("kategori", {
        _id: new BSON.ObjectId(),
        nama_kategori: datakategori.nama_kategori,
        id_jenis: Realm.BSON.ObjectId(datakategori.id_jenis),
      });
    });
    return datakategori;
  } catch (error) {
    console.log("tidak berhasil menambah data!: " + error);
  } finally {
    //realm.close()
  }
}

//jenis
async function getallJenis() {
  try {
    const jenisDataAll = realms.objects("Jenis");
    return jenisDataAll;
  } catch (error) {
    console.log("error fetch all data jenis:" + error);
  }
}

async function getfirstJenis() {
  try {
    const jenisDataAll = realms.objects("Jenis");
    if (jenisDataAll.length > 0) {
      return jenisDataAll[0];
    } else {
      return null;
    }
  } catch (error) {
    console.log("Error fetching the first Jenis data:", error);
    throw error;
  } finally {
    //realm.close();
  }
}

async function SearchJenisByName(datajenis) {
  try {
    const jenisDataAll = realms
      .objects("kategori")
      .filtered("nama_kategori = $0", datajenis.nama_jenis);
    if (jenisDataAll.length > 0) {
      return jenisDataAll[0]; // Return the first matching element
    } else {
      return null; // Return null if no data is found
    }
  } catch (error) {
    console.log("Error fetching the first category data:", error);
    throw error;
  } finally {
    //realm.close();
  }
}

async function addJenis(datajenis) {
  try {
    if (isOnline) {
      realms.subscriptions.update((subs) => {
        subs.add(realms.objects("Jenis"));
      });
    }
    realms.write(() => {
      realms.create("Jenis", {
        _id: new BSON.ObjectId(),
        nama_jenis: datajenis.nama_jenis,
      });
    });
    return datajenis;
  } catch (error) {
    console.log("tidak berhasil menambah data!:" + error);
  } finally {
    //realm.close()
  }
}

async function searchjenisBykategori(katakategori) {
  try {
    const kategori = await realms
      .objects("kategori")
      .filtered("nama_kategori == $0", katakategori)[0];
    if (!kategori) {
      console.log("kategori tidak ditemukan");
    } else {
      const jenis = realms.objectForPrimaryKey("Jenis", kategori.id_jenis);
      if (!jenis) {
        console.log("Jenis tidak ditemukan");
        return null;
      } else {
        return jenis;
      }
    }
  } catch (error) {
    console.log("gagal mendapat jenis dari kategori...");
  } finally {
    //realm.close()
  }
}

//diskon
async function add_diskon(datadiskon) {
  let realms = await openRealm();
  try {
    const diskon = await realm
      .objects("Diskon")
      .filtered("nama_diskon = $0", datadiskon.nama_diskon);
    if (diskon.length > 0) {
      console.log("diskon dengan nama tersebut sudah ada!");
    } else {
      if (isOnline) {
        realms.subscriptions.update((subs) => {
          subs.add(realms.objects("Diskon"));
        });
      }
      const persentase = BigInt(datadiskon.persentase_diskon);
      realms.write(() => {
        realms.create("Diskon", {
          _id: new BSON.ObjectId(),
          nama_diskon: datadiskon.nama_diskon,
          id_cabang_reference: datadiskon.id_cabang_reference,
          persentase_diskon: persentase,
          start_date: datadiskon.start_date,
          end_date: datadiskon.end_date,
        });
      });
      const alldata = await realms.objects("Diskon");
      return alldata;
    }
  } catch (error) {
    console.log("gagal menambah diskon!:" + error);
  } finally {
    // realm.close()
  }
}

async function add_barang_diskon(id_diskon, databarang) {
  try {
    const Diskon = await ShowDiskonByID(id_diskon);
    console.log("ini targetnya:" + Diskon);
    if (Diskon.length < 1) {
      throw new Error("Diskon not found when adding stuff");
    } else {
      realms.write(() => {
        Diskon.Barang.push({
          _id: new BSON.ObjectId(),
          nama_barang: databarang.nama_barang,
          id_reference: databarang.id_reference,
          insert_date: databarang.insert_date,
          exp_date: databarang.exp_date,
          jenis_barang: databarang.jenis_barang,
          kategori_barang: databarang.kategori_barang,
        });
      });
      const alldata = await realms.objects("Diskon");
      return alldata.Barang;
    }
  } catch (error) {
    console.log("gagal menambahkan barang pada diskon!:" + error);
  } finally {
    //realm.close()
  }
}

async function ShowDiskonByCabang(id_cabang) {
  try {
    const diskon = await realms
      .objects("Diskon")
      .filtered("id_cabang_reference = $0", id_cabang);
    if (diskon.length < 1) {
      console.log("Diskon kosong");
      return [];
    } else {
      return diskon;
    }
  } catch (error) {
    console.log(
      "gagal menampilkan barang pada diskon berdasar id cabang!:" + error
    );
    return [];
  }
}

async function ShowDiskonByBarang(id_reference, id_cabang) {
  try {
    const diskon = await realms
      .objects("Diskon")
      .filtered("id_cabang_reference = $0", id_cabang);
    console.log("semua diskon:" + diskon);
    const discounts = [];

    diskon.forEach((ds) => {
      ds.Barang.forEach((barang) => {
        if (barang.id_reference === id_reference) {
          discounts.push(ds);
        }
      });
    });

    if (discounts.length === 0) {
      console.log("No discounts found for id_reference:", id_reference);
      return null;
    }

    console.log(
      "Found discounts:",
      discounts.map((discount) => discount.toJSON())
    );

    return discounts;
  } catch (error) {
    console.log("Failed to fetch discounts for the item: " + error);
    throw error; // Propagate the error back to the caller
  }
}

async function ShowDiskonByName(nama_diskon) {
  try {
    const diskon = await realms
      .objects("Diskon")
      .filtered("nama_diskon = $0", nama_diskon);
    if (!diskon) {
      throw new Error("Diskon not found");
    }
    return diskon;
  } catch (error) {
    console.log("gagal menampilkan barang sesuai nama diskon!:" + error);
  }
}

async function ShowDiskonByID(id_diskon) {
  try {
    const diskon = await realms.objectForPrimaryKey("Diskon", id_diskon);
    if (diskon == null) {
      console.log("Diskon not found");
      return null;
    }
    return diskon;
  } catch (error) {
    console.log(
      "gagal menampilkan barang pada berdasarkan id diskon!:" + error
    );
  }
}

async function ShowDiskonBarangByID(id_diskon) {
  try {
    const diskon = await realms.objectForPrimaryKey("Diskon", id_diskon);
    if (diskon == null) {
      console.log("Diskon not found");
      return null;
    }
    const baranglist = diskon.Barang;
    return baranglist;
  } catch (error) {
    console.log("gagal menampilkan barang pada diskon!:" + error);
  }
}

//
async function deleteDiskon(id_diskon) {
  try {
    const diskon = await ShowDiskonByID(id_diskon);
    console.log(diskon);
    if (diskon === null) {
      throw console.log("Diskon not found");
    } else {
      await realms.write(() => {
        realms.delete(diskon);
      });
    }
  } catch (error) {
    console.log("gagal menghapus diskon!:" + error);
  } finally {
    //realm.close()
  }
}

//Transaksi
async function addTrans(id_cabang, data_transaksi) {
  try {
    realms.subscriptions.update((subs) => {
      subs.add(realms.objects("Transaksi"));
    });
    await realms.write(() => {
      const trans = realms.create("Transaksi", {
        _id: new BSON.ObjectId(),
        id_cabang: id_cabang,
        trans_date: data_transaksi.trans_date,
        payment_method: data_transaksi.payment_method,
        delivery: data_transaksi.delivery,
        desc: data_transaksi.desc,
        status: data_transaksi.status,
      });
      data_transaksi.Items.forEach((item) => {
        trans.Items.push({
          _id: new BSON.ObjectId(),
          id_reference: item.id_reference,
          nama_barang: item.nama_barang,
          id_satuan: item.id_satuan,
          satuan_price: item.satuan_price,
          trans_qty: item.trans_qty,
          persentase_diskon: item.persentase_diskon,
          total_price: item.total_price,
        });
      });
      return trans;
    });
  } catch (error) {
    console.log("gagal tambah transaksi:" + error);
  }
}

//
async function ShowAllTransfromCabang(id_cabang) {
  try {
    const transAll = realms
      .objects("Transaksi")
      .filtered("id_cabang = $0", id_cabang);
    console.log(transAll);
    return transAll;
  } catch (error) {
    console.log("error fetch data transaksi:" + error);
  } finally {
    //realm.close()
  }
}

module.exports = {
  add_diskon,
  add_barang_diskon,
  AddItems,
  addKategori,
  addJenis,
  addsatuan,
  addTrans,
  deleteUser,
  delbarang,
  deleteDiskon,
  getallCategory,
  getfirstkategori,
  getfirstJenis,
  getallJenis,
  insertCabang,
  insertGudang,
  insertOwner,
  insertUser,
  SearchItemByID,
  searchCabangByName,
  searchCabangByID,
  searchCabangByIDfiltered,
  searchUsersByEmail,
  searchGudangById,
  searchjenisBykategori,
  showAllCabang,
  showAllUserfromCabang,
  ShowAllTransfromCabang,
  ShowItemFromCabang,
  ShowDiskonByName,
  ShowDiskonByCabang,
  ShowDiskonByID,
  ShowDiskonBarangByID,
  ShowDiskonByBarang,
  SearchSatuanByID,
  SearchSatuanByIdBarang,
  searchjenisBykategori,
  SearchJenisByName,
  SearchKategoriByName,
  SearchOwner,
  updateUser,
  initializeRealm,
  checkDataPresence,
};
