import sys, os
from os import path

# Arg 1: The input text file name
# Arg 2: The location (directory) of the wav files
# Arg 3: The output segments file name
# Arg 4: The output wav.scp file name

# Output segment file format <utterance-id> <recording-id> <segment-begin> <segment-end>
# <segment-begin> and <segment-end> in seconds

infn = sys.argv[1]
wavsdir = sys.argv[2]
outsegsfn = sys.argv[3]
outwavfn = sys.argv[4]

with open(infn, 'r') as fin:
    indat = [aline.strip().split() for aline in fin]

# Transform the input data to our segment file requirement
outsegslines = []
outwavslines = set([])
for aitem in indat:
    uttid = aitem[0]
    split_ = uttid.split('_')
    if len(split_) == 5:
        # Possible includes speaker ID
        spkid_recid = "_".join(split_[2:4])
        split_segs = split_[4].split('-')
    elif len(split_) == 4:
        # Without speaker ID
        spkid_recid = split_[2]
        split_segs = split_[3].split('-')
    # Convert the segment (frame) index to seconds
    segbeg = str(float(split_segs[0]) / 100)
    segend = str(float(split_segs[1]) / 100)
    outsegslines.append( ' '.join([uttid, spkid_recid, segbeg, segend]) + "\n" )

    #outwavslines.add( ' '.join([spkid+"_"+recid, path.join(wavsdir, spkid+"_"+recid + '.wav')]) +  "\n" )
    outwavslines.add( ' '.join([spkid_recid, "sox", path.join(wavsdir, spkid_recid + '.wav'), "-t wav -r 16000 -c 1 - |"]) +  "\n" )

with open(outsegsfn, 'w') as fout:
    fout.writelines(sorted(outsegslines))

with open(outwavfn, 'w') as fout:
    fout.writelines(sorted(outwavslines))

