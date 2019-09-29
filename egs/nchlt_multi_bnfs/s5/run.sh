#!/bin/bash

# Author: Ewald van der Westhuizen
# Affiliation: Stellenbosch University

# The main run script to train the NCHLT BNF extractor.
# The recipe is based on the Babel multilingual BNF extractor.

. ./cmd.sh
[ -f path.sh ] && . ./path.sh

stage=0

# Acoustic Model Parameters
numLeavesTri=2500
numGaussTri=30000
numLeavesMLLT=6000
numGaussMLLT=75000
numLeavesSAT=6000 
numGaussSAT=75000 
numGaussUBM=800   
numLeavesSGMM=10000     
numGaussSGMM=80000

# Lexicon and Language Model Parameters
oovsymbol="<unk>"

train_nj=12
decode_nj=8

datadir=data
expdir=exp

languages=(eng nbl nso sot ssw tsn tso ven xho zul)

database="/home/ewaldvdw/projects/corpora"
lm=

# Parse command line options
. utils/parse_options.sh

if [ $stage -le 0 ]; then
    echo ===========================================================================
    echo "         Prepare speech data"
    echo ===========================================================================

    datadirs_to_merge=()
    for alang in "${languages[@]}"; do
        local/prepare_data.sh --corpora_dir $database --set-list "trn" --languages "${alang}" --datadir "${datadir}" || exit 1
        datadirs_to_merge=(${datadirs_to_merge[*]} "${datadir}/nchlt_${alang}/train")
    done

    # Merge the data direcories
    utils/combine_data.sh ${datadir}/train ${datadirs_to_merge[*]}
    utils/validate_data_dir.sh --no-feats ${datadir}/train
fi


if [ $stage -le 1 ]; then
    echo ===========================================================================
    echo "         Prepare pronunciation dictionary"
    echo ===========================================================================

    lexs_to_merge=()
    for alang in "${languages[@]}"; do
        echo "Preparing lexicon for: ${alang}"
        lexicon_fn=$(ls -1 ${database}/nchlt_${alang}/nchlt_corpus_${alang}_*dict.gz)
        lex_outdir=${datadir}/nchlt_${alang}/local/dict
        echo "Using lexicon file: ${lexicon_fn}"
        local/prepare_dict.sh $lexicon_fn ${lex_outdir} || exit 1
        lexs_to_merge=(${lexs_to_merge[*]} ${lex_outdir})
    done

    # Merge the lexicons
    local/merge_dictionary_dirs.sh "${datadir}/local/dict" ${lexs_to_merge[*]}

    utils/prepare_lang.sh data/local/dict "!SIL" data/local/lang data/lang || exit 1

    #local/prepare_lm.sh $lm || exit 1
fi


if [ $stage -le 2 ]; then
    echo ============================================================================
    echo "         MFCC Feature Extration & CMVN for Training and Test set           "
    echo ============================================================================

    # Now make MFCC features.
    mfccdir=mfcc

    #for x in train test; do 
    for aset in train; do 
      steps/make_mfcc.sh --cmd "$train_cmd" --nj $train_nj data/$aset exp/make_mfcc/$aset $mfccdir
      utils/fix_data_dir.sh data/$aset; # run by hand due to an error in previous step
      steps/compute_cmvn_stats.sh data/$aset exp/make_mfcc/$aset $mfccdir
      utils/fix_data_dir.sh data/$aset; # run by hand due to an error in previous step
    done
fi


if [ $stage -le 3 ]; then
    echo ============================================================================
    echo "                     Monophone training"
    echo ============================================================================

    steps/train_mono.sh --nj "$train_nj" --cmd "$train_cmd" ${datadir}/train ${datadir}/lang ${expdir}/mono
fi

### Triphone
if [ $stage -le 4 ]; then
    echo "Starting triphone training."
    steps/align_si.sh --nj $train_nj --cmd "$train_cmd" $datadir/train $datadir/lang $expdir/mono $expdir/mono_ali || exit 1;
    steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" $numLeavesTri $numGaussTri $datadir/train $datadir/lang $expdir/mono_ali $expdir/tri1 || exit 1;
    echo "Triphone training done."
fi

if [ $stage -le 5 ]; then
    steps/align_si.sh --nj $train_nj --cmd "$train_cmd" $datadir/train $datadir/lang $expdir/tri1 $expdir/tri1_ali || exit 1;
    echo "Starting LDA+MLLT training."
    steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" $numLeavesMLLT $numGaussMLLT $datadir/train $datadir/lang $expdir/tri1_ali $expdir/tri2 || exit 1;
fi

if [ $stage -le 6 ]; then
    steps/align_si.sh --nj $train_nj --cmd "$train_cmd" --use-graphs true $datadir/train $datadir/lang $expdir/tri2 $expdir/tri2_ali || exit 1;
    echo "Starting SAT+FMLLR training."
    steps/train_sat.sh --cmd "$train_cmd" $numLeavesSAT $numGaussSAT $datadir/train $datadir/lang $expdir/tri2_ali $expdir/tri3 || exit 1;
fi

if [ $stage -le 7 ]; then
    echo "Getting alignments using SAT+FMLLR models."
    steps/align_si.sh --nj $train_nj --cmd "$train_cmd" --use-graphs true $datadir/train $datadir/lang $expdir/tri3 $expdir/tri3_ali || exit 1;
fi



exit 0

# local/chain/multilingual/run_tdnn_f.sh --stage 8

# Train the BNF extractor.
local/nnet3/run_multilingual_bnf.sh


