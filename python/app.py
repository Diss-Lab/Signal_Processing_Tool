import streamlit as st
import os
import sys

# 添加项目根目录到系统路径
sys.path.append(os.path.abspath(os.path.dirname(__file__)))

# 导入页面模块
from pages.module_a_page import module_a_page
from pages.module_b_page import module_b_page

def main():
    """
    主应用程序
    """
    # 页面配置
    st.set_page_config(
        page_title="信号处理工具",
        page_icon="🔬",
        layout="wide",
        initial_sidebar_state="expanded"
    )
    
    # 主标题
    st.title("🔬 信号处理工具 (Signal Processing Tool)")
    st.markdown("---")
    
    # 侧边栏导航
    with st.sidebar:
        st.title("📋 功能模块")
        
        # 模块选择
        module_choice = st.selectbox(
            "选择处理模块",
            [
                "🏠 首页",
                "📊 单点信号处理 (模块A)",
                "📈 B扫描处理 (模块B)",
                "🌊 波场处理 (模块C)"
            ],
            index=0
        )
        
        st.markdown("---")
        st.markdown("### 📖 使用说明")
        st.markdown("""
        1. **单点信号处理**: 处理单个信号文件，支持多种滤波器
        2. **B扫描处理**: 批量处理多个位置的信号数据
        3. **波场处理**: 处理三维波场数据，生成时间切片
        """)
    
    # 根据选择显示相应页面
    if module_choice == "🏠 首页":
        show_home_page()
    elif module_choice == "📊 单点信号处理 (模块A)":
        module_a_page()
    elif module_choice == "📈 B扫描处理 (模块B)":
        module_b_page()
    elif module_choice == "🌊 波场处理 (模块C)":
        st.title("🌊 波场处理")
        st.info("🚧 模块C正在开发中，敬请期待...")

def show_home_page():
    """
    显示首页
    """
    st.header("🏠 欢迎使用信号处理工具")
    
    # 工具介绍
    col1, col2 = st.columns([2, 1])
    
    with col1:
        st.markdown("""
        ### 🎯 工具简介
        
        这是一个专业的信号处理工具，基于Python和Streamlit开发，提供了丰富的信号分析功能。
        工具包含三个主要模块，每个模块针对不同类型的信号处理需求：
        
        **🔧 主要功能:**
        - 多种滤波器支持（带通、低通、高通、中值、SG滤波）
        - 交互式信号可视化
        - 频域分析（FFT、STFT）
        - 信号包络提取
        - 数据导出（MAT、CSV格式）
        
        **📁 支持格式:**
        - TXT格式：时间序列数据
        - MAT格式：MATLAB数据文件
        
        **🚀 开始使用:**
        请在左侧选择相应的功能模块开始处理您的信号数据。
        """)
    
    with col2:
        st.markdown("""
        ### 📊 功能模块
        
        **模块A - 单点信号处理**
        - ✅ 已完成
        - 单个信号文件处理
        - 实时滤波和可视化
        
        **模块B - B扫描处理**
        - 🚧 开发中
        - 批量文件处理
        - 瀑布图和3D可视化
        
        **模块C - 波场处理**
        - 🚧 开发中
        - 三维波场数据
        - 时间切片分析
        """)
    
    # 快速开始
    st.markdown("---")
    st.header("🚀 快速开始")
    
    col1, col2, col3 = st.columns(3)
    
    with col1:
        st.markdown("""
        ### 1️⃣ 上传文件
        
        点击左侧"单点信号处理"模块，然后上传您的信号文件。
        支持TXT和MAT格式。
        """)
    
    with col2:
        st.markdown("""
        ### 2️⃣ 配置参数
        
        根据您的需求选择合适的滤波器类型和参数。
        可以实时预览处理效果。
        """)
    
    with col3:
        st.markdown("""
        ### 3️⃣ 分析结果
        
        查看时域、频域分析结果，
        并可以导出处理后的数据。
        """)
    
    # 技术信息
    st.markdown("---")
    st.header("🔧 技术信息")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.markdown("""
        **核心技术栈:**
        - Python 3.8+
        - Streamlit (Web界面)
        - NumPy & SciPy (数值计算)
        - Plotly (交互式可视化)
        - Pandas (数据处理)
        """)
    
    with col2:
        st.markdown("""
        **支持的滤波器:**
        - 巴特沃斯带通/低通/高通滤波器
        - 中值滤波器
        - Savitzky-Golay滤波器
        - 希尔伯特变换包络提取
        """)

if __name__ == "__main__":
    main()