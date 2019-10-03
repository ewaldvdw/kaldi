#!/bin/bash
#
# Author: Ewald van der Westhuizen
# Affiliation: Stellenbosch University
#

. path.sh

export LC_ALL=C

corpora_dir=
languages=eng
datadir=
set_list=trn

. utils/parse_options.sh # accept options

# Convert the strings with spaces to a list
languages=(${languages})
set_list=(${set_list})

for alang in "${languages[@]}"; do
    echo "Process data for language: ${alang}"
    for aset in "${set_list[@]}"; do
        if [ "${aset}" == "trn" ]; then
            aset_dir="train"
        elif [ "${aset}" == "dev" ]; then
            aset_dir="dev"
        elif [ "${aset}" == "tst" ]; then
            aset_dir="test"
        fi

        trns_fn="${corpora_dir}/nchlt_${alang}/transcriptions_kaldi/nchlt_${alang}.${aset}.txt"
        adatadir="${datadir}/nchlt_${alang}/${aset_dir}"

        [ -f "${trns_fn}" ] && echo "Found ${trns_fn}"

        [ ! -f "${adatadir}" ] && mkdir -p "${adatadir}"

        cp "${trns_fn}" "${adatadir}/text"
        # Use characters 7 to 14 contain the speaker ID
        paste -d' ' <(cut -d' ' -f1 "${adatadir}/text") <(cut -b1-14 "${adatadir}/text") > "${adatadir}/utt2spk"

        utils/utt2spk_to_spk2utt.pl "${adatadir}/utt2spk" > "${adatadir}/spk2utt" || exit 1;

        # Make the wav.scp file
        paste -d' ' <(cut -d' ' -f1 "${adatadir}/utt2spk") <(cut -d' ' -f2 "${adatadir}/utt2spk" | sed "s/^nchlt_${alang}_//g" | sed "s/[mf]$//g" | sed "s+^+${corpora_dir}/nchlt_${alang}/audio/+g") > "${adatadir}/wav.scp.edit"
        paste -d'/' "${adatadir}/wav.scp.edit" <(cut -d' ' -f1 "${adatadir}/utt2spk" | sed "s/$/.wav/g") > "${adatadir}/wav.scp"
        [ -f "${adatadir}/wav.scp.edit" ] && rm "${adatadir}/wav.scp.edit"

        utils/validate_data_dir.sh --no-feats $adatadir || exit 1
    done

done

exit 0





if [ $# -ne 1 ]; then
   echo "Argument should be the database directory, see ../run.sh for example."
   exit 1;
fi

train_flist=$*/lists/nchlt_eng.trn.lst
nl=`cat $train_flist | wc -l`
[ "$nl" -eq 74180 ] || echo "Warning: expected 74180 lines in nchlt_eng.trn.lst, got $nl"
dir=data/train
mkdir -p $dir
# Convert the transcritps into our format (no normalization yet)
./local/flist2scp.pl $train_flist | sort | awk -v trans_path="$*/transcriptions/" '{printf "%s %s%s\n",$1,trans_path,$2 }' > $dir/txt.scp

test_flist=$*/lists/nchlt_eng.tst.lst
nl=`cat $test_flist | wc -l`
[ "$nl" -eq 3232 ] || echo "Warning: expected 3232 lines in nchlt_eng.tst.lst, got $nl"
dir=data/test
mkdir -p $dir
# Convert the transcritps into our format (no normalization yet)
./local/flist2scp.pl $test_flist | sort | awk -v trans_path="$*/transcriptions/" '{printf "%s %s%s\n",$1,trans_path,$2 }' > $dir/txt.scp

# Prepare: test, train,
for set in test train; do
  dir=data/$set
  mkdir -p $dir

  # Do normalization step
  cat $dir/txt.scp | ./local/find_transcripts.pl | sort > $dir/text || exit 1;

  # Create scp's with wav's
  awk '{printf("%s sox %s -t wav -r 16000 - |\n", $1, $2);}' < $dir/txt.scp | sed -e 's/transcriptions/audio/g' | sed -e 's/.txt/.wav/g' > $dir/wav.scp
  cat $dir/wav.scp | awk '{ print $1, $1, "A"; }' > $dir/reco2file_and_channel

  # Make the utt2spk and spk2utt files
  cut -d' ' -f1 $dir/txt.scp > $dir/uttids
  cut -c1-3 $dir/uttids | paste -d' ' $dir/uttids - > $dir/utt2spk
  cat $dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $dir/spk2utt || exit 1;

  
  # Create empty 'glm' file
  echo ';; empty.glm
  [FAKE]     =>  %HESITATION     / [ ] __ [ ] ;; hesitation token
  ' > $dir/glm

  # Check that data dirs are okay!
  utils/validate_data_dir.sh --no-feats $dir || exit 1
done

