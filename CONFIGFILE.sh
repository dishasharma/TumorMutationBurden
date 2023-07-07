#!/bin/bash
TOOL_PATH='/cardiomed/naraina/WorkSpace/Disha/TMB/Pipeline/FastqToVCF/Tools'
NO_OF_PROCESSES='2'
THREADS='16'
TRIM_QUALITY='20'
MIN_LENGTH='30'
PATH_TO_REFERENCE_GENOME='/cardiomed3/Genome/Resource_for_GATK/hg38/Homo_sapiens_assembly38.fasta'
PATH_TO_REFERENCE_GENOME_INDEX='/cardiomed3/Genome/Resource_for_GATK/hg38/Homo_sapiens_assembly38.fasta'
SCATTER_COUNT='10'
PATH_TO_RESOURCE_FILES='/cardiomed3/Genome/Resource_for_GATK/hg38'
AF_OF_ALLELES_NOT_IN_RESOURCE='0.00003125'
GERMLINE_VCF='dbsnp_146.hg38.vcf.gz'

##VCF_to_TMB
LIST_OF_GERMLINE_VCF='GermlineVcfsToInclude'
CHROMOSOME_LIST='ChrList'
BUILD='hg38'