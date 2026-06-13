"use strict";

// Treadom — sunucu tarafı fetih (territory conquest).
//
// Kısmi/tam fetih, fetheden kullanıcının başka kullanıcıların alanlarını
// değiştirmesini/silmesini gerektirir. Bunu istemcide yapmak güvenlik
// kurallarını gevşetmeyi gerektiriyordu; burada admin yetkisiyle sunucuda
// yapıyoruz, böylece `territories` koleksiyonu istemciye salt-okunur kalır.
//
// İstemci `claimTerritory` callable'ını {name, points:[{lat,lng}]} ile çağırır;
// fonksiyon kullanıcının yeni alanını (döngünün tamamı) oluşturur ve döngünün
// kapladığı rakip alan parçalarını çıkarır (boolean difference):
//   - tamamen kapsanan rakip alan SİLİNİR (adı kaybolur),
//   - kısmen çakışan rakip alan küçülür (sahibi/adı korunur),
//   - döngü bir alanı böldüyse kalan her parça ayrı alan olur,
//   - alanın ortasından geçilirse delik (hole) oluşur.

const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const polygonClipping = require("polygon-clipping");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
const GeoPoint = admin.firestore.GeoPoint;
const FieldValue = admin.firestore.FieldValue;

const REGION = "us-central1";

// --- Push bildirim yardımcıları -------------------------------------------

// Bir kullanıcının kayıtlı FCM token'larını döner (yoksa boş dizi).
async function tokensForUid(uid) {
  const doc = await db.collection("users").doc(uid).get();
  const t = doc.exists && doc.data().fcmTokens;
  return Array.isArray(t) ? t : [];
}

// Bir kullanıcının tüm cihazlarına bildirim gönderir ve geçersiz token'ları
// temizler. notification = {title, body}, data = düz string harita.
async function sendToUid(uid, notification, data) {
  const tokens = await tokensForUid(uid);
  if (!tokens.length) return;
  const res = await messaging.sendEachForMulticast({
    tokens,
    notification,
    data: data || {},
    android: {
      priority: "high",
      notification: { channelId: "treadom_messages" },
    },
    apns: { payload: { aps: { sound: "default" } } },
  });
  const invalid = [];
  res.responses.forEach((r, i) => {
    const code = r.error && r.error.code;
    if (
      code === "messaging/invalid-registration-token" ||
      code === "messaging/registration-token-not-registered"
    ) {
      invalid.push(tokens[i]);
    }
  });
  if (invalid.length) {
    await db
      .collection("users")
      .doc(uid)
      .update({ fcmTokens: FieldValue.arrayRemove(...invalid) });
  }
}

// Yeni sohbet mesajında, gönderen dışındaki katılımcılara bildirim gönderir.
exports.onChatMessage = onDocumentCreated(
  { region: REGION, maxInstances: 10, document: "chats/{chatId}/messages/{messageId}" },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const msg = snap.data();
    if (!msg) return;
    const chatId = event.params.chatId;
    const messageId = event.params.messageId;

    const chatDoc = await db.collection("chats").doc(chatId).get();
    if (!chatDoc.exists) return;
    const chat = chatDoc.data();
    const participants = chat.participants || [];
    const senderId = msg.senderId;
    const senderName = msg.senderName || "";
    const text = msg.text || "";
    const isGroup = !!chat.isGroup;

    const title = isGroup ? chat.name || senderName : senderName;
    const body = isGroup ? `${senderName}: ${text}` : text;
    const data = { type: "chat", chatId, messageId };

    await Promise.all(
      participants
        .filter((u) => u && u !== senderId)
        .map((u) => sendToUid(u, { title, body }, data))
    );
  }
);


const EARTH_R = 6378137.0; // WGS84 ekvator yarıçapı (m)

