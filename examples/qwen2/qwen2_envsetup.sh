# Pai-Megatron-Patch
# set -x

export CUDA_DEVICE_MAX_CONNECTIONS=1

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo "CURRENT_DIR: ${CURRENT_DIR}"
MEGATRON_PATH=$( dirname $( dirname ${CURRENT_DIR}))
# 如果PYTHONPATH中没有 MEGATRON_PATH ，则添加PYTHONPATH
if [[ ${PYTHONPATH} != *${MEGATRON_PATH}* ]]; then
    export PYTHONPATH=${MEGATRON_PATH}:${PYTHONPATH}
fi


function train() {
    
    export CMODEL_GLOBAL_MEM_SIZE=120000000000
    export CMODEL_FAST_EXEC=1
    export DISABLE_CACHE=1
    
    pushd ${MEGATRON_PATH}
    source ${MEGATRON_PATH}/env.sh
    
    TRAIN_ITERS=1
    BATCH_SIZE=8
    GLOBAL_BATCH_SIZE=8
    
    SEQ_LEN=512
    PAD_LEN=512
    
    LR=1e-4
    
    DATASET_PATH=$CURRENT_DIR/qwen-datasets/wudao_qwenbpe_text_document
    DS_CONFIG=ds_config.json
    
    MODEL_SIZE=${1:-7B}
    LAYERS=${2:-1}
    TP=${3:-2}
    PP=${4:-1}
    BACKEND=${5:-sccl}
    TINY_TEST=0
    ## tiny test
    if [ $MODEL_SIZE = 'tiny' ]; then
        echo "Tiny test"
        TINY_TEST=1
        NUM_LAYERS=1
        HIDDEN_SIZE=56
        NUM_ATTN_HEADS=28
        INTERMEDIATE_SIZE=296
        NUM_KEY_VALUE_HEADS=4
        RMS_NORM_EPS=1e-6
    elif [ $MODEL_SIZE = '7B' ]; then
        echo "7B model"
        NUM_LAYERS=28
        HIDDEN_SIZE=3584
        NUM_ATTN_HEADS=28
        INTERMEDIATE_SIZE=18944
        NUM_KEY_VALUE_HEADS=4
        RMS_NORM_EPS=1e-6
    elif [ $MODEL_SIZE = '72B' ]; then
        echo "72B model"
        NUM_LAYERS=80
        HIDDEN_SIZE=8192
        NUM_ATTN_HEADS=64
        INTERMEDIATE_SIZE=29568
        NUM_KEY_VALUE_HEADS=8
        RMS_NORM_EPS=1e-5
    else
        echo "Invalid model size: $MODEL_SIZE"
        return 1
    fi
    
    if [ $LAYERS = '0' ]; then
        echo "Use full $NUM_LAYERS layers"
    else
        echo "Use $LAYERS layers"
        NUM_LAYERS=$LAYERS
    fi
    
    if [ $((NUM_LAYERS % PP)) -ne 0 ]; then
        echo "${NUM_LAYERS} layers should be divisible by PP ${PP}"
        return 1
    fi
    
    if [ $(((HIDDEN_SIZE / NUM_ATTN_HEADS) % TP)) -ne 0 ]; then
        echo "Head dim $((HIDDEN_SIZE / NUM_ATTN_HEADS)) should be divisible by TP ${TP}"
        return 1
    fi
    
    echo "TP=${TP}, PP=${PP}"
    
    MAX_POSITION_EMBEDDINGS=131072
    EXTRA_VOCAB_SIZE=421
    gqa_options=" \
    --group-query-attention \
    --num-query-groups ${NUM_KEY_VALUE_HEADS}"
    
    megatron_options="  \
    --lr ${LR} \
    --weight-decay 0.1 \
    --adam-beta1 0.9 \
    --adam-beta2 0.95 \
    --clip-grad 1.0 \
    --init-method-std 0.008 \
    --attention-dropout 0.0 \
    --hidden-dropout 0.0 \
    --train-iters ${TRAIN_ITERS} \
    --micro-batch-size ${BATCH_SIZE} \
    --global-batch-size ${GLOBAL_BATCH_SIZE} \
    --num-layers ${NUM_LAYERS} \
    --hidden-size ${HIDDEN_SIZE} \
    --num-attention-heads ${NUM_ATTN_HEADS} \
    --ffn-hidden-size ${INTERMEDIATE_SIZE} \
    --seq-length ${SEQ_LEN} \
    --max-position-embeddings ${MAX_POSITION_EMBEDDINGS} \
    --max-padding-length ${PAD_LEN} \
    --log-interval 1 \
    --log-throughput \
    --log-progress \
    --eval-iters 0 \
    --save-interval 1 \
    --tensor-model-parallel-size ${TP} \
    --pipeline-model-parallel-size ${PP} \
    --no-load-optim \
    --no-load-rng \
    --num-workers 16 \
    --extra-vocab-size ${EXTRA_VOCAB_SIZE} \
    --patch-tokenizer-type Qwen2Tokenizer \
    --swiglu \
    --normalization RMSNorm \
    --norm-epsilon ${RMS_NORM_EPS} \
    --use-rotary-position-embeddings \
    --position-embedding-type rope \
    --untie-embeddings-and-output-weights \
    --disable-bias-linear \
    --add-qkv-bias \
    --rotary-percent 1.0 \
    --rotary-base 1000000 \
    --rotary-seq-len-interpolation-factor 1 \
    --no-save-optim \
    --save ${CURRENT_DIR}/qwen-ckpts/Qwen2-0.5B-checkpoint \
    --load ${CURRENT_DIR}/qwen-ckpts/Qwen2-0.5B \
    "

    echo $megatron_options

    fuse_options=" \
    --no-gradient-accumulation-fusion \
    --no-bias-gelu-fusion \
    --no-bias-dropout-fusion"
    
    te_options=" \
    --transformer-impl local"
    
    dataset_option=" \
    --data-path ${DATASET_PATH} \
    --split 99,1,0 \
    --dataset LLama-Pretrain-Idxmap"
    
    pr_options=" \
    --fp16 \
    --apply-query-key-layer-scaling \
    --loss-scale 16384.0 \
    --use-cpu-initialization"
    
    sft_option=" \
    --train-mode pretrain"
    
    comm_overlap_option="\
    --overlap-grad-reduce"
    
    tensorboard_option=" \
    --tensorboard-queue-size 1 \
    --tensorboard-dir output_dir_tpu \
    --log-timers-to-tensorboard \
    --log-batch-size-to-tensorboard \
    --log-validation-ppl-to-tensorboard"
    
    extra_options=" \
    --distributed-backend ${BACKEND}"
    
    # echo \
    MASTER_ADDR=127.0.0.1 \
    MASTER_PORT=6000 \
    RANK=0 \
    WORLD_SIZE=$((TP*PP)) \
    LOCAL_RANK=0 \
    LOCAL_WORLD_SIZE=$((TP*PP)) \
    python ${CURRENT_DIR}/pretrain_qwen.py \
    ${megatron_options} \
    ${fuse_options} \
    ${te_options} \
    ${dataset_option} \
    ${pr_options} \
    ${sft_option} \
    ${gqa_options} \
    ${extra_options} \
    ${comm_overlap_option} \
    ${tensorboard_option} &
    
    
    # echo \
    MASTER_ADDR=127.0.0.1 \
    MASTER_PORT=6000 \
    RANK=1 \
    WORLD_SIZE=$((TP*PP)) \
    LOCAL_RANK=1 \
    LOCAL_WORLD_SIZE=$((TP*PP)) \
    python ${CURRENT_DIR}/pretrain_qwen.py \
    ${megatron_options} \
    ${fuse_options} \
    ${te_options} \
    ${dataset_option} \
    ${pr_options} \
    ${sft_option} \
    ${gqa_options} \
    ${extra_options} \
    ${comm_overlap_option} \
    ${tensorboard_option}
    
    set +x
    popd
}


