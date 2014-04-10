import sys
import os
from optparse import OptionParser


#This script extracts sample names for family ids from high-conifdence cnv trio plots
##Usage:
##python get_sample_names.py  

def get_sample_names(fn1="/net/eichler/vol20/projects/epi4k/nobackups/araja/epi4k_manifest/samples_list_for_plotting.txt"):

        if not fn1:

                sys.stderr.write("Error: Supply a file name.\n")

                return None

        f=open(fn1)

        fh = f.readlines()
        d={}
        for line in fh:
                if not line.startswith("studyID"):

                        text=line.rstrip()
                        #print text
                        fields=text.split("\t")
                        
                        

                        id= fields[1]

			if not id in d.keys():

				d[id]=[fields[3]]


			else:

				d[id]+=[fields[3]]

        f.close()

        return d

def join_files(fn1="missing_parents.bed",fn2="tmp.txt"):
	d=get_sample_names("/net/eichler/vol20/projects/epi4k/nobackups/araja/epi4k_manifest/samples_list_for_plotting.txt")
	

	out_file=open(fn2,"w")
	out_file.write("chromosome"+"\t"+"start"+"\t"+"stop"+"\t"+"familyID"+"\t"+"inheritance"+"\t"+"sampleID"+"\n")
	f=open(fn1,"r")

	fh=f.readlines()

	for line in fh:

		if not line.startswith("chromosome"):

			text=line.rstrip()
			fields=text.split("\t")

			if fields[3] in d.keys():

				for i in d[fields[3]]:

					if i.endswith ("1"):

						out_file.write(fields[0]+"\t"+fields[1]+"\t"+fields[2]+"\t"+fields[3]+"\t"+fields[4]+"\t"+ i+"\n")

	f.close()
	out_file.close()

				 

if __name__ == "__main__":

	join_files()
