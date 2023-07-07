#!/bin/bash 
start=`date +%s`
usage()
{
  echo "Usage: ./run.sh -v <list of germline vcf files> -s <somatic vcf path> -a <soma ref> -t <Directory where tools are installed> -g <Human_Reference_Genome.fa> -c <list_of_chromosome to include> -r <RESOURCE_FILE_PATH> -o <OUTPUT_DIRECTORY> -p <NOOFPROCESSES> -h <help>"
  exit 2
}

while getopts v:t:g:c:r:o:p:d:b:s:a:h: option 
do 
 case "${option}" 
 in 
 v) VCF_FILES=${OPTARG};;
 t) TOOLS_DIRECTORY=${OPTARG};;
 g) HUMAN_REFERENCE=${OPTARG};;
 a) SOMA_REFERENCE=${OPTARG};;
 c) CHROMOSOME_LIST=${OPTARG};;
 r) RESOURCE_FILE_PATH=${OPTARG};;
 o) OUTPUT_DIR=${OPTARG};;
 p) NOOFPROCESSES=${OPTARG};;
 d) INPUT_DIRECTORY=${OPTARG};;
 b) BUILD=${OPTARG};;
 s) SOMAVCF=${OPTARG};;
 
 h|?) usage ;; esac
done



####SplitGermlineVCFs
VcfList="$(awk '{ print $0}' $VCF_FILES )"
ChrList="$(awk '{print $0}' $CHROMOSOME_LIST)"

mkdir $OUTPUT_DIR
mkdir $OUTPUT_DIR/RefSplitFiles
touch $OUTPUT_DIR/RefSplitFiles/splitchrfiles_ps.sh
touch $OUTPUT_DIR/RefSplitFiles/splitchrfiles_ps1.sh
splitchrfiles=$OUTPUT_DIR/RefSplitFiles/splitchrfiles_ps.sh
splitchrfiles1=$OUTPUT_DIR/RefSplitFiles/splitchrfiles_ps1.sh
for i in $VcfList
do
for j in $ChrList
do
echo $i"\t"$j
SPLIT_CHR_COMMAND=`echo -e $TOOLS_DIRECTORY"\t"$RESOURCE_FILE_PATH"\t"$i"\t"$j"\t"$OUTPUT_DIR"\t"$HUMAN_REFERENCE | awk '{ print $1"/gatk-4.1.2.0/gatk SelectVariants -R "$6" -V "$2"/"$3" -L chr"$4" -O "$5"/RefSplitFiles/chr"$4"_"$3".vcf"}'`
echo $SPLIT_CHR_COMMAND >> "$splitchrfiles"
done
done
awk '{ print $0}' "$splitchrfiles" | awk '{ print "nohup "$0" &"}' | sed "0~$NOOFPROCESSES s: &: &\nwait:" > $OUTPUT_DIR/RefSplitFiles/splitchrfiles_ps1.sh
echo "Splitting Germline VCFs with "$NOOFPROCESSES" jobs in parallel"
#sh $OUTPUT_DIR/RefSplitFiles/splitchrfiles_ps1.sh
#pid=$!
#wait $pid
echo "Spliting Reference Files Done"
###END OF SplitGermlineVCFs


###Split Somatic VCFs
SOMAVCFs="$(awk '{print $0}' $SOMAVCF)"
mkdir $OUTPUT_DIR/VCFSplitFiles
touch $OUTPUT_DIR/VCFSplitFiles/splitchrfiles_somavcf_ps.sh
touch $OUTPUT_DIR/VCFSplitFiles/splitchrfiles_somavcf_ps1.sh
splitchrfiles_somavcf=$OUTPUT_DIR/VCFSplitFiles/splitchrfiles_somavcf_ps.sh
splitchrfiles_somavcf1=$OUTPUT_DIR/VCFSplitFiles/splitchrfiles_somavcf_ps1.sh

for i in $SOMAVCFs
do
for j in $ChrList
do
echo $i"\t"$j
SPLIT_CHR_COMMAND_SOMAVCF=`echo -e $TOOLS_DIRECTORY"\t"$i"\t"$j"\t"$OUTPUT_DIR"\t"$SOMA_REFERENCE | awk '{ print $1"/gatk-4.1.2.0/gatk SelectVariants -R "$5" -V InputFiles/"$2" -L chr"$3" -O "$4"/VCFSplitFiles/chr"$3"_"$2".vcf"}'`
echo $SPLIT_CHR_COMMAND_SOMAVCF >> "$splitchrfiles_somavcf"
done
done
awk '{ print $0}' "$splitchrfiles_somavcf" | awk '{ print "nohup "$0" &"}' | sed "0~$NOOFPROCESSES s: &: &\nwait:" > $OUTPUT_DIR/VCFSplitFiles/splitchrfiles_somavcf_ps1.sh
#sh $OUTPUT_DIR/VCFSplitFiles/splitchrfiles_somavcf_ps1.sh
#pid=$!
#wait $pid
echo "Spliting Sample VCF Files Done"
###SOMATIC VCF SPLITTED.

