#!/bin/bash
#
#

. ./cmd.sh
[ -f path.sh ] && . ./path.sh   

set -e           #Exit on non-zero return code from any command
set -o pipefail  #Exit if any of the commands in the pipeline will
                 #return non-zero return code

set -u           #Fail on an undefined variable

nj=10
expdir=exp
datadir=data

has_spkids=true

bnf_model_dir="models_d39/nnet3/9lang"
global_extractor="models_d39/multi/nnet3/extractor"

# BNF extraction options

. utils/parse_options.sh

echo ===========================================================================
echo "         Speech Data & Lexicon & Language Model  Preparation             "
echo ===========================================================================

[ -d "${expdir}" ] && rm -rf "${expdir}"
[ -d "${datadir}" ] && rm -rf "${datadir}"

database_keywords="/home/ewaldvdw/projects/corpora/SABN_corpus/marcos_releases/corpora/keywordspotting/english/v1.1/data_kws/audio"
database_utterances="/home/ewaldvdw/projects/corpora/SABN_corpus/marcos_releases/corpora/sabn/data_search"

local/prepare_data_sabn_kws.sh --has_spkids "${has_spkids}" $database_keywords $database_utterances $datadir || exit 1


echo ============================================================================
echo "         MFCC Feature Extration & CMVN for Training and Test set           "
echo ============================================================================

for aset in dev test train keywords; do
    dump_bnf_dir="$expdir/bnf/${aset}"
    data_hires_dir="$datadir/${aset}_hires"
    data_hires_pitch_dir="$datadir/${aset}_hires_pitch"
    data_bnf_dir="$datadir/${aset}_bnf"
    ivector_dir=$expdir/ivectors/${aset}

    utils/copy_data_dir.sh ${datadir}/${aset} ${datadir}/${aset}_hires
    utils/copy_data_dir.sh ${datadir}/${aset} ${datadir}/${aset}_hires_pitch

    # Make hi-res MFCC features.
    mfccdir=mfcc_hires
#    if [ ! -f "${mfccdir}/.done" ]; then
        steps/make_mfcc.sh --cmd "$train_cmd" --mfcc-config conf/mfcc_hires.conf --nj ${nj} ${data_hires_dir} ${expdir}/make_mfcc_hires/${aset} $mfccdir
        utils/fix_data_dir.sh ${data_hires_dir}
        steps/compute_cmvn_stats.sh ${data_hires_dir} ${expdir}/make_mfcc_hires/${aset} $mfccdir
        utils/fix_data_dir.sh ${data_hires_dir}
#        touch ${mfccdir}/.done
#    fi

    mfccdir=mfcc_hires_pitch
#    if [ ! -f "${mfccdir}/.done" ]; then
        steps/make_mfcc_pitch.sh --cmd "$train_cmd" --mfcc-config conf/mfcc_hires.conf --pitch-config conf/pitch.conf --nj ${nj} ${data_hires_pitch_dir} ${expdir}/make_mfcc_hires_pitch/${aset} $mfccdir
        utils/fix_data_dir.sh ${data_hires_pitch_dir}
        steps/compute_cmvn_stats.sh ${data_hires_pitch_dir} ${expdir}/make_mfcc_hires_pitch/${aset} $mfccdir
        utils/fix_data_dir.sh ${data_hires_pitch_dir}
#        touch ${mfccdir}/.done
#    fi

    #####################################################################################

    if [ ! -f "${ivector_dir}/.done" ]; then
        steps/online/nnet2/extract_ivectors_online.sh \
            --cmd "$train_cmd" --nj ${nj} \
            $data_hires_dir $global_extractor $ivector_dir || exit 1;
        touch "${ivector_dir}/.done"
    fi

    #########################################################################################

    [ ! -d $dump_bnf_dir ] && mkdir -p $dump_bnf_dir
    if [ ! -f $data_bnf_dir/.done ]; then
        # put the archives in ${dump_bnf_dir}/.
        steps/nnet3/make_bottleneck_features.sh --use-gpu true --nj ${nj} --cmd "$train_cmd" \
            --ivector-dir $ivector_dir \
            tdnn_bn.renorm $data_hires_pitch_dir $data_bnf_dir \
            $bnf_model_dir $dump_bnf_dir/log $dump_bnf_dir || exit 1;
        touch $data_bnf_dir/.done
    fi

    if true; then
        # If a text version of the features are required, set false to true to run this step.
        # Copy the feature to convert them to text format for easy inspection.
        echo "Converting binary features to text format."
        $train_cmd JOB=1:$nj $dump_bnf_dir/log/bin_to_txt.JOB.log \
            copy-feats ark:$dump_bnf_dir/raw_bnfeat_${aset}_hires_pitch.JOB.ark \
            ark,t:$dump_bnf_dir/raw_bnfeat_${aset}_hires_pitch.JOB.txt \
            || exit 1;
        cat $dump_bnf_dir/raw_bnfeat_${aset}_hires_pitch.*.txt > $dump_bnf_dir/raw_bnfeat_${aset}_hires_pitch.txt
    fi

done

exit 0




