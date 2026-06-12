#!/usr/bin/env python3
"""Treadom için test kullanıcıları ve başlangıç alanlarını (territories) Firebase
REST API'leriyle oluşturur.

Amaç: emülatörde fetih senaryosunu canlı denemek için sahneyi hazırlamak.
  - ayse   -> Rota 1 (Merkez Kare)      "Ayşe Bahçesi"
  - mehmet -> Rota 2 (Doğu Komşu)       "Mehmet Tarlası"
  - zeynep -> Rota 3 (Kuzey Komşu)      "Zeynep Korusu"
  - fatih  -> (alan yok) — uygulamada Rota 5'i koşup ayse+mehmet'i FETHEDECEK.

Tüm kullanıcıların şifresi: test1234
Çalıştır: python3 tool/seed_test_data.py
"""
import json
import math
import sys
import urllib.request
import urllib.error

API_KEY = "AIzaSyDpJSJ7pw-SwOk1Netbh9CmACuBm83x-YU"  # web anahtarı (REST için)
PROJECT = "able-pottery-241209"
PASSWORD = "test1234"

BASE_LAT = 39.9208
BASE_LON = 32.8541
UNIT = 0.0009

IDTK = "https://identitytoolkit.googleapis.com/v1/accounts"
FS = (f"https://firestore.googleapis.com/v1/projects/{PROJECT}"
      "/databases/(default)/documents")


def grid_to_latlon(gx, gy):
    lat = BASE_LAT + gy * UNIT
    lon = BASE_LON + gx * (UNIT / math.cos(math.radians(BASE_LAT)))
    return (lat, lon)


def planar_area_m2(points):
    """Uygulamadaki planarAreaM2 ile aynı (equirectangular + shoelace)."""
    R = 6378137.0
    lat0 = math.radians(points[0][0])
    cos0 = math.cos(lat0)
    xs = [R * math.radians(lon) * cos0 for (_, lon) in points]
    ys = [R * math.radians(lat) for (lat, _) in points]
    s = 0.0
    n = len(points)
    for i in range(n):
        j = (i + 1) % n
        s += xs[i] * ys[j] - xs[j] * ys[i]
    return abs(s) / 2.0


def post(url, body, token=None):
    data = json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        return {"_error": e.read().decode()}


def patch(url, body, token):
    data = json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, method="PATCH")
    req.add_header("Content-Type", "application/json")
    req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())


def ensure_user(username):
    """Auth hesabını oluşturur (varsa giriş yapar); (uid, idToken) döner."""
    email = f"{username}@treadom.app"
    res = post(f"{IDTK}:signUp?key={API_KEY}",
               {"email": email, "password": PASSWORD, "returnSecureToken": True})
    if "_error" in res and "EMAIL_EXISTS" in res["_error"]:
        res = post(f"{IDTK}:signInWithPassword?key={API_KEY}",
                   {"email": email, "password": PASSWORD,
                    "returnSecureToken": True})
    if "_error" in res:
        raise RuntimeError(f"{username}: {res['_error']}")
    return res["localId"], res["idToken"]


def write_user_doc(uid, username, token, total_area):
    body = {"fields": {
        "username": {"stringValue": username},
        "totalAreaM2": {"doubleValue": total_area},
        "createdAt": {"timestampValue": "2026-06-12T15:00:00Z"},
    }}
    patch(f"{FS}/users/{uid}?key={API_KEY}", body, token)


def write_territory(uid, username, name, corners, token):
    pts = [grid_to_latlon(gx, gy) for (gx, gy) in corners]
    area = planar_area_m2(pts)
    geo_values = [{"geoPointValue": {"latitude": lat, "longitude": lon}}
                  for (lat, lon) in pts]
    body = {"fields": {
        "ownerUid": {"stringValue": uid},
        "ownerUsername": {"stringValue": username},
        "name": {"stringValue": name},
        "points": {"arrayValue": {"values": geo_values}},
        "areaM2": {"doubleValue": area},
        "createdAt": {"timestampValue": "2026-06-12T15:00:00Z"},
        "previousOwnerUsername": {"nullValue": None},
    }}
    res = post(f"{FS}/territories?key={API_KEY}", body, token)
    if "_error" in res:
        raise RuntimeError(f"territory {name}: {res['_error']}")
    return area


# username -> (alan adı, köşe ızgara noktaları). fatih'in alanı yok (canlı fetih).
SEED = {
    "ayse":   ("Ayşe Bahçesi",  [(0, 0), (1, 0), (1, 1), (0, 1)]),
    "mehmet": ("Mehmet Tarlası", [(1, 0), (2, 0), (2, 1), (1, 1)]),
    "zeynep": ("Zeynep Korusu",  [(0, 1), (1, 1), (1, 2), (0, 2)]),
}


def delete_all_territories(token):
    """Mevcut tüm alanları siler (temiz bir demo için). Gevşetilmiş kurallar
    sayesinde giriş yapmış kullanıcı silebilir."""
    url = f"{FS}/territories?key={API_KEY}&pageSize=300"
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req) as r:
        data = json.loads(r.read())
    docs = data.get("documents", [])
    for d in docs:
        name = d["name"]  # tam kaynak yolu
        del_url = (f"https://firestore.googleapis.com/v1/{name}"
                   f"?key={API_KEY}")
        dreq = urllib.request.Request(del_url, method="DELETE")
        dreq.add_header("Authorization", f"Bearer {token}")
        urllib.request.urlopen(dreq).read()
    print(f"✔ {len(docs)} mevcut alan silindi (temiz başlangıç)")


def main():
    if "--reset" in sys.argv:
        _, token = ensure_user("fatih")
        delete_all_territories(token)

    for username, (name, corners) in SEED.items():
        uid, token = ensure_user(username)
        area = write_territory(uid, username, name, corners, token)
        write_user_doc(uid, username, token, area)
        print(f"✔ {username:7s} -> {name:16s} (~{area:.0f} m²)  uid={uid}")

    # Fetheden kullanıcı: yalnızca hesap + boş kullanıcı dökümanı.
    uid, token = ensure_user("fatih")
    write_user_doc(uid, "fatih", token, 0)
    print(f"✔ fatih   -> (alan yok; uygulamada Rota 5'i koşacak)  uid={uid}")
    print("\nTüm test kullanıcılarının şifresi: test1234")


if __name__ == "__main__":
    main()