// İstemcideki run_math.planarAreaM2 ile aynı (equirectangular + shoelace).
function planarAreaM2(ring) {
  if (ring.length < 3) return 0;
  const lat0 = (ring[0].lat * Math.PI) / 180;
  const cos0 = Math.cos(lat0);
  const xs = ring.map((p) => EARTH_R * ((p.lng * Math.PI) / 180) * cos0);
  const ys = ring.map((p) => EARTH_R * ((p.lat * Math.PI) / 180));
  let s = 0;
  for (let i = 0; i < ring.length; i++) {
    const j = (i + 1) % ring.length;
    s += xs[i] * ys[j] - xs[j] * ys[i];
  }
  return Math.abs(s) / 2;
}

function shapeArea(outer, holes) {
  let a = planarAreaM2(outer);
  for (const h of holes) a -= planarAreaM2(h);
  return a < 0 ? 0 : a;
}

// {lat,lng} halkası <-> polygon-clipping [lng,lat] halkası
const toPC = (ring) => ring.map((p) => [p.lng, p.lat]);
const fromPC = (ring) => ring.map(([lng, lat]) => ({ lat, lng }));

const geoPoints = (ring) => ring.map((p) => new GeoPoint(p.lat, p.lng));
const holesField = (holes) => holes.map((h) => ({ points: geoPoints(h) }));

function parseGeom(data) {
  const outer = (data.points || []).map((g) => ({
    lat: g.latitude,
    lng: g.longitude,
  }));
  const holes = (data.holes || []).map((h) =>
    (h.points || []).map((g) => ({ lat: g.latitude, lng: g.longitude }))
  );
  return { outer, holes };
}

function bbox(ring) {
  let mnLa = Infinity, mnLn = Infinity, mxLa = -Infinity, mxLn = -Infinity;
  for (const p of ring) {
    if (p.lat < mnLa) mnLa = p.lat;
    if (p.lat > mxLa) mxLa = p.lat;
    if (p.lng < mnLn) mnLn = p.lng;
    if (p.lng > mxLn) mxLn = p.lng;
  }
  return { mnLa, mnLn, mxLa, mxLn };
}

const bboxOverlap = (a, b) =>
  a.mnLa <= b.mxLa && a.mxLa >= b.mnLa && a.mnLn <= b.mxLn && a.mxLn >= b.mnLn;

// Bir halkanın temsilî merkez noktası (sınır kutusu merkezi) — viewport
// sorgusu için territory dökümanına yazılır. Kutu merkezi her zaman alanın
// yakınındadır, böylece harita görünür alan sorgusu alanı yakalar.
function centroidOf(ring) {
  const b = bbox(ring);
  return { lat: (b.mnLa + b.mxLa) / 2, lng: (b.mnLn + b.mxLn) / 2 };
}

// Bir kullanıcının denormalize toplamlarını (liderlik tablosu için) territory
// koleksiyonundan yeniden hesaplayıp user dökümanına yazar.
async function recomputeUserTotals(ownerUid) {
  if (!ownerUid) return;
  const snap = await db
    .collection("territories")
    .where("ownerUid", "==", ownerUid)
    .get();
  let total = 0;
  snap.forEach((d) => {
    const a = d.data().areaM2;
    if (typeof a === "number") total += a;
  });
  await db
    .collection("users")
    .doc(ownerUid)
    .set({ totalAreaM2: total, territoryCount: snap.size }, { merge: true });
}

