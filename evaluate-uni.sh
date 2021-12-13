#!/bin/bash
EXPDIR=$PWD 

read -p "GPUS: " GPUS
read -p "MODEL NAME: " MODEL_NAME
read -p "EVAL (0 or 1 or 2)?: " EVAL

read -p "Source language (en or vi): " SRC
read -p "Target language (en or vi): " TGT

MOSES=$EXPDIR/mosesdecoder/scripts
DETRUECASER=$MOSES/recaser/detruecase.perl

DATASET=$EXPDIR/dataset

RESULTS=$EXPDIR/results

UNI_DATASET=$EXPDIR/dataset/${SRC}2${TGT}

BIN_DATA=$UNI_DATASET/bin-data
BPE_DATA=$UNI_DATASET/bpe-data
MODEL_RESULT=$RESULTS/${SRC}2${TGT}

if [ ! -d $MODEL_RESULT ]; then
    mkdir -p $MODEL_RESULT
fi

REF=$UNI_DATASET/data/test.${TGT}
VALID_REF=$UNI_DATASET/data/valid.${TGT}

HYP=$MODEL_RESULT/hyp.${TGT}
VALID_HYP=$MODEL_RESULT/dev_hyp.${TGT}

if [ $EVAL -eq 1 ]; then

	for i in 21 22 23 24 25 26 27 28 29 30
	do
        MODEL=$EXPDIR/models/${MODEL_NAME}/checkpoint${CHECKPOINT}.pt
        echo "${MODEL}" >> $MODEL_RESULT/result

        CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 python3 $EXPDIR/fairseq/fairseq_cli/interactive.py $BIN_DATA \
                    --input $BPE_DATA/test.${SRC} \
                    --path $MODEL \
                    --beam 5 | tee $MODEL_RESULT/interactive.valid.translation

        grep ^H $MODEL_RESULT/interactive.valid.translation | cut -f3 > $MODEL_RESULT/valid.translation
        cat $MODEL_RESULT/valid.translation| sed -r 's/(@@ )|(@@ ?$)//g' > $MODEL_RESULT/valid.translation.${TGT}

        # detruecase
        # detruecase
        $DETRUECASER < $MODEL_RESULT/valid.translation.${TGT} > $MODEL_RESULT/detruecase.${TGT}

        # detokenize
        python3 $DETOK $MODEL_RESULT/detruecase.${TGT} $VALID_HYP

        echo "VALID" >> $MODEL_RESULT/result
        env LC_ALL=en_US.UTF-8 perl $BLEU $VALID_REF < $VALID_HYP >> $MODEL_RESULT/result
		
	done

fi

if [ $EVAL -eq 0 ]; then
	read -p "Which checkpoint do you choose: " CHECKPOINT
	MODEL=$EXPDIR/models/${MODEL_NAME}/checkpoint${CHECKPOINT}.pt
	echo "${MODEL}" >> $MODEL_RESULT/result.test

    CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 python3 $EXPDIR/fairseq/fairseq_cli/interactive.py $BIN_DATA \
	            --input $BPE_DATA/test.${SRC} \
	            --path $MODEL \
	            --beam 5 | tee $MODEL_RESULT/interactive.test.translation

	grep ^H $MODEL_RESULT/interactive.test.translation | cut -f3 > $MODEL_RESULT/test.translation
	cat $MODEL_RESULT/test.translation| sed -r 's/(@@ )|(@@ ?$)//g' > $MODEL_RESULT/test.translation.${TGT}

	# detruecase
	# detruecase
	$DETRUECASER < $MODEL_RESULT/test.translation.${TGT} > $MODEL_RESULT/detruecase.${TGT}

    # detokenize
	python3 $DETOK $MODEL_RESULT/detruecase.${TGT} $HYP

    echo "TEST" >> $MODEL_RESULT/result.test
    env LC_ALL=en_US.UTF-8 perl $BLEU $REF < $HYP >> $MODEL_RESULT/result.test


fi


if [ $EVAL -eq 2 ]; then
	read -p "Which checkpoint do you choose: " CHECKPOINT
	MODEL=$EXPDIR/models/${MODEL_NAME}/checkpoint${CHECKPOINT}.pt
	echo "${MODEL}" >> $MODEL_RESULT/result.valid

    CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 python3 $EXPDIR/fairseq/fairseq_cli/interactive.py $BIN_DATA \
	            --input $BPE_DATA/test.${SRC} \
	            --path $MODEL \
	            --beam 5 | tee $MODEL_RESULT/interactive.valid.translation

	grep ^H $MODEL_RESULT/interactive.valid.translation | cut -f3 > $MODEL_RESULT/valid.translation
	cat $MODEL_RESULT/valid.translation| sed -r 's/(@@ )|(@@ ?$)//g' > $MODEL_RESULT/valid.translation.${TGT}

	# detruecase
	# detruecase
	$DETRUECASER < $MODEL_RESULT/valid.translation.${TGT} > $MODEL_RESULT/detruecase.${TGT}

    # detokenize
	python3 $DETOK $MODEL_RESULT/detruecase.${TGT} $VALID_HYP

    echo "VALID" >> $MODEL_RESULT/result.valid
    env LC_ALL=en_US.UTF-8 perl $BLEU $VALID_REF < $VALID_HYP >> $MODEL_RESULT/result.valid


fi