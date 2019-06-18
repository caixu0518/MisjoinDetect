# MisjoinDetect 
An automated misjoins correction pipeline (named MisjoinDetect) based on Hi-C data

cd MisjoinDetect

##-Step 1: Detect misjoin locus
perl  ${pipelineWd}/01.misjoin_detect.pl  -matrix ${matrix} -bed ${intervals} -Scfsizes ${sizes} -binsize ${binsize}

##-Step 2: Correct breakpoint information
perl ${pipelineWd}/02.generate_corrected_breakpoints.pl -fasta ${fasta}  -breakpoint misjoin.bin.list -binsize ${binsize}  -gap ${gap}  -gene  ${gene}

##-Step 3: Break misjoin scaffolds
perl ${pipelineWd}/03.break_misjoin_scfs.pl  -fasta  ${fasta}  -breakpoint  corrected.breakpoints.list

##-Step 4: Generate Hi-C map of each potential misjoin scaffold
cut -f 1 corrected.breakpoints.list > misjoin.scfs.list
bash ${pipelineWd}/Run_HiCPlotter.multi_threads.sh  ${matrix} ${intervals} ${sizes} "misjoin.scfs.list"


##——-------------------------------------------------------------------------------------------------------
Generate candidate misjoins from 3D-DNA output
cd misjoins_from_3d_dna

##- run 3D-DNA
/data/mg1/caix/src/Hi-C/3d-dna/edit/run-mismatch-detector.sh  YunNanWild.scf.0.hic  

##- generate breakpoints 
perl  01.get_breakpoints.pl  *_asm.scaffold_track.txt  mismatch_narrow.bed

##- correct breakpoints
perl  02.generate_corrected_breakpoints.pl -fasta  fasta file  -breakpoint  candidate breakpoints list  -gap gap file  -gene  gene list  

##- break scaffold by corrected breakpoints
perl  03.break_misjoin_scfs.pl   -fasta   fasta file   -breakpoint   corrected reakpoints list 

##---------------------------------------------------------------------------------------------------------
Generate candidate misjoins from Syntenic gene list
 cd misjoins_from_Syntenic_genes
 
 perl  get_misjoins_from_SynGenes.pl -s SynOrths Output   -m Minimum fragment length