exports.claimTerritory = onCall(
  { region: "us-central1", maxInstances: 10 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Giriş gerekli.");
    }
    const uid = request.auth.uid;
    const data = request.data || {};
    const name = (data.name || "").toString().slice(0, 60);
    const points = (data.points || [])
      .map((p) => ({ lat: Number(p.lat), lng: Number(p.lng) }))
      .filter((p) => Number.isFinite(p.lat) && Number.isFinite(p.lng));
    if (points.length < 3) {
      throw new HttpsError("invalid-argument", "En az 3 nokta gerekir.");
    }

    const userDoc = await db.collection("users").doc(uid).get();
    const username = (userDoc.exists && userDoc.data().username) || "";

    const terr = db.collection("territories");
    const batch = db.batch();

    const loopPC = [toPC(points)];
    const loopBox = bbox(points);

    const snap = await terr.get();
    const conqueredFrom = [];
    // Fethedilen rakiplerin uid'leri (kişi başına bir "bölgen ele geçirildi"
    // bildirimi gönderilir).
    const conqueredUids = new Set();

    // Yeni döngüyle başla; kendi (çakışan) alanlarımı buna katıp TEK polygon
    // yaparım — böylece bir kişide üst üste binen iki ayrı polygon kalmaz.
    let myGeom = [[toPC(points)]]; // MultiPolygon: tek polygon (döngü)
    const ownToDelete = [];

    for (const doc of snap.docs) {
      const d = doc.data();
      const isOwn = d.ownerUid === uid;

      const geom = parseGeom(d);
      if (geom.outer.length < 3) continue;
      if (!bboxOverlap(loopBox, bbox(geom.outer))) continue;

      const subject = [[toPC(geom.outer), ...geom.holes.map(toPC)]];
      let result;
      try {
        result = polygonClipping.difference(subject, loopPC);
      } catch (e) {
        continue; // dejenere geometride güvenli atla
      }

      const origArea =
        typeof d.areaM2 === "number"
          ? d.areaM2
          : shapeArea(geom.outer, geom.holes);
      const pieces = result.map((poly) => {
        const outer = fromPC(poly[0]);
        const holes = poly.slice(1).map(fromPC);
        return { outer, holes, area: shapeArea(outer, holes) };
      });
      const newTotal = pieces.reduce((a, p) => a + p.area, 0);
      if (Math.abs(origArea - newTotal) < 0.5) continue; // çakışma yok

      if (isOwn) {
        // Kendi alanım: yeni döngüyle birleştir; eski dökümanı sil.
        try {
          myGeom = polygonClipping.union(myGeom, subject);
          ownToDelete.push(doc.ref);
        } catch (e) {
          // birleştirilemezse eskiyi olduğu gibi bırak
        }
        continue;
      }

      // Rakip alan: kısmi/tam fetih.
      conqueredFrom.push(d.ownerUsername || "");
      if (d.ownerUid && d.ownerUid !== uid) conqueredUids.add(d.ownerUid);
      if (pieces.length === 0) {
        batch.delete(doc.ref); // tamamen fethedildi → sil
        continue;
      }
      const c0 = centroidOf(pieces[0].outer);
      batch.update(doc.ref, {
        points: geoPoints(pieces[0].outer),
        holes: holesField(pieces[0].holes),
        areaM2: pieces[0].area,
        centroidLat: c0.lat,
        centroidLng: c0.lng,
      });
      for (let i = 1; i < pieces.length; i++) {
        const extra = terr.doc();
        const ci = centroidOf(pieces[i].outer);
        batch.set(extra, {
          ownerUid: d.ownerUid,
          ownerUsername: d.ownerUsername || "",
          name: d.name || "",
          points: geoPoints(pieces[i].outer),
          holes: holesField(pieces[i].holes),
          areaM2: pieces[i].area,
          centroidLat: ci.lat,
          centroidLng: ci.lng,
          createdAt: d.createdAt || FieldValue.serverTimestamp(),
          previousOwnerUsername: null,
        });
      }
    }

    // Kendi (çakışan) alanlarımı yeni döngüyle birleştir → tek polygon, eskileri sil.
    for (const ref of ownToDelete) batch.delete(ref);
    let firstId = null;
    for (const poly of myGeom) {
      const outer = fromPC(poly[0]);
      const holes = poly.slice(1).map(fromPC);
      const ref = terr.doc();
      if (!firstId) firstId = ref.id;
      const c = centroidOf(outer);
      batch.set(ref, {
        ownerUid: uid,
        ownerUsername: username,
        name,
        points: geoPoints(outer),
        holes: holesField(holes),
        areaM2: shapeArea(outer, holes),
        centroidLat: c.lat,
        centroidLng: c.lng,
        createdAt: FieldValue.serverTimestamp(),
        previousOwnerUsername: null,
      });
    }

    await batch.commit();

    // Etkilenen kullanıcıların (ben + fethedilenler) denormalize toplamlarını
    // yeniden hesapla (liderlik tablosu `users.totalAreaM2`'den okunur).
    const affected = new Set([uid, ...conqueredUids]);
    await Promise.all(
      [...affected].map((u) =>
        recomputeUserTotals(u).catch((e) =>
          console.error("recomputeUserTotals hata:", u, e)
        )
      )
    );

    // Fethedilen her kullanıcıya push bildirimi gönder (bildirim hatası fethi
    // etkilememeli).
    if (conqueredUids.size > 0) {
      const conqueror = username || name || "Birisi";
      await Promise.all(
        [...conqueredUids].map((to) =>
          sendToUid(
            to,
            {
              title: "Bölgen ele geçirildi!",
              body: `${conqueror} bir bölgeni ele geçirdi.`,
            },
            { type: "conquest" }
          ).catch((e) => console.error("conquest push hata:", e))
        )
      );
    }

    return { territoryId: firstId, conqueredFrom };
  }
);

