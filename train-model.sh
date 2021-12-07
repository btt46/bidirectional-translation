#!/bin/bash
EXPDIR=$PWD 


read -p "GPUS: " GPUS
read -p "MODEL NAME: " MODEL_NAME
read -p "EPOCHS NUM: " EPOCHS
read -p "IBT STEP: " STEP

LOG=$EXPDIR/logs/models
MODELS=$EXPDIR/models

if [ ! -d $LOG ]; then
    mkdir -p $LOG
fi

if [ ! -d $MODELS ]; then
    mkdir -p $MODELS
fi


if [ ${STEP} -eq 0 ]; then
    echo "=>> Training a bidirectional model..."
    echo "=> IBT step: ${STEP}"
	IBT_DATASET=$EXPDIR/dataset/ibt_step_${STEP}/bin-data
    CUDA_VISIBLE_DEVICES=$GPUS fairseq-train $IBT_DATASET -s src -t tgt \
		            --log-interval 100 \
					--log-format json \
					--max-epoch ${EPOCHS} \
		    		--optimizer adam --lr 0.0001 \
					--clip-norm 0.0 \
					--max-tokens 4000 \
					--no-progress-bar \
					--log-interval 100 \
					--min-lr '1e-09' \
					--weight-decay 0.0001 \
					--criterion label_smoothed_cross_entropy \
					--label-smoothing 0.1 \
					--lr-scheduler inverse_sqrt \
					--warmup-updates 4000 \
					--warmup-init-lr '1e-08' \
					--adam-betas '(0.9, 0.98)' \
					--arch transformer_iwslt_de_en \
					--dropout 0.1 \
					--attention-dropout 0.1 \
					--share-decoder-input-output-embed \
					--share-all-embeddings \
					--save-dir $MODELS/$MODEL_NAME \
					2>&1 | tee $LOG/${MODEL_NAME}
fi

if [ ${STEP} -gt 0 ]; then
	read -p "beam or random: " TRANSLATION_TYPE
	read -p "Pretrained model name: " PRETRAINED_MODEL_NAME
	read -p "Which checkpoint do you choose: " PRETRAIND_MODEL_CHECKPOINT

	echo "=>> Training a bidirectional model..."
    echo "=> IBT step: ${STEP}"

	PRETRAINED_MODEL=$MODELS/${PRETRAINED_MODEL_NAME}/checkpoint${PRETRAIND_MODEL_CHECKPOINT}.pt

	
	IBT_DATASET=$EXPDIR/dataset/ibt_step_${STEP}_${TRANSLATION_TYPE}/bin-data
	

	CUDA_VISIBLE_DEVICES=$GPUS fairseq-train $IBT_DATASET -s src -t tgt \
		            --log-interval 100 \
					--log-format json \
					--max-epoch ${EPOCHS} \
		    		--optimizer adam --lr 0.0001 \
					--clip-norm 0.0 \
					--max-tokens 4000 \
					--no-progress-bar \
					--log-interval 100 \
					--min-lr '1e-09' \
					--weight-decay 0.0001 \
					--criterion label_smoothed_cross_entropy \
					--label-smoothing 0.1 \
					--lr-scheduler inverse_sqrt \
					--warmup-updates 4000 \
					--warmup-init-lr '1e-08' \
					--adam-betas '(0.9, 0.98)' \
					--arch transformer_iwslt_de_en \
					--dropout 0.1 \
					--attention-dropout 0.1 \
					--share-decoder-input-output-embed \
					--share-all-embeddings \
					--finetune-from-model $PRETRAINED_MODEL\
					--save-dir $MODELS/$MODEL_NAME \
					2>&1 | tee $LOG/${MODEL_NAME}
fi