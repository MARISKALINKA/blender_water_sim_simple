# HPC.md

## 1. Kods darba izpildei: `run_blender.sh`

```bash
#!/bin/sh
#PBS -N blender
#PBS -q batch
#PBS -l walltime=12:00:00
#PBS -l nodes=1:ppn=16:gpus=1,feature=l40s,mem=16gb
#PBS -j oe
##PBS -t 1-100%50

module load blender/3.6.4-sg-test
cd $PBS_O_WORKDIR

blender --background ./Simulation_v1.blend --python bake.py
blender --background ./Simulation_v1.blend --python render.py
```

### Skripta skaidrojums

#### a. Shebang
```bash
#!/bin/sh
```
Norāda, ka skripts jāpalaiž ar POSIX `sh` čaulu.

#### b. Darba nosaukums
```bash
#PBS -N blender
```
Piešķir darba nosaukumu "blender".

#### c. Izpildes rinda
```bash
#PBS -q batch
```
Nosaka, ka darbs tiek izpildīts rindā *batch*.

#### d. Maksimālais izpildes laiks
```bash
#PBS -l walltime=12:00:00
```
Pieprasa 12 h maksimālo izpildes laiku.

#### e. Pieprasītie resursi
```bash
#PBS -l nodes=1:ppn=16:gpus=1,feature=l40s,mem=16gb
```
* `nodes=1` – viens mezgls
* `ppn=16` – 16 CPU kodoli
* `gpus=1` – viens GPU
* `feature=l40s` – jābūt L40s GPU mezglam
* `mem=16gb` – kopējā atmiņa

#### f. Apvienot STDOUT + STDERR
```bash
#PBS -j oe
```
Izvada visu vienā failā.

#### g. Komentēta job array rinda
```bash
##PBS -t 1-100%50
```
Ļautu palaist vairākus paralēlus darbus.

#### h. Ielādē Blender moduli
```bash
module load blender/3.6.4-sg-test
```

#### i. Pāriet uz iesniegšanas mapi
```bash
cd $PBS_O_WORKDIR
```

#### j. Bake process
```bash
blender --background ./Simulation_v1.blend --python bake.py
```

#### k. Renderēšana
```bash
blender --background ./Simulation_v1.blend --python render.py
```

---

## 2. Bake skripts: `bake.py`

```python
import bpy
import os
import time

start_time = time.time()
JOBID = os.environ.get("PBS_JOBID")

scene = bpy.data.scenes['Scene']
obj = scene.objects['SimulacijasVide']

if obj.modifiers.get("Fluid"):
    fluid_modifier = obj.modifiers["Fluid"]
    domain_settings = fluid_modifier.domain_settings
    my_cache_dir = os.path.abspath("./cash_" + JOBID)
    domain_settings.cache_directory = my_cache_dir
    print("Cache directory set to:", domain_settings.cache_directory)

with bpy.context.temp_override(scene=scene, active_object=obj):
    bpy.ops.fluid.bake_data()
    bpy.ops.fluid.bake_mesh()
    print("All baking steps completed successfully!")

end_time = time.time()
print(f"Baking time: {end_time - start_time} seconds")
```

### Skripta skaidrojums

#### a. Moduļu ielāde
* `bpy` – Blender API
* `os`, `time` – ceļi, taimeris

#### b. JOBID ielasīšana
Izmanto unikālu keša mapi.

#### c. Scenas un objekta izvēle
Piekļūst objektam ar Fluid modifikatoru.

#### d. Keša direktorija iestatīšana
Izveido keša mapi: `cash_<JOBID>`.

#### e. Bake process
Izpilda:
* `bake_data()` – pamata simulācija
* `bake_mesh()` – ģenerē mesh

#### f. Laika mērīšana
Izdrukā kopējo bake ilgumu.

---

## 3. Renderēšanas skripts

```python
import bpy
import os
import time

JOBID = os.environ.get("PBS_JOBID")
start_time = time.time()

bpy.context.scene.render.engine = 'CYCLES'
cycles_prefs = bpy.context.preferences.addons["cycles"].preferences
cycles_prefs.get_devices()

for device in cycles_prefs.devices:
    print(f"Device: {device.name}, Enabled: {device.use}")

bpy.context.preferences.addons['cycles'].preferences.compute_device_type = 'CUDA'
bpy.context.scene.cycles.device = 'GPU'

scene = bpy.data.scenes['Scene']
obj = scene.objects['SimulacijasVide']
if obj.modifiers.get("Fluid"):
    fluid_modifier = obj.modifiers["Fluid"]
    domain_settings = fluid_modifier.domain_settings
    my_cache_dir = os.path.abspath("./cash_" + JOBID)
    domain_settings.cache_directory = my_cache_dir
    print("Cache directory set to:", domain_settings.cache_directory)

bpy.context.scene.render.filepath = "./render_output_3/frame_"
bpy.ops.render.render(animation=True)

end_time = time.time()
print(f"Rendering time: {end_time - start_time} seconds")
```

### Skripta skaidrojums

#### a. Moduļu ielāde un JOBID
Sagatavo vidi un render taimeri.

#### b. Cycles aktivizēšana un GPU konfigurācija
Pārslēdz renderētāju uz Cycles un aktivizē CUDA.

#### c. GPU ierīču izdruka
Parāda pieejamos GPU HPC mezglā.

#### d. Keša direktorija izveide
Nodrošina unikālu kešu katram darbam.

#### e. Renderēšana
Renderē animāciju GPU režīmā.

#### f. Renderēšanas laiks
Izdrukā kopējo render ilgumu.

