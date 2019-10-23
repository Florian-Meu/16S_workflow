#!/bin/bash


#fastqc $1/*.fastq.gz -o $2/

cd $1/../soft/
echo $PWD

java -jar AlienTrimmer.jar -i $1/*R1.fastq.gz -ir $1/*R2.fastq.gz -c $1/../databases/contaminants.fasta -q 20
