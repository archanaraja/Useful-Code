from conifertools import ConiferPipeline, CallTable, CallFilterTemplate
import numpy as np
import argparse
import pandas as pd
import os

#Extract proband entries in the high-confidence sample list from epi4k cluster file and write out to a file to send Heather

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--call_file", action="store", required=True)
    parser.add_argument("--outfile", "-o", action="store", required=True)
    args = parser.parse_args()
    
    calls = CallTable(args.call_file)
    samples = pd.read_csv("/net/eichler/vol20/projects/epi4k/nobackups/araja/epi4k_exome/calling/pvh_pmg_pruned/tmp.txt", sep="\t")
    sample_list=samples["sampleID"].tolist()
    chrom_list=samples["chromosome"].tolist()
    start_list=samples["start"].tolist()
    stop_list=samples["stop"].tolist()

    
    calls.calls["rel"] = map(lambda x: x[-1], calls.calls.sampleID.values)
    calls.calls["inheritance"]="denovo"

    calls=calls.filter(lambda x: x["sampleID"] in sample_list).\
		filter(lambda x: x["rel"] == "1").\
		filter(lambda x: x["chromosome"] in chrom_list).\
		filter(lambda x: x["start"] in start_list).\
		filter(lambda  x:x["stop"] in stop_list) 

    calls.save(args.outfile,index=False)
