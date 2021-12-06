#!/bin/bash
set -e

EXPDIR=$PWD
BPESIZE=5000

# Libraries and Framework
MOSES=$EXPDIR/mosesdecoder/scripts
NORM=$MOSES/tokenizer/normalize-punctuation.perl
TOK=$MOSES/tokenizer/tokenizer.perl
DEES=$MOSES/tokenizer/deescape-special-chars.perl
TRUECASER_TRAIN=$MOSES/recaser/train-truecaser.perl
TRUECASER=$MOSES/recaser/truecase.perl
FARISEQ=$PWD/fairseq


DATASET=$EXPDIR/dataset
TRANSLATION_DATA=$DATASET/translation-data
BPE_MODEL=$DATASET/bpe-model
TRUECASED_DATA=$DATASET/ibt_step_0/truecased

TAG=""

if [ ! -d $TRANSLATION_DATA ]; then
    mkdir -p $TRANSLATION_DATA

    echo "=> Preparing...."
    DATA_NAME="train valid test"

    for lang in en vi; do
        echo "[$lang]..."
        for SET in $DATA_NAME; do
            echo "${SET}..."
            subword-nmt apply-bpe -c ${BPE_MODEL}/code.${BPESIZE}.bpe < ${TRUECASED_DATA}/${SET}.${lang} > ${TRANSLATION_DATA}/${SET}.${lang} 
        done
    done

    for lang in en vi; do
        echo "[$lang]..."
        if [ "${SRC}" = "en" ] ; then
            TAG="<e2v>"
        fi

        if [ "${SRC}" = "vi" ] ; then
            TAG="<v2e>"
        fi 
        echo "tag: ${TAG}"

        for SET in $DATA_NAME; do
            echo "${SET}..."
            cat ${BPE_DATA}/${SET}.${lang}  | awk -vtgt_tag="${TAG}" '{ print tgt_tag" "$0 }' > ${TRANSLATION_DATA}/tagged-${SET}.${lang} 
        done
    done

fi