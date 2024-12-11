[English](./README.md) | [简体中文](./README_zh-CN.md)

# TPU-Megatron-Patch

TPU-Megatron-Patch 是一个基于 Megatron 框架的高性能工具包，用于训练大语言模型(LLM)和视觉语言模型(VLM)，旨在提供高效的分布式训练解决方案。

## 支持的模型

|          |               位置               |
| :------- | :------------------------------: |
| Qwen2-7B | [说明文档](./examples/qwen2/README.md) |


## 简介

TPU-Megatron-Patch (https://github.com/sophgo/TPU-Megatron-Patch) 是一个为开发者打造的深度学习训练工具包，可以使用 Megatron 框架轻松训练和预测 LLM 和 VLM。

TPU-Megatron-Patch 的代码基于 [Pai-Megatron-Patch](https://github.com/alibaba/Pai-Megatron-Patch)，以下是 Pai-Megatron-Patch 的原始描述：

> 随着大语言模型的持续发展，模型结构和规模正在快速演进。虽然这些模型可以使用 Transformers 或 DeepSpeed 训练框架方便地构建，但训练效率相对较低。当模型规模超过 100 亿参数时，这种现象变得更加明显。Pai-Megatron-Patch 的主要目标是有效利用 GPU 的计算能力来训练大语言模型。该工具可以方便地训练常用的大语言模型，并使用 Megatron-LM 提供的所有加速技术。

## 最新更新

- **支持 qwen2 7B 模型微调。** [🔥🔥 2024.12.11]


## 通用步骤

不同案例的环境配置细则，请参考各模型的文档。但有一些通用步骤需要提前完成，请参考以下步骤。

### 步骤1. 准备 torch_tpu 环境

参考 [torch_tpu](https://github.com/sophgo/torch_tpu) 安装设备驱动，准备 docker 环境并安装 torch_tpu。

### 步骤2. 获取 TPU-Megatron-Patch 代码库

完成步骤1后，你可以通过 git clone 获取 TPU-Megatron-Patch 代码库（在 docker 容器内）：

```bash
git clone --recurse-submodules https://github.com/sophgo/TPU-Megatron-Patch.git /workspace/TPU-Megatron-Patch
```


## 许可证
本项目采用 [Apache License (Version 2.0)](./LICENSE) 许可证。本工具包还包含了一些来自其他开源许可证的修改代码。更多信息请参见 [NOTICE](./NOTICE) 文件。