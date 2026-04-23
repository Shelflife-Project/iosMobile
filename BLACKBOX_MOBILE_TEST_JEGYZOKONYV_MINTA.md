# Feketedobozos Mobil Tesztelesi Jegyzokonyv - Minta

## Tesztelesi Kornyezet
- Platform: iOS 26+
- Tesztelt eszkozok: iPhone 15, iPhone 17
- Alkalmazas verzio: [kitoltendo]
- Build azonosito: [kitoltendo]
- Datum: [kitoltendo]
- Tesztelo: [kitoltendo]

## Jegyzokonyv

| ID | Teszteset | Vart eredmeny | Elert eredmeny | Atment | Ido |
| --- | --- | --- | --- | --- | --- |
| AUTH-001 | Login ervenyes email + jelszo | Sikeres bejelentkezes, fo app felulet betolt | sikeres | I | 11:24 |
| AUTH-002 | Login hibas jelszoval | Hibauzenet jelenik meg, user Auth oldalon marad | sikeres | I | 11:26 |
| AUTH-003 | Login ures email mezovel | Login gomb tiltott allapotban marad | sikeres | I | 11:28 |
| AUTH-004 | Login ures jelszo mezovel | Login gomb tiltott allapotban marad | sikeres | I | 11:28 |
| AUTH-005 | Signup ervenyes adatokkal | Sikeres regisztracio, fo app felulet betolt | sikeres | I | 11:31 |
| AUTH-006 | Signup jelszo es megerosites nem egyezik | Validacios hiba jelenik meg, nincs regisztracio | nem jelenik meg hiba |  | 11:34 |
| AUTH-007 | Signup ervenytelen email formatummal | Validacios hiba jelenik meg, nincs regisztracio | nem jekenik meg hiba |  | 11:35 |
| AUTH-008 | Login/Signup szegmens valtas | A megfelelo form jelenik meg helyesen | sikeres | I | 11:36 |
| ROOT-001 | App inditas ervenyes tokennel | Session validalas utan fo app nyilik meg | sikeres | I | 11:36 |
| ROOT-002 | App inditas ervenytelen tokennel | Auth oldal nyilik meg | sikeres | I | 11:37 |
| ROOT-003 | Betoltes kozbeni allapot ellenorzese | Loading allapot lathato session bootstrap kozben | sikeres | I | 11:37 |
| ROOT-004 | Tab navigacio Home -> Notifications -> Profile | Minden tab hiba nelkul megnyilik | sikeres | I | 11:38 |
| ROOT-005 | Kijelentkezes utan visszalepes vedelme | Vissza gombbal sem erheto el vedett oldal | sikeres | I | 11:39 |
| HOME-001 | Home oldal betoltese | Stat kartyak megjelennek (storages/products/shopping) | sikeres | I | 11:41 |
| HOME-002 | Storage stat kartya erintese | Storages oldal nyilik meg | sikeres | I | 11:41 |
| HOME-003 | Products stat kartya erintese | Products oldal nyilik meg | sikeres | I | 11:41 |
| HOME-004 | Shopping stat kartya erintese | Shopping List oldal nyilik meg | sikeres | I | 11:42 |
| HOME-005 | Home pull-to-refresh | Adatok frissulnek vizualis hiba nelkul | sikeres | I | 11:43 |
| STOR-001 | Storages lista betoltese | Sajat es tagsagi tarolok listazodnak | sikeres | I | 11:43 |
| STOR-002 | Ures storage lista allapot | Ures allapot + letrehozas CTA jelenik meg | sikeres | I | 11:43 |
| STOR-003 | Storage keresese talalattal | Lista szurve jelenik meg (debounce utan) | sikeres | I | 11:44 |
| STOR-004 | Storage keresese nem talalattal | Ures talalati allapot jelenik meg | sikeres | I | 11:45 |
| STOR-005 | Uj storage letrehozasa ervenyes nevvel | Uj storage megjelenik a listaban | sikeres | I | 11:45 |
| STOR-006 | Uj storage letrehozasa ures nevvel | Mentes gomb tiltott, nincs letrehozas | sikeres | I | 11:45 |
| STOR-007 | Sajat storage atnevezese | Modositott nev azonnal latszik a listaban | sikeres | I | 11:46 |
| STOR-008 | Sajat storage torlese swipe actionnel | Storage eltunik a listabol | sikeres | I | 11:46 |
| STOR-009 | Tagkent leave storage muvelet | Storage eltunik a user listajabol | sikeres | I | 11:47 |
| STOR-010 | Oldalmeret beallitas 0 (all) | Lapozas tiltva, osszes elem lathato | sikeres | I | 11:47 |
| STOR-011 | Oldalmeret beallitas 5/10/15/20 | Lista megfelelo lapszammal mukodik | sikeres | I | 11:47 |
| STOR-012 | Lapozas Next/Previous | Helyes oldal adatok toltodnek be | sikeres | I | 11:49 |
| SDET-001 | Storage Detail megnyitas | Item, member, invited szekciok helyesen jelennek meg | sikeres | I | 11:49 |
| SDET-002 | Add Item sheet megnyitasa | Product valaszto es datum valaszto megjelenik | sikeres | I | 11:50 |
| SDET-003 | Add Item mentes valasztott termekkel | Uj item megjelenik a listaban visszateres nelkul | sikeres | I | 11:50 |
| SDET-004 | Add Item mentes termek valasztas nelkul | Add gomb tiltott allapotban marad | sikeres | I | 11:51 |
| SDET-005 | Item torlese swipe actionnel | Item eltunik a listabol visszateres nelkul | sikeres | I | 11:51 |
| SDET-006 | Item Add to List action | Termek bekerul shopping listaba | sikeres | I | 11:51 |
| SDET-007 | Mar shopping listaban levo termek kezelese | Add to List action tiltott/inaktiv | sikeres | I | 11:52 |
| SDET-008 | Running Low sheet megnyitas | Threshold allitasi felulet helyesen megjelenik | sikeres | I | 11:53 |
| SDET-009 | Running Low uj beallitas mentese | Beallitas letrejon es kesobb latszik | expiration date valtoytatasaval elutnik ay osszes product |  | - |
| SDET-010 | Running Low meglevo beallitas modositas | Uj threshold ertek ervenyesul |  |  | - |
| SDET-011 | Running Low beallitas torlese | Beallitas eltunik a storagebol |  |  | - |
| SDET-012 | Invite Member ervenyes emaillel | Meghivo pending listaba kerul | sikeres | I | 11:57 |
| SDET-013 | Invite Member ervenytelen emaillel | Send Invite tiltott vagy validacios hiba | sikeres, de eltunnek a memberek es az invite amig nem lepunk be ujra | I | 12:02 |
| SDET-014 | Pending invite cancel | Pending meghivo eltunik a listabol | sikeres | I | 12:02 |
| SDET-015 | Member remove (owner joggal) | Kivalasztott tag eltunik members listabol | sikeres | I | 12:04 |
| SDET-016 | Storage atnevezes Detail oldalrol | Uj nev azonnal latszik fejlécben/listaban | sikeres | I | 12:05 |
| SDET-017 | Ures storage allapot | Empty state jelenik meg ertelmes uzenettel | sikeres | I | 12:06 |
| PROD-001 | Products oldal betoltese | Sajat es global products szekcio megjelenik | sikeres | I | 12:07 |
| PROD-002 | Product keresese talalattal | Lista szurve jelenik meg (debounce utan) | sikeres | I | 12:07 |
| PROD-003 | Product keresese nem talalattal | Ures allapot jelenik meg | sikeres | I | 12:07 |
| PROD-004 | Uj product letrehozasa ervenyes adatokkal | Product megjelenik a listaban | sikeres | I | 12:07 |
| PROD-005 | Uj product mentes ures nevvel | Save gomb tiltott, nincs letrehozas | sikeres | I | 12:09 |
| PROD-006 | Sajat product szerkesztese | Modositott adatok latszanak listaban | sikeres | I | 12:10 |
| PROD-007 | Sajat product torlese | Product eltunik listabol | sikeres | I | 13:03 |
| PROD-008 | Category filter alkalmazasa | Csak valasztott kategoriaba tartozo elemek latszanak | sikeres | I | 13:04 |
| SHOP-001 | Shopping list betoltese | Shopping itemek listazodnak helyesen | sikeres | I | 13:06 |
| SHOP-002 | Shopping item mennyiseg novelese (+) | Mennyiseg 1-gyel no | sikeres | I | 13:06 |
| SHOP-003 | Shopping item mennyiseg csokkentese (-) | Mennyiseg 1-gyel csokken, minimum vedett | sikeres | I | 13:06 |
| SHOP-004 | Shopping item done/complete | Tetel eltunik vagy complete allapotba kerul | sikeres | I | 13:07 |
| SHOP-005 | Shopping item torlese swipe actionnel | Tetel eltunik a listabol | sikeres | I | 13:08 |
| SHOP-006 | Shopping item hozzaadasa (+ sheet) | Uj tetel megjelenik listaban | sikeres | I | 13:09 |
| SHOP-007 | Shopping list pull-to-refresh | Lista friss adatokkal ujratoltodik | sikertelen, eltunik az osszes item |  | - |
| NOTI-001 | Notifications oldal betoltese | Expiring, running low es invite szekciok helyesen jelennek meg | sikeres, running low nem jelenik meg |  | - |
| NOTI-002 | Expiring item Add to List action | Tetel bekerul shopping listaba | nem jelenik meg |  | - |
| NOTI-003 | Expiring item torlese | Tetel eltunik az ertesitesi listabol | sikeres | I | 13:25 |
| NOTI-004 | Running low item Add to List action | Tetel bekerul shopping listaba vagy inaktiv, ha mar benne van | sikeres | I | 13:27 |
| NOTI-005 | Pending invite elfogadas/elutasitas | Statusz megfeleloen valtozik | sikeres | I | 13:27 |
| NOTI-006 | Notifications pull-to-refresh | Minden ertesitesi szekcio frissul | eltunnek a notificationok |  | - |
| PROF-001 | Profile oldal betoltese | Felhasznalo adatai (nev/email/avatar) megjelennek | sikeres | I | 13:28 |
| PROF-002 | Edit profile mentes ervenyes adatokkal | Modositott profil adatok megjelennek | sikeres | I | 13:29 |
| PROF-003 | Push notifications toggle BE | Jogosultsagkeres/engedelyezes folyamata lefut | sikeres | I | 13:29 |
| PROF-004 | Push notifications toggle KI | Beallitas mentodik, tovabbi ertesites kapcsolodik | sikeres | I | 13:30 |
| PROF-005 | Dark mode toggle valtas | Megjelenes azonnal valtozik es persistal | sikeres | I | 13:31 |
| PROF-006 | Sign out action | Kijelentkeztet es Auth oldalra navigal | sikeres | I | 13:31 |
| PROF-007 | Sign out utan ujrainditas | Session nelkul Auth oldal jelenik meg | sikeres | I | 13:32 |

## Osszegzes
- Osszes teszteset: 75
- Atment: [kitoltendo]
- Elbukott: [kitoltendo]
- Blokkolo hiba: [I/N]
- Megjegyzes: [kitoltendo]
