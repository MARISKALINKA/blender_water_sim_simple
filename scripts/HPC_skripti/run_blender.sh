#!/bin/sh
#PBS -N blender
#PBS -q batch
#PBS -l walltime=12:00:00
#PBS -l nodes=1:ppn=16:gpus=1,feature=l40s,mem=16gb
#PBS -j oe
##PBS -t 1-100%50

# load blender environment
module load blender/3.6.4-sg-test

# change directory to the job submission directory
cd $PBS_O_WORKDIR

# run simulation - Bake All
blender --background ./Simulation_v1.blend --python bake.py

# run rendering
blender --background ./Simulation_v1.blend --python render.py

# blender --background test.blend -o frame_###.jpg --threads 2 -f $PBS_ARRAYID
