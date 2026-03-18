# 💧 Blender ūdens simulācijas projekts
## Studentu soli-pa-solim ceļvedis (Git + Blender)

**Video: Projekta ievads**  
https://img.youtube.com/vi/YOUTUBE_ID_00/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_00)

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

# 1. Instalējiet Git (obligāti)

**Video: Kā uzinstalēt Git**  
https://img.youtube.com/vi/YOUTUBE_ID_01/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_01)

## Windows  
https://git-scm.com/download/win

## macOS
```
xcode-select --install
```

## Linux
```
sudo apt install git
```

Pārbaudiet:
```
git --version
```

---

# 2. Paņemiet projektu no GitHub ar Git

**Video: Klonēšana un atjaunināšana**  
https://img.youtube.com/vi/YOUTUBE_ID_02/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_02)

## 2.1 Atveriet Git Bash / Terminal  
## 2.2 Pārejiet uz mapi
```
cd Documents
```

## 2.3 Klonējiet projektu
```
git clone https://github.com/___________/blender-water-sim.git
```

## 2.4 Atjauniniet projektu
```
cd blender-water-sim
git pull
```

---

# 3. Instalējiet Blender

**Video: Blender instalācija**  
https://img.youtube.com/vi/YOUTUBE_ID_03/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_03)

Lejupielāde:  
https://www.blender.org/download/

---

# 4. Atveriet projektu Blender programmā

**Video: Kā atvērt projektu Blender vidē**  
https://img.youtube.com/vi/YOUTUBE_ID_04/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_04)

## 4.1 Palaidiet Blender  
## 4.2 Izvēlieties **Scripting**  
## 4.3 Atveriet skriptu:
```
scripts/create_scene.py
```

## 4.4 Nospiediet **Run Script**

---

# 5. Palaidiet ūdens simulāciju (BAKE)

**Video: Bake Liquid simulācija**  
https://img.youtube.com/vi/YOUTUBE_ID_05/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_05)

Soļi:
1. Atlasiet **FluidDomain**  
2. Physics Properties → Fluid  
3. Nospiediet **Bake All**  

---

# 6. Parametru maiņa

🎥 **Video: Parametru maiņa ar params.json**  
https://img.youtube.com/vi/YOUTUBE_ID_06/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_06)

Faili:
```
scripts/params.default.json
```

Mainiet:
1. Kopējiet → `params.json`  
2. Rediģējiet

---

# 7. Kur mācīties Blender

**Video: Blender pamati**  
https://img.youtube.com/vi/YOUTUBE_ID_07/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_07)

Dokumentācija:  
https://docs.blender.org/manual/en/latest/

---

# 9. Biežākās problēmas

**Video: Problēmu risināšana**  
https://img.youtube.com/vi/YOUTUBE_ID_09/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_09)

---

# Veiksmi darbā un eksperimentēšanā ar Blender!
Materiāla sagatavošanā izmantots AI palīdzība
