#!/bin/bash
module load java/7u17
# If you adapt this script for your own use, you will need to set these two variables based on your environment.
# SV_DIR is the installation directory for SVToolkit - it must be an exported environment variable.
# SV_TMPDIR is a directory for writing temp files, which may be large if you have a large data set.
export SV_DIR=/net/eichler/vol4/home/araja/bin/svtoolkit
SV_TMPDIR=./tmpdir
REF_DIR=/net/eichler/vol4/home/araja/bin/svtoolkit/1000G_phase3
runDir=epi4k_all_samples_run2
bam=/net/eichler/vol20/projects/epi4k/nobackups/araja/epi4k_whole_genomes/GenomeSTRiP/epi4k_samples.list
sites=/net/eichler/vol20/projects/epi4k/nobackups/araja/epi4k_whole_genomes/GenomeSTRiP/epi4k_all_samples_run2/epi4k_all_samples_run2.discovery.vcf
genotypes=/net/eichler/vol20/projects/epi4k/nobackups/araja/epi4k_whole_genomes/GenomeSTRiP/epi4k_all_samples_run2/epi4k_all_samples_run2.genotyping.vcf

# These executables must be on your path.
which java > /dev/null || exit 1
which Rscript > /dev/null || exit 1
which samtools > /dev/null || exit 1

# For SVAltAlign, you must use the version of bwa compatible with Genome STRiP.
export PATH=${SV_DIR}/bwa:${PATH}
export LD_LIBRARY_PATH=${SV_DIR}/bwa:${LD_LIBRARY_PATH}

mx="-Xmx4g"
classpath="${SV_DIR}/lib/SVToolkit.jar:${SV_DIR}/lib/gatk/GenomeAnalysisTK.jar:${SV_DIR}/lib/gatk/Queue.jar"

mkdir -p ${runDir}/logs || exit 1
mkdir -p ${runDir}/metadata || exit 1

# Unzip the reference sequence and masks if necessary
#if [ ! -e ${REF_DIR}/human_g1k_hs37d5.fasta -a -e ${REF_DIR}/human_g1k_hs37d5.fasta.gz ]; then
 #   gunzip ${REF_DIR}/human_g1k_hs37d5.fasta.gz
#fi
#if [ ! -e ${REF_DIR}/ -a -e data/human_b36_chr1.mask.fasta.gz ]; then
 #   gunzip data/human_b36_chr1.mask.fasta.gz
#fi
#if [ ! -e data/cn2_mask_g1k_b36_chr1.fasta -a -e data/cn2_mask_g1k_b36_chr1.fasta.gz ]; then
#    gunzip data/cn2_mask_g1k_b36_chr1.fasta.gz
#fi

# Display version information.
java -cp ${classpath} ${mx} -jar ${SV_DIR}/lib/SVToolkit.jar

# Run preprocessing.
# For large scale use, you should use -reduceInsertSizeDistributions, but this is too slow for the installation test.
# The method employed by -computeGCProfiles requires a CN2 copy number mask and is currently only supported for human genomes.
java -cp ${classpath} ${mx} \
    org.broadinstitute.sting.queue.QCommandLine \
    -S ${SV_DIR}/qscript/SVPreprocess.q \
    -S ${SV_DIR}/qscript/SVQScript.q \
    -gatk ${SV_DIR}/lib/gatk/GenomeAnalysisTK.jar \
    -cp ${classpath} \
    -configFile ${SV_DIR}/conf/genstrip_parameters.txt \
    -tempDir ${SV_TMPDIR} \
    -R ${REF_DIR}/human_g1k_hs37d5.fasta \
    -genomeMaskFile ${REF_DIR}/human_g1k_hs37d5.svmask.fasta \
    -ploidyMapFile /net/eichler/vol4/home/araja/bin/svtoolkit/ploidy_map/humgen_g1k_v37_ploidy.map \
    -copyNumberMaskFile ${REF_DIR}/human_g1k_hs37d5.gcmask.fasta \
    -genderMapFile /net/eichler/vol20/projects/epi4k/nobackups/araja/epi4k_whole_genomes/GenomeSTRiP/epi4k_gender.map \
    -reduceInsertSizeDistributions \
    -computeGCProfiles \
    -bamFilesAreDisjoint \
    -runDirectory ${runDir} \
    -md ${runDir}/metadata \
    -jobLogDir ${runDir}/logs \
    -I ${bam} \
    --disableJobReport \
    -parallelJobs 5 \
    -qsub \
    -jobQueue all.q \
    -run \
    || exit 1

# Run discovery.
java -cp ${classpath} ${mx} \
    org.broadinstitute.sting.queue.QCommandLine \
    -S ${SV_DIR}/qscript/SVDiscovery.q \
    -S ${SV_DIR}/qscript/SVQScript.q \
    -gatk ${SV_DIR}/lib/gatk/GenomeAnalysisTK.jar \
    --disableJobReport \
    -cp ${classpath} \
    -configFile ${SV_DIR}/conf/genstrip_parameters.txt \
    -tempDir ${SV_TMPDIR} \
    -R ${REF_DIR}/human_g1k_hs37d5.fasta \
    -genomeMaskFile ${REF_DIR}/human_g1k_hs37d5.svmask.fasta \
    -genderMapFile /net/eichler/vol20/projects/epi4k/nobackups/araja/epi4k_whole_genomes/GenomeSTRiP/epi4k_gender.map \
    -runDirectory ${runDir} \
    -md ${runDir}/metadata \
    -jobLogDir ${runDir}/logs \
    -minimumSize 100 \
    -maximumSize 1000000 \
    -windowSize 1000000 \
    -windowPadding 10000 \
    -I ${bam} \
    -O ${sites} \
    -parallelJobs 5 \
    -qsub \
    -jobQueue all.q  \
    -run \
    || exit 1

(grep -v ^##fileDate= ${sites} | grep -v ^##source= | grep -v ^##reference= | diff -q - benchmark/${sites}) \
    || { echo "Error: test results do not match benchmark data"; exit 1; }

# Run genotyping on the discovered sites.
java -cp ${classpath} ${mx} \
    org.broadinstitute.sting.queue.QCommandLine \
    -S ${SV_DIR}/qscript/SVGenotyper.q \
    -S ${SV_DIR}/qscript/SVQScript.q \
    -gatk ${SV_DIR}/lib/gatk/GenomeAnalysisTK.jar \
    --disableJobReport \
    -cp ${classpath} \
    -configFile conf/genstrip_installtest_parameters.txt \
    -tempDir ${SV_TMPDIR} \
    -R data/human_b36_chr1.fasta \
    -genomeMaskFile data/human_b36_chr1.mask.fasta \
    -genderMapFile data/installtest_gender.map \
    -runDirectory ${runDir} \
    -md ${runDir}/metadata \
    -disableGATKTraversal \
    -jobLogDir ${runDir}/logs \
    -I ${bam} \
    -vcf ${sites} \
    -O ${genotypes} \
    -run \
    || exit 1

(grep -v ^##fileDate= ${genotypes} | grep -v ^##source= | grep -v ^##contig= | grep -v ^##reference= | diff -q - benchmark/${genotypes}) \
    || { echo "Error: test results do not match benchmark data"; exit 1; }

