# 💧 Blender ūdens simulācijas projekts
## Studentu soli-pa-solim ceļvedis (Git + Blender)

🎥 **Video: Projekta ievads**  
https://img.youtube.com/vi/YOUTUBE_ID_00/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_00)

Šis projekts palīdzēs Jums:
- Iemācīties Git pamatus
- Paņemt projektu no GitHub savā datorā
- Instalēt un lietot Blender
- Palaist Python skriptus Blender vidē
- Izveidot ūdens simulāciju ar Mantaflow
- Sagatavot materiālus iesniegšanai

**Svarīgi:** Jūs strādājat tikai lokāli. Nekas nav jāpusho uz GitHub.

---
# 🟦 1. Instalējiet Git

🎥 **Video: Git instalācija**  
https://img.youtube.com/vi/YOUTUBE_ID_01/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_01)

Windows: https://git-scm.com/download/win

macOS:
```
xcode-select --install
```
Linux:
```
sudo apt install git
```

Pārbaudiet:
```
git --version
```

---
# 🟩 2. Paņemiet projektu no GitHub

🎥 **Video: Kā klonēt projektu**  
https://img.youtube.com/vi/YOUTUBE_ID_02/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_02)

```
cd Documents
git clone https://github.com/<skolotajs>/blender-water-sim.git
```

Atjaunināšana:
```
cd blender-water-sim
git pull
```

---
# 🟧 3. Instalējiet Blender

🎥 **Video: Blender instalēšana**  
https://img.youtube.com/vi/YOUTUBE_ID_03/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_03)

Oficiālā lapa: https://www.blender.org/download/

---
# 🟨 4. Atveriet projektu Blender

🎥 **Video: Kā atvērt projektu Blender**  
https://img.youtube.com/vi/YOUTUBE_ID_04/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_04)

1. Atveriet Blender
2. Augšā izvēlieties **Scripting**
3. Atveriet skriptu:
```
scripts/create_scene.py
```
4. Spiediet **Run Script**

---
# 🟫 5. Palaidiet ūdens simulāciju (Bake)

🎥 **Video: Bake Liquid simulācija**  
https://img.youtube.com/vi/YOUTUBE_ID_05/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_05)

1. Atlasiet **FluidDomain** objektu 
2. Physics Properties → Fluid → Liquid
3. Spiediet **Bake All**

---
# 🟥 6. Parametru maiņa

🎥 **Video: Parametru rediģēšana**  
https://img.youtube.com/vi/YOUTUBE_ID_06/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_06)

Parametru fails:
```
scripts/params.default.json
```

Mainīšanai:
1. Nokopējiet uz `params.json`
2. Rediģējiet vērtības

---
# 🟦 7. Kur mācīties Blender

🎥 **Video: Blender pamati**  
https://img.youtube.com/vi/YOUTUBE_ID_07/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_07)

https://docs.blender.org/manual/en/latest/

---
# 8. Biežākās problēmas

🎥 **Video: Problēmu risināšana**  
https://img.youtube.com/vi/YOUTUBE_ID_09/hqdefault.jpg](https://www.youtube.com/watch?v=YOUTUBE_ID_09)

---