function evaluate() {
    
    export CMODEL_GLOBAL_MEM_SIZE=120000000000
    export CMODEL_FAST_EXEC=1
    
    
    #     local PYTHONPATH=${MEGATRON_PATH}:${PYTHONPATH}
    
    #     rm -rf ${MEGATRON_PATH}/examples/qwen2/qwen-ckpts/Qwen2-0.5B-hf-to-mcore-te-tp1-pp1
    #     mkdir -p ${MEGATRON_PATH}/examples/qwen2/qwen-ckpts/Qwen2-0.5B-hf-to-mcore-te-tp1-pp1
    #     echo "1" > ${MEGATRON_PATH}/examples/qwen2/qwen-ckpts/Qwen2-0.5B-hf-to-mcore-te-tp1-pp1/latest_checkpointed_iteration.txt
    
    pushd ${MEGATRON_PATH}/toolkits/model_checkpoints_convertor/qwen
    MODEL_SIZE=${1:-7B}
    LAYERS=${2:-1}
    TP=${3:-2}
    PP=${4:-1}
    
    bash hf2mcore_qwen2_convertor.sh \
    7B \
    ${MEGATRON_PATH}/examples/qwen2/qwen-ckpts/Qwen2-0.5B-hf-to-mcore-te-tp1-pp1  \
    ${MEGATRON_PATH}/examples/qwen2/qwen-ckpts/Qwen2-0.5B-mcore-te-to-hf    \
    $TP  \
    $PP  \
    1 \
    fp16 \
    false \
    true \
    ${MEGATRON_PATH}/examples/qwen2/qwen-ckpts/Qwen2-7B
    popd
}
