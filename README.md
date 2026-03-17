# 💧 Blender ūdens simulācijas projekts  
## Studentu soli-pa-solim ceļvedis (Git + Blender)

Šis projekts palīdzēs Jums:
- Iemācīties pamata Git darbības (klonēšana, atjaunināšana)
- Paņemt projektu no GitHub savā datorā
- Instalēt un lietot Blender programmu
- Palaist Python skriptus Blender vidē
- Izveidot ūdens (liquid) simulāciju ar Mantaflow
- Sagatavot rezultātus iesniegšanai

**Svarīgi:** Jums NAV jāaugšupielādē darbs atpakaļ GitHub.  
Jūs strādājat tikai savā datorā.

---

# 🟦 1. Instalējiet Git (obligāti)

## Windows
Lejupielādēt un instalēt:  
https://git-scm.com/download/win

## macOS
Git bieži jau ir. Ja nav:
```
xcode-select --install
```

## Linux
```
sudo apt install git
```

Pārbaudiet, vai Git darbojas:
```
git --version
```

---

# 🟩 2. Paņemiet projektu no GitHub ar Git

## 2.1 Atveriet Git Bash / Terminal
- Windows → Git Bash  
- Linux/Mac → Terminal

## 2.2 Pārejiet mapē, kur vēlaties saglabāt projektu
Piemēram:
```
cd Documents
```

## 2.3 Klonējiet projektu
```
git clone https://github.com/<skolotajs>/blender-water-sim.git
```

Tas izveidos mapi:
```
blender-water-sim/
```

## 2.4 Ja skolotājs publicē izmaiņas
Projektu var atjaunināt:
```
cd blender-water-sim
git pull
```

**Jūs neizmantosiet: `git add`, `git commit`, `git push`.**  
Šis ir vienvirziena darbs: **GitHub → Jūsu dators**.

---

# 🟧 3. Instalējiet Blender

Lejupielādēt no oficiālās lapas:  
https://www.blender.org/download/

Rekomendētās versijas:
- Blender **4.x**
- Blender **3.6 LTS**

Instalējiet ar noklusējuma iestatījumiem.

---

# 🟨 4. Atveriet projektu Blender programmā

## 4.1 Palaidiet Blender
## 4.2 Izvēlieties darba vidi **Scripting**
Augšējā izvēlnē → **Scripting**

## 4.3 Atveriet skriptu
Blender → Text Editor → **Open**

Atveriet:
```
blender-water-sim/scripts/create_scene.py
```

## 4.4 Nospiediet **Run Script**
Blender automātiski izveidos:
- stikla tvertni
- ieplūdes un izplūdes caurules
- šķidruma domēnu
- ūdens avotu un izplūdi
- kameru
- gaismu

---

# 🟫 5. Palaidiet ūdens simulāciju (BAKE)

1. Atlasiet objektu **FluidDomain**
2. Labajā panelī atveriet **Physics Properties**
3. Sadaļā **Fluid → Liquid → Bake**  
4. Spiediet **Bake All**

Bake var ilgt 1–10 minūtes atkarībā no datora.

Pēc bake parādīsies ūdens simulācija.

---

# 🟥 6. Parametru maiņa (pēc izvēles)

Projektā ir šāds fails:
```
scripts/params.default.json
```

Ja vēlaties mainīt parametrus (ūdens ātrumu, tvertnes izmērus, viskozitāti u.c.):

1. Nokopējiet `params.default.json` → `params.json` repozitorija saknē
2. Rediģējiet `params.json`

Skripts automātiski nolasīs jaunos parametrus.

---

# 🟦 7. Kur mācīties Blender

## Oficiālā dokumentācija
https://docs.blender.org/manual/en/latest/

## Blender Python API
https://docs.blender.org/api/current/

## Video pamācības
Blender Fundamentals (oficiālais kurss):  
https://www.youtube.com/playlist?list=PLa1F2ddGya_8acrgoQr1fTeIuQtkSd1Z9

Mantaflow ūdens simulācijas piemēri:  
https://www.youtube.com/results?search_query=blender+liquid+simulation

---

# 🟩 8. Ko Jums jāiesniedz skolotājam

Jums nav jāizsūta GitHub kods. Jāiesniedz tikai lokālais rezultāts:

✔ īss apraksts, kādi parametri tika mainīti  
✔ attēli (PNG/JPG) ar simulācijas rezultātu  
✔ īss video (MP4) ar animāciju  
✔ salīdzinājums, ja bake veikts vairākas reizes

---

# 🟪 9. Biežākās problēmas

### ❗ Skripts nestrādā
- pārbaudiet Blender versiju
- pārbaudiet faila ceļu
- restartējiet Blender

### ❗ Ļoti lēna simulācija
- samaziniet `domain_resolution`
- aizveriet citas programmas

### ❗ Nekas neparādās pēc Bake
- pārbaudiet, vai inflow ir domēna iekšpusē
- izdzēsiet `fluid_cache/` mapi

---

# 🎉 Veiksmi darbā un eksperimentēšanā ar Blender!
