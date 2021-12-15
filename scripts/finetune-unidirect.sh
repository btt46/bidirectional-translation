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

# LOGS
LOGS=$EXPDIR/logs

# Data
DATASET=$EXPDIR/dataset
RAW_DATA=$DATASET/iwslt15

DATA_NAME="train valid test"

read -p "Source language (en or vi): " SRC
read -p "Target language (en or vi): " TGT

read -p "Which steps do you choose to finetune: " STEP

if [ $STEP -gt 0 ]; then
    read -p "beam or random: " TRANSLATION_TYPE
    FINETUNE_BIN_DATA=$EXPDIR/dataset/ibt_step_${STEP}_${TRANSLATION_TYPE}/bin-data
fi

if [ $STEP -eq 0 ]; then
    FINETUNE_BIN_DATA=$EXPDIR/dataset/ibt_step_0/bin-data
fi

TAG=""

if [ "${SRC}" = "en" ] ; then
	TAG="<e2v>"
fi

if [ "${SRC}" = "vi" ] ; then
	TAG="<v2e>"
fi 

echo "${TAG}"

UNI_DATASET=$EXPDIR/dataset/finetune-${SRC}2${TGT}

# UTILS
UTILS=$EXPDIR/utils

DATA=$UNI_DATASET/data
PROCESSED_DATA=$UNI_DATASET/processed
NORMALIZED_DATA=$UNI_DATASET/normalized
TOKENIZED_DATA=$UNI_DATASET/tok
TRUECASED_DATA=$UNI_DATASET/truecased
BPE_DATA=$UNI_DATASET/bpe-data
BIN_DATA=$UNI_DATASET/bin-data
BPE_MODEL=$UNI_DATASET/bpe-model

##### PREPROCESSING
echo "PREPROCESSING"
echo "=> refreshing..."
rm -rf $DATA
rm -rf $PROCESSED_DATA
rm -rf $NORMALIZED_DATA
rm -rf $TOKENIZED_DATA
rm -rf $TRUECASED_DATA
rm -rf $BPE_DATA
rm -rf $BIN_DATA


mkdir -p $DATA
mkdir -p $PROCESSED_DATA
mkdir -p $NORMALIZED_DATA
mkdir -p $TOKENIZED_DATA
mkdir -p $TRUECASED_DATA

## Create train, dev, test dataset
echo "=> Creating train, dev, test dataset"
for lang in en vi; do
    cp ${RAW_DATA}/train.${lang} ${DATA}/train.${lang}
    cp ${RAW_DATA}/tst2012.${lang} ${DATA}/valid.${lang}
    cp ${RAW_DATA}/tst2013.${lang} ${DATA}/test.${lang}
done

# normalization
echo "=> normalizing..."
for lang in en vi; do
    echo "[$lang]..."
    for set in $DATA_NAME; do
        echo "$set..."
        python3.6 ${UTILS}/normalize.py ${DATA}/${set}.${lang}  ${NORMALIZED_DATA}/${set}.${lang}
    done
done

# Tokenization
echo "=> tokenize..."
for SET in $DATA_NAME ; do
    env LC_ALL=en_US.UTF-8 $TOK -l en < ${NORMALIZED_DATA}/${SET}.en > ${TOKENIZED_DATA}/${SET}.en
    python3.6 ${UTILS}/tokenize-vi.py  ${NORMALIZED_DATA}/${SET}.vi ${TOKENIZED_DATA}/${SET}.vi
done

# Truecaser
echo "=> Truecasing..."

echo "Traning for english..."
env LC_ALL=en_US.UTF-8 $TRUECASER_TRAIN --model truecase-model.en --corpus ${TOKENIZED_DATA}/train.en

echo "Traning for vietnamese..."
env LC_ALL=en_US.UTF-8 $TRUECASER_TRAIN --model truecase-model.vi --corpus ${TOKENIZED_DATA}/train.vi

for lang in en vi; do
    echo "[$lang]..."
    for set in $DATA_NAME; do
        echo "${set}..."
        env LC_ALL=en_US.UTF-8 $TRUECASER --model truecase-model.${lang} < ${TOKENIZED_DATA}/${set}.${lang} > ${TRUECASED_DATA}/${set}.${lang}
    done
done

for SET in $DATA_NAME; do
    for lang in en vi; do
        cp ${TRUECASED_DATA}/${SET}.${lang} ${PROCESSED_DATA}/${SET}.${lang}
    done
done

# learn bpe model with training data
if [ ! -d $BPE_MODEL ]; then  

    mkdir -p $BPE_MODEL

fi

echo "=> LEARNING BPE MODEL: $BPE_MODEL"
subword-nmt learn-joint-bpe-and-vocab --input ${PROCESSED_DATA}/train.${SRC} ${PROCESSED_DATA}/train.${TGT} \
                -s $BPESIZE -o $BPE_MODEL/code.${BPESIZE}.bpe \
                --write-vocabulary $BPE_MODEL/train.${SRC}.vocab $BPE_MODEL/train.${TGT}.vocab 


# apply sub-word segmentation
echo "=> Apply sub-word"
if [ ! -d $BPE_DATA ]; then
    mkdir $BPE_DATA
fi

for SET in $DATA_NAME; do
    subword-nmt apply-bpe -c $BPE_MODEL/code.${BPESIZE}.bpe < ${PROCESSED_DATA}/${SET}.${SRC} > $BPE_DATA/${SET}.${SRC}
    subword-nmt apply-bpe -c $BPE_MODEL/code.${BPESIZE}.bpe < ${PROCESSED_DATA}/${SET}.${TGT} > $BPE_DATA/${SET}.${TGT}
done


echo "=> Add tags"

for SET in $DATA_NAME; do
    python3.6 $UTILS/addTag.py -f $BPE_DATA/${SET}.${SRC} -p1 1 -t1 $TAG -p2 0 -t2 "" 
done

echo "=> Done"

PREPROCESS_LOG=$LOGS/preprocess/log.preprocess.finetune-${SRC}2${TGT}
fairseq-preprocess -s ${SRC} -t ${TGT} \
        --destdir $BIN_DATA \
        --trainpref $BPE_DATA/train \
        --validpref $BPE_DATA/valid \
        --testpref $BPE_DATA/test \
        --tgtdict $FINETUNE_BIN_DATA/dict.tgt.txt \
		--srcdict $FINETUNE_BIN_DATA/dict.src.txt \
        --workers 32 \
        2>&1 | tee $PREPROCESS_LOG