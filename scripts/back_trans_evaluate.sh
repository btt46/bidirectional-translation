#!/bin/bash
EXPDIR=$PWD 

read -p "MODEL NAME: " MODEL_NAME
read -p "IBT STEP: " STEP

MOSES=$EXPDIR/mosesdecoder/scripts
DETRUECASER=$MOSES/recaser/detruecase.perl

BACK_EVALUATE=$EXPDIR/back_trans_evaluate

if [ ! -d $BACK_EVALUATE ]; then
    mkdir -p $BACK_EVALUATE
fi

DATASET=$EXPDIR/dataset

BLEU=$EXPDIR/multi-bleu.pl

if [ $STEP -ge 1 ]; then
    read -p "beam or random: " TRANSLATION_TYPE
	SYN_DATA=$DATASET/ibt_step_${STEP}_${TRANSLATION_TYPE}/synthetic-data
    REF_EN=$DATASET/ibt_step_${STEP}_${TRANSLATION_TYPE}/train.en
    REF_VI=$DATASET/ibt_step_${STEP}_${TRANSLATION_TYPE}/train.vi
fi

HYP_EN=$BACK_EVALUATE/ibt_step_${STEP}_${TRANSLATION_TYPE}/hyp.en
HYP_VI=$BACK_EVALUATE/ibt_step_${STEP}_${TRANSLATION_TYPE}/hyp.vi

$DETRUECASER < $SYN_DATA/syn.en > $HYP_EN
$DETRUECASER < $SYN_DATA/syn.vi > $HYP_VI

env LC_ALL=en_US.UTF-8 perl $BLEU $REF_VI < $HYP_VI > $BACK_EVALUATE/ibt_step_${STEP}_${TRANSLATION_TYPE}/result.vi
env LC_ALL=en_US.UTF-8 perl $BLEU $REF_EN < $HYP_EN > $BACK_EVALUATE/ibt_step_${STEP}_${TRANSLATION_TYPE}/result.en