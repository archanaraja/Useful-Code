#!/bin/bash

# If you adapt this script for your own use, you will need to set these two variables based on your environment.
# SV_DIR is the installation directory for SVToolkit - it must be an exported environment variable.
# SV_TMPDIR is a directory for writing temp files, which may be large if you have a large data set.
module load R/2.15.0 samtools/0.1.18 tabix/0.2.6 bwa/0.7.3 java/7u17 
export SV_DIR=~araja/bin/GenomeSTRiP/svtoolkit
export SV_TMPDIR=./tmpdir

REF_DIR=/net/eichler/vol4/home/araja/bin/svtoolkit/1000G_phase3
runDir=epi4k_all_samples_GS_V2
bam=/net/eichler/vol20/projects/epi4k/nobackups/araja/epi4k_whole_genomes/GenomeSTRiP/epi4k_samples.list
sites=/net/eichler/vol20/projects/epi4k/nobackups/araja/epi4k_whole_genomes/GenomeSTRiP/epi4k_all_samples_GS_V2/epi4k_all_samples.discovery.vcf
genotypes=/net/eichler/vol20/projects/epi4k/nobackups/araja/epi4k_whole_genomes/GenomeSTRiP/epi4k_all_samples_GS_V2/epi4k_all_samples.discovery.vcf

mkdir -p run_Dir
# These executables must be on your path.
which java > /dev/null || exit 1
which Rscript > /dev/null || exit 1
which samtools > /dev/null || exit 1

# For SVAltAlign, you must use the version of bwa compatible with Genome STRiP.
export PATH=${SV_DIR}/bwa:${PATH}
export LD_LIBRARY_PATH=${SV_DIR}/bwa:${LD_LIBRARY_PATH}

mx="-Xmx4g"
classpath="${SV_DIR}/lib/SVToolkit.jar:${SV_DIR}/lib/gatk/GenomeAnalysisTK.jar:${SV_DIR}/lib/gatk/Queue.jar"
echo $(date) >gs_v2_time.txt
mkdir -p ${runDir}/logs || exit 1
mkdir -p ${runDir}/metadata || exit 1

# Unzip the reference sequence and masks if necessary
#if [ ! -e data/human_b36_chr1.fasta -a -e data/human_b36_chr1.fasta.gz ]; then
#    gunzip data/human_b36_chr1.fasta.gz
#fi
#if [ ! -e data/human_b36_chr1.svmask.fasta -a -e data/human_b36_chr1.svmask.fasta.gz ]; then
#    gunzip data/human_b36_chr1.svmask.fasta.gz
#fi
#if [ ! -e data/human_b36_chr1.gcmask.fasta -a -e data/human_b36_chr1.gcmask.fasta.gz ]; then
#    gunzip data/human_b36_chr1.gcmask.fasta.gz
#fi

# Display version information.
java -cp ${classpath} ${mx} -jar ${SV_DIR}/lib/SVToolkit.jar

# Run preprocessing.
# For large scale use, you should use -reduceInsertSizeDistributions, but this is too slow for the installation test.
# The method employed by -computeGCProfiles requires a GC mask and is currently only supported for human genomes.
java -cp ${classpath} ${mx} \
    org.broadinstitute.gatk.queue.QCommandLine \
    -S ${SV_DIR}/qscript/SVPreprocess.q \
    -S ${SV_DIR}/qscript/SVQScript.q \
    -gatk ${SV_DIR}/lib/gatk/GenomeAnalysisTK.jar \
    --disableJobReport \
    -cp ${classpath} \
    -configFile ${SV_DIR}/conf/genstrip_parameters.txt \
    -tempDir ${SV_TMPDIR} \
    -R ${REF_DIR}/human_g1k_hs37d5.fasta \
    -genomeMaskFile ${REF_DIR}/human_g1k_hs37d5.svmask.fasta \
    -copyNumberMaskFile ${REF_DIR}/human_g1k_hs37d5.gcmask.fasta \
    -genderMapFile /net/eichler/vol20/projects/epi4k/nobackups/araja/epi4k_whole_genomes/GenomeSTRiP/epi4k_gender.map \
    -ploidyMapFile /net/eichler/vol4/home/araja/bin/svtoolkit/ploidy_map/humgen_g1k_v37_ploidy.map \
    -runDirectory ${runDir} \
    -md ${runDir}/metadata \
    -useMultiStep \
    -reduceInsertSizeDistributions false \
    -computeGCProfiles true \
    -computeReadCounts true \
    -bamFilesAreDisjoint true \
    -jobLogDir ${runDir}/logs \
    -I ${bam} \
    -parallelJobs 5 \
    -qsub \
    -jobQueue all.q \
    -run \
    || exit 1

# Run CNV Discovery Pipeline , identifies large deletions , duplications and mCNVs based on read-depth, packaged discovery and genotyping pipeline

java -Xmx4g -cp ${classpath} \
     org.broadinstitute.gatk.queue.QCommandLine \
     -S ${SV_DIR}/qscript/discovery/cnv/CNVDiscoveryPipeline.q \
     -S ${SV_DIR}/qscript/SVQScript.q \
     -cp ${classpath} \
     -gatk ${SV_DIR}/lib/gatk/GenomeAnalysisTK.jar \
     -configFile ${SV_DIR}/conf/genstrip_parameters.txt \
     -R ${REF_DIR}/human_g1k_hs37d5.fasta \
     -I ${bam} \
     -genomeMaskFile ${REF_DIR}/human_g1k_hs37d5.svmask.fasta \
     -genderMapFile /net/eichler/vol20/projects/epi4k/nobackups/araja/epi4k_whole_genomes/GenomeSTRiP/epi4k_gender.map \
     -ploidyMapFile /net/eichler/vol4/home/araja/bin/svtoolkit/ploidy_map/humgen_g1k_v37_ploidy.map \
     -md ${runDir}/metadata \
     -runDirectory ${runDir} \
     -jobLogDir ${runDir}/logs \
     -intervalList /net/eichler/vol4/home/araja/bin/GenomeSTRiP/1000G_phase3/human_g1k_hs37d5.interval.list \
     -tilingWindowSize 1000 \
     -tilingWindowOverlap 500 \
     -maximumReferenceGapLength 1000 \
     -boundaryPrecision 100 \
     -minimumRefinedLength 500 -jobRunner Drmaa \
     -gatkJobRunner Drmaa \
     -jobNative "-v PATH" \
     -jobNative "-v SV_DIR" \
     -jobNative "-q all.q" \
     -jobNative "-l mfree=20G" \
     -qsub \
     -parallelJobs 5 \
     -run || exit 1


echo $(date) >>gs_v2_time.txt

(grep -v ^##fileDate= ${sites} | grep -v ^##source= | grep -v ^##reference= | diff -q - benchmark/${sites}) \
    || { echo "Error: test results do not match benchmark data"; exit 1; }

