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