// Kullanıcının tek alan adını değiştirir ve TÜM alanlarının etiketini
// (denormalize `name`) buna eşitler. `territories` istemciye salt-okunur
// olduğundan relabel admin yetkisiyle burada yapılır.
exports.renameLand = onCall(
  { region: "us-central1", maxInstances: 10 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Giriş gerekli.");
    }
    const uid = request.auth.uid;
    const landName = (request.data && request.data.landName ? request.data.landName : "")
      .toString()
      .slice(0, 60)
      .trim();

    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();
    const username = (userDoc.exists && userDoc.data().username) || "";
    const label = landName === "" ? username : landName;

    const mine = await db
      .collection("territories")
      .where("ownerUid", "==", uid)
      .get();

    let batch = db.batch();
    let n = 0;
    batch.set(userRef, { landName }, { merge: true });
    n++;
    for (const doc of mine.docs) {
      batch.update(doc.ref, { name: label });
      n++;
      if (n >= 400) {
        await batch.commit();
        batch = db.batch();
        n = 0;
      }
    }
    if (n > 0) await batch.commit();
    return { ok: true };
  }
);

// TEK SEFERLİK bakım: mevcut alanlara centroid ekler ve tüm sahiplerin
// denormalize toplamlarını yeniden hesaplar (viewport sorgusu + liderlik
// tablosu yeni alanlara dayandığından eski veriyi taşımak için). Basit bir
// anahtarla korunur; çalıştırıldıktan sonra kaldırılabilir.
exports.backfillTerritories = onRequest(
  { region: "us-central1", maxInstances: 1 },
  async (req, res) => {
    if (req.query.key !== "treadom-backfill-2026") {
      res.status(403).send("forbidden");
      return;
    }
    const snap = await db.collection("territories").get();
    const owners = new Set();
    let batch = db.batch();
    let n = 0;
    let updated = 0;
    for (const doc of snap.docs) {
      const d = doc.data();
      if (d.ownerUid) owners.add(d.ownerUid);
      const hasCentroid =
        typeof d.centroidLat === "number" && typeof d.centroidLng === "number";
      if (hasCentroid) continue;
      const outer = (d.points || []).map((g) => ({
        lat: g.latitude,
        lng: g.longitude,
      }));
      if (outer.length < 3) continue;
      const c = centroidOf(outer);
      batch.update(doc.ref, { centroidLat: c.lat, centroidLng: c.lng });
      updated++;
      n++;
      if (n >= 400) {
        await batch.commit();
        batch = db.batch();
        n = 0;
      }
    }
    if (n > 0) await batch.commit();

    for (const o of owners) {
      await recomputeUserTotals(o).catch((e) =>
        console.error("backfill recompute hata:", o, e)
      );
    }
    res.send(
      `done: centroids updated ${updated}, owners recomputed ${owners.size}`
    );
  }
);
