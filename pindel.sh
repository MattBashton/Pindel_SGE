#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 5
#$ -l h_rt=480:00:00
#$ -l h_vmem=38G

# Matthew Bashton 2016
# Script for running pindel on the cluster as a SGE array.

set -o pipefail
hostname
date

module add compilers/gnu/4.9.3
module add apps/htslib/1.3.1

DEST=$PWD
BED="regions.bed"
G_NAME="RUN"
REF="/opt/databases/GATK_bundle/2.8/hg19/ucsc.hg19.fasta"

LIST="config.txt"
LINE=`awk "NR==$SGE_TASK_ID" $LIST`
set $LINE
BAM=$1
INSERT_SIZE=$2
SAMP_ID=$3

B_NAME=`basename $BAM .bam`

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - BAM = $BAM"
echo " - B_NAME = $B_NAME"
echo " - INSERT_SIZE = $INSERT_SIZE"
echo " - SAMP_ID = $SAMP_ID"
echo " - PWD = $PWD"
echo " - LIST = $LIST"
echo " - REF = $REF"

echo "Copying input $B_NAME* to $TMPDIR"
/usr/bin/time --verbose cp -v $B_NAME.bam $TMPDIR
/usr/bin/time --verbose cp -v $B_NAME.bai $TMPDIR

echo "Copying over bed file $BED to $TMPDIR"
/usr/bin/time --verbose cp -v $BED $TMPDIR

echo "Converting input $TMPDIR/$B_NAME.bam with sam2pindel for sample $SAMP_ID, insert size is $INSERT_SIZE"
cd $TMPDIR
/usr/bin/time --verbose samtools view $TMPDIR/$B_NAME.bam | sam2pindel - $TMPDIR/input.pindel.$SGE_TASK_ID.txt $INSERT_SIZE "$SAMP_ID" 0 Illumina-PairEnd

echo "Check on files before running"
ls -lh

echo "Running pindel using referance genome $REF on input $TMPDIR/input.pindel.$SGE_TASK_ID.txt, output saved to $TMPDIR/output"
/usr/bin/time --verbose pindel -f $REF -p $TMPDIR/input.pindel.$SGE_TASK_ID.txt -x 9 -T 5 -j $TMPDIR/$BED --report_interchromosomal_events -o $TMPDIR/output.$SGE_TASK_ID.$SAMP_ID

echo "Check files before copying output to Luster"
ls -lh

echo "Copying output.* back to $DEST"
/usr/bin/time --verbose cp -vR $TMPDIR/output.$SGE_TASK_ID.* $DEST

cd $DEST

date
echo "END"