###Remove Germline Variants
##Cat Germline Coordinates
mkdir $OUTPUT_DIR/GETSOMATICVARIANTS
touch $OUTPUT_DIR/GETSOMATICVARIANTS/cat_germlinevariants.sh
touch $OUTPUT_DIR/GETSOMATICVARIANTS/cat_germlinevariants1.sh
cat_germlinevariants=$OUTPUT_DIR/GETSOMATICVARIANTS/cat_germlinevariants.sh
cat_germlinevariants1=$OUTPUT_DIR/GETSOMATICVARIANTS/cat_germlinevariants1.sh
ChrList="$(awk '{print $0}' $CHROMOSOME_LIST)"
for i in $ChrList
do
CAT_REF_COORDS=`echo -e $OUTPUT_DIR"\t"$i | awk '{ print "cat "$1"/RefSplitFiles/chr"$2"*.vcf | grep -v ^# | cut --output-delimiter=\"\:\" -f1\,2\,4\,5 > "$1"/GETSOMATICVARIANTS/chr"$2"_GermlineVariants"}'`
echo $CAT_REF_COORDS >> "$cat_germlinevariants"
done
awk '{ print "nohup "$0" &"}' "$cat_germlinevariants" | sed "0~$NOOFPROCESSES s: &: &\nwait:" > $OUTPUT_DIR/GETSOMATICVARIANTS/cat_germlinevariants1.sh
#sh $OUTPUT_DIR/GETSOMATICVARIANTS/cat_germlinevariants1.sh
#pid=$!
#wait $pid
echo "Concatenating Germline Variants Done."

##Cat Sample VCF Coordinates
touch $OUTPUT_DIR/VCFSplitFiles/cat_samplevariants.sh
touch $OUTPUT_DIR/VCFSplitFiles/cat_samplevariants1.sh
GETSAMPLEVARIANTCOORDS=$OUTPUT_DIR/VCFSplitFiles/cat_samplevariants.sh
GETSAMPLEVARIANTCOORDS1=$OUTPUT_DIR/VCFSplitFiles/cat_samplevariants1.sh
for i in $ChrList
do
for j in $SOMAVCFs
do
CAT_SAMPLEVCF_COORDS=`echo -e $OUTPUT_DIR"\t"$i"\t"$j | awk '{ print "cat "$1"/VCFSplitFiles/chr"$2"_"$3".vcf| grep -v ^# | cut --output-delimiter=\"\:\" -f1\,2\,4\,5 > "$1"/VCFSplitFiles/chr"$2"_"$3"_VariantCoords"}'`
echo $CAT_SAMPLEVCF_COORDS >> "$GETSAMPLEVARIANTCOORDS"
done
done
awk '{ print "nohup "$0" &"}' "$GETSAMPLEVARIANTCOORDS" | sed "0~$NOOFPROCESSES s: &: &\nwait:" > $OUTPUT_DIR/VCFSplitFiles/cat_samplevariants1.sh
#sh $OUTPUT_DIR/VCFSplitFiles/cat_samplevariants1.sh
#pid=$!
#wait $pid
echo "Getting Sample VCF Coordinates Done"

##Grep from sample vcfs
touch $OUTPUT_DIR/GETSOMATICVARIANTS/cat_samplesomaticvariants.sh
touch $OUTPUT_DIR/GETSOMATICVARIANTS/cat_samplesomaticvariants1.sh
GETSOMATICVARIANTCOORDS=$OUTPUT_DIR/GETSOMATICVARIANTS/cat_samplesomaticvariants.sh
GETSOMATICVARIANTCOORDS1=$OUTPUT_DIR/GETSOMATICVARIANTS/cat_samplesomaticvariants1.sh
for i in $ChrList
do
for j in $SOMAVCFs
do
REMOVE_GERMLINE_VARIANTS=`echo -e $OUTPUT_DIR"\t"$i"\t"$j | awk '{ print "grep -vwFf "$1"/GETSOMATICVARIANTS/chr"$2"_GermlineVariants "$1"/VCFSplitFiles/chr"$2"_"$3"_VariantCoords > "$1"/GETSOMATICVARIANTS/chr"$2"_"$3"_somaticvariants"}'`
echo $REMOVE_GERMLINE_VARIANTS >> "$GETSOMATICVARIANTCOORDS"
done
done
awk '{ print "nohup "$0" &"}' "$GETSOMATICVARIANTCOORDS" | sed "0~$NOOFPROCESSES s: &: &\nwait:" > $OUTPUT_DIR/GETSOMATICVARIANTS/cat_samplesomaticvariants1.sh
#sh $OUTPUT_DIR/GETSOMATICVARIANTS/cat_samplesomaticvariants1.sh
#pid=$!
#wait $pid
echo "Filtering Somatic Variants Done."

