#!/bin/bash
#
# Author: Ewald van der Westhuizen
# Affiliation: Stellenbosch University
#

. path.sh

export LC_ALL=C
if [ $# -ne 2 ]; then
   echo "ERROR: $0: Two arguments required."
   exit 1;
fi

indict=$1
outdir=$2

[ ! -d "${outdir}" ] && mkdir -p "${outdir}"

[ ! -r $indict ] && echo "Missing $indict" && exit 1

if file -b --mime-type "${indict}" | grep -q "gzip$"; then
    cat_cmd=zcat
else
    # Assume it is a text file if it is not a gzipped file
    cat_cmd=cat
fi

# Join dicts and fix some troubles
#"${cat_cmd}" $indict | grep -v "<s>" | grep -v "</s>" | LANG= LC_ALL= sort | sed 's:([0-9])::g' > $outdir/lexicon_words.txt 
"${cat_cmd}" $indict | grep -v "<s>" | grep -v "</s>" | grep -v "SIL\-ENCE\ssil" > $outdir/lexicon_words.txt 

cat $outdir/lexicon_words.txt | awk '{ for(n=2;n<=NF;n++){ phones[$n] = 1; }} END{for (p in phones) print p;}' | \
  grep -v sil | grep -v nse | sort > $outdir/nonsilence_phones.txt  

( echo sil; echo nse ) > $outdir/silence_phones.txt

echo sil > $outdir/optional_silence.txt

# No extra questions but silence
echo sil > $outdir/extra_questions.txt

# Add to the lexicon the silences, noises etc.
#(echo '!SIL sil'; echo '<UNK> NSN') | \
(echo '!SIL sil') | \
 cat - $outdir/lexicon_words.txt | sort | uniq > $outdir/lexicon.txt

# Check that the dict dir is okay!
utils/validate_dict_dir.pl $outdir || exit 1
