# MisjoinDetect 

##--------------------------------------------------------------------------------------------------------

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

##-----------------------------------------------------------------------------------------------------

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
 
##----------------------------------------------------------------------------------------------------

Reference

Cheng F, Wu J, Fang L and Wang X. Syntenic gene analysis between Brassica rapa and other Brassicaceae species. Front Plant Sci. 2012;3:198. doi:10.3389/fpls.2012.00198.

Dudchenko O, Batra SS, Omer AD, Nyquist SK, Hoeger M, Durand NC, et al. De novo assembly of the Aedes aegypti genome using Hi-C yields chromosome-length scaffolds. Science. 2017;356 6333:92-5. doi:10.1126/science.aal3327.

Durand NC, Shamim MS, Machol I, Rao SSP, Huntley MH, Lander ES, et al. Juicer Provides a One-Click System for Analyzing Loop-Resolution Hi-C Experiments. Cell Syst. 2016;3 1:95-8. doi:10.1016/j.cels.2016.07.002.

Robinson JT, Turner D, Durand NC, Thorvaldsdottir H, Mesirov JP and Aiden EL. Juicebox.js Provides a Cloud-Based Visualization System for Hi-C Data. Cell Syst. 2018;6 2:256-+. doi:10.1016/j.cels.2018.01.001.

Servant N, Varoquaux N, Lajoie BR, Viara E, Chen CJ, Vert JP, et al. HiC-Pro: an optimized and flexible pipeline for Hi-C data processing. Genome Biol. 2015;16  doi:ARTN 25910.1186/s13059-015-0831-x.
