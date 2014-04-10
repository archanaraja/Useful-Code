import csv
import sys
import os
from optparse import OptionParser

##compare_lists.py is used to compare two lists to check for missing samples
##Usage:
##python compare_lists.py <file1> <file2> >outfile.txt


def compare(fn1="None",fn2="None"):
	l1 = list(csv.reader(open(fn1)))
	
	l2= list(csv.reader(open(fn2)))

	for i in l1:

		if not i in l2:

			print "".join(i)



if __name__ == "__main__":
    parser = OptionParser()
    (options, args) = parser.parse_args()

    if len(args) != 2:
        sys.stderr.write("Specify two files to compare\n")
        parser.print_usage()
        sys.exit(1)

    compare(args[0],args[1])




