# MisjoinDetect (generated candidate misjoins from 3D-DNA)
An automated misjoins correction pipeline (named MisjoinDetect) based on Hi-C data

##- run 3D-DNA
/data/mg1/caix/src/Hi-C/3d-dna/edit/run-mismatch-detector.sh  YunNanWild.scf.0.hic  

##- generate breakpoints 
perl  01.get_breakpoints.pl  *_asm.scaffold_track.txt  mismatch_narrow.bed

##- correct breakpoints
perl  02.generate_corrected_breakpoints.pl -fasta  fasta file  -breakpoint  candidate breakpoints list  -gap gap file  -gene  gene list  

##- break scaffold by corrected breakpoints
perl  03.break_misjoin_scfs.pl   -fasta   fasta file   -breakpoint   corrected reakpoints list 
