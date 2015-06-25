from conifertools import ConiferPipeline, CallTable, CallFilterTemplate
import numpy as np
import argparse
import pandas as pd
import os

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--call_file", action="store", required=True)
    parser.add_argument("--outfile", "-o", action="store", required=True)
    args = parser.parse_args()
    
    calls=CallTable(args.call_file)
    samples = pd.read_csv("/net/eichler/vol20/projects/epi4k/nobackups/araja/epi4k_exome/xhmm/DATA/conifer_xhmm_overlap_epp.bed", sep="\t")
    calls.calls = pd.merge(samples,calls.calls)
    calls.save(args.outfile)
