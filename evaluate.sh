#!/bin/bash
EXPDIR=$PWD 


read -p "GPUS: " GPUS
read -p "MODEL NAME: " MODEL_NAME
read -p "IBT STEP: " STEP


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
fi

if [ $STEP -ge 1 ]; then
    MODEL_RESULT=$RESULTS/result_step_${STEP}_${TRANSLATION_TYPE}
fi

if [ ! -d $MODEL_RESULT ]; then
    mkdir -p $MODEL_RESULT
fi


REF_EN=$DATASET/ibt_step_${STEP}/data/test.en
REF_VI=$DATASET/ibt_step_${STEP}/data/test.vi

VALID_REF_EN=$DATASET/ibt_step_${STEP}/data/valid.en
VALID_REF_VI=$DATASET/ibt_step_${STEP}/data/valid.vi

HYP_EN=$MODEL_RESULT/hyp.en
HYP_VI=$MODEL_RESULT/hyp.vi

VALID_HYP_EN=$MODEL_RESULT/dev_hyp.en
VALID_HYP_VI=$MODEL_RESULT/dev_hyp.vi

echo >  $MODEL_RESULT/result

for i in 21 22 23 24 25 26 27 28 29 30
do
	echo "${MODELS}/${MODEL_NAME}/checkpoint${i}.pt" >> $MODEL_RESULT/result
	# The model used for evaluate
	MODEL=$EXPDIR/models/${MODEL_NAME}/checkpoint${i}.pt
	CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 python3 $EXPDIR/fairseq/fairseq_cli/interactive.py $BIN_DATA \
	            --input $BPE_DATA/test.src \
	            --path $MODEL \
	            --beam 5 | tee $MODEL_RESULT/interactive.test.translation

	grep ^H $MODEL_RESULT/interactive.test.translation | cut -f3 > $MODEL_RESULT/test.translation

	cat $MODEL_RESULT/test.translation | awk 'NR % 2 == 1' | sed -r 's/(@@ )|(@@ ?$)//g'  > $MODEL_RESULT/test.translation.vi
	cat $MODEL_RESULT/test.translation | awk 'NR % 2 == 0'| sed -r 's/(@@ )|(@@ ?$)//g' > $MODEL_RESULT/test.translation.en

	# detruecase
	$DETRUECASER < $MODEL_RESULT/test.translation.vi > $MODEL_RESULT/detruecase.vi
	$DETRUECASER < $MODEL_RESULT/test.translation.en > $MODEL_RESULT/detruecase.en

	# detokenize
	python3 $DETOK $MODEL_RESULT/detruecase.vi $HYP_VI
	python3 $DETOK $MODEL_RESULT/detruecase.en $HYP_EN

	# English to Vietnamese
	echo "TEST" >> $MODEL_RESULT/result
	echo "En > Vi" >> $MODEL_RESULT/result
	env LC_ALL=en_US.UTF-8 perl $BLEU $REF_VI < $HYP_VI >> $MODEL_RESULT/result

	# Vietnamese to English
	echo "Vi > En"  >> $MODEL_RESULT/result
	env LC_ALL=en_US.UTF-8 perl $BLEU $REF_EN < $HYP_EN >> $MODEL_RESULT/result


	####### DEV ######
	CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 python3 $EXPDIR/fairseq/fairseq_cli/interactive.py $BIN_DATA \
	            --input $BPE_DATA/valid.src \
	            --path $MODEL \
	            --beam 5 | tee $MODEL_RESULT/interactive.valid.translation

	grep ^H $MODEL_RESULT/interactive.valid.translation | cut -f3 > $MODEL_RESULT/valid.translation


	cat $MODEL_RESULT/valid.translation | awk 'NR % 2 == 1' | sed -r 's/(@@ )|(@@ ?$)//g'  > $MODEL_RESULT/valid.translation.vi
	cat $MODEL_RESULT/valid.translation | awk 'NR % 2 == 0'| sed -r 's/(@@ )|(@@ ?$)//g' > $MODEL_RESULT/valid.translation.en

	# detruecase
	$DETRUECASER < $MODEL_RESULT/valid.translation.vi > $MODEL_RESULT/valid_detruecase.vi
	$DETRUECASER < $MODEL_RESULT/valid.translation.en > $MODEL_RESULT/valid_detruecase.en

	# detokenize
	python3 $DETOK $MODEL_RESULT/valid_detruecase.vi $VALID_HYP_VI
	python3 $DETOK $MODEL_RESULT/valid_detruecase.en $VALID_HYP_EN

	# English to Vietnamese
	echo "VALID" >> $MODEL_RESULT/result
	echo "En > Vi" >> $MODEL_RESULT/result
	env LC_ALL=en_US.UTF-8 perl $BLEU $VALID_REF_VI < $VALID_HYP_VI >> $MODEL_RESULT/result

	# Vietnamese to English
	echo "Vi > En" >> $MODEL_RESULT/result
	env LC_ALL=en_US.UTF-8 perl $BLEU $VALID_REF_EN < $VALID_HYP_EN >> $MODEL_RESULT/result
done