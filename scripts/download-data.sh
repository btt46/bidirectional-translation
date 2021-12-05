#!/bin/bash

set -e

EXPDIR=$PWD 
DATA=$EXPDIR/data 
mkdir -p $DATA/iwslt15

cd $DATA/iwslt15
    wget "https://nlp.stanford.edu/projects/nmt/data/iwslt15.en-vi/tst2012.en"  
    wget "https://nlp.stanford.edu/projects/nmt/data/iwslt15.en-vi/tst2012.vi"  
    wget "https://nlp.stanford.edu/projects/nmt/data/iwslt15.en-vi/tst2013.en"  
    wget "https://nlp.stanford.edu/projects/nmt/data/iwslt15.en-vi/tst2013.vi"  
    wget "https://nlp.stanford.edu/projects/nmt/data/iwslt15.en-vi/train.en" 
    wget "https://nlp.stanford.edu/projects/nmt/data/iwslt15.en-vi/train.vi"  
cd ../