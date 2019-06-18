#!/bin/bash


export PATH=/home/caix/miniconda3/envs/py2.7/bin/:${PATH}
export PERL5LIB=:/home/caix/miniconda3/envs/py2.7/lib/perl5/5.22.0/x86_64-linux-thread-multi/:${PERL5LIB}

##- initialize input 
matrix=$1
intervals=$2
binsize=$3
misScf=$4
HiCPlotterWd=/data/mg1/caix/src/Hi-C/HiCPlotter

##------------------------------------------------------------
scaffolds=$(cat $misScf)
   for scf in ${scaffolds}

   do
   python ${HiCPlotterWd}/HiCPlotter.py  -f ${matrix}  -tri 1 -bed ${intervals}  -wg 0 -chr ${scf}  -r ${binsize}  -n ${scf} -o ${scf} -da 1
   done

pngfolder="misjoin.png.folder"

   if [ -d "${pngfolder}" ]; then
       rm -r "${pngfolder}"
       mkdir "${pngfolder}"

   else
       mkdir "${pngfolder}"

   fi
  
   mv *png  ${pngfolder}
