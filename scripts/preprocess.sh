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

if [ ! -d $LOGS ]; then
    mkdir -p $LOGS
fi

if [ ! -d $LOGS/preprocess ]; then
    mkdir -p $LOGS/preprocess
fi



# Data
DATASET=$EXPDIR/dataset
RAW_DATA=$DATASET/iwslt15

# BPE models
BPE_MODEL=$DATASET/bpe-model

STEP=-1
IBT="N"
read -p "Do you use iterative back translation (Y/N): " IBT
echo "$IBT"

if [ $IBT != "N" ]; then
    read -p "Which steps do you train: " STEP

    if [ $STEP -eq 0 ]; then
        IBT_DATASET=$EXPDIR/dataset/ibt_step_${STEP}
        
    fi

    if [ $STEP -gt 0 ]; then
        read -p "beam or random: " TRANSLATION_TYPE
        IBT_DATASET=$EXPDIR/dataset/ibt_step_${STEP}_${TRANSLATION_TYPE}
    fi

    if [ -d $IBT_DATASET ]; then
        mkdir -p $IBT_DATASET
    fi
   

    DATA=$IBT_DATASET/data
    PROCESSED_DATA=$IBT_DATASET/processed
    NORMALIZED_DATA=$IBT_DATASET/normalized
    TOKENIZED_DATA=$IBT_DATASET/tok
    TRUECASED_DATA=$IBT_DATASET/truecased
    BPE_DATA=$IBT_DATASET/bpe-data
    BIN_DATA=$IBT_DATASET/bin-data
else
    DATA=$DATASET/data
    PROCESSED_DATA=$DATASET/processed
    NORMALIZED_DATA=$DATASET/normalized
    TOKENIZED_DATA=$DATASET/tok
    TRUECASED_DATA=$DATASET/truecased
    BPE_DATA=$DATASET/bpe-data
    BIN_DATA=$DATASET/bin-data
fi

DATA_NAME="train valid test"

# scripts
SCRIPTS=$EXPDIR/scripts

# UTILS
UTILS=$EXPDIR/utils

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

echo "=> refresh done!"

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



echo "=> Merge data for the bidirectional model"
if [ $STEP -eq 0 ]; then
    # prepare data for the bidirectional model
    for SET in $DATA_NAME ; do
        touch ${PROCESSED_DATA}/${SET}.src
        touch ${PROCESSED_DATA}/${SET}.tgt
        python3.6 ${UTILS}/merge-file.py  \
                                        -s1 ${TRUECASED_DATA}/${SET}.en\
                                        -s2 ${TRUECASED_DATA}/${SET}.vi\
                                        -s3 ${PROCESSED_DATA}/${SET}.src\
                                        -msrc ${PROCESSED_DATA}/${SET}.src \
                                        -t1 ${TRUECASED_DATA}/${SET}.vi\
                                        -t2 ${TRUECASED_DATA}/${SET}.en\
                                        -t3 ${PROCESSED_DATA}/${SET}.tgt\
                                        -mtgt ${PROCESSED_DATA}/${SET}.tgt \
                                        -t "sentence" -stride 0
    done

    echo "=> merged"

fi

IBT_DATASET=$EXPDIR/dataset/ibt_step_${STEP}_${TRANSLATION_TYPE}
SYN_DATA=$IBT_DATASET/synthetic-data
TRANSLATION_DATA=$DATASET/translation-data

if [ $STEP -eq 1 ]; then
    PREVIOUS_DATA=$DATASET/ibt_step_0/processed
fi

if [ $STEP -gt 1 ]; then
    PREVIOUS_DATA=$DATASET/ibt_step_$((STEP-1))_${TRANSLATION_TYPE}/processed
fi

if [ $STEP -gt 0 ]; then
    echo "=> previous data: ${PREVIOUS_DATA}"
    touch ${PROCESSED_DATA}/train.src
    touch ${PROCESSED_DATA}/train.tgt
    python3.6 ${UTILS}/merge-file.py  \
                        -s1 ${SYN_DATA}/tok.en\
                        -s2 ${SYN_DATA}/tok.vi\
                        -s3 ${PREVIOUS_DATA}/train.src\
                        -msrc ${PROCESSED_DATA}/train.src \
                        -t1 $DATASET/ibt_step_0/truecased/train.vi \
                        -t2 $DATASET/ibt_step_0/truecased/train.en \
                        -t3 ${PREVIOUS_DATA}/train.tgt\
                        -mtgt ${PROCESSED_DATA}/train.tgt \
                        -t "sentence" -stride $STEP

    cp ${PREVIOUS_DATA}/valid.src ${PROCESSED_DATA}/valid.src
    cp ${PREVIOUS_DATA}/valid.tgt ${PROCESSED_DATA}/valid.tgt
    cp ${PREVIOUS_DATA}/test.src ${PROCESSED_DATA}/test.src
    cp ${PREVIOUS_DATA}/test.tgt ${PROCESSED_DATA}/test.tgt
