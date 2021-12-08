#!/bin/bash
EXPDIR=$PWD 

read -p "IBT STEP: " STEP

MOSES=$EXPDIR/mosesdecoder/scripts
DETRUECASER=$MOSES/recaser/detruecase.perl

BACK_EVALUATE=$EXPDIR/back_trans_evaluate

UTILS=$EXPDIR/utils

if [ ! -d $BACK_EVALUATE ]; then
    mkdir -p $BACK_EVALUATE
fi

DATASET=$EXPDIR/dataset

BLEU=$EXPDIR/multi-bleu.pl


read -p "beam or random: " TRANSLATION_TYPE
SYN_DATA=$DATASET/ibt_step_${STEP}_${TRANSLATION_TYPE}/synthetic-data
REF_EN=$DATASET/ibt_step_${STEP}_${TRANSLATION_TYPE}/data/train.en
REF_VI=$DATASET/ibt_step_${STEP}_${TRANSLATION_TYPE}/data/train.vi

RESULT_FOLDER=$BACK_EVALUATE/ibt_step_${STEP}_${TRANSLATION_TYPE}

if [ ! -d $RESULT_FOLDER ]; then
    mkdir -p $RESULT_FOLDER
fi


HYP_EN=$RESULT_FOLDER/hyp.en
HYP_VI=$RESULT_FOLDER/hyp.vi


$DETRUECASER < $SYN_DATA/syn.en > $HYP_EN
$DETRUECASER < $SYN_DATA/syn.vi > $HYP_VI

env LC_ALL=en_US.UTF-8 perl $BLEU $REF_VI < $HYP_VI > $RESULT_FOLDER/bleu.vi
env LC_ALL=en_US.UTF-8 perl $BLEU $REF_EN < $HYP_EN > $RESULT_FOLDER/bleu.en

python3 $UTILS/compare.py -f1 $REF_VI -f2 $HYP_VI -o $RESULT_FOLDER/accuracy.vi
python3 $UTILS/compare.py -f1 $REF_EN -f2 $HYP_EN -o $RESULT_FOLDER/accuracy.en