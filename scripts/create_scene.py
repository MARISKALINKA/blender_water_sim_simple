import bpy
import bmesh
import math
import os

PARAMS = {
    "frame_start": 1,
    "frame_end": 250,
    "cache_directory": r"C:\Temp\blender_fluid_cache",
    "render_engine": "CYCLES",

    "tank_location": (0.0, 0.0, 1.5),
    "tank_scale": (1.5, 1.0, 1.5),
    "tank_wall_thickness": 0.12,

    "pipe_vertices": 64,
    "pipe_wall_thickness": 0.05,

    "inlet_pipe_location": (-2.2, 0.0, 2.4),
    "inlet_pipe_radius": 0.18,
    "inlet_pipe_length": 2.0,
    "inlet_pipe_rotation_deg": (0.0, 90.0, 0.0),

    "outlet_pipe_location": (2.2, 0.0, 0.8),
    "outlet_pipe_radius": 0.16,
    "outlet_pipe_length": 2.0,
    "outlet_pipe_rotation_deg": (0.0, 90.0, 0.0),

    "domain_location": (0.0, 0.0, 1.6),
    "domain_scale": (3.6, 1.9, 2.2),
    "domain_resolution": 160,
    "timesteps_max": 6,
    "mesh_scale": 2,

    "viscosity_base": 1,
    "viscosity_exponent": 6,
    "use_diffusion": False,

    # svarīgākais labojums
    "inflow_location": (-2.95, 0.0, 2.4),
    "inflow_radius": 0.05,
    "inflow_length": 0.12,
    "inflow_rotation_deg": (0.0, 90.0, 0.0),
    "inflow_velocity_xyz": (3.0, 0.0, 0.0),
    "inflow_sampling_substeps": 4,

    "outflow_location": (2.85, 0.0, 0.8),
    "outflow_scale": (0.10, 0.10, 0.10),

    "glass_color": (0.92, 0.97, 1.0, 1.0),
    "glass_roughness": 0.02,
    "glass_ior": 1.45,

    "camera_location": (8.0, -8.0, 5.0),
    "camera_rotation_deg": (65.0, 0.0, 45.0),
    "sun_location": (4.0, -4.0, 8.0),
    "sun_energy": 3.0,
}

# =========================================================
# CLEAN SCENE
# =========================================================

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
scene.frame_start = PARAMS["frame_start"]
scene.frame_end = PARAMS["frame_end"]
scene.render.engine = PARAMS["render_engine"]

# =========================================================
# HELPERS
# =========================================================

def deg_to_rad(rot_deg):
    return tuple(math.radians(v) for v in rot_deg)

def set_active(obj):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

def apply_scale(obj):
    set_active(obj)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

def recalc_normals(obj):
    set_active(obj)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode='OBJECT')

def clear_materials(obj):
    if hasattr(obj.data, "materials"):
        obj.data.materials.clear()

def add_cube(name, location, scale):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    return obj

def add_fluid_modifier(obj):
    return obj.modifiers.new(name="Fluid", type='FLUID')

def add_open_box(name, location, scale, wall_thickness):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    apply_scale(obj)

    set_active(obj)
    bpy.ops.object.mode_set(mode='EDIT')
    bm = bmesh.from_edit_mesh(obj.data)
    bm.faces.ensure_lookup_table()
    top_face = max(bm.faces, key=lambda f: f.calc_center_median().z)
    for f in bm.faces:
        f.select = False
    top_face.select = True
    bmesh.update_edit_mesh(obj.data)
    bpy.ops.mesh.delete(type='FACE')
    bpy.ops.object.mode_set(mode='OBJECT')

    solid = obj.modifiers.new(name="Solidify", type='SOLIDIFY')
    solid.thickness = wall_thickness
    solid.offset = -1.0
    set_active(obj)
    bpy.ops.object.modifier_apply(modifier=solid.name)

    recalc_normals(obj)
    return obj