for i in $SOMAVCFs
do
for j in $ChrList
do
sed 's/:/\t/g' $OUTPUT_DIR/GETSOMATICVARIANTS/chr"$j"_"$i"_somaticvariants | awk '{ print $1"\t"$2"\t.\t"$3"\t"$4}' > $OUTPUT_DIR/GETSOMATICVARIANTS/chr"$j"_"$i"_somaticvariants1 
done
done

##Make Somatic VCF
touch $OUTPUT_DIR/GETSOMATICVARIANTS/GETHEADER.sh
touch $OUTPUT_DIR/GETSOMATICVARIANTS/GETHEADER1.sh
GETHEADERSCRIPT=$OUTPUT_DIR/GETSOMATICVARIANTS/GETHEADER.sh
GETHEADERSCRIPT1=$OUTPUT_DIR/GETSOMATICVARIANTS/GETHEADER1.sh

for i in $SOMAVCFs
do 
GETHEADER=`echo -e $i"\t"$OUTPUT_DIR | awk '{ print "grep -i \"#\" InputFiles/"$1" > "$2"/GETSOMATICVARIANTS/header_"$1}'` 
echo $GETHEADER >> "$GETHEADERSCRIPT"
done
awk '{ print "nohup "$0" &"}' "$GETHEADERSCRIPT" | sed "0~$NOOFPROCESSES s: &: &\nwait:" > $OUTPUT_DIR/GETSOMATICVARIANTS/GETHEADER1.sh
#sh $OUTPUT_DIR/GETSOMATICVARIANTS/GETHEADER1.sh
#pid=$!
#wait $pid
echo "Getting Header from Sample VCFs Done"

mkdir $OUTPUT_DIR/SOMATICVCFs
touch $OUTPUT_DIR/GETSOMATICVARIANTS/somaticvcfscript.sh
touch $OUTPUT_DIR/GETSOMATICVARIANTS/somaticvcfscript1.sh
SOMATICVCF_S=$OUTPUT_DIR/GETSOMATICVARIANTS/somaticvcfscript.sh
SOMATICVCF_S1=$OUTPUT_DIR/GETSOMATICVARIANTS/somaticvcfscript1.sh

for i in $SOMAVCFs
do
for j in $ChrList
do
SOMATICVCF=`echo -e $i"\t"$OUTPUT_DIR"\t"$j | awk '{ print "grep -wFf "$2"/GETSOMATICVARIANTS/chr"$3"_"$1"_somaticvariants1 "$2"/VCFSplitFiles/chr"$3"_"$1".vcf | cat "$2"/GETSOMATICVARIANTS/header_"$1" - > "$2"/SOMATICVCFs/chr"$3"_"$1}'`
echo $SOMATICVCF >> "$SOMATICVCF_S"
done
done
awk '{ print "nohup "$0" &"}' "$SOMATICVCF_S" | sed "0~$NOOFPROCESSES s: &: &\nwait:" > $OUTPUT_DIR/GETSOMATICVARIANTS/somaticvcfscript1.sh
#sh $OUTPUT_DIR/GETSOMATICVARIANTS/somaticvcfscript1.sh
#pid=$!
#wait $pid
echo "Somatic Variant VCF Files Done"

###Run Annovar
SOMAVCFs="$(awk '{print $0}' $SOMAVCF)"
mkdir $OUTPUT_DIR/Annovar
touch $OUTPUT_DIR/Annovar/vcftoavi.sh
touch $OUTPUT_DIR/Annovar/vcftoavi1.sh
aviscriptpath=$OUTPUT_DIR/Annovar/vcftoavi.sh
aviscriptpath1=$OUTPUT_DIR/Annovar/vcftoavi1.sh
for i in $SOMAVCFs
do
for j in $ChrList
do
echo $i
echo $j
VCFTOAVI_COMMAND=`echo -e $TOOLS_DIRECTORY"\t"$OUTPUT_DIR"\t"$i"\t"$j | awk '{ print $1"/annovar/convert2annovar.pl  --format vcf4old "$2"/SOMATICVCFs/chr"$4"_"$3" --outfile "$2"/Annovar/chr"$4"_"$3".avinput --includeinfo --withzyg"}'`
echo $VCFTOAVI_COMMAND >> "$aviscriptpath"
done
done
awk '{ print $0}' "$aviscriptpath" | awk '{ print "nohup "$0" &"}' | sed "0~$NOOFPROCESSES s: &: &\nwait:" > $aviscriptpath1
echo "Running Annovar with "$NOOFPROCESSES" jobs in parallel"
#sh $aviscriptpath1
#pid=$!
#wait $pid
echo "VCF to AVI input Done"

