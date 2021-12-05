#!/bin/bash

EXPDIR=$PWD

# mosesdecoder
if [ ! -d $EXPDIR/mosesdecoder ]; then
    echo 'Cloning Moses github repository (for tokenization scripts)...'
    git clone https://github.com/moses-smt/mosesdecoder.git
fi

# fairseq
if [ ! -d $EXPDIR/fairseq ]; then 
    echo 'Cloning fairseq repository (for training models)...'
    git clone https://github.com/pytorch/fairseq
    cd fairseq
    pip3.6 install --editable ./
    cd ../
fi


# subword-nmt 

echo 'Cloning Subword NMT repository (for BPE pre-processing)...'
git clone https://github.com/rsennrich/subword-nmt.git
# pip3.6 install subword-nmt