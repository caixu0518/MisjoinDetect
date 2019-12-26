# MisjoinDetect 
===============

# An automated misjoins correction pipeline (named MisjoinDetect) based on Hi-C data
====================================================================================

# Introduction
To detect misjoins in the hybrid assembled scaffolds, we developed a reliable misjoins correction pipeline (named MisjoinDetect) based on the Hi-C data. Our pipeline included the following three main steps. First, detection of regions of candidate misjoins. fastp (Chen et al., 2018) was used to filter low-quality Hi-C reads, and then clean reads were mapped onto the initial assembled scaffold sequences by HiC-Pro (Servant et al., 2015). Meanwhile, scaffolds were divided into different segments according to the fixed bin size, and the interaction values between all of the fragments within each scaffold were extracted and used to form an interaction matrix. The regions of the candidate misjoins were defined based on the difference in the interaction values of adjacent bins. Second, we determined the locations of the breakpoints. The program first searched for gap information in the candidate area. If the gap existed, the gap area would be deleted, and the location would be defined as a breakpoint (these errors were caused by different contigs being incorrectly connected by the de novo assembly software). If it did not exist, the program would use the midpoint of the two genes in the middle of the candidate region as a potential breakpoint to ensure that the gene sequence was intact. Moreover, we provided an additional script that relied on a collinear list of genes from the related species. Based on the collinearity results, we could more accurately determine the location of the breakpoint to ensure a more complete syntenic region. 

==========================================================================================================================
# Instructions

cd MisjoinDetect

# Step 1: Detect misjoin locus

perl  ${pipelineWd}/01.misjoin_detect.pl  -matrix ${matrix} -bed ${intervals} -Scfsizes ${sizes} -binsize ${binsize}

# Step 2: Correct breakpoint information
perl ${pipelineWd}/02.generate_corrected_breakpoints.pl -fasta ${fasta}  -breakpoint misjoin.bin.list -binsize ${binsize}  -gap ${gap}  -gene  ${gene}

# Step 3: Break misjoin scaffolds
perl ${pipelineWd}/03.break_misjoin_scfs.pl  -fasta  ${fasta}  -breakpoint  corrected.breakpoints.list

# Step 4: Generate Hi-C map of each potential misjoin scaffold

cut -f 1 corrected.breakpoints.list > misjoin.scfs.list

bash ${pipelineWd}/Run_HiCPlotter.multi_threads.sh  ${matrix} ${intervals} ${sizes} "misjoin.scfs.list"

# Others

# Generate candidate misjoins from 3D-DNA output
cd misjoins_from_3d_dna

# Run 3D-DNA
/data/mg1/caix/src/Hi-C/3d-dna/edit/run-mismatch-detector.sh  YunNanWild.scf.0.hic  

# Generate breakpoints 
perl  01.get_breakpoints.pl  *_asm.scaffold_track.txt  mismatch_narrow.bed

# Correct breakpoints
perl  02.generate_corrected_breakpoints.pl -fasta  fasta file  -breakpoint  candidate breakpoints list  -gap gap file  -gene  gene list  

# Break scaffold by corrected breakpoints
perl  03.break_misjoin_scfs.pl   -fasta   fasta file   -breakpoint   corrected reakpoints list 

==============================================================================================

# Generate candidate misjoins from Syntenic gene list
cd misjoins_from_Syntenic_genes
 
perl  get_misjoins_from_SynGenes.pl -s SynOrths Output   -m Minimum fragment length
 
===================================================================================

# Reference

Cheng F, Wu J, Fang L and Wang X. Syntenic gene analysis between Brassica rapa and other Brassicaceae species. Front Plant Sci. 2012;3:198. doi:10.3389/fpls.2012.00198.

Dudchenko O, Batra SS, Omer AD, Nyquist SK, Hoeger M, Durand NC, et al. De novo assembly of the Aedes aegypti genome using Hi-C yields chromosome-length scaffolds. Science. 2017;356 6333:92-5. doi:10.1126/science.aal3327.

Durand NC, Shamim MS, Machol I, Rao SSP, Huntley MH, Lander ES, et al. Juicer Provides a One-Click System for Analyzing Loop-Resolution Hi-C Experiments. Cell Syst. 2016;3 1:95-8. doi:10.1016/j.cels.2016.07.002.

Robinson JT, Turner D, Durand NC, Thorvaldsdottir H, Mesirov JP and Aiden EL. Juicebox.js Provides a Cloud-Based Visualization System for Hi-C Data. Cell Syst. 2018;6 2:256-+. doi:10.1016/j.cels.2018.01.001.

Servant N, Varoquaux N, Lajoie BR, Viara E, Chen CJ, Vert JP, et al. HiC-Pro: an optimized and flexible pipeline for Hi-C data processing. Genome Biol. 2015;16  doi:ARTN 25910.1186/s13059-015-0831-x.
