import numpy as np
import argparse
import pandas as pd
import os

#merges two files by a common sampleID column by performing a left join ie; displays both the merged and unmerged samples in the firs file (all rows in file1)
#Usage: python merge_files.py --manifest_file <> --extra_file <> -o <> 


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest_file", action="store", required=True)
    parser.add_argument("--extra_file", action="store", required=True)
    parser.add_argument("--outfile", "-o", action="store", required=True)
    args = parser.parse_args()

    #manifest = pd.read_csv(args.manifest_file,sep=" ")
    manifest = pd.read_csv(args.manifest_file,sep="\t")
    g = pd.read_csv(args.extra_file, sep="\t")

    final=pd.merge(manifest,g, on='sampleID',how='left') 

    final.to_csv(args.outfile,sep='\t',index=False)
