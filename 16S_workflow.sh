#!/bin/bash
echo"
#Création des dossiers pour les résutlats.
mkdir $2/fastqc_output
mkdir $2/AlienTrimmer_output
mkdir $2/vsearch_output
mkdir $2/prep_OTU

#On décompresse les zip pour la suite
gunzip $1/*.gz

fastqc $1/*.fastq -o $2/fastqc_output/

#On va procéder au AlienTrimmer
cd $1/../soft/
echo $PWD

for i in $(ls $1/*_R1.fastq) 
do
    nameR1=$i
    nameR2=$(echo $i |sed "s/R1/R2/g")
	java -jar AlienTrimmer.jar -if $nameR1 -ir $nameR2 -c $1/../databases/contaminants.fasta -q 20 -of $2/AlienTrimmer_output/$(basename $nameR1).at.fq -or $2/AlienTrimmer_output/$(basename $nameR2).at.fq
done

#On fusionne les reads obtenus à l'aide de Vsearch
for i in $(ls $2/AlienTrimmer_output/*_R1.fastq.at.fq) 
do
    nameR1=$i
    nameR2=$(echo $i |sed "s/R1/R2/g")
    name=$(echo $(basename $i) | cut -d. -f1)
    vsearch --fastq_mergepairs $nameR1 --reverse $nameR2\
    --fastq_minovlen 40 --fastq_maxdiff 15\
    --fastaout $2/vsearch_output/$(basename $i).fasta --label_suffix ";sample=$name;"
done

#On concatène les fasta
cat $2/vsearch_output/*.fasta | sed -e "s/ //g" > $2/amplicon.fasta

#déduplication du fichier amplicon
vsearch --derep_fulllength $2/amplicon.fasta --output $2/prep_OTU/Dedup.fasta --sizeout

#Suppression des singletons = <10
vsearch --fastx_filter $2/prep_OTU/Dedup.fasta --minsize 10 --fastaout $2/prep_OTU/filtre1.fasta

#Suppression des chimères
vsearch --uchime_denovo $2/prep_OTU/filtre1.fasta --nonchimeras $2/prep_OTU/filtre2_chimera.fasta

#Clustering
vsearch --cluster_size $2/prep_OTU/filtre2_chimera.fasta --id 0.97 --centroids $2/OTU.fasta --relabel OTU_

#étude OTU
vsearch --usearch_global $2/amplicon.fasta --db $2/OTU.fasta --id 0.97 --sizeout --otutabout $2/table_abondance.txt

#étude OTU 16S
vsearch --usearch_global $2/amplicon.fasta --db $2/../databases/mock_16S_18S.fasta --id 0.9 --top_hits_only\
 --userfields query+target --userout $2/versus_16s.txt"

#Ajout de noms de colonnes.
sed -i '1iOTU\tAnnotation' $2/versus_16s.txt

