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

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const polygonClipping = require("polygon-clipping");

admin.initializeApp();
const db = admin.firestore();
const GeoPoint = admin.firestore.GeoPoint;
const FieldValue = admin.firestore.FieldValue;

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
      if (pieces.length === 0) {
        batch.delete(doc.ref); // tamamen fethedildi → sil
        continue;
      }
      batch.update(doc.ref, {
        points: geoPoints(pieces[0].outer),
        holes: holesField(pieces[0].holes),
        areaM2: pieces[0].area,
      });
      for (let i = 1; i < pieces.length; i++) {
        const extra = terr.doc();
        batch.set(extra, {
          ownerUid: d.ownerUid,
          ownerUsername: d.ownerUsername || "",
          name: d.name || "",
          points: geoPoints(pieces[i].outer),
          holes: holesField(pieces[i].holes),
          areaM2: pieces[i].area,
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
      batch.set(ref, {
        ownerUid: uid,
        ownerUsername: username,
        name,
        points: geoPoints(outer),
        holes: holesField(holes),
        areaM2: shapeArea(outer, holes),
        createdAt: FieldValue.serverTimestamp(),
        previousOwnerUsername: null,
      });
    }

    await batch.commit();
    return { territoryId: firstId, conqueredFrom };
  }
);
