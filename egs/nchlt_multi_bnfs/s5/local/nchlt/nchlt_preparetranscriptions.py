#!/usr/bin/env python

# Author: Ewald van der Westhuizen
# Affiliation: Stellenbosch University

from __future__ import print_function

import sys
import os
import nchlt_xmlparse as nxml

# Apologies for the hardcoded values... it is not ideal.

langs = ['nbl', 'nso', 'sot', 'ssw', 'tsn', 'tso', 'ven', 'xho', 'zul']

set_list = ['trn', 'dev', 'tst']

# A data directory under Kaldi root where the NCHLT speech corpora
# have been unzipped.
corpora_dir = '../../../data'


if __name__ == '__main__':

    for alang in langs:
        for aset in set_list:

            acorp_dir = os.path.join(corpora_dir, 'nchlt_' + alang)
            if not os.path.isfile(os.path.join(acorp_dir, 'transcriptions', 'nchlt_' + alang + '.trn.xml')):
                continue

            if not os.path.isdir( os.path.join(acorp_dir, 'transcriptions_kaldi') ):
                os.makedirs(os.path.join(acorp_dir, 'transcriptions_kaldi'))

            uttid_list_fn = os.path.join('resources', 'set_definitions', 'nchlt_' + alang, 'nchlt_' + alang + '.' + aset + '.lst')

            if aset == 'dev' or aset == 'trn':
                infn = os.path.join(acorp_dir, 'transcriptions', 'nchlt_' + alang + '.trn.xml')
                outfn = os.path.join(acorp_dir, 'transcriptions_kaldi', 'nchlt_' + alang + '.' + aset + '.xml')
                print('Extracting', aset , 'set from', infn, 'and saving to', outfn)
                nxml.create_set_from_listfilename(
                        uttid_list_fn,
                        aset,
                        infn,
                        outfn)
                infn = outfn
            elif aset == 'tst':
                infn = os.path.join(acorp_dir, 'transcriptions', 'nchlt_' + alang + '.' + aset + '.xml')

            outfn = os.path.join(acorp_dir, 'transcriptions_kaldi', 'nchlt_' + alang + '.' + aset + '.txt')

            print('Converting', infn, 'to', outfn)
            nxml.xml_to_kaldi_text(infn, outfn)

