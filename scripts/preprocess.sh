#!/bin/bash
set -e

SRCS="en vi"
TGTS="vi en"
BPESIZE=5000

EXPDIR=$PWD 

# Libraries and Framework
MOSES=$EXPDIR/mosesdecoder/scripts
NORM=$MOSES/tokenizer/normalize-punctuation.perl
TOK=$MOSES/tokenizer/tokenizer.perl
DEES=$MOSES/tokenizer/deescape-special-chars.perl
TRUECASER_TRAIN=$MOSES/recaser/train-truecaser.perl
TRUECASER=$MOSES/recaser/truecase.perl
FARISEQ=$PWD/fairseq

# Data
DATASET=$EXPDIR/dataset
RAW_DATA=$DATASET/iwslt15
DATA=$DATASET/data
PROCESSED_DATA=$DATASET/processed-data
NORMALIZED_DATA=$DATASET/normalized
TOKENIZED_DATA=$DATASET/tok
TRUECASED_DATA=$DATASET/truecased
BPE_DATA=$DATASET/bpe-data
BIN_DATA=$DATASET/bin-data

DATA_NAME="train valid test"

# scripts
SCRIPTS=$EXPDIR/scripts

TEXT_UTILS=$EXPDIR/utils


