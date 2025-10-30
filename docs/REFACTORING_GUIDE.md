# 信号处理工具重构指导书

## 项目概述

**项目名称**: Signal_Processing_Tool  
**MATLAB版本**: R2023b  
**重构开始日期**: 2024年  
**当前状态**: 准备阶段

### 功能模块

- **A模块**: 单点信号处理（TXT转MAT、信号对比分析）
- **B模块**: B扫描多文件处理（时域信号分析、峰峰值提取）
- **C模块**: 波场数据处理（3D数据可视化、时频分析）

---

## 核心重构原则

### 1. 数据结构标准化

#### 统一数据格式
```matlab
% 所有模块使用统一的3D数据格式：data_xyt(m, n, t)
% - A模块: data_xyt(1, 1, t) - 单点
% - B模块: data_xyt(1, m, t) - 单行多点
% - C模块: data_xyt(m, n, t) - 二维网格
```

#### 标准数据结构体
```matlab
SignalData 类属性:
- data         % 3D矩阵 (m×n×t)
- time         % 时间向量
- fs           % 采样频率
- metadata     % 元数据 (type, source, dimensions)
```

### 2. 模块职责分离

