@echo off
echo 正在启动信号处理工具...

REM 检查Python环境
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 未检测到Python，请确保已安装Python并添加到系统PATH中。
    pause
    exit /b 1
)

REM 检查requirements.txt文件
if not exist "%~dp0requirements.txt" (
    echo 错误: 未找到requirements.txt文件。
    pause
    exit /b 1
)

REM 检查是否已安装依赖
echo 检查依赖项...
pip show streamlit >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 安装依赖项...
    pip install -r "%~dp0requirements.txt"
    if %ERRORLEVEL% NEQ 0 (
        echo 错误: 安装依赖项失败。
        pause
        exit /b 1
    )
)

REM 启动Streamlit应用
echo 启动应用...
cd /d "%~dp0"
REM 使用Python模块方式运行，避免PATH问题
python -m streamlit run app.py

pause