SOMAVCFs="$(awk '{print $0}' $SOMAVCF)"
mkdir $OUTPUT_DIR/Annovar
touch $OUTPUT_DIR/Annovar/vcftomultianno.sh
touch $OUTPUT_DIR/Annovar/vcftomultianno1.sh
multiannoscriptpath=$OUTPUT_DIR/Annovar/vcftomultianno.sh
multiannoscriptpath1=$OUTPUT_DIR/Annovar/vcftomultianno1.sh

for i in $SOMAVCFs
do
for j in $ChrList
do
echo $i
echo $j
VCFTOMULTIANNO_COMMAND=`echo -e $TOOLS_DIRECTORY"\t"$OUTPUT_DIR"\t"$i"\t"$j"\t"$BUILD | awk '{ print "perl "$1"/annovar/table_annovar.pl "$2"/Annovar/chr"$4"_"$3".avinput "$1"/humandb -buildver "$5" --out "$2"/Annovar/chr"$4"_"$3".avinput -remove -protocol refGene,avsnp150,1000g2015aug_all,1000g2015aug_afr,1000g2015aug_eur,1000g2015aug_sas,1000g2015aug_eas,1000g2015aug_amr,gnomad_exome,gnomad_genome,exac03,esp6500siv2_all,gme,clinvar_20190305,intervar_20180118 -operation g,f,f,f,f,f,f,f,f,f,f,f,f,f,f -nastring . -polish -otherinfo"}'`
echo $VCFTOMULTIANNO_COMMAND >> "$multiannoscriptpath"
done
done
awk '{ print $0}' "$multiannoscriptpath" | awk '{ print "nohup "$0" &"}' | sed "0~$NOOFPROCESSES s: &: &\nwait:" > $multiannoscriptpath1
echo "Running Annovar with "$NOOFPROCESSES" jobs in parallel"
#sh $multiannoscriptpath1
#pid=$!
#wait $pid
echo "VCF to Multianno input Done"

touch $OUTPUT_DIR/Annovar/catmultinnoscript.sh
touch $OUTPUT_DIR/Annovar/catmultinnoscript1.sh
catmultinnos=$OUTPUT_DIR/Annovar/catmultinnoscript.sh
catmultinnos1=$OUTPUT_DIR/Annovar/catmultinnoscript1.sh
for i in $SOMAVCFs
do
echo $i
CAT_MULTIANNO=`echo -e $i"\t"$OUTPUT_DIR"\t"$BUILD | awk '{ print "cat "$2"/Annovar/chr\*_"$1".avinput."$3"_multianno.txt > "$2"/Annovar/chr\*_"$1"_allchr_annovar.txt"}'`
echo $CAT_MULTIANNO >> "$catmultinnos"
done
awk '{ print $0}' "$catmultinnos" | awk '{ print "nohup "$0" &"}' | sed "0~$NOOFPROCESSES s: &: &\nwait:" > "$catmultinnos1"
#sh "$catmultinnos1"
#pid=$!
#wait $pid
echo "Multianno for all chromosomes merged"


touch $OUTPUT_DIR/Annovar/filtervariants.sh
touch $OUTPUT_DIR/Annovar/filtervariants1.sh
FILTERVARIANTS=$OUTPUT_DIR/Annovar/filtervariants.sh
FILTERVARIANTS1=$OUTPUT_DIR/Annovar/filtervariants1.sh
for i in $SOMAVCFs
do
echo $i
FILTERV=`echo -e $i"\t"$OUTPUT_DIR | awk '{ print "grep -w nonsynonymous "$2"/Annovar/"$1"_allchr_annovar.txt > "$2"/Annovar/"$1"_NonSynoVariants"}'`
echo $FILTERV >> "$FILTERVARIANTS"
done
awk '{ print $0}' "$FILTERVARIANTS" | awk '{ print "nohup "$0" &"}' | sed "0~$NOOFPROCESSES s: &: &\nwait:" > "$FILTERVARIANTS1"
sh "$FILTERVARIANTS1"
pid=$!
wait $pid
echo "Filter Variants Done."