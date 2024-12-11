[English](./README.md) | [简体中文](./README_zh-CN.md)

# TPU-Megatron-Patch

TPU-Megatron-Patch is a high-performance toolkit for training large language models (LLM) and visual language models (VLM), based on the Megatron framework. It aims to provide efficient distributed training solutions.

## Supported Models

|          |               Location               |
| :------- | :----------------------------------: |
| Qwen2-7B | [ReadMe](./examples/qwen2/README.md) |

## Introduction

TPU-Megatron-Patch (https://github.com/sophgo/TPU-Megatron-Patch) is a deep learning training toolkit built for developers to train and predict LLMs & VLMs by using Megatron framework easily. 

The code of TPU-Megatron-Patch is based on [Pai-Megatron-Patch](https://github.com/alibaba/Pai-Megatron-Patch), here is original description of Pai-Megatron-Patch:

> With the continuous development of LLMs, the model structure and scale are rapidly evolving. Although these models can be conveniently manufactured using Transformers or DeepSpeed training framework, the training efficiency is comparably low. This phenomenon becomes even severer when the model scale exceeds 10 billion. The primary objective of **Pai-Megatron-Patch** is to effectively utilize the computational power of GPUs for LLM. This tool allows convenient training of commonly used LLM with all the accelerating techniques provided by Megatron-LM.

## What's New:

- **Support qwen2 7B model finetuning.** [🔥🔥 2024.12.11]


## Getting Started

> You should complete the following steps before you start training or predicting each models.

### Step1. Prepare torch_tpu Environment

refer to [torch_tpu](https://github.com/sophgo/torch_tpu) to device driver, prepare docker environment and install torch_tpu.

### Step2. Get TPU-Megatron-Patch repository

After step1, you can get TPU-Megatron-Patch repository by git clone (in docker container):

```bash
git clone --recurse-submodules https://github.com/sophgo/TPU-Megatron-Patch.git /workspace/TPU-Megatron-Patch
```


## License
This project is licensed under the [Apache License (Version 2.0)](./LICENSE). This toolkit also contains some code modified from other repos under other open-source licenses. See the [NOTICE](./NOTICE) file for more information.
