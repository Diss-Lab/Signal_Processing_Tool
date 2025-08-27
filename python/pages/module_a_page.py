import streamlit as st
import numpy as np
import pandas as pd
import os
import sys
from io import StringIO

# 添加项目根目录到系统路径
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

from modules.module_a.processor import SinglePointProcessor
from modules.module_a.visualizer import SinglePointVisualizer

def module_a_page():
    """
    模块A页面：单点信号处理
    """
    st.title("📊 单点信号处理")
    st.markdown("---")
    
    # 初始化session state
    if 'processor_a' not in st.session_state:
        st.session_state.processor_a = SinglePointProcessor()
    
    processor = st.session_state.processor_a
    
    # 侧边栏 - 文件上传和基本信息
    with st.sidebar:
        st.header("📁 文件上传")
        
        # 文件上传
        uploaded_file = st.file_uploader(
            "选择信号文件",
            type=['txt', 'mat'],
            help="支持TXT和MAT格式的信号文件"
        )
        
        if uploaded_file is not None:
            # 保存上传的文件到临时位置
            temp_dir = os.path.join(os.path.dirname(__file__), "..", "temp")
            os.makedirs(temp_dir, exist_ok=True)
            temp_path = os.path.join(temp_dir, uploaded_file.name)
            with open(temp_path, "wb") as f:
                f.write(uploaded_file.getbuffer())
            
            # 加载文件
            if processor.load_from_file(temp_path):
                st.success(f"✅ 文件加载成功：{uploaded_file.name}")
                
                # 显示文件信息
                st.subheader("📋 文件信息")
                st.write(f"**文件名：** {uploaded_file.name}")
                st.write(f"**信号长度：** {len(processor.signal_data)} 点")
                st.write(f"**采样率：** {processor.sampling_rate:.0f} Hz")
                st.write(f"**持续时间：** {len(processor.signal_data)/processor.sampling_rate:.4f} 秒")
            else:
                st.error("❌ 文件加载失败，请检查文件格式")
        
        # 示例数据按钮
        st.markdown("---")
        if st.button("📁 加载示例数据"):
            example_path = os.path.join(os.path.dirname(__file__), "..", "data", "single_point", "sine_wave.txt")
            if os.path.exists(example_path):
                if processor.load_from_file(example_path):
                    st.success("✅ 示例数据加载成功")
                    st.rerun()
            else:
                st.error("❌ 示例数据文件不存在")
    
    # 主内容区域
    if processor.signal_data is not None:
        
        # 滤波器控制面板
        st.header("🔧 信号处理控制")
        
        col1, col2, col3 = st.columns(3)
        
        with col1:
            st.subheader("带通滤波器")
            enable_bandpass = st.checkbox("启用带通滤波", key="bandpass_enable")
            if enable_bandpass:
                low_freq = st.number_input(
                    "低截止频率 (Hz)", 
                    min_value=100.0, 
                    max_value=1000000.0, 
                    value=100000.0,
                    step=1000.0,
                    key="bandpass_low"
                )
                high_freq = st.number_input(
                    "高截止频率 (Hz)", 
                    min_value=100.0, 
                    max_value=1000000.0, 
                    value=500000.0,
                    step=1000.0,
                    key="bandpass_high"
                )
                bandpass_order = st.selectbox(
                    "滤波器阶数", 
                    [2, 4, 6, 8], 
                    index=1,
                    key="bandpass_order"
                )
        
        with col2:
            st.subheader("低通滤波器")
            enable_lowpass = st.checkbox("启用低通滤波", key="lowpass_enable")
            if enable_lowpass:
                lowpass_freq = st.number_input(
                    "截止频率 (Hz)", 
                    min_value=100.0, 
                    max_value=1000000.0, 
                    value=300000.0,
                    step=1000.0,
                    key="lowpass_freq"
                )
                lowpass_order = st.selectbox(
                    "滤波器阶数", 
                    [2, 4, 6, 8], 
                    index=1,
                    key="lowpass_order"
                )
        
        with col3:
            st.subheader("高通滤波器")
            enable_highpass = st.checkbox("启用高通滤波", key="highpass_enable")
            if enable_highpass:
                highpass_freq = st.number_input(
                    "截止频率 (Hz)", 
                    min_value=100.0, 
                    max_value=1000000.0, 
                    value=50000.0,
                    step=1000.0,
                    key="highpass_freq"
                )
                highpass_order = st.selectbox(
                    "滤波器阶数", 
                    [2, 4, 6, 8], 
                    index=1,
                    key="highpass_order"
                )
        
        # 其他滤波器
        st.markdown("---")
        col4, col5, col6 = st.columns(3)
        
        with col4:
            st.subheader("中值滤波器")
            enable_median = st.checkbox("启用中值滤波", key="median_enable")
            if enable_median:
                median_kernel = st.selectbox(
                    "核大小", 
                    [3, 5, 7, 9, 11], 
                    index=1,
                    key="median_kernel"
                )
        
        with col5:
            st.subheader("Savitzky-Golay滤波器")
            enable_savgol = st.checkbox("启用SG滤波", key="savgol_enable")
            if enable_savgol:
                savgol_window = st.selectbox(
                    "窗口长度", 
                    [11, 21, 31, 41, 51], 
                    index=0,
                    key="savgol_window"
                )
                savgol_order = st.selectbox(
                    "多项式阶数", 
                    [2, 3, 4, 5], 
                    index=1,
                    key="savgol_order"
                )
        
        with col6:
            st.subheader("信号处理")
            enable_normalize = st.checkbox("归一化信号", key="normalize_enable")
        
        # 应用滤波器按钮
        st.markdown("---")
        col_apply, col_reset = st.columns([1, 1])
        
        with col_apply:
            if st.button("🔄 应用滤波器", type="primary", use_container_width=True):
                # 重置处理
                processor.reset_processing()
                
                # 应用滤波器
                try:
                    if enable_bandpass and low_freq < high_freq:
                        processor.apply_bandpass_filter(low_freq, high_freq, bandpass_order)
                    
                    if enable_lowpass:
                        processor.apply_lowpass_filter(lowpass_freq, lowpass_order)
                    
                    if enable_highpass:
                        processor.apply_highpass_filter(highpass_freq, highpass_order)
                    
                    if enable_median:
                        processor.apply_median_filter(median_kernel)
                    
                    if enable_savgol:
                        processor.apply_savgol_filter(savgol_window, savgol_order)
                    
                    if enable_normalize:
                        processor.normalize_signal()
                    
                    st.success("✅ 滤波器应用成功")
                    
                except Exception as e:
                    st.error(f"❌ 滤波器应用失败：{str(e)}")
        
        with col_reset:
            if st.button("🔄 重置处理", use_container_width=True):
                processor.reset_processing()
                st.success("✅ 信号已重置为原始状态")
        
        # 可视化部分
        st.markdown("---")
        st.header("📈 信号可视化")
        
        # 创建标签页
        tab1, tab2, tab3, tab4 = st.tabs(["时域对比", "频域分析", "信号包络", "时频分析"])
        
        with tab1:
            st.subheader("原始信号 vs 处理后信号")
            try:
                fig_comparison = SinglePointVisualizer.plot_comparison(
                    processor.time_axis,
                    processor.signal_data,
                    processor.processed_data,
                    use_plotly=True
                )
                st.plotly_chart(fig_comparison, use_container_width=True)
            except Exception as e:
                st.error(f"绘制时域对比图时出错：{str(e)}")
        
        with tab2:
            st.subheader("频域分析")
            try:
                freqs, magnitudes = processor.compute_fft()
                if freqs is not None and magnitudes is not None:
                    fig_freq = SinglePointVisualizer.plot_frequency_domain(
                        freqs, magnitudes, use_plotly=True
                    )
                    st.plotly_chart(fig_freq, use_container_width=True)
                else:
                    st.warning("无法计算FFT")
            except Exception as e:
                st.error(f"绘制频域图时出错：{str(e)}")
        
        with tab3:
            st.subheader("信号包络")
            try:
                envelope_method = st.selectbox("包络计算方法", ["hilbert", "peak"])
                envelope = processor.compute_envelope(envelope_method)
                if envelope is not None:
                    fig_envelope = SinglePointVisualizer.plot_envelope(
                        processor.time_axis,
                        processor.processed_data,
                        envelope,
                        use_plotly=True
                    )
                    st.plotly_chart(fig_envelope, use_container_width=True)
                else:
                    st.warning("无法计算信号包络")
            except Exception as e:
                st.error(f"绘制包络图时出错：{str(e)}")
        
        with tab4:
            st.subheader("短时傅里叶变换（STFT）")
            try:
                # STFT参数控制
                col_stft1, col_stft2 = st.columns(2)
                with col_stft1:
                    nperseg = st.selectbox("窗口长度", [128, 256, 512, 1024], index=1)
                with col_stft2:
                    noverlap = st.selectbox("重叠点数", [64, 128, 256, 512], index=1)
                
                f, t, Zxx = processor.compute_stft(nperseg, noverlap)
                if f is not None and t is not None and Zxx is not None:
                    fig_stft = SinglePointVisualizer.plot_stft(
                        t, f, Zxx, use_plotly=True
                    )
                    st.plotly_chart(fig_stft, use_container_width=True)
                else:
                    st.warning("无法计算STFT")
            except Exception as e:
                st.error(f"绘制STFT图时出错：{str(e)}")
        
        # 数据导出
        st.markdown("---")
        st.header("💾 数据导出")
        
        col_export1, col_export2 = st.columns(2)
        
        with col_export1:
            if st.button("📄 导出为MAT文件", use_container_width=True):
                temp_dir = os.path.join(os.path.dirname(__file__), "..", "temp")
                os.makedirs(temp_dir, exist_ok=True)
                output_path = os.path.join(temp_dir, "processed_signal.mat")
                if processor.save_to_mat(output_path):
                    with open(output_path, "rb") as file:
                        st.download_button(
                            label="📥 下载MAT文件",
                            data=file.read(),
                            file_name="processed_signal.mat",
                            mime="application/octet-stream",
                            use_container_width=True
                        )
                else:
                    st.error("❌ MAT文件导出失败")
        
        with col_export2:
            if st.button("📊 导出为CSV文件", use_container_width=True):
                try:
                    # 创建DataFrame
                    df = pd.DataFrame({
                        'Time': processor.time_axis,
                        'Original_Signal': processor.signal_data,
                        'Processed_Signal': processor.processed_data
                    })
                    
                    # 转换为CSV
                    csv = df.to_csv(index=False)
                    st.download_button(
                        label="📥 下载CSV文件",
                        data=csv,
                        file_name="processed_signal.csv",
                        mime="text/csv",
                        use_container_width=True
                    )
                except Exception as e:
                    st.error(f"❌ CSV文件导出失败：{str(e)}")
    
    else:
        # 如果没有加载数据，显示欢迎信息
        st.info("👋 欢迎使用单点信号处理模块！请在左侧上传信号文件或加载示例数据开始使用。")
        
        # 显示支持的功能
        st.subheader("🌟 支持的功能")
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.markdown("""
            **滤波器类型：**
            - 带通滤波器
            - 低通滤波器  
            - 高通滤波器
            - 中值滤波器
            - Savitzky-Golay滤波器
            """)
        
        with col2:
            st.markdown("""
            **分析功能：**
            - 时域信号对比
            - 频域分析（FFT）
            - 信号包络提取
            - 短时傅里叶变换（STFT）
            - 数据导出（MAT/CSV）
            """)

if __name__ == "__main__":
    module_a_page()