# 🔧 Skripta koda skaidrojums (saprotams iesācējiem)

Šis dokuments paskaidro, ko dara Blender Python skripts katrā tā posmā.

---
## 1. PARAMS — tvertnes, cauruļu un ūdens iestatījumi

Šis ir "projektu uzstādījumu panelis", kur var droši mainīt vērtības:
```python
"tank_scale": (1.5, 1.0, 1.5),
"tank_wall_thickness": 0.10,
"inlet_pipe_radius": 0.18,
"outlet_pipe_radius": 0.16,
"inflow_velocity_xyz": (20.0, 0.0, 0.0),
```

### Tvertne
- `tank_scale` → izmēri
- `tank_location` → novietojums
- `tank_wall_thickness` → sienu biezums

### Caurules
- `inlet_pipe_radius` / `outlet_pipe_radius` → caurules resnums
- `inlet_pipe_length` / `outlet_pipe_length` → garums
- `pipe_wall_thickness` → sienu biezums

### Ūdens
- `inflow_velocity_xyz` → ūdens ātrums
- `inflow_size` → infow laukums
- `domain_resolution` → simulācijas kvalitāte

---
## 2. CLEAN SCENE — notīra Blender skatuvi

- Izdzēš visus objektus
- Iestata metrisko sistēmu
- Iestata animācijas kadrus

Katru reizi sāk no nulles.

---
## 3. HELPERS — palīgfunkcijas

Nelielas funkcijas, kas palīdz skriptam:
- veidot objektus (`add_cube`, `add_plane`)
- labot mērogu (`apply_scale`)
- izgriezt caurumus (`boolean_difference`)

---
## 4. TANK — tika uzbūvēta stikla tvertne

`add_open_box()` uztaisa tvertni bez vāka un ar noteiktu sienu biezumu.

---
## 5. PIPES — dobas caurules

Izveido **ieplūdes** un **izplūdes** caurules.

---
## 6. CUT OPENINGS — izgriež caurumus sienās

Izmanto "cutter" cilindrus, lai izveidotu precīzas atveres tvertnē.

---
## 7. MATERIALS — stikla materiāls

Pievieno caurspīdīgu materiālu ar IOR 1.45.

---
## 8. FLUID COLLISIONS — ūdens saskarsmes objekti

Tvertne un caurules kļūst par "Collision" objektiem.

---
## 9. DOMAIN — ūdens simulācijas pamats

Iestata:
- kvalitāti (`resolution`)
- viskozitāti
- cache mapi

---
## 10. INFLOW — ūdens avots

Ūdens parādās no `WaterInflow` plakanes.

---
## 11. OUTFLOW — ūdens izvadīšana

Ūdens pazūd pie `WaterOutflow`.

---
## 12. CAMERA / LIGHT — kamera un saules gaisma

Automātiski uzstādīta aina renderēšanai.

---
## 13. Beigu paziņojumi

Skripts informē, ka aina ir gatava Bake.
