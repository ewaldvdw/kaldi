#!/bin/bash

# Merge the given Kaldi dictionaties directories
# Author: Ewald van der Westhuizen
# Date: May 2019

#. utils/parse_options.sh || exit 1;
. path.sh || exit 1

if [ $# -lt 1 ]; then
  echo "Usage: $0 <out-dict-dir> <in-dict-dir1> <in-dict-dir2> ..."
  exit 1
fi

outdir=$1
[ ! -d "${outdir}" ] && mkdir -p "${outdir}"
shift

# Initialise the output dir by creating these empty files.
: > $outdir/extra_questions.txt
: > $outdir/lexicon.txt
: > $outdir/nonsilence_phones.txt
: > $outdir/optional_silence.txt
: > $outdir/silence_phones.txt

for adir in "$@"; do
    echo "Merging ${adir}"
    cat $adir/extra_questions.txt | sed 's/\s*$//g' >> $outdir/extra_questions.txt && sort -u -o $outdir/extra_questions.txt $outdir/extra_questions.txt
    cat $adir/lexicon.txt | sed 's/\s*$//g' >> $outdir/lexicon.txt && sort -u -o $outdir/lexicon.txt $outdir/lexicon.txt
    cat $adir/nonsilence_phones.txt | sed 's/\s*$//g' >> $outdir/nonsilence_phones.txt && sort -u -o $outdir/nonsilence_phones.txt $outdir/nonsilence_phones.txt
    cat $adir/optional_silence.txt | sed 's/\s*$//g' >> $outdir/optional_silence.txt && sort -u -o $outdir/optional_silence.txt $outdir/optional_silence.txt
    cat $adir/silence_phones.txt | sed 's/\s*$//g' >> $outdir/silence_phones.txt && sort -u -o $outdir/silence_phones.txt $outdir/silence_phones.txt
done

utils/validate_dict_dir.pl $outdir || exit 1

