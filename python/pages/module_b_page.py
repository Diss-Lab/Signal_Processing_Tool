import streamlit as st
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
import sys
import scipy.io as sio
from typing import Tuple, List, Dict, Any, Optional, Union
import plotly.graph_objects as go
from glob import glob

# 添加项目根目录到系统路径
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# 导入模块
from modules.module_b import BScanProcessor, BScanVisualizer
from utils.file_utils import FileUtils

def module_b_page():
    """
    B扫描信号处理页面
    """
    st.title("B扫描信号处理")
    
    # 初始化session state
    if 'processor_b' not in st.session_state:
        st.session_state.processor_b = BScanProcessor()
    
    processor = st.session_state.processor_b
    visualizer = BScanVisualizer()
    
    # 创建侧边栏
    with st.sidebar:
        st.header("参数设置")
        
        # 数据加载选项
        st.subheader("数据加载")
        data_source = st.radio("数据来源", ["文件夹", "MAT文件"])
        
        if data_source == "文件夹":
            folder_path = st.text_input("信号文件夹路径")
            file_pattern = st.text_input("文件名模式", "*.txt")
            position_from_filename = st.checkbox("从文件名提取位置信息", True)
            if position_from_filename:
                position_pattern = st.text_input("位置提取模式", "pos_(\\d+)")
        else:  # MAT文件
            mat_file = st.file_uploader("上传B扫描MAT文件", type=["mat"])
        
        # 滤波器设置
        st.subheader("滤波器设置")
        filter_type = st.selectbox("滤波器类型", ["带通滤波", "低通滤波", "高通滤波", "中值滤波", "Savitzky-Golay滤波"])
        
        if filter_type in ["带通滤波", "低通滤波", "高通滤波"]:
            order = st.slider("滤波器阶数", 1, 10, 4)
            if filter_type == "带通滤波":
                low_freq = st.number_input("低截止频率 (Hz)", 0.0, 1000000.0, 10000.0, step=1000.0)
                high_freq = st.number_input("高截止频率 (Hz)", 0.0, 1000000.0, 100000.0, step=1000.0)
            elif filter_type == "低通滤波":
                cutoff_freq = st.number_input("截止频率 (Hz)", 0.0, 1000000.0, 100000.0, step=1000.0)
            elif filter_type == "高通滤波":
                cutoff_freq = st.number_input("截止频率 (Hz)", 0.0, 1000000.0, 10000.0, step=1000.0)
        elif filter_type == "中值滤波":
            window_size = st.slider("窗口大小", 3, 51, 5, step=2)
        elif filter_type == "Savitzky-Golay滤波":
            window_size = st.slider("窗口大小", 5, 51, 11, step=2)
            poly_order = st.slider("多项式阶数", 1, 5, 3)
        
        # B扫描图像设置
        st.subheader("B扫描图像设置")
        normalize_bscan = st.checkbox("归一化B扫描", True)
        use_envelope = st.checkbox("使用包络", True)
        if use_envelope:
            envelope_method = st.selectbox("包络计算方法", ["希尔伯特变换", "峰值检测"])
        
        # 可视化选项
        st.subheader("可视化选项")
        plot_type = st.selectbox("图表类型", [
            "B扫描图像", 
            "指定位置信号", 
            "瀑布图", 
            "3D B扫描图像", 
            "指定时间点位置切片"
        ])
        use_plotly = st.checkbox("使用交互式图表", True)
        
        if plot_type == "指定位置信号":
            position_index = st.slider("位置索引", 0, 100, 0, key="pos_slider")
        elif plot_type == "指定时间点位置切片":
            time_index = st.slider("时间索引", 0, 1000, 500, key="time_slider")
        
        # 保存选项
        st.subheader("保存选项")
        save_results = st.checkbox("保存处理结果", False)
        if save_results:
            save_path = st.text_input("保存路径", "processed_bscan.mat")
        
        # 处理按钮
        process_button = st.button("处理B扫描数据")
    
    # 主内容区域
    if (data_source == "文件夹" and folder_path) or (data_source == "MAT文件" and mat_file is not None):
        # 处理B扫描数据
        if process_button:
            with st.spinner("正在处理B扫描数据..."):
                # 加载数据
                if data_source == "文件夹":
                    st.write(f"从文件夹加载数据: {folder_path}")
                    success = processor.load_from_folder(folder_path, file_pattern)
                    if success:
                        st.success(f"✅ 成功加载 {len(processor.signals)} 个信号文件")
                    else:
                        st.error("❌ 文件加载失败，请检查文件夹路径和文件格式")
                else:  # MAT文件
                    # 保存上传的文件到临时位置
                    temp_dir = os.path.join(os.path.dirname(__file__), "..", "temp")
                    os.makedirs(temp_dir, exist_ok=True)
                    file_path = os.path.join(temp_dir, mat_file.name)
                    
                    with open(file_path, "wb") as f:
                        f.write(mat_file.getbuffer())
                    
                    st.write(f"从MAT文件加载数据: {mat_file.name}")
                    processor.load_from_mat(file_path)
                
                # 应用滤波器
                if filter_type == "带通滤波":
                    processor.apply_bandpass_filter(low_freq, high_freq, order)
                elif filter_type == "低通滤波":
                    processor.apply_lowpass_filter(cutoff_freq, order)
                elif filter_type == "高通滤波":
                    processor.apply_highpass_filter(cutoff_freq, order)
                elif filter_type == "中值滤波":
                    processor.apply_median_filter(window_size)
                elif filter_type == "Savitzky-Golay滤波":
                    processor.apply_savgol_filter(window_size, poly_order)
                
                # 创建B扫描图像
                if use_envelope:
                    envelope_method_str = "hilbert" if envelope_method == "希尔伯特变换" else "peak"
                    processor.create_bscan(normalize=normalize_bscan, envelope=True, method=envelope_method_str)
                else:
                    processor.create_bscan(normalize=normalize_bscan, envelope=False)
                
                # 保存结果
                if save_results:
                    processor.save_to_mat(save_path)
                    st.success(f"处理结果已保存到 {save_path}")
                
                # 可视化结果
                st.subheader("处理结果")
                
                if plot_type == "B扫描图像":
                    if use_plotly:
                        fig = visualizer.plot_bscan_interactive(
                            processor.bscan_data, 
                            processor.time_axis, 
                            processor.positions, 
                            title="B扫描图像"
                        )
                        st.plotly_chart(fig, use_container_width=True)
                    else:
                        fig = visualizer.plot_bscan(
                            processor.bscan_data, 
                            processor.time_axis, 
                            processor.positions, 
                            title="B扫描图像", 
                            show=False
                        )
                        st.pyplot(fig)
                
                elif plot_type == "指定位置信号":
                    # 确保位置索引在有效范围内
                    max_pos_idx = len(processor.positions) - 1
                    position_index = min(position_index, max_pos_idx)
                    
                    time_axis, signal = processor.get_signal_at_position(position_index)
                    if time_axis is not None and signal is not None:
                        if use_plotly:
                            fig = visualizer.plot_signal_at_position_interactive(
                                time_axis, 
                                signal, 
                                processor.positions[position_index], 
                                title=f"位置 {processor.positions[position_index]} 处的信号"
                            )
                            st.plotly_chart(fig, use_container_width=True)
                        else:
                            fig = visualizer.plot_signal_at_position(
                                time_axis, 
                                signal, 
                                processor.positions[position_index], 
                                title=f"位置 {processor.positions[position_index]} 处的信号", 
                                show=False
                            )
                            st.pyplot(fig)
                
                elif plot_type == "瀑布图":
                    if use_plotly:
                        fig = visualizer.plot_waterfall_interactive(
                            processor.bscan_data, 
                            processor.time_axis, 
                            processor.positions, 
                            title="B扫描瀑布图"
                        )
                        st.plotly_chart(fig, use_container_width=True)
                    else:
                        fig = visualizer.plot_waterfall(
                            processor.bscan_data, 
                            processor.time_axis, 
                            processor.positions, 
                            title="B扫描瀑布图", 
                            show=False
                        )
                        st.pyplot(fig)
                
                elif plot_type == "3D B扫描图像":
                    if use_plotly:
                        fig = visualizer.plot_bscan_3d_interactive(
                            processor.bscan_data, 
                            processor.time_axis, 
                            processor.positions, 
                            title="3D B扫描图像"
                        )
                        st.plotly_chart(fig, use_container_width=True)
                    else:
                        fig = visualizer.plot_bscan_3d(
                            processor.bscan_data, 
                            processor.time_axis, 
                            processor.positions, 
                            title="3D B扫描图像", 
                            show=False
                        )
                        st.pyplot(fig)
                
                elif plot_type == "指定时间点位置切片":
                    # 确保时间索引在有效范围内
                    max_time_idx = processor.bscan_data.shape[1] - 1
                    time_index = min(time_index, max_time_idx)
                    
                    positions, signal = processor.get_signal_at_time(time_index)
                    if positions is not None and signal is not None:
                        if use_plotly:
                            fig = visualizer.plot_signal_at_time_interactive(
                                positions, 
                                signal, 
                                processor.time_axis[time_index], 
                                title=f"时间 {processor.time_axis[time_index]:.6f} s 的位置切片"
                            )
                            st.plotly_chart(fig, use_container_width=True)
                        else:
                            fig = visualizer.plot_signal_at_time(
                                positions, 
                                signal, 
                                processor.time_axis[time_index], 
                                title=f"时间 {processor.time_axis[time_index]:.6f} s 的位置切片", 
                                show=False
                            )
                            st.pyplot(fig)
                
                # 显示B扫描参数
                st.subheader("B扫描参数")
                st.write(f"采样率: {processor.sampling_rate} Hz")
                st.write(f"位置数量: {len(processor.positions)}")
                st.write(f"每个信号的采样点数: {processor.bscan_data.shape[1]}")
                st.write(f"信号持续时间: {len(processor.time_axis)/processor.sampling_rate:.6f} 秒")
                
                # 显示统计信息
                st.subheader("B扫描统计信息")
                stats_df = pd.DataFrame({
                    "参数": ["最大值", "最小值", "均值", "标准差"],
                    "值": [
                        f"{np.max(processor.bscan_data):.6f}",
                        f"{np.min(processor.bscan_data):.6f}",
                        f"{np.mean(processor.bscan_data):.6f}",
                        f"{np.std(processor.bscan_data):.6f}"
                    ]
                })
                st.table(stats_df)
    else:
        # 显示使用说明
        st.info("""
        ### 使用说明
        1. 在侧边栏选择数据来源（文件夹或MAT文件）
        2. 设置滤波器参数和B扫描图像设置
        3. 选择可视化方式
        4. 点击"处理B扫描数据"按钮进行处理和可视化
        
        ### 支持的数据格式
        - **文件夹**: 包含多个TXT格式信号文件的文件夹，每个文件代表一个位置的信号
        - **MAT文件**: 包含B扫描数据的MATLAB数据文件
        """)
        
        # 显示示例
        st.subheader("示例")
        
        # 创建示例B扫描数据
        num_positions = 50
        num_samples = 1000
        t = np.linspace(0, 0.1, num_samples)
        positions = np.linspace(0, 100, num_positions)
        
        # 创建一个简单的B扫描图像
        bscan_image = np.zeros((num_positions, num_samples))
        for i, pos in enumerate(positions):
            # 创建一个随位置变化的信号
            delay = 0.02 + 0.03 * np.sin(pos / 10)
            signal = np.exp(-((t - delay) ** 2) / (2 * 0.005 ** 2)) * np.sin(2 * np.pi * 100 * (t - delay))
            bscan_image[i, :] = signal
        
        # 添加一些噪声
        bscan_image += 0.1 * np.random.randn(*bscan_image.shape)
        
        # 显示示例B扫描图像
        fig, ax = plt.subplots(figsize=(10, 6))
        im = ax.imshow(bscan_image, aspect='auto', extent=[0, t[-1], positions[-1], positions[0]], cmap='viridis')
        plt.colorbar(im, ax=ax, label='幅值')
        ax.set_title("示例B扫描图像")
        ax.set_xlabel("时间 (s)")
        ax.set_ylabel("位置")
        st.pyplot(fig)
        
        st.write("""
        上面显示的是一个示例B扫描图像，横轴表示时间，纵轴表示位置。
        图像中的亮度表示信号的幅值，可以看到一个随位置变化的波形。
        请提供您自己的B扫描数据以开始处理。
        """)

if __name__ == "__main__":
    module_b_page()