#!/bin/bash
#
# Data preparation for the MFCC step for Luganda ASR-free keyword spotting experiments.
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
for set in test dev train; do

  dir=$datadirout/$set
  [ ! -d "${dir}" ] && mkdir -p $dir

  if [ "${set}" == "test" ]; then
      setpat=tst
  elif [ "${set}" == "dev" ]; then
      setpat=dev
  elif [ "${set}" == "train" ]; then
      setpat=trn
  fi

  echo "Writing $dir/text"
  #grep "^lugr_${setpat}_" $datadirin_ut/text | awk -v setpat="${setpat}" '{printf "s%s%06i_%s\n", setpat, NR, $0}' | sort > $dir/text
  grep "^lugr_${setpat}_" $datadirin_ut/text | sort > $dir/text
  dos2unix $dir/text

  # Remove a specific problematic utterance (too short; segments begin and end indices equal and fails validation) from the training set
  if [ "${set}" == "train" ]; then
      sed -i "/lugr_trn_*.*_87\.5\.2015\-08\-26T11\.25\.0500000000000000000000000_00025409\-00025409/d" $dir/text
  fi

  # Create wav.scp and segments file
  # Format for segments file: <utterance-id> <recording-id> <segment-begin> <segment-end>
  # <segment-begin> and <segment-end> in seconds
  python local/create_segments_file.py $dir/text $datadirin_ut/${setpat} $dir/segments $dir/wav.scp

  # Create 'uttids'
  cut -d' ' -f1 $dir/text > $dir/uttids


  # Make the utt2spk and spk2utt files
  if $has_spkids; then
      grep -o "^lugr_[td][ers][nvt]_[sS][pP][kK][0-9]\{6\}" $dir/uttids | paste -d' ' $dir/uttids - > $dir/utt2spk
  else
      paste -d' ' $dir/uttids $dir/uttids > $dir/utt2spk
  fi
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

if $has_spkids; then
    find "$datadirin_kw/" -name "*.wav" -printf "%f\n" | sed 's/\.wav//g' | awk -F'_' '{OFS = "_"; print "keyw", $4, $1, $2, $3}' | sort > $dir/uttids
else
    find "$datadirin_kw/" -name "*.wav" -printf "%f\n" | sed 's/\.wav//g' | awk -F'_' '{OFS = "_"; print "keyw", $2, $1}' > $dir/uttids
fi

# Make the utt2spk and spk2utt files
paste -d' ' $dir/uttids $dir/uttids > $dir/utt2spk
cat $dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $dir/spk2utt || exit 1;

#python local/create_segments_file.py $dir/text $datadirin/luganda-transcribed/with_spk_ids/${setpat} $dir/segments $dir/wav.scp
if $has_spkids; then
    find "$datadirin_kw/" -name "*.wav" -printf "%p\n" | sort | paste -d' ' $dir/uttids - > $dir/wav.scp
else
    find "$datadirin_kw/" -name "*.wav" -printf "%p\n" | paste -d' ' $dir/uttids - > $dir/wav.scp

    tmpfn=$(mktemp); sort $dir/uttids > "${tmpfn}" && mv "${tmpfn}" $dir/uttids
    tmpfn=$(mktemp); sort $dir/utt2spk > "${tmpfn}" && mv "${tmpfn}" $dir/utt2spk
    tmpfn=$(mktemp); sort $dir/spk2utt > "${tmpfn}" && mv "${tmpfn}" $dir/spk2utt
    tmpfn=$(mktemp); sort $dir/wav.scp > "${tmpfn}" && mv "${tmpfn}" $dir/wav.scp
fi


cat $dir/wav.scp | awk '{ print $1, $1, "A"; }' > $dir/reco2file_and_channel

# Create empty 'glm' file
echo ';; empty.glm
[FAKE]     =>  %HESITATION     / [ ] __ [ ] ;; hesitation token
' > $dir/glm

# Check that data dirs are okay!
utils/validate_data_dir.sh --no-text --no-feats $dir || exit 1

exit 0

