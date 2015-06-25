import sys
import os
from optparse import OptionParser

import collections

##frequency.py is used to calculate the number of calls made for each sample in a particular cohort (eg: is/lg , pvh/pmg , eppr)
#Usage:
#python frequency.py <call_file> <out_file>
#python frequency.py all_calls_40.csv epp_frequency.txt

def get_frequency(fn1=None):

        if not fn1:

                sys.stderr.write("Error: Supply a file name.\n")

                return None

        f=open(fn1)

        fh = f.readlines()
	sample_list=[]
        for line in fh:
		if not line.startswith("	sampleID"):
			
			text=line.rstrip()
			
			fields=text.split("\t")
			
			if fields[1].startswith("i"):
	
				sample_list.append(fields[1])

	f.close()

	return sample_list


def get_counts(fn1=None,fn2=None):
	l=get_frequency(fn1)	
	out_file=open(fn2,"w")

	count_dict=collections.Counter(l)
	
	print(count_dict.most_common(20))

	for i in count_dict.keys():

		
		out_file.write(i + "\t"+ str(count_dict[i])+"\n")

		
	out_file.close()


if __name__ == "__main__":
    parser = OptionParser()
    (options, args) = parser.parse_args()

    if len(args) != 2:
        sys.stderr.write("Specify Input and output files\n")
        parser.print_usage()
        sys.exit(1)

    get_counts(args[0],args[1])



