#!/bin/bash

# Author: Ewald van der Westhuizen, Trideba Padhi
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

train_nj=10
decode_nj=8

datadir=data
expdir=exp

languages=(nbl nso sot ssw tsn tso ven xho zul)

# Location of the NCHLT corpora. In our setup we put them in $KALDI_ROOT/data/.
database="$KALDI_ROOT/data"
lm=

bnf_dim=39
# Use nn_train_iter to continue an interrupted NN training session. Just specify the iteration from which to continue.
bnf_train_stage=-10

# Parse command line options
. utils/parse_options.sh

# The download link for the NCHLT corpora.
declare -A dl_links
dl_links[afr]="https://repo.sadilar.org/bitstream/handle/20.500.12185/280/nchlt.speech.corpus.afr.zip?sequence=3&isAllowed=y"
dl_links[eng]="https://repo.sadilar.org/bitstream/handle/20.500.12185/274/nchlt.speech.corpus.eng_1.zip?sequence=3&isAllowed=y"
dl_links[nbl]="https://repo.sadilar.org/bitstream/handle/20.500.12185/272/nchlt.speech.corpus.nbl.zip?sequence=3&isAllowed=y"
dl_links[nso]="https://repo.sadilar.org/bitstream/handle/20.500.12185/270/nchlt.speech.corpus.nso.zip?sequence=3&isAllowed=y"
dl_links[sot]="https://repo.sadilar.org/bitstream/handle/20.500.12185/278/nchlt.speech.corpus.sot.zip?sequence=3&isAllowed=y"
dl_links[ssw]="https://repo.sadilar.org/bitstream/handle/20.500.12185/271/nchlt.speech.corpus.ssw.zip?sequence=3&isAllowed=y"
dl_links[tsn]="https://repo.sadilar.org/bitstream/handle/20.500.12185/281/nchlt.speech.corpus.tsn.zip?sequence=3&isAllowed=y"
dl_links[tso]="https://repo.sadilar.org/bitstream/handle/20.500.12185/277/nchlt.speech.corpus.tso.zip?sequence=3&isAllowed=y"
dl_links[ven]="https://repo.sadilar.org/bitstream/handle/20.500.12185/276/nchlt.speech.corpus.ven.zip?sequence=3&isAllowed=y"
dl_links[xho]="https://repo.sadilar.org/bitstream/handle/20.500.12185/279/nchlt.speech.corpus.xho.zip?sequence=3&isAllowed=y"
dl_links[zul]="https://repo.sadilar.org/bitstream/handle/20.500.12185/275/nchlt.speech.corpus.zul.zip?sequence=3&isAllowed=y"


if [ $stage -le 0 ]; then
    echo ===========================================================================
    echo "         Prepare speech data"
    echo ===========================================================================

    [ ! -d "$KALDI_ROOT/data" ] && mkdir -p "$KALDI_ROOT/data"

    # Download the speech corpora if they haven't been yet.
    for alang in "${languages[@]}"; do
        if [ ! -f "$KALDI_ROOT/data/nchlt.speech.corpus.${alang}.zip" ]; then
            read -p "Proceed to download NCHLT speech corpus for ${alang}? [Y/n]: " ananswer
            if [ "$ananswer" != "n" ]; then
                echo "Downloading the speech corpus for $alang."
                wget -O "$KALDI_ROOT/data/nchlt.speech.corpus.${alang}.zip" "${dl_links[$alang]}"
            fi
        fi
    done

    # Unzip the downloaded corpora.
    for alang in "${languages[@]}"; do
        if [ -f "$KALDI_ROOT/data/nchlt_$alang/transcriptions/nchlt_${alang}.trn.xml" ]; then
            echo "Using existing $KALDI_ROOT/data/nchlt_${alang}/"
        elif [ -f "$KALDI_ROOT/data/nchlt.speech.corpus.${alang}.zip" ]; then
            echo "Unzipping $KALDI_ROOT/data/nchlt.speech.corpus.${alang}.zip"
            unzip -d "$KALDI_ROOT/data/" "$KALDI_ROOT/data/nchlt.speech.corpus.${alang}.zip" >/dev/null
        else
            echo "Error during Downloading/unzipping of speech corpus for ${alang}"
            exit 1
        fi
    done

    # Convert the XML transcriptions to Kaldi-compatible text.
    PYTHON_PATH=$PYTHON_PATH; python local/nchlt/nchlt_preparetranscriptions.py

    # Do data preparation.
    for alang in "${languages[@]}"; do
        local/prepare_data.sh --corpora_dir $database --set-list "trn" --languages "${alang}" --datadir "${datadir}" || exit 1
    done

fi


