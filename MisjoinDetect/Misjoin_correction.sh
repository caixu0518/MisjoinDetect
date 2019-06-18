#!/bin/bash

##- pipelines to detect misjoins in sacffolds
##-Author: Xu Cai
##-Bug report: caixu0518@163.com


fasta=HN53.scf.fasta            ##- scaffolds 
matrix=HN53_50000_iced.matrix   ##- generated from HiC pro
intervals=HN53_50000_abs.bed    ##- generated from HiC pro
sizes=HN53.scf.fasta.sizes      ##- each scaffold size  （scaffold id, scaffold length）
binsize=50000                   ##- bin size

gap=Gap_info.list               ##- the file discribe gap information and generated from   detect_N_info.pl 
gene=HN53.evm.ft.gene.gff3.sort.Coords   ##- gene info (gene id, scaffold id, gene start, gene end, strand)
##--------------------------------------------------------------------

pipelineWd=/data/mg1/caix/scripts/misjoin_correction/utils
export PATH=/home/caix/miniconda3/envs/py2.7/bin/:${PATH}
export PERL5LIB=:/home/caix/miniconda3/envs/py2.7/lib/perl5/5.22.0/x86_64-linux-thread-multi/:${PERL5LIB}


##--------------------------------------------------------------------------------------------------------------------------------------
##-Step 1: Detect misjoin locus
perl  ${pipelineWd}/01.misjoin_detect.pl  -matrix ${matrix} -bed ${intervals} -Scfsizes ${sizes} -binsize ${binsize}

##-Step 2: Correct breakpoint information
perl ${pipelineWd}/02.generate_corrected_breakpoints.pl -fasta ${fasta}  -breakpoint misjoin.bin.list -binsize ${binsize}  -gap ${gap}  -gene  ${gene}

##-Step 3: Break misjoin scaffolds
perl ${pipelineWd}/03.break_misjoin_scfs.pl  -fasta  ${fasta}  -breakpoint  corrected.breakpoints.list

##-Step 4: Generate Hi-C map of each potential misjoin scaffold
cut -f 1 corrected.breakpoints.list > misjoin.scfs.list
bash ${pipelineWd}/Run_HiCPlotter.multi_threads.sh  ${matrix} ${intervals} ${sizes} "misjoin.scfs.list"
