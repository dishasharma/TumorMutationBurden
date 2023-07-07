#!/bin/bash 
start=`date +%s`
usage()
{
  echo "Usage: ./splitchr.sh -L <list of vcf files> -t <Directory where tools are installed> -g <Human_Reference_Genome.fa> -c <list_of_chromosome> -r <RESOURCE_FILE_PATH> -o <OUTPUT_DIRECTORY> -p <NOOFPROCESSES> -h <help>"
  exit 2
}

while getopts L:t:g:c:r:o:p:h: option 
do 
 case "${option}" 
 in 
 L) VCF_FILES=${OPTARG};;
 t) TOOLS_DIRECTORY=${OPTARG};;
 g) HUMAN_REFERENCE=${OPTARG};;
 c) CHROMOSOME_LIST=${OPTARG};;
 r) RESOURCE_FILE_PATH=${OPTARG};;
 o) OUTPUT_DIR=${OPTARG};;
 p) NOOFPROCESSES=${OPTARG};;
 h|?) usage ;; esac
done

VcfList="$(awk '{ print $0}' $VCF_FILES)"
ChrList="$(awk '{print $0}' $CHROMOSOME_LIST)"

mkdir $OUTPUT_DIR
touch $OUTPUT_DIR/splitchrfiles_ps.sh
touch $OUTPUT_DIR/splitchrfiles_ps1.sh

splitchrfiles=$OUTPUT_DIR/splitchrfiles_ps.sh
splitchrfiles1=$OUTPUT_DIR/splitchrfiles_ps1.sh

for i in $VcfList
do
for j in $ChrList
do
echo $i
echo $j
echo $i"\thello"$j
SPLIT_CHR_COMMAND=`echo $TOOLS_DIRECTORY"\t"$RESOURCE_FILE_PATH"\t"$i"\t"$j | awk '{ print $1"/gatk-4.1.2.0/gatk SelectVariants -R "$2"/Resource_for_GATK/hg38/Homo_sapiens_assembly38.fasta -V "$2"/Resource_for_GATK/hg38/"$i" -L chr"$4" -O chr"$4"_1000G.vcf"}'`
echo $SPLIT_CHR_COMMAND >> "$splitchrfiles"
done
done
echo $NOOFPROCESSES
awk '{ print $0}' "$splitchrfiles" | awk '{ print "nohup "$0" &"}' | sed "0~$NOOFPROCESSES s: &::" > "splitchrfiles1"
echo $ChrList
echo $VcfList