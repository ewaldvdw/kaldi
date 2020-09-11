#!/usr/bin/env python

# Author: Ewald van der Westhuizen
# Affiliation: Stellenbosch University

from __future__ import print_function

import sys
import os
import codecs
from copy import deepcopy


def get_recordings_all(xmltree):
    return xmltree.findall('.//recording')

def filter_cleanup_apostrophes_at_wordbeginnings(xmltree, element_to_append_to):
    '''
    Returns a list of elements which has been filtered by keeping only the utterances
    occuring in the given keeputtslist of utterance names.
    An utterance name is e.g. similar to 'nchlt_afr_001m_0003'
    '''

    for arec in xmltree.iter(tag='recording'):
        orthwords = arec[0].text.split()
        newtext = []
        for awd in orthwords:
            if awd.startswith("'"):
                newtext.append(awd.replace("'", '', 1))
            else:
                newtext.append(awd)

        newrec = deepcopy(arec)
        newrec[0].text = ' '.join(newtext)
        element_to_append_to.append(newrec)

def filter_cleanup_hyphen_to_space(xmltree, element_to_append_to):
    '''
    Returns a list of elements which has been filtered by keeping only the utterances
    occuring in the given keeputtslist of utterance names.
    An utterance name is e.g. similar to 'nchlt_afr_001m_0003'
    '''

    for arec in xmltree.iter(tag='recording'):
        orthwords = arec[0].text.split()
        newtext = []
        for awd in orthwords:
            if '-' in awd:
                newtext.append(awd.replace("-", ' ', 1))
            else:
                newtext.append(awd)

        newrec = deepcopy(arec)
        newrec[0].text = ' '.join(newtext)
        element_to_append_to.append(newrec)


def filter_recordings_with_utterancelist(xmltree, element_to_append_to, keeputtslist):
    '''
    Returns a list of elements which has been filtered by keeping only the utterances
    occuring in the given keeputtslist of utterance names.
    An utterance name is e.g. similar to 'nchlt_afr_001m_0003'
    '''

    for arec in xmltree.iter(tag='recording'):
        # get the 'audio' attribute, which is the wavfilename.
        wavfilename_without_ext = os.path.splitext(os.path.basename(arec.get('audio')))[0]

        if wavfilename_without_ext in keeputtslist:
            element_to_append_to.append(deepcopy(arec))

def open_xmlfile(filename):
    '''
    Returns the ElementTree from the given XML file name.
    '''
    from lxml import etree
    xmltree = None
    with open(filename, 'r') as fid:
        xmltree = etree.parse(fid)
    return xmltree

def write_xmlfile(element, filename):

    from lxml import etree
    xmltree = etree.ElementTree(element=element)
    xmltree.write(filename, encoding='utf-8')

def xml_to_kaldi_text(xmlfilename, outfilename):
    '''
    Create word level transcription file in the format that Kaldi expects from the given NCHLT XML filename.
    ( Not used at the moment -->) Kaldi prefers that the speaker ID be a prefix of the utterance ID, hence we shuffle the standard NCHLT
    utterance ID a bit to meet this specification.
    E.g. `nchlt_eng_001m_0003` will become `s001m_nchlt_eng_0003`
    '''
    xmltree = open_xmlfile(xmlfilename)

    recordings_all = get_recordings_all(xmltree)
    with codecs.open(outfilename, mode='w', encoding='utf-8') as fid:
        
        for arec in xmltree.iter(tag='recording'):
            # change wav file name to equivalent label file name
            uttid = os.path.splitext(os.path.basename(arec.get('audio')))[0]
            if False:
                # Not used at the moment...
                # Parse and shuffle the components of the utterance ID to place the
                # speaker ID element first in the utterance ID.
                uttid_elements = uttid.split('_')
                uttid = "_".join(["s" + uttid_elements[2], uttid_elements[0], uttid_elements[1], uttid_elements[3]])
            # get the text from the child element 'orth'
            fid.write(uttid + ' ' + arec[0].text + '\n')


def create_set_from_listfilename(
    listfilename,
    setname,
    inputxmlfilename,
    outputxmlfilename):
    '''
    Create new xmlfile containing the transcriptions given in the given file listing
    the required utterance names.
    '''

    from lxml import etree
    with open(listfilename, 'r') as fidlistin:
        uttnamesset = fidlistin.readlines()
        uttnamesset = set([aline.strip() for aline in uttnamesset])

    xmltree = open_xmlfile(inputxmlfilename)

    rootel = etree.Element(setname)
    rootel2 = etree.Element(setname)
    rootel3 = etree.Element(setname)
    filter_recordings_with_utterancelist(xmltree, rootel, uttnamesset)
    filter_cleanup_apostrophes_at_wordbeginnings(rootel, rootel2)
    filter_cleanup_hyphen_to_space(rootel2, rootel3)
    write_xmlfile(rootel3, outputxmlfilename)

