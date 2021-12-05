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
DATA
