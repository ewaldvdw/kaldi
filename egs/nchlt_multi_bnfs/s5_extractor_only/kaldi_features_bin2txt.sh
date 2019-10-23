#!/bin/bash

. ./cmd.sh
[ -f path.sh ] && . ./path.sh   

indir=$1
outfn=$2

[ ! -d "$(dirname ${outfn})" ] && mkdir -p "$(dirname ${outfn})"

for afn in ${indir}/*.ark; do
    copy-feats ark:$afn ark,t:-
done | gzip > $outfn

