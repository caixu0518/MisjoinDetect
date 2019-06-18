/data/mg1/caix/src/Hi-C/3d-dna/edit/run-mismatch-detector.sh   -w 50000 -d  200000  YunNanWild.scf.0.hic  

perl  01.get_breakpoints.pl  *_asm.scaffold_track.txt  mismatch_narrow.bed

perl  02.generate_corrected_breakpoints.pl -fasta  fasta file  -breakpoint  candidate breakpoints list  -gap gap file  -gene  gene list  

perl  03.break_misjoin_scfs.pl   -fasta   fasta file   -breakpoint   corrected reakpoints list 