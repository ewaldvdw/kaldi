# The NCHLT BNF extractor

I followed the Babel BNF extractor recipe as closely as I could.

The NN architecture currently used in the Babel recipe is TDNN, which is what I used here.
We want to experiment with TDNN-F too, but this has to be implemented still.

Extractors with BN dimensions of 39, 80 and 120 have been trained on the training set data of the nine Bantu langauges in the NCHLT corpora.


## Required corpora

Get the zipped corpora from Ewald. The MD5 signatures for these zip files are:

    f7513996116d3cb445bdef716af981ba  nchlt_afr.zip
    af259138410a95fd22461a5dd1e2d82a  nchlt_eng.zip
    cdabef2dac225bbaaf8b20b1fe8b3e35  nchlt_nbl.zip
    414dc3537320a9bd60218f847173b3ab  nchlt_nso.zip
    852e947c65a0475f228554afe2310cbc  nchlt_sot.zip
    92a4d5535a373907076dc81b50c392e7  nchlt_ssw.zip
    45bb748589878c9c25335c96172d0c81  nchlt_tsn.zip
    cd469cce251a6877ddc8c36f4b2f5503  nchlt_tso.zip
    321c32b707942beafdc7170f44b3e4ac  nchlt_ven.zip
    b7e5095a6c6dc008605f38093f1bf601  nchlt_xho.zip
    b7febbbabf7698528761b39cd6528f83  nchlt_zul.zip

Under your cloned Kaldi root directory ($KALDI_ROOT), make a directory called `data` and unzip each of the corpora zip files in the `data` directory.
The content of this data directory should look as follows:

    /<path_to_your_kaldi_root_dir>/data/nchlt_afr
                                       ├── audio
                                       │   ├─ 001
                                       │   │  └─ <wav_files_for_speaker_001>
                                       │   ├─ 002
                                       │   │  └─ <wav_files_for_speaker_002>
                                       │   └─ etc. ...
                                       ├── nchlt_afr.dev.lst
                                       ├── nchlt_afr.trn.lst
                                       ├── nchlt_afr.tst.lst
                                       ├── nchlt_corpus_afr_v0.1.dict.gz
                                       ├── transcriptions
                                       │   ├── nchlt_afr.trn.xml
                                       │   └── nchlt_afr.tst.xml
                                       └── transcriptions_kaldi
                                           ├── nchlt_afr.dev.txt
                                           ├── nchlt_afr.dev.xml
                                           ├── nchlt_afr.trn.txt
                                           ├── nchlt_afr.trn.xml
                                           └── nchlt_afr.tst.txt

    /<path_to_your_kaldi_root_dir>/data/nchlt_eng/
                                       ├── audio
                                       │   ├─ 001
                                       │   │  └─ <wav_files_for_speaker_001>
                                       │   ├─ 002
                                       │   │  └─ <wav_files_for_speaker_002>
                                       │   └─ etc. ...
                                       ├── nchlt_eng.dev.lst
                                       ├── nchlt_eng.trn.lst
                                       ├── nchlt_eng.tst.lst
                                       ├── nchlt_corpus_eng_v0.1.dict.gz
                                       ├── transcriptions
                                       │   ├── nchlt_eng.trn.xml
                                       │   └── nchlt_eng.tst.xml
                                       └── transcriptions_kaldi
                                           ├── nchlt_eng.dev.txt
                                           ├── nchlt_eng.dev.xml
                                           ├── nchlt_eng.trn.txt
                                           ├── nchlt_eng.trn.xml
                                           └── nchlt_eng.tst.txt

    /<path_to_your_kaldi_root_dir>/data/nchlt_nbl/
                                       ├── etc. etc. The rest of the corpora follow the same pattern.

    /<path_to_your_kaldi_root_dir>/data/nchlt_nso/
                                       ├── etc. etc. The rest of the corpora follow the same pattern.
    ...
    etc.

Got to the `/<path_to_your_kaldi_root_dir>/egs/nchlt_multi_bnfs/s5` directory. And execute the `run.sh` script with `bash`:

    bash run.sh

Hopefully you don't see any error messages.

