EXPDIR=$PWD 

read -p "Source language (en or vi): " SRC
read -p "Target language (en or vi): " TGT
read -p "GPUS: " GPUS
read -p "Which steps do you train: " STEP
read -p "beam or random: " TRANSLATION_TYPE
read -p "Which models do you use to do back-translation: " MODEL_NAME
read -p "Which checkpoint do you choose: " CHECKPOINT
read -p "SEED: " SEED
read -p "Temperature: " TEMP

# UTILS
UTILS=$EXPDIR/utils
DETOK=$UTILS/detokenize.py

DATASET=$EXPDIR/dataset
TRANSLATION_DATA=$DATASET/translation-data



IBT_DATASET=$EXPDIR/dataset/ibt_step_${STEP}_${TRANSLATION_TYPE}
MODEL=$EXPDIR/models/${MODEL_NAME}/checkpoint${CHECKPOINT}.pt

if [ $STEP -eq 1 ]: then
    BIN_DATA=$EXPDIR/dataset/ibt_step_0/bin-data
fi

if [ $STEP -gt 1 ]: then
    PREVIOS_STEP=$((STEP-1))
    BIN_DATA=$EXPDIR/dataset/ibt_step_${PREVIOS_STEP}_${TRANSLATION_TYPE}/bin-data
fi

if [ -d $IBT_DATASET ]; then
    mkdir -p $IBT_DATASET
fi

SYN_DATA=$IBT_DATASET/synthetic-data
if [ -d $SYN_DATA ]; then
    mkdir -p $SYN_DATA
fi

if [ $TRANSLATION_TYPE == "beam" ]; then
    CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
                        --input ${TRANSLATION_DATA}/tagged-translation.${SRC} \
                        --beam 5 \
                        --path $MODEL  | tee $SYN_DATA/iteractive_translation.{TGT}
fi

if [ $TRANSLATION_TYPE == "random" ]; then
    echo "random"			
    CUDA_VISIBLE_DEVICES=$GPUS env LC_ALL=en_US.UTF-8 fairseq-interactive $BIN_DATA \
                --input ${TRANSLATION_DATA}/tagged-translation.${SRC} \
                --sampling \
                --seed ${SEED} \
                --sampling-topk -1 \
                --nbest 1\
                --beam 1\
                --temperature ${TEMP} \
                --path $MODEL  | tee $SYN_DATA/iteractive_translation.{TGT}
fi

grep ^H $SYN_DATA/iteractive_translation.{TGT} | cut -f3 > $SYN_DATA/corpus.${TGT}

cat $SYN_DATA/corpus.${TGT}  | sed -r 's/(@@ )|(@@ ?$)//g'  > $SYN_DATA/tok.${TGT}

if [ "${TGT}" = "vi" ] ; then
    python3 $DETOK $SYN_DATA/tok.${TGT} $SYN_DATA/syn.${TGT}
fi

if [ "${TGT}" = "en" ] ; then
    cp $SYN_DATA/tok.${TGT} $SYN_DATA/syn.${TGT}
fi