#!/bin/bash
EXPDIR=$PWD 


read -p "GPUS: " GPUS
read -p "MODEL NAME: " MODEL_NAME
read -p "IBT STEP: " STEP
read -p "EVAL (0 or 1 or 2)?: " EVAL


MOSES=$EXPDIR/mosesdecoder/scripts
DETRUECASER=$MOSES/recaser/detruecase.perl

DATASET=$EXPDIR/dataset

PROCESSED_DATA=$DATASET/ibt_step_${STEP}/processed-data

if [ $STEP -eq 0 ]; then
	BIN_DATA=$DATASET/ibt_step_${STEP}/bin-data
	BPE_DATA=$DATASET/ibt_step_${STEP}/bpe-data
fi

if [ $STEP -ge 1 ]; then
    read -p "beam or random: " TRANSLATION_TYPE
	BIN_DATA=$DATASET/ibt_step_${STEP}_${TRANSLATION_TYPE}/bin-data
	BPE_DATA=$DATASET/ibt_step_${STEP}_${TRANSLATION_TYPE}/bpe-data
fi

DETOK=$EXPDIR/utils/detokenize.py
BLEU=$PWD/multi-bleu.pl

RESULTS=$EXPDIR/results

MODELS=$EXPDIR/models

if [ ! -d $RESULTS ]; then
    mkdir -p $RESULTS
fi

if [ $STEP -eq 0 ]; then
	MODEL_RESULT=$RESULTS/result_step_${STEP}
	REF_EN=$DATASET/ibt_step_${STEP}/data/test.en
	REF_VI=$DATASET/ibt_step_${STEP}/data/test.vi
	VALID_REF_EN=$DATASET/ibt_step_${STEP}/data/valid.en
	VALID_REF_VI=$DATASET/ibt_step_${STEP}/data/valid.vi
fi

if [ $STEP -ge 1 ]; then
    MODEL_RESULT=$RESULTS/result_step_${STEP}_${TRANSLATION_TYPE}
	REF_EN=$DATASET/ibt_step_${STEP}_${TRANSLATION_TYPE}/data/test.en
	REF_VI=$DATASET/ibt_step_${STEP}_${TRANSLATION_TYPE}/data/test.vi
	VALID_REF_EN=$DATASET/ibt_step_${STEP}_${TRANSLATION_TYPE}/data/valid.en
	VALID_REF_VI=$DATASET/ibt_step_${STEP}_${TRANSLATION_TYPE}/data/valid.vi
fi

MODEL=$EXPDIR/models/${MODEL_NAME}/checkpoint${i}.pt
echo "${MODEL}" >> $MODEL_RESULT/result

CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 python3 $EXPDIR/fairseq/fairseq_cli/interactive.py $BIN_DATA \
            --input $EXPDIR/txt/test.txt \
            --path $MODEL \
            --beam 5
