# Qwen2 模型训练指南

## Table of Contents
- [Qwen2 模型训练指南](#qwen2-模型训练指南)
  - [Table of Contents](#table-of-contents)
  - [安装步骤](#安装步骤)
    - [Step 1. 前置步骤](#step-1-前置步骤)
    - [Step 2. 安装依赖](#step-2-安装依赖)
    - [Step 3. 预训练数据集和模型下载](#step-3-预训练数据集和模型下载)
  - [训练流程](#训练流程)
      - [预训练\&微调命令统一描述](#预训练微调命令统一描述)
      - [预训练示例](#预训练示例)
  - [下游任务评估](#下游任务评估)
    - [评估格式转换](#评估格式转换)
    - [运行评估工具](#运行评估工具)

## 安装步骤

### Step 1. 前置步骤

参考[通用步骤](../../README_zh-CN.md#getting-started)完成环境的准备和项目的下载

### Step 2. 安装依赖

```bash
pip install -r examples/qwen2/requirements.txt
```

### Step 3. 预训练数据集和模型下载

```bash
cd examples/qwen2/
mkdir qwen-ckpts
cd qwen-ckpts
wget https://atp-modelzoo-wlcb-pai.oss-cn-wulanchabu.aliyuncs.com/release/models/pai-megatron-patch/qwen-ckpts/Qwen2-0.5B.tgz
tar -zxf Qwen2-0.5B.tgz

cd -
mkdir qwen-datasets
cd qwen-datasets
wget https://atp-modelzoo-wlcb-pai.oss-cn-wulanchabu.aliyuncs.com/release/models/pai-megatron-patch/qwen-datasets/wudao_qwenbpe_text_document.bin
wget https://atp-modelzoo-wlcb-pai.oss-cn-wulanchabu.aliyuncs.com/release/models/pai-megatron-patch/qwen-datasets/wudao_qwenbpe_text_document.idx

wget https://atp-modelzoo-wlcb-pai.oss-cn-wulanchabu.aliyuncs.com/release/models/pai-megatron-patch/qwen-datasets/alpaca_zh-qwen-train.json
wget https://atp-modelzoo-wlcb-pai.oss-cn-wulanchabu.aliyuncs.com/release/models/pai-megatron-patch/qwen-datasets/alpaca_zh-qwen-valid.json

cd -
```

## 训练流程

#### 预训练&微调命令统一描述

传入的参数列表如下：
```bash
MODEL_SIZE=$1                   # 模型结构参数量级: 7B, 72B, A14B
BATCH_SIZE=$2                   # 一次迭代一个数据并行内的样本数
GLOBAL_BATCH_SIZE=$3            # 一次迭代多个数据并行的总样本数
LR=$4                           # 学习率
MIN_LR=$5                       # 最小学习率
SEQ_LEN=$6                      # 序列长度
PAD_LEN=$7                      # Padding长度
PR=${8}                         # 训练精度: fp16, bf16, fp8
TP=${9}                        # 模型并行度
PP=${10}                        # 流水并行度
CP=${11}                        # 上下文并行度
EP=${12}                        # 专家并行度
SP=${13}                        # 是否使用序列并行: true, false
DO=${14}                        # 是否使用Megatron版Zero-1降显存优化器: true, false
FL=${15}                        # 是否优先使用Flash Attention: true, false
SFT=${16}                       # 是否执行微调训练: true, false
AC=${17}                        # 激活检查点模式: sel, full, offload, false
OPTIMIZER_OFFLOAD=${18}         # 是否启用Offload optimizer: false, static, auto
SAVE_INTERVAL=${19}             # 保存ckpt的间隔
DATASET_PATH=${20}              # 训练数据集路径
VALID_DATASET_PATH=${21}        # 验证数据集路径
PRETRAIN_CHECKPOINT_PATH=${22}  # 预训练模型路径
TRAIN_TOKENS_OR_ITERS=${23}     # 训练TOKEN或者Iter数
WARMUP_TOKENS_OR_ITERS=${24}    # 预热TOKEN或者Iter数        
OUTPUT_BASEPATH=${25}           # 训练输出日志文件路径
```

#### 预训练示例
使用以下命令启动对qwen2的继续预训练。
备注：当`AC=offload`或`full`时，可设置`MP_AC_LAYERS`环境变量来控制Checkpointing或Offload的TransformerLayer层数（默认值：`1`）。

```bash
cd /workspace/TPU-Megatron-Patch/examples/qwen2
sh run_qwen2_train.sh 7B 1 2 1
```

## 下游任务评估

### 评估格式转换
您需要将训练/微调后保存的Megatron-Core转换为HuggingFace格式来进行推理评估。

```bash
cd /workspace/TPU-Megatron-Patch/toolkits/model_checkpoints_convertor/qwen
bash hf2mcore_qwen2_convertor.sh \
0.5B \
/workspace/TPU-Megatron-Patch/examples/qwen2/qwen-ckpts/Qwen2-0.5B-hf-to-mcore-te-tp1-pp1  \
/workspace/TPU-Megatron-Patch/examples/qwen2/qwen-ckpts/Qwen2-0.5B-mcore-te-to-hf    \
1  \
1  \
1 \
fp32 \
true \
true \
/workspace/TPU-Megatron-Patch/examples/qwen2/qwen-ckpts/Qwen2-0.5B
```

### 运行评估工具
下载评估数据
```bash
# In container
cd /workspace

wget https://atp-modelzoo-wlcb-pai.oss-cn-wulanchabu.aliyuncs.com/release/models/pai-megatron-patch/evaluation-datasets/evaluate.tgz 
wget https://atp-modelzoo-wlcb-pai.oss-cn-wulanchabu.aliyuncs.com/release/models/pai-megatron-patch/evaluation-datasets/cmmlu.tgz 
wget https://atp-modelzoo-wlcb-pai.oss-cn-wulanchabu.aliyuncs.com/release/models/pai-megatron-patch/evaluation-datasets/ceval.tgz 

tar -xvzf cmmlu.tgz 
tar -xvzf ceval.tgz 
tar -xvzf evaluate.tgz
```
运行以下指令对转换后的模型进行评估。
```bash
cd /workspace/TPU-Megatron-Patch/LM-Evaluation-Harness-240310
accelerate launch --main_process_port 29051 -m lm_eval \
--model hf \
--model_args pretrained=/mnt/qwen-ckpts/Qwen2-0.5B-mcore-te-to-hf,trust_remote_code=True \
--tasks cmmlu,ceval-valid  \
--batch_size 16
```