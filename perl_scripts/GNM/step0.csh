## PLEASE CHECK FOR LOWERCASE, symbols, etc...
mkdir BLASTOUT_2WGS
## optimized for sleep anf interval
setupCommandsFromListAndSchedule.pl -lis list.transcriptome.111 -out fff -sleep 10 -inter 1000 -string 'blastn -db DB/wgs.5d.scafSeq200+.trimmed -query FASTADIR_NT/$i.ALL.1.fasta -out BLASTOUT_2WGS/$i.blast.nt '

## this creates the contamination and clean list
## currently only one differs from list.transcriptome.clean - C55080_G1_I1 for a cutoff of 70, so we have cutoff of 75
parseBlastLatestList.pl -out MAPDIRS/map.full.TRS2Scaffold -lis list.transcriptome.111 -blastdir BLASTOUT_2WGS/ -blastcutoff 75 -forWGS 1 -findcha 0  > & ! /dev/null & 
extractindexfromfile.pl -in MAPDIRS/map.full.TRS2Scaffold.75.found 
\mv -f MAPDIRS/map.full.TRS2Scaffold.75.found.0 list.transcriptome.clean 

TW list.transcriptome.111 list.transcriptome.clean 
wc -l list.transcriptome.clean
\mv -f ofhinAbutnotinB list.transcriptome.contam


## Identify RRNA's
mkdir -p  BLASTOUT_RRNA/ 
setupCommandsFromListAndSchedule.pl -lis list.transcriptome.clean -out fff -sleep 3 -inter 2000 -string 'blastn -db DB/rel_con_pln_r124.rRNA.fasta -query FASTADIR_NT/$i.ALL.1.fasta -out BLASTOUT_RRNA/$i.blast.nt '

parseBlastLatestList.pl -out RRNA.anno -lis list.transcriptome.clean -blastdir BLASTOUT_RRNA/ -blastcutoff 1000 -forWGS 1 -findcha 0  > & ! /dev/null & 

cat RRNA.anno.1000.anno.real list.transcriptome.contam > list.transcriptome.contam.andRRNA



parseBlastLatestList.pl -out MAPDIRS/map.full.TRS2Scaffold -lis list.transcriptome.clean -blastdir BLASTOUT_2WGS/ -blastcutoff 500 -forWGS 1 > & ! /dev/null & 
## still reversed - only about 70 
checkBLASTtrs2scaffolddirection.pl -blastdi BLASTOUT_SCAFFOLD -out blast.err 
## lot of hardcoded stuff here
parseBlastLatestpairwiseAllScaffolds.pl -blas BLASTOUT_SCAFFOLD -just 0 -inf scaff2trs.500

cat INFO/*.info > ! III  &
echo Run this genReportsForScaff.pl -outf uuuu -inf III -ann genome.ann.realgood -ignore ~/ooo 

mkdir  ORFTMP 
mkdir  ORF 
setupCommandsFromListAndSchedule.pl -lis list.transcriptome.111 -out fff -sleep 1 -inter 100 -string 'getorf FASTADIR_NT/$i.ALL.1.fasta ORFTMP/$i.orf' 

## this renames the strings, adding ORF
setupCommandsFromListAndSchedule.pl -lis list.transcriptome.111 -out fff -sleep 1 -inter 100 -string 'fixORFnames.pl -inf ORFTMP/$i.orf -out ORF/$i.orf '

## creates the top 3 ORFs in FASTADIR_ORF, and the longest in FASTADIR_JUSTONLONGEST
setupCommandsFromListAndSchedule.pl -lis list.transcriptome.111 -out fff -sleep 1 -inter 100 -string 'findrepeatedorfs.pl -trs $i -orfdir ORF/ -write 4 '

$SRC/GNM/catANNintOnefile.csh FASTADIR_ORF list list.transcriptome.clean.ORFS # you need to edit this file


setupCommandsFromListAndSchedule.pl -lis list.transcriptome.clean.ORFS -out fff -sleep 3 -inter 5 -string \
 'blastp -db DB/plantpep.fasta -query FASTADIR_ORF/$i.ALL.1.fasta -out BLASTOUT_AA/$i.blast.nt '


setupCommandsFromListAndSchedule.pl -lis list.transcriptome.clean.ORFS -out fff -sleep 3 -inter 100 -string 'parseWebBlastOuts.pl -outf jjj -tr $i -cutoff 1E-8 -blast BLASTOUT_AA -orfdir FASTADIR_ORF -ver 0 '

# Check for ANN/ERR and ANN/WARN (repeats) 
# then run
catANNintOnefile.csh ANN/COMMANDS c commandstocopy.csh
source commandstocopy.csh > & ! /dev/null &  # this creates all the FASTA files in FASTADIR_ORFBEST 

## Make each fasta file have the right name
mv FASTADIR_ORFBEST FASTADIR_ORFBESTRAW
setupCommandsFromListAndSchedule.pl -lis list.transcriptome.clean.expanded -out fff -sleep 2 -inter 100 -string 'fixFastaNames.pl -in FASTADIR_ORFBESTRAW/$i.ALL.1.fasta -trs $i -out FASTADIR_ORFBEST/$i.ALL.1.fasta '