def add_hollow_pipe(name, location, radius, length, rotation, wall_thickness, vertices):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=length,
        location=location,
        rotation=rotation,
        end_fill_type='NOTHING'
    )
    obj = bpy.context.active_object
    obj.name = name

    solid = obj.modifiers.new(name="Solidify", type='SOLIDIFY')
    solid.thickness = wall_thickness
    solid.offset = -1.0
    set_active(obj)
    bpy.ops.object.modifier_apply(modifier=solid.name)

    apply_scale(obj)
    recalc_normals(obj)
    return obj

def add_closed_cylinder(name, location, radius, length, rotation, vertices=24):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=length,
        location=location,
        rotation=rotation,
        end_fill_type='NGON'
    )
    obj = bpy.context.active_object
    obj.name = name
    apply_scale(obj)
    recalc_normals(obj)
    return obj

def add_cutter_cylinder(name, location, radius, length, rotation, vertices=48):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=length,
        location=location,
        rotation=rotation,
        end_fill_type='NGON'
    )
    obj = bpy.context.active_object
    obj.name = name
    apply_scale(obj)
    return obj

def boolean_difference(target_obj, cutter_obj):
    mod = target_obj.modifiers.new(name=f"Bool_{cutter_obj.name}", type='BOOLEAN')
    mod.operation = 'DIFFERENCE'
    mod.solver = 'EXACT'
    mod.object = cutter_obj
    set_active(target_obj)
    bpy.ops.object.modifier_apply(modifier=mod.name)

def make_glass_material(name, color, roughness, ior):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["IOR"].default_value = ior
        if "Transmission Weight" in bsdf.inputs:
            bsdf.inputs["Transmission Weight"].default_value = 1.0
        elif "Transmission" in bsdf.inputs:
            bsdf.inputs["Transmission"].default_value = 1.0
    mat.blend_method = 'BLEND'
    mat.shadow_method = 'NONE'
    return mat

# =========================================================
# MATERIAL
# =========================================================

glass_mat = make_glass_material(
    "GlassMaterial",
    PARAMS["glass_color"],
    PARAMS["glass_roughness"],
    PARAMS["glass_ior"]
)

# =========================================================
# GEOMETRY
# =========================================================

tank_outer = add_open_box(
    "TankOuter",
    PARAMS["tank_location"],
    PARAMS["tank_scale"],
    PARAMS["tank_wall_thickness"]
)

inlet_pipe = add_hollow_pipe(
    "InletPipe",
    PARAMS["inlet_pipe_location"],
    PARAMS["inlet_pipe_radius"],
    PARAMS["inlet_pipe_length"],
    deg_to_rad(PARAMS["inlet_pipe_rotation_deg"]),
    PARAMS["pipe_wall_thickness"],
    PARAMS["pipe_vertices"]
)

outlet_pipe = add_hollow_pipe(
    "OutletPipe",
    PARAMS["outlet_pipe_location"],
    PARAMS["outlet_pipe_radius"],
    PARAMS["outlet_pipe_length"],
    deg_to_rad(PARAMS["outlet_pipe_rotation_deg"]),
    PARAMS["pipe_wall_thickness"],
    PARAMS["pipe_vertices"]
)

# atveres tvertnē
inlet_cutter = add_cutter_cylinder(
    "InletCutter",
    PARAMS["inlet_pipe_location"],
    PARAMS["inlet_pipe_radius"] - 0.01,
    PARAMS["inlet_pipe_length"] + 0.20,
    deg_to_rad(PARAMS["inlet_pipe_rotation_deg"]),
    PARAMS["pipe_vertices"]
)

outlet_cutter = add_cutter_cylinder(
    "OutletCutter",
    PARAMS["outlet_pipe_location"],
    PARAMS["outlet_pipe_radius"] - 0.01,
    PARAMS["outlet_pipe_length"] + 0.20,
    deg_to_rad(PARAMS["outlet_pipe_rotation_deg"]),
    PARAMS["pipe_vertices"]
)

boolean_difference(tank_outer, inlet_cutter)
boolean_difference(tank_outer, outlet_cutter)
recalc_normals(tank_outer)

inlet_cutter.hide_set(True)
outlet_cutter.hide_set(True)
inlet_cutter.hide_render = True
outlet_cutter.hide_render = True