if [ $stage -le 1 ]; then
    echo ===========================================================================
    echo "         Prepare pronunciation dictionary"
    echo ===========================================================================

    for alang in "${languages[@]}"; do
        echo "Preparing lexicon for: ${alang}"
        lexicon_fn="resources/corpus_dictionaries/nchlt_corpus_${alang}_*dict.gz"
        lex_outdir=${datadir}/nchlt_${alang}/local/dict
        echo "Using lexicon file: ${lexicon_fn}"
        local/prepare_dict.sh $lexicon_fn ${lex_outdir} || exit 1
        utils/prepare_lang.sh ${datadir}/nchlt_${alang}/local/dict "!SIL" ${datadir}/nchlt_${alang}/local/lang ${datadir}/nchlt_${alang}/lang || exit 1
    done

fi


if [ $stage -le 2 ]; then
    echo ============================================================================
    echo "         MFCC Feature Extration & CMVN for Training and Test set           "
    echo ============================================================================

    # Now make MFCC features.
    for alang in "${languages[@]}"; do
        mfccdir=mfcc/nchlt_${alang}

        #for x in train test; do 
        for aset in train; do 
          #steps/make_mfcc.sh --cmd "$train_cmd" --nj $train_nj ${datadir}/nchlt_${alang}/$aset ${expdir}/nchlt_${alang}/make_mfcc/$aset $mfccdir
          steps/make_mfcc_pitch.sh --cmd "$train_cmd" --nj $train_nj ${datadir}/nchlt_${alang}/$aset ${expdir}/nchlt_${alang}/make_mfcc/$aset $mfccdir
          utils/fix_data_dir.sh ${datadir}/nchlt_${alang}/$aset; # run by hand due to an error in previous step
          steps/compute_cmvn_stats.sh ${datadir}/nchlt_${alang}/$aset ${expdir}/nchlt_${alang}/make_mfcc/$aset $mfccdir
          utils/fix_data_dir.sh ${datadir}/nchlt_${alang}/$aset; # run by hand due to an error in previous step
        done
    done
fi


if [ $stage -le 3 ]; then
    echo ============================================================================
    echo "                     Monophone training"
    echo ============================================================================

    for alang in "${languages[@]}"; do
        steps/train_mono.sh --nj "$train_nj" --cmd "$train_cmd" ${datadir}/nchlt_${alang}/train ${datadir}/nchlt_${alang}/lang ${expdir}/nchlt_${alang}/mono
    done
fi

### Triphone
if [ $stage -le 4 ]; then
    echo "Starting triphone training."
    for alang in "${languages[@]}"; do
        steps/align_si.sh --nj $train_nj --cmd "$train_cmd" $datadir/nchlt_${alang}/train $datadir/nchlt_${alang}/lang $expdir/nchlt_${alang}/mono $expdir/nchlt_${alang}/mono_ali || exit 1;
        steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" $numLeavesTri $numGaussTri $datadir/nchlt_${alang}/train $datadir/nchlt_${alang}/lang $expdir/nchlt_${alang}/mono_ali $expdir/nchlt_${alang}/tri1 || exit 1;
    done
    echo "Triphone training done."
fi

if [ $stage -le 5 ]; then
    echo "Starting LDA+MLLT training."
    for alang in "${languages[@]}"; do
        steps/align_si.sh --nj $train_nj --cmd "$train_cmd" $datadir/nchlt_${alang}/train $datadir/nchlt_${alang}/lang $expdir/nchlt_${alang}/tri1 $expdir/nchlt_${alang}/tri1_ali || exit 1;
        steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" $numLeavesMLLT $numGaussMLLT $datadir/nchlt_${alang}/train $datadir/nchlt_${alang}/lang $expdir/nchlt_${alang}/tri1_ali $expdir/nchlt_${alang}/tri2 || exit 1;
    done
fi

if [ $stage -le 6 ]; then
    echo "Starting SAT+FMLLR training."
    for alang in "${languages[@]}"; do
        steps/align_si.sh --nj $train_nj --cmd "$train_cmd" --use-graphs true $datadir/nchlt_${alang}/train $datadir/nchlt_${alang}/lang $expdir/nchlt_${alang}/tri2 $expdir/nchlt_${alang}/tri2_ali || exit 1;
        steps/train_sat.sh --cmd "$train_cmd" $numLeavesSAT $numGaussSAT $datadir/nchlt_${alang}/train $datadir/nchlt_${alang}/lang $expdir/nchlt_${alang}/tri2_ali $expdir/nchlt_${alang}/tri3 || exit 1;
    done
fi

if [ $stage -le 7 ]; then
    echo "Getting alignments using SAT+FMLLR models."
    for alang in "${languages[@]}"; do
        steps/align_si.sh --nj $train_nj --cmd "$train_cmd" --use-graphs true $datadir/nchlt_${alang}/train $datadir/nchlt_${alang}/lang $expdir/nchlt_${alang}/tri3 $expdir/nchlt_${alang}/tri3_ali || exit 1;
    done
fi


if [ $stage -le 8 ]; then
    # Train the BNF extractor.
    local/nnet3/run_multilingual_bnf.sh --bnf-dim "${bnf_dim}" --bnf-train-stage ${bnf_train_stage} --alidir tri3_ali nchlt_nbl
fi

