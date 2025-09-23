# PowerShell script to run the Signal Processing Tool
Write-Host "正在启动信号处理工具..." -ForegroundColor Green

# Check if Python is available
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Python版本: $pythonVersion" -ForegroundColor Green
}
catch {
    Write-Host "错误: 未检测到Python，请确保已安装Python并添加到系统PATH中。" -ForegroundColor Red
    pause
    exit 1
}

# Check if requirements.txt exists
if (-not (Test-Path "requirements.txt")) {
    Write-Host "错误: 未找到requirements.txt文件。" -ForegroundColor Red
    pause
    exit 1
}

# Check if dependencies are installed
try {
    pip show streamlit 2>&1 | Out-Null
    Write-Host "依赖项已安装" -ForegroundColor Green
}
catch {
    Write-Host "安装依赖项..." -ForegroundColor Yellow
    pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        Write-Host "错误: 安装依赖项失败。" -ForegroundColor Red
        pause
        exit 1
    }
}

# Start Streamlit application
Write-Host "启动应用..." -ForegroundColor Green
Write-Host "应用将在浏览器中打开: http://localhost:8501" -ForegroundColor Cyan

# Use Python module method to avoid PATH issues
python -m streamlit run app.py