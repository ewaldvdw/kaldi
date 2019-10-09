# Bottleneck feature extractor train on 9 languages of the NCHLT corpora

Author: Ewald van der Westhuizen
Affiliation: Stellenbosch University

This BNF extractor has been trained on the nine Bantu languages of the NCHLT corpora
(`nchlt_nbl`, `nchlt_nso`, `nchlt_sot`, `nchlt_ssw`, `nchlt_tsn`, `nchlt_tso`, `nchlt_ven`, `nchlt_xho`, `nchlt_zul`)
Only the training sets were used for the training of the BNF extractor. The standard Babel recipe (`egs/babel_multilang/s5`)
was used as a basis to start from. The recipe for the NCHLT BNF is in `egs/nchlt_multi_bnfs/s5` on Ewald's `nchlt_bnf_ewald_dev1`
branch of his Kaldi fork on Bitbucket.

Usage:

Create a `data/train_hires` and a `data/train_hiresi_pitch` directory that each contain the necessary files:

    spk2utt
    text
    utt2spk
    wav.scp

Run `run_extract_bnfs.sh`:

    bash run_extract_bnfs.sh

If all goes well, the BNFs should be in the `bnf/train` directory.

