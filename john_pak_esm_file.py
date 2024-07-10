#!/bin/env python3 
# this was originally written by John Pak

import torch
import esm

torch.hub.set_dir("/hpc/apps/anaconda/2023.03/envs/ESMFold2")

model = esm.pretrained.esmfold_v1()
model = model.eval().cuda()

import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument("--sequence", type=str, help="Sequence string")
parser.add_argument("--output_dir", type=str, help="Output directory path")
args = parser.parse_args()

sequence = args.sequence
output_dir = args.output_dir

# Create the output directory if it doesn't exist
os.makedirs(output_dir, exist_ok=True)

# Use the output_dir to specify where you save the generated files
# For example:
output_file_path = os.path.join(output_dir, "output.txt")
with open(output_file_path, "w") as output_file:
    output_file.write("Your output data")

# Optionally, uncomment to set a chunk size for axial attention. This can help reduce memory.
# Lower sizes will have lower memory requirements at the cost of increased speed.
# model.set_chunk_size(32)

# Multimer prediction can be done with chains separated by ':'

with torch.no_grad():
    output = model.infer_pdb(sequence)

with open("result.pdb", "w") as f:
    f.write(output)

import biotite.structure.io as bsio
struct = bsio.load_structure("result.pdb", extra_fields=["b_factor"])
print(struct.b_factor.mean())  # this will be the pLDDT
# 88.3
