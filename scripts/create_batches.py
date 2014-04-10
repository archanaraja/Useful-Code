#Create batches from samples for conifer calling
##Usage:
##python create_batches.py <infile> <outfile>

def create_batches(fn=None,fn2=None):
	file=open(fn2,"w")

        if not fn:

                sys.stderr.write("Error: Supply a file name.\n")

                return None

        f=open(fn)

        fh = f.readlines()
	count=0

	counter=1
        for line in fh:
		count=count+1
		text=line.rstrip()
                fields = text.split(",")
		if not count==10:
	
			file.write(fields[0]+","+"batch"+str(counter)+"\n")

		if count ==10:

			count=0
			counter=counter+1
			file.write(fields[0]+","+"batch"+str(counter)+"\n")


	f.close()

	file.close()



if __name__ == "__main__":
    parser = OptionParser()
    (options, args) = parser.parse_args()

    if len(args) != 2:
        sys.stderr.write("Specify Input and outpute files\n")
        parser.print_usage()
        sys.exit(1)

    create_batches(args[0],args[1])
			
