@echo off
echo 正在启动信号处理工具...

REM 使用Python模块方式运行Streamlit，避免PATH问题
python -m streamlit run app.py

pause