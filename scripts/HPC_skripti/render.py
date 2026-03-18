import bpy
import os
import time

JOBID = os.environ.get("PBS_JOBID")
start_time = time.time()

# Enable Cycles render engine
bpy.context.scene.render.engine = 'CYCLES'

# Load cycles preferences
cycles_prefs = bpy.context.preferences.addons["cycles"].preferences

# Refresh device list
cycles_prefs.get_devices()

# Print available devices
for device in cycles_prefs.devices:
    print(f"Device: {device.name}, Enabled: {device.use}")

# Set Blender to use GPU rendering
bpy.context.preferences.addons['cycles'].preferences.compute_device_type = 'CUDA'
bpy.context.scene.cycles.device = 'GPU'

scene = bpy.data.scenes['Scene']
obj =  scene.objects['SimulacijasVide']
if obj.modifiers.get("Fluid"):
    fluid_modifier = obj.modifiers["Fluid"]
    domain_settings = fluid_modifier.domain_settings
#    # Specify the cache directory (use an absolute path)
    my_cache_dir = os.path.abspath("./cash_" + JOBID)
    domain_settings.cache_directory = my_cache_dir
#    domain_settings.use_disk_cache = True  # Ensure disk cache is enabled
    print("Cache directory set to:", domain_settings.cache_directory)


bpy.context.scene.render.filepath = "./render_output_3/frame_"

bpy.ops.render.render(animation=True)  # Render animation

end_time = time.time()

print(f"Rendering time: {end_time - start_time} seconds")
