import bpy
import os
import time

start_time = time.time()
JOBID = os.environ.get("PBS_JOBID")

scene = bpy.data.scenes['Scene']

obj =  scene.objects['SimulacijasVide']

if obj.modifiers.get("Fluid"):
   fluid_modifier = obj.modifiers["Fluid"]
   domain_settings = fluid_modifier.domain_settings
    
   # Specify the cache directory (use an absolute path)
   my_cache_dir = os.path.abspath("./cash_" + JOBID)
   domain_settings.cache_directory = my_cache_dir
    
   print("Cache directory set to:", domain_settings.cache_directory)


#with bpy.context.temp_override(scene=scene, active_object=obj):
#    bpy.ops.fluid.free_all() # if you'd like to free existing bakes first

with bpy.context.temp_override(scene=scene, active_object=obj):
    
    # Bake base simulation (Mandatory first step)
    bpy.ops.fluid.bake_data()

    # Bake mesh
    bpy.ops.fluid.bake_mesh()

    # Bake noise (for smoke/fire simulations)
    # bpy.ops.fluid.bake_noise()

    # Bake guiding (if using fluid guiding)
    # bpy.ops.fluid.bake_guiding()

    # Bake particles (for splashes, foam, bubbles)
    # bpy.ops.fluid.bake_particles()

    print("All baking steps completed successfully!")

end_time = time.time()

print(f"Baking time: {end_time - start_time} seconds")
