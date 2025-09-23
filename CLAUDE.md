# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 上下文规则！！

- 在上下文长度接近限制时，优先删除与现在任务无关的历史对话；
- 在历史对话接近最大上下文限制时，调用/compact命令总结上下文对话，并继续执行任务。

## 数据读取规则！！

- 在以了解数据格式为目的读取数据

## Project Overview

This is a dual-platform Signal Processing Tool with both MATLAB and Python implementations. The project provides three specialized modules (A, B, C) for different types of signal processing:

- **Module A**: Single point signal processing (TXT files)
- **Module B**: B-scan signal processing (multiple TXT files) 
- **Module C**: Wave field data processing (MAT files)

## Development Commands

### Python Application
```bash
# Navigate to Python directory
cd python

# Install dependencies
pip install -r requirements.txt

# Run the Streamlit application
streamlit run app.py

# Run module tests
python test_modules.py

# Alternative run (Windows PowerShell)
# Install dependencies
pip install streamlit numpy scipy pandas matplotlib plotly h5py

# Run Streamlit app
python -m streamlit run app.py

# Or use the batch files
run_simple.bat  # 简化版，直接运行
run.bat         # 完整版，包含依赖检查
```

### MATLAB Application
```bash
# Navigate to MATLAB directory
cd matlab

# Start the main application in MATLAB
SPT
# or
start_SPT
```

## Code Architecture

### Python Implementation Structure

**Core Architecture Pattern**: The Python version follows a modular processor-visualizer pattern:
- Each module has a `processor.py` (data processing logic) and `visualizer.py` (plotting/display)
- Pages (`pages/`) handle Streamlit UI and user interactions
- Utils (`utils/`) provide shared functionality across modules

**Key Components**:
- `app.py`: Main Streamlit application with navigation
- `modules/module_*/processor.py`: Core signal processing logic using scipy/numpy
- `modules/module_*/visualizer.py`: Plotly-based interactive visualizations
- `utils/signal_utils.py`: Shared signal processing functions (filters, FFT, STFT, envelopes)
- `utils/file_utils.py`: File I/O handling for TXT/MAT formats

**Data Flow Pattern**:
1. File upload via Streamlit UI
2. Data loading through FileUtils (handles TXT/MAT parsing)
3. Signal processing via processor classes (apply filters, compute transforms)
4. Visualization through visualizer classes (interactive Plotly charts)
5. Export functionality (MAT/CSV formats)

### MATLAB Implementation Structure

**Architecture**: Traditional MATLAB GUI with modular design
- `SPT.m`: Main launcher with GUI navigation
- `A/`, `B/`, `C/`: Separate directories for each processing module
- Each module has dedicated files: `Read*.m` (main), `*_processor.m`, `*_visualizer.m`, etc.

### Module Functionality Mapping

**Module A (Single Point)**: 
- Processes individual signal files
- Supports multiple filter types (bandpass, lowpass, highpass, median, Savitzky-Golay)
- FFT, STFT, envelope extraction
- Interactive parameter tuning

**Module B (B-Scan)**: 
- Batch processing of multiple position-based signals
- Creates 2D B-scan images from 1D signals
- Waterfall plots and 3D visualizations
- Signal slice analysis

**Module C (Wave Field)**:
- 3D wave field data processing from MAT files
- Time slice extraction and visualization
- Energy maps, max amplitude maps, arrival time calculations
- 3D wave field visualization

## Development Notes

### Current State
- Module A is fully functional in Python
- Modules B and C show "under development" messages in Python app
- MATLAB version appears to have all three modules implemented

### File Format Support
- **TXT files**: Time-series signal data (space/tab separated, 2 columns: time, amplitude)
- **MAT files**: MATLAB data files for wave field data and export

### Key Dependencies
- **Python**: streamlit, numpy, scipy, pandas, matplotlib, plotly, h5py
- **MATLAB**: Signal Processing Toolbox, basic MATLAB functions

### Testing
- Python has comprehensive test suite in `test_modules.py`
- Tests cover file utils, signal utils, and all processor classes
- Run tests to verify module functionality before deployment