fi

# learn bpe model with training data
if [ ! -d $BPE_MODEL ]; then  

    mkdir -p $BPE_MODEL

    echo "=> LEARNING BPE MODEL: $BPE_MODEL"
    subword-nmt learn-joint-bpe-and-vocab --input ${PROCESSED_DATA}/train.src ${PROCESSED_DATA}/train.tgt \
                    -s $BPESIZE -o $BPE_MODEL/code.${BPESIZE}.bpe \
                    --write-vocabulary $BPE_MODEL/train.src.vocab $BPE_MODEL/train.tgt.vocab 

fi

# apply sub-word segmentation
echo "=> Apply sub-word"
if [ ! -d $BPE_DATA ]; then
    mkdir $BPE_DATA
fi

for SET in $DATA_NAME; do
    subword-nmt apply-bpe -c $BPE_MODEL/code.${BPESIZE}.bpe < ${PROCESSED_DATA}/${SET}.src > $BPE_DATA/${SET}.src 
    subword-nmt apply-bpe -c $BPE_MODEL/code.${BPESIZE}.bpe < ${PROCESSED_DATA}/${SET}.tgt > $BPE_DATA/${SET}.tgt
done

echo "=> Done"

echo "=> Add tags"


python3.6 $UTILS/addTag.py -f $BPE_DATA/train.src -p1 $((STEP+1)) -t1 "<e2v>" -p2 $(((STEP+1)*2)) -t2 "<v2e>" 
python3.6 $UTILS/addTag.py -f $BPE_DATA/valid.src -p1 1 -t1 "<e2v>" -p2 2 -t2 "<v2e>" 
python3.6 $UTILS/addTag.py -f $BPE_DATA/test.src -p1 1 -t1 "<e2v>" -p2 2 -t2 "<v2e>" 


echo "=> Done"

# binarize train/valid/test
echo "=> Binarize"
if [ ! -d $BIN_DATA ]; then
    mkdir $BIN_DATA
fi

PREPROCESS_LOG=$LOGS/preprocess/log.preprocess

if [ $STEP -eq 0 ]; then
    PREPROCESS_LOG=$LOGS/preprocess/log.preprocess.IBT.${STEP}
    fairseq-preprocess -s src -t tgt \
			--destdir $BIN_DATA \
			--trainpref $BPE_DATA/train \
			--validpref $BPE_DATA/valid \
			--testpref $BPE_DATA/test \
			--joined-dictionary \
			--workers 32 \
            2>&1 | tee $PREPROCESS_LOG
fi

if [ $STEP -eq 1 ]; then
    PREPROCESS_LOG=$LOGS/preprocess/log.preprocess.IBT.${TRANSLATION_TYPE}.${STEP}
    fairseq-preprocess -s src -t tgt \
			--destdir $BIN_DATA \
			--trainpref $BPE_DATA/train \
			--validpref $BPE_DATA/valid \
			--testpref $BPE_DATA/test \
            --tgtdict $DATASET/ibt_step_0/bin-data/dict.tgt.txt \
			--srcdict $DATASET/ibt_step_0/bin-data/dict.src.txt \
			--workers 32 \
            2>&1 | tee $PREPROCESS_LOG
fi

if [ $STEP -gt 1 ]; then
    PREPROCESS_LOG=$LOGS/preprocess/log.preprocess.IBT.${TRANSLATION_TYPE}.${STEP}
    fairseq-preprocess -s src -t tgt \
			--destdir $BIN_DATA \
			--trainpref $BPE_DATA/train \
			--validpref $BPE_DATA/valid \
			--testpref $BPE_DATA/test \
            --tgtdict $DATASET/ibt_step_$((STEP-1))_${TRANSLATION_TYPE}/bin-data/dict.tgt.txt \
			--srcdict $DATASET/ibt_step_$((STEP-1))_${TRANSLATION_TYPE}/bin-data/dict.src.txt \
			--workers 32 \
            2>&1 | tee $PREPROCESS_LOG
fi