# materiāli
clear_materials(tank_outer)
tank_outer.data.materials.append(glass_mat)

clear_materials(inlet_pipe)
inlet_pipe.data.materials.append(glass_mat)

clear_materials(outlet_pipe)
outlet_pipe.data.materials.append(glass_mat)

# =========================================================
# COLLISIONS
# =========================================================

for collider in [tank_outer, inlet_pipe, outlet_pipe]:
    mod = add_fluid_modifier(collider)
    mod.fluid_type = 'EFFECTOR'
    mod.effector_settings.effector_type = 'COLLISION'
    if hasattr(mod.effector_settings, "surface_distance"):
        mod.effector_settings.surface_distance = 0.015
    collider.show_transparent = True

# =========================================================
# DOMAIN
# =========================================================

domain = add_cube("FluidDomain", PARAMS["domain_location"], PARAMS["domain_scale"])
domain.display_type = 'WIRE'
apply_scale(domain)

domain_mod = add_fluid_modifier(domain)
domain_mod.fluid_type = 'DOMAIN'
dom = domain_mod.domain_settings
dom.domain_type = 'LIQUID'
dom.resolution_max = PARAMS["domain_resolution"]
dom.timesteps_max = PARAMS["timesteps_max"]
dom.use_mesh = True
dom.mesh_scale = PARAMS["mesh_scale"]
dom.cache_frame_start = PARAMS["frame_start"]
dom.cache_frame_end = PARAMS["frame_end"]
dom.cache_type = 'MODULAR'
dom.cache_directory = PARAMS["cache_directory"]
dom.viscosity_base = PARAMS["viscosity_base"]
dom.viscosity_exponent = PARAMS["viscosity_exponent"]
dom.use_diffusion = PARAMS["use_diffusion"]

os.makedirs(PARAMS["cache_directory"], exist_ok=True)

# =========================================================
# INFLOW
# =========================================================

inflow = add_closed_cylinder(
    "WaterInflow",
    PARAMS["inflow_location"],
    PARAMS["inflow_radius"],
    PARAMS["inflow_length"],
    deg_to_rad(PARAMS["inflow_rotation_deg"]),
    vertices=24
)

inflow_mod = add_fluid_modifier(inflow)
inflow_mod.fluid_type = 'FLOW'
flow = inflow_mod.flow_settings
flow.flow_type = 'LIQUID'
flow.flow_behavior = 'INFLOW'
flow.flow_source = 'MESH'

if hasattr(flow, "use_plane_init"):
    flow.use_plane_init = False

flow.use_initial_velocity = True
flow.velocity_coord = PARAMS["inflow_velocity_xyz"]
flow.velocity_normal = 0.0
flow.velocity_factor = 0.0

if hasattr(flow, "sampling_substeps"):
    flow.sampling_substeps = PARAMS["inflow_sampling_substeps"]
elif hasattr(flow, "subframes"):
    flow.subframes = PARAMS["inflow_sampling_substeps"]

# =========================================================
# OUTFLOW
# =========================================================

outflow = add_cube("WaterOutflow", PARAMS["outflow_location"], PARAMS["outflow_scale"])
apply_scale(outflow)
outflow.display_type = 'WIRE'

outflow_mod = add_fluid_modifier(outflow)
outflow_mod.fluid_type = 'FLOW'
outf = outflow_mod.flow_settings
outf.flow_type = 'LIQUID'
outf.flow_behavior = 'OUTFLOW'
outf.flow_source = 'MESH'

# =========================================================
# CAMERA / LIGHT
# =========================================================

inflow.hide_render = True
outflow.hide_render = True

bpy.ops.object.camera_add(
    location=PARAMS["camera_location"],
    rotation=deg_to_rad(PARAMS["camera_rotation_deg"])
)
scene.camera = bpy.context.active_object

bpy.ops.object.light_add(type='SUN', location=PARAMS["sun_location"])
sun = bpy.context.active_object
sun.data.energy = PARAMS["sun_energy"]

print("Scene created.")
print("Bake secība: FluidDomain > Bake Data > Bake Mesh.")