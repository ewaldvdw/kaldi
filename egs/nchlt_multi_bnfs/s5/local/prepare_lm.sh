#!/bin/bash 
#
# Copyright  2014 Nickolay V. Shmyrev 
# Apache 2.0


. path.sh
export LC_ALL=C
if [ $# -ne 1 ]; then
   echo "Argument should be the path to language model, see ../run.sh for example."
   exit 1;
fi

arpa_lm=$*

[ ! -f $arpa_lm ] && echo No such file $arpa_lm && exit 1;

rm -rf data/lang_test
cp -r data/lang data/lang_test
cat $arpa_lm | utils/find_arpa_oovs.pl data/lang_test/words.txt > data/lang_test/oovs.txt

# grep -v '<s> <s>' etc. is only for future-proofing this script.  Our
# LM doesn't have these "invalid combinations".  These can cause 
# determinization failures of CLG [ends up being epsilon cycles].
# Note: remove_oovs.pl takes a list of words in the LM that aren't in
# our word list.  Since our LM doesn't have any, we just give it
# /dev/null [we leave it in the script to show how you'd do it].
cat "$arpa_lm" | \
   grep -v '<s> <s>' | \
   grep -v '</s> <s>' | \
   grep -v '</s> </s>' | \
   arpa2fst - | fstprint | \
   utils/remove_oovs.pl data/lang_test/oovs.txt | \
   utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=data/lang_test/words.txt \
     --osymbols=data/lang_test/words.txt  --keep_isymbols=false --keep_osymbols=false | \
    fstrmepsilon | fstarcsort --sort_type=ilabel > data/lang_test/G.fst


echo  "Checking how stochastic G is (the first of these numbers should be small):"
fstisstochastic data/lang_test/G.fst

utils/validate_lang.pl data/lang_test || exit 1;

exit 0;
