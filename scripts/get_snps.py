import sys
import os
from optparse import OptionParser

###This script extracts snps for conifer predicted CNVs for the appropriate sampleID
##Usage:
###python get_snps.py <in_file> <out_file>
### python get_snps.py tmp_conf_penncnv_high_conf.txt high_confidence_denovos_withsnps.txt

def get_sample_genotypes(fn1=None,fn2=None):

        out_file=open(fn2,"w")
	out_file.write("chr"+"\t"+"start"+"\t"+"stop"+"\t"+"familyID"+"\t"+"Penn_chr"+ "\t"+"Penn_start"+"\t"+"Penn_stop"+"\t"+"sampleID,number_snps"+"\t"+"bases_overlap"+"\n")

        if not fn1:

                sys.stderr.write("Error: Supply a file name.\n")

                return None

        f=open(fn1)

        fh = f.readlines()

        for line in fh:
               
        	text=line.rstrip()
                fields = text.split("\t")

		fam_id=fields[3]

		pro_id =fields[7].split(",")[0]

		if pro_id.endswith(fam_id+"1"):
			out_file.write(line)

		 
		else :

			print fam_id +"\t" +fields[7]	

		

	f.close()
	out_file.close()

def get_sample_genotypes_names(fn1=None,fn2=None):

        out_file=open(fn2,"w")
        out_file.write("chr"+"\t"+"start"+"\t"+"stop"+"\t"+"familyID"+"\t"+"Penn_chr"+ "\t"+"Penn_start"+"\t"+"Penn_stop"+"\t"+"sampleID,number_snps"+"\t"+"bases_overlap"+"\n")

        if not fn1:

                sys.stderr.write("Error: Supply a file name.\n")

                return None

        f=open(fn1)

        fh = f.readlines()

        for line in fh:

                text=line.rstrip()
                fields = text.split("\t")

                fam_id=fields[3]

                pro_id =fields[7].split(",")[0]

                if fam_id==pro_id:
                        out_file.write(line)


                else :

                        print fam_id +"\t" +fields[7]



        f.close()
        out_file.close()



if __name__ == "__main__":
    parser = OptionParser()
    (options, args) = parser.parse_args()

    if len(args) != 2:
        sys.stderr.write("Specify Input and outpute files\n")
        parser.print_usage()
        sys.exit(1)

    #get_sample_genotypes(args[0],args[1])
###If you have the exact sample id in columns 4 and 8 uncomment below

    get_sample_genotypes_names(args[0],args[1])

