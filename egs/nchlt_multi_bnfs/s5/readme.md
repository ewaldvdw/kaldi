# The NCHLT BNF extractor

This recipe to train a bottleneck feature (BNF) extractor using the NCHLT speech corpora for South African language
follows the Babel BNF extractor recipe as closely as possible.

The NN architecture currently used in the Babel recipe is TDNN, which is what is used here.

Extractors with BN dimensions of 39, 80 and 120 have been trained on the training set data of the nine Bantu langauges in the NCHLT corpora.

For any questions and queries, contact the repository mainteners (Ewald, Trideba or Thomas).


## Required corpora and resources

* *The NCHLT speech corpora* for the nine South African Bantu languages. The corpora can be downloaded free of charge from 
  the SADiLaR (https://www.sadilar.org) resource website.
* *The NCHLT corpus dictionaries.* The corpus dictionaries were available at https://sites.google.com/site/nchltspeechcorpus
  but have recently became less accessible. We therefore include these dictionary files in our repository under `resources/corpus_dictionaries/`.
* The training, development and test set definitions provided under `resources/set_definitions/`.


## Corpora preparation

The downloading and preparation of the speech corpora are done automatically in the `egs/nchlt_multi_bnf/s5/run.sh`.
The speech corpora file names have the following format, `nchlt.speech.corpus.<language_code>.zip`.
The will be downloaded and placed under a `data` directory in your cloned Kaldi root directory (`$KALDI_ROOT/data`).
The content of this data directory should look as follows after unzipping the corpora archives:

    /<path_to_your_kaldi_root_dir>/data/nchlt_nbl/
                                        ├── audio
                                        │   ├─ 001
                                        │   │  └─ <wav_files_for_speaker_001>
                                        │   ├─ 002
                                        │   │  └─ <wav_files_for_speaker_002>
                                        │   └─ etc. ...
                                        └── transcriptions
                                            ├── nchlt_nbl.trn.xml
                                            └── nchlt_nbl.tst.xml

    /<path_to_your_kaldi_root_dir>/data/nchlt_nso/
                                        ├── audio
                                        │   ├─ 001
                                        │   │  └─ <wav_files_for_speaker_001>
                                        │   ├─ 002
                                        │   │  └─ <wav_files_for_speaker_002>
                                        │   └─ etc. ...
                                        └── transcriptions
                                            ├── nchlt_nso.trn.xml
                                            └── nchlt_nso.tst.xml
    ...
    etc.

Conversion of the XML transcription files (`data/nchlt_<language_code>/transcriptions/nchlt_<language_code>.trn.xml`)
into a corresponding Kaldi-compatible transcription file called `data/nchlt_<language_code>/transcriptions_kaldi/nchlt_<language_code>.trn.txt`
is also done in the run script.

## Usage

Got to the `/<path_to_your_kaldi_root_dir>/egs/nchlt_multi_bnfs/s5` directory. And execute the `run.sh` script with `bash`:

    bash run.sh

## Changing the BNF dimensionality

Edit line 3 in `conf/common.fullLP` to your choosing:

    bottleneck_dim=39

And, edit line 41 in `run.sh` to the same value:

    bnf_dim=39

