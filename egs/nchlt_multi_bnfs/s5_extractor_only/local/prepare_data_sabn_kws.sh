#!/bin/bash
#
# Data preparation for the SABN/English ASR-free BNF extraction for the keyword spotting experiments.
# Author: Ewald van der Westhuizen
# Date: Feb 2019
#

export LC_ALL=C

. path.sh

has_spkids=false

. utils/parse_options.sh # accept options

if [ $# -ne 3 ]; then
   echo "Argument should be the database directory, see ../run.sh for example."
   echo "First argument: the is the path to the luganda keyword dataset dir, e.g. /path/to/the/luganda_kws_dataset/luganda-keywords."
   echo "Second argument: the is the path to the luganda dataset dir containing the search utterances, e.g. /path/to/the/luganda_kws_dataset/luganda-transcribed."
   echo "Third argument: the local output data dir."
   exit 1;
fi

datadirin_kw=$1
datadirin_ut=$2
datadirout=$3


# For full length utterances
# Create the 'text' transcription file
for aset in test dev train; do

  dir=$datadirout/$aset
  [ ! -d "${dir}" ] && mkdir -p $dir

  if [ "${aset}" == "test" ]; then
      setpat=tst
  elif [ "${aset}" == "dev" ]; then
      setpat=dev
  elif [ "${aset}" == "train" ]; then
      setpat=trn
  fi

  echo "Writing $dir/text"
  sort $datadirin_ut/$aset/text | grep -v '^[ \t]*$' > $dir/text
  dos2unix $dir/text

  # create the wav.scp
  find $datadirin_ut/$aset/audio/ -name '*.wav' -exec realpath '{}' \; | sort > $dir/wav.scp_tmp
  if [ $(wc -l $dir/wav.scp_tmp | cut -d' ' -f1) -ne $(wc -l $dir/text | cut -d' ' -f1) ]; then
      echo "The number of wav files ($(wc -l $dir/wav.scp_tmp | cut -d' ' -f1)) not equal to the number of transcription utterances ($(wc -l $dir/text | cut -d' ' -f1)) in ${aset}"
      exit 1
  fi
  paste -d' ' <(cut -d' ' -f1 $dir/text) $dir/wav.scp_tmp > $dir/wav.scp
  [ -f $dir/wav.scp_tmp ] && rm $dir/wav.scp_tmp

  # Create 'uttids'
  cut -d' ' -f1 $dir/text > $dir/uttids

  # Make the utt2spk and spk2utt files
  paste -d' ' $dir/uttids $dir/uttids > $dir/utt2spk
  cat $dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $dir/spk2utt || exit 1;

  cat $dir/wav.scp | awk '{ print $1, $1, "A"; }' > $dir/reco2file_and_channel

  # Create empty 'glm' file
  echo ';; empty.glm
  [FAKE]     =>  %HESITATION     / [ ] __ [ ] ;; hesitation token
  ' > $dir/glm

  # Check that data dirs are okay!
  utils/validate_data_dir.sh --no-feats $dir || exit 1

done


# For isolated keywords
dir=$datadirout/keywords
[ ! -d "${dir}" ] && mkdir -p $dir

find "$datadirin_kw/" -name "*.wav" -exec realpath '{}' \; | sort > $dir/wav.scp_tmp
while read -r aline ; do
    basename $aline .wav
done <$dir/wav.scp_tmp >$dir/uttids

paste -d' ' $dir/uttids $dir/wav.scp_tmp | sort > $dir/wav.scp
[ -f $dir/wav.scp_tmp ] && rm $dir/wav.scp_tmp

# Make the utt2spk and spk2utt files
paste -d' ' $dir/uttids $dir/uttids | sort > $dir/utt2spk
cat $dir/utt2spk | utils/utt2spk_to_spk2utt.pl | sort > $dir/spk2utt || exit 1;

cat $dir/wav.scp | awk '{ print $1, $1, "A"; }' > $dir/reco2file_and_channel

# Create empty 'glm' file
echo ';; empty.glm
[FAKE]     =>  %HESITATION     / [ ] __ [ ] ;; hesitation token
' > $dir/glm

# Check that data dirs are okay!
utils/validate_data_dir.sh --no-text --no-feats $dir || exit 1

exit 0

