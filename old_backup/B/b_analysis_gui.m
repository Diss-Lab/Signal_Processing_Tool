function b_analysis_gui(varargin)
    % B扫时域信号分析GUI - 基于SignalAnalysisGUI3.m修改
    % 支持读取data.mat文件格式
    
    % 创建主界面
    fig = figure('Name', 'B-Scan 时域信号分析GUI', 'NumberTitle', 'off', ...
                'Position', [100, 100, 1400, 850], 'MenuBar', 'none', ...
                'ToolBar', 'none', 'Resize', 'on');
    
    % 全局变量
    global signalData originalSignalData positions fileNames amplitudes_peak amplitudes_pp amplitudes_rms amplitudes_max5us
    global numPoints isFiltered filterParams wavePacketTimeRange data_loaded_from_mat
    
    % 初始化数据
    signalData = {};
    originalSignalData = {}; % 保存原始未滤波数据
    positions = [];
    fileNames = {};
    amplitudes_peak = [];
    amplitudes_pp = [];
    amplitudes_rms = [];
    amplitudes_max5us = [];
    numPoints = 13; % 默认13个点
    isFiltered = false;
    filterParams = struct('lowFreq', 100e3, 'highFreq', 1e6, 'order', 4); % 默认滤波参数
    wavePacketTimeRange = [0, 10e-6]; % 默认波包时间范围 0-10微秒
    data_loaded_from_mat = false; % 标记是否从mat文件加载了数据
    
    % 检查是否有传入的数据
    if nargin >= 3
        try
            auto_load_data_from_params(varargin{1}, varargin{2}, varargin{3});
        catch ME
            fprintf('自动加载传入数据失败: %s\n', ME.message);
        end
    end
    
    % 创建UI控件
    createUI();
    
    function auto_load_data_from_params(data_xyt, data_time, fs)
        % 从传入参数自动加载数据
        try
            if size(data_xyt, 3) ~= length(data_time)
                error('数据时间维度不匹配');
            end
            
            numPoints = size(data_xyt, 2); % 从数据获取点数
            
            % 转换数据格式
            signalData = {};
            originalSignalData = {};
            fileNames = {};
            
            for i = 1:numPoints
                % 提取每个位置的信号
                signal_data = squeeze(data_xyt(1, i, :)); % 假设是单行多列数据
                
                data_struct = struct();
                data_struct.time = data_time(:);
                data_struct.signal = signal_data(:);
                
                signalData{i} = data_struct;
                originalSignalData{i} = data_struct;
                fileNames{i} = sprintf('Point_%d', i);
            end
            
            data_loaded_from_mat = true;
            fprintf('成功从传入参数加载 %d 个信号点\n', numPoints);
            
        catch ME
            fprintf('从传入参数加载数据失败: %s\n', ME.message);
        end
    end
    
    function createUI()
        % 标题
        uicontrol('Style', 'text', 'String', 'B扫时域信号分析系统', ...
                  'Position', [600, 800, 200, 30], 'FontSize', 14, 'FontWeight', 'bold');
        
        % 数据加载区域
        uicontrol('Style', 'text', 'String', '数据加载选项:', ...
                  'Position', [50, 750, 100, 25], 'HorizontalAlignment', 'left', 'FontWeight', 'bold');
        
        % 数据加载方式选择
        uicontrol('Style', 'pushbutton', 'String', '加载data.mat文件', ...
                  'Position', [160, 755, 120, 25], 'Callback', @load_mat_file);
        
        uicontrol('Style', 'pushbutton', 'String', '选择TXT文件夹', ...
                  'Position', [290, 755, 120, 25], 'Callback', @load_txt_folder);
        
        % 数据点数设置
        uicontrol('Style', 'text', 'String', '数据点数:', ...
                  'Position', [70, 710, 80, 25], 'HorizontalAlignment', 'left');
        
        numPointsEdit = uicontrol('Style', 'edit', 'Position', [130, 715, 60, 25], ...
                                 'String', num2str(numPoints), 'Callback', @updateNumPoints);
        
        uicontrol('Style', 'text', 'String', '测量距离(mm):', ...
                  'Position', [220, 710, 100, 25], 'HorizontalAlignment', 'left');
        
        distanceEdit = uicontrol('Style', 'edit', 'Position', [300, 715, 60, 25], ...
                                'String', '25');
        
        % 数据状态显示
        dataStatusText = uicontrol('Style', 'text', 'String', '未加载数据', ...
                                  'Position', [430, 730, 300, 30], 'HorizontalAlignment', 'left', ...
                                  'BackgroundColor', [0.95 0.95 0.95]);
        
        % 滤波设置区域
        uicontrol('Style', 'text', 'String', '--- 带通滤波设置 ---', ...
                  'Position', [700, 750, 150, 25], 'HorizontalAlignment', 'center', ...
                  'FontWeight', 'bold');
        
        uicontrol('Style', 'text', 'String', '低频截止(kHz):', ...
                  'Position', [700, 730, 100, 20], 'HorizontalAlignment', 'left');
        
        lowFreqEdit = uicontrol('Style', 'edit', 'Position', [800, 730, 80, 20], ...
                               'String', '100');
        
        uicontrol('Style', 'text', 'String', '高频截止(kHz):', ...
                  'Position', [700, 695, 100, 20], 'HorizontalAlignment', 'left');
        
        highFreqEdit = uicontrol('Style', 'edit', 'Position', [800, 700, 80, 20], ...
                                'String', '1000');
        
        uicontrol('Style', 'text', 'String', '滤波器阶数:', ...
                  'Position', [895, 695, 80, 20], 'HorizontalAlignment', 'left');
        
        filterOrderEdit = uicontrol('Style', 'edit', 'Position', [960, 700, 40, 20], ...
                                   'String', '4');
        
        uicontrol('Style', 'pushbutton', 'String', '应用滤波', ...
                  'Position', [900, 730, 90, 30], 'Callback', @applyFilter);
        
        uicontrol('Style', 'pushbutton', 'String', '移除滤波', ...
                  'Position', [990, 730, 90, 30], 'Callback', @removeFilter);
        
        % 滤波状态显示
        filterStatusText = uicontrol('Style', 'text', 'String', '当前状态: 未滤波', ...
                                    'Position', [1020, 690, 120, 25], 'HorizontalAlignment', 'left', ...
                                    'ForegroundColor', 'blue');
        
        % 波包时间范围设置
        uicontrol('Style', 'text', 'String', '波包时间范围:', ...
                  'Position', [50, 650, 100, 25], 'HorizontalAlignment', 'left');
        
        uicontrol('Style', 'text', 'String', '开始(μs):', ...
                  'Position', [150, 650, 60, 20], 'HorizontalAlignment', 'left');
        
        timeStartEdit = uicontrol('Style', 'edit', 'Position', [210, 650, 60, 20], ...
                                 'String', '0', 'Callback', @updateTimeRange);
        
        uicontrol('Style', 'text', 'String', '结束(μs):', ...
                  'Position', [280, 650, 60, 20], 'HorizontalAlignment', 'left');
        
        timeEndEdit = uicontrol('Style', 'edit', 'Position', [340, 650, 60, 20], ...
                               'String', '10', 'Callback', @updateTimeRange);
        
        % 阈值设置
        uicontrol('Style', 'text', 'String', '波包检测阈值:', ...
                  'Position', [420, 650, 100, 25], 'HorizontalAlignment', 'left');
        
        thresholdEdit = uicontrol('Style', 'edit', 'Position', [520, 650, 100, 25], ...
                                 'String', '1e-12');
        
        uicontrol('Style', 'pushbutton', 'String', '计算幅值', ...
                  'Position', [630, 650, 80, 25], 'Callback', @calculateAmplitudes);
        
        % 显示选项
        uicontrol('Style', 'text', 'String', '显示选项:', ...
                  'Position', [750, 650, 80, 25], 'HorizontalAlignment', 'left');
        
        ampTypePopup = uicontrol('Style', 'popupmenu', ...
                                'String', {'峰值', '峰峰值', 'RMS值', '最大绝对值'}, ...
                                'Position', [830, 650, 150, 25], ...
                                'Callback', @updateAmplitudePlot);
        
        % 点分布显示区域
        pointsAxes = axes('Parent', fig, 'Position', [0.1, 0.45, 0.8, 0.15]);
        title('测量点分布 (点击查看时域信号)');
        xlabel('位置 (mm)');
        ylabel('幅值');
        grid on;
        hold on;
        
        % 幅值曲线显示区域
        amplitudeAxes = axes('Parent', fig, 'Position', [0.1, 0.1, 0.8, 0.25]);
        title('幅值曲线');
        xlabel('位置 (mm)');
        ylabel('幅值');
        grid on;
        hold on;
        
        % 存储UI控件句柄
        handles.numPointsEdit = numPointsEdit;
        handles.distanceEdit = distanceEdit;
        handles.dataStatusText = dataStatusText;
        handles.thresholdEdit = thresholdEdit;
        handles.timeStartEdit = timeStartEdit;
        handles.timeEndEdit = timeEndEdit;
        handles.ampTypePopup = ampTypePopup;
        handles.lowFreqEdit = lowFreqEdit;
        handles.highFreqEdit = highFreqEdit;
        handles.filterOrderEdit = filterOrderEdit;
        handles.filterStatusText = filterStatusText;
        handles.pointsAxes = pointsAxes;
        handles.amplitudeAxes = amplitudeAxes;
        
        % 将handles保存到figure的UserData中
        set(fig, 'UserData', handles);
        
        % 如果已经从参数加载了数据，更新界面
        if data_loaded_from_mat
            update_ui_after_loading();
        end
    end

    function load_mat_file(~, ~)
        [filename, pathname] = uigetfile('*.mat', 'Select data.mat file');
        if filename == 0
            return;
        end
        
        try
            full_path = fullfile(pathname, filename);
            loaded_data = load(full_path);
            
            if ~isfield(loaded_data, 'data_xyt') || ~isfield(loaded_data, 'data_time')
                errordlg('Selected file does not contain required data_xyt and data_time variables', 'Error');
                return;
            end
            
            % 转换数据格式
            data_xyt = loaded_data.data_xyt;
            data_time = loaded_data.data_time;
            fs = loaded_data.fs;
            
            % 确定数据点数（假设数据格式为 1 x numPoints x timePoints 或 numPoints x 1 x timePoints）
            [dim1, dim2, dim3] = size(data_xyt);
            if dim1 == 1
                numPoints = dim2;
                point_dim = 2;
            elseif dim2 == 1
                numPoints = dim1;
                point_dim = 1;
            else
                % 如果都不是1，让用户选择
                choice = questdlg('Data format unclear. Which dimension represents measurement points?', ...
                                 'Data Format', 'First (m)', 'Second (n)', 'First (m)');
                if strcmp(choice, 'First (m)')
                    numPoints = dim1;
                    point_dim = 1;
                else
                    numPoints = dim2;
                    point_dim = 2;
                end
            end
            
            % 转换为分析工具需要的格式
            signalData = {};
            originalSignalData = {};
            fileNames = {};
            
            for i = 1:numPoints
                if point_dim == 1
                    signal_data = squeeze(data_xyt(i, 1, :));
                else
                    signal_data = squeeze(data_xyt(1, i, :));
                end
                
                data_struct = struct();
                data_struct.time = data_time(:);
                data_struct.signal = signal_data(:);
                
                signalData{i} = data_struct;
                originalSignalData{i} = data_struct;
                fileNames{i} = sprintf('Point_%d.mat', i);
            end
            
            data_loaded_from_mat = true;
            update_ui_after_loading();
            
            msgbox(sprintf('Successfully loaded %d signal points from MAT file', numPoints), 'Success');
            
        catch ME
            errordlg(['Error loading MAT file: ' ME.message], 'Error');
        end
    end
    
    function load_txt_folder(~, ~)
        folder = uigetdir('', 'Select folder containing numbered TXT files');
        if folder == 0
            return;
        end
        
        % 调用原有的TXT文件加载逻辑
        load_txt_data_from_folder(folder);
    end
    
    function load_txt_data_from_folder(folder)
        handles = get(gcf, 'UserData');
        
        % 更新距离和位置
        distance = str2double(get(handles.distanceEdit, 'String'));
        if isnan(distance)
            distance = 25;
        end
        positions = linspace(0, distance, numPoints);
        
        % 清空之前的数据
        signalData = {};
        originalSignalData = {};
        fileNames = {};
        
        % 检查文件是否存在并加载
        missingFiles = {};
        loadedCount = 0;
        for i = 1:numPoints
            fileName = fullfile(folder, sprintf('%d.txt', i));
            if exist(fileName, 'file')
                try
                    data = loadSignalFile(fileName);
                    signalData{i} = data;
                    originalSignalData{i} = data; % 保存原始数据
                    fileNames{i} = fileName;
                    loadedCount = loadedCount + 1;
                catch ME
                    warning('加载文件 %s 时出错: %s', fileName, ME.message);
                    signalData{i} = [];
                    originalSignalData{i} = [];
                end
            else
                missingFiles{end+1} = sprintf('%d.txt', i);
                signalData{i} = [];
                originalSignalData{i} = [];
            end
        end
        
        data_loaded_from_mat = false;
        update_ui_after_loading();
        
        if ~isempty(missingFiles)
            msgbox(['以下文件未找到: ' strjoin(missingFiles, ', ')], '警告', 'warn');
        end
        
        msgbox(sprintf('成功加载 %d/%d 个文件', loadedCount, numPoints), '信息');
    end
    
    function update_ui_after_loading()
        handles = get(gcf, 'UserData');
        
        % 更新点数显示
        set(handles.numPointsEdit, 'String', num2str(numPoints));
        
        % 更新数据状态
        if data_loaded_from_mat
            status_str = sprintf('已加载MAT数据: %d个信号点', numPoints);
        else
            loaded_count = sum(~cellfun(@isempty, signalData));
            status_str = sprintf('已加载TXT数据: %d/%d个文件', loaded_count, numPoints);
        end
        set(handles.dataStatusText, 'String', status_str);
        
        % 重置滤波状态
        isFiltered = false;
        set(handles.filterStatusText, 'String', '当前状态: 未滤波', 'ForegroundColor', 'blue');
        
        % 更新点分布显示
        updatePointsDisplay();
    end

    function applyFilter(~, ~)
        handles = get(gcf, 'UserData');
        
        % 获取滤波参数
        lowFreq = str2double(get(handles.lowFreqEdit, 'String'))*1000;
        highFreq = str2double(get(handles.highFreqEdit, 'String'))*1000;
        filterOrder = str2double(get(handles.filterOrderEdit, 'String'));
        
        % 验证参数
        if isnan(lowFreq) || isnan(highFreq) || isnan(filterOrder) || ...
           lowFreq <= 0 || highFreq <= lowFreq || filterOrder < 1
            msgbox('请输入有效的滤波参数：低频 < 高频，且所有参数 > 0', '错误', 'error');
            return;
        end
        
        % 检查是否有数据
        if isempty(originalSignalData) || all(cellfun(@isempty, originalSignalData))
            msgbox('请先加载数据', '错误', 'error');
            return;
        end
        
        % 对每个信号进行滤波
        try
            for i = 1:numPoints
                if ~isempty(originalSignalData{i})
                    signalData{i} = applyBandpassFilter(originalSignalData{i}, lowFreq, highFreq, filterOrder);
                end
            end
            
            % 更新滤波状态
            isFiltered = true;
            filterParams.lowFreq = lowFreq;
            filterParams.highFreq = highFreq;
            filterParams.order = filterOrder;
            
            set(handles.filterStatusText, 'String', sprintf('已滤波: %.1f-%.1f Hz', lowFreq, highFreq), ...
                'ForegroundColor', 'red');
            
            msgbox(sprintf('滤波完成\n频段: %.1f - %.1f Hz\n阶数: %d', lowFreq, highFreq, filterOrder), '信息');
            
        catch ME
            msgbox(['滤波失败: ' ME.message], '错误', 'error');
        end
    end

    function removeFilter(~, ~)
        handles = get(gcf, 'UserData');
        
        if isempty(originalSignalData) || all(cellfun(@isempty, originalSignalData))
            msgbox('没有原始数据可以恢复', '警告', 'warn');
            return;
        end
        
        % 恢复原始数据
        signalData = originalSignalData;
        isFiltered = false;
        
        set(handles.filterStatusText, 'String', '当前状态: 未滤波', 'ForegroundColor', 'blue');
        
        msgbox('已移除滤波，恢复原始信号', '信息');
    end

    function calculateAmplitudes(~, ~)
        handles = get(gcf, 'UserData');
        threshold = str2double(get(handles.thresholdEdit, 'String'));
        
        if isnan(threshold)
            msgbox('请输入有效的阈值数值', '错误', 'error');
            return;
        end
        
        amplitudes_peak = zeros(1, numPoints);
        amplitudes_pp = zeros(1, numPoints);
        amplitudes_rms = zeros(1, numPoints);
        amplitudes_max5us = zeros(1, numPoints);
        
        for i = 1:numPoints
            if ~isempty(signalData{i})
                [peak_amp, pp_amp, rms_amp, max_amp] = calculateFirstWavePacket(signalData{i}, threshold);
                amplitudes_peak(i) = peak_amp;
                amplitudes_pp(i) = pp_amp;
                amplitudes_rms(i) = rms_amp;
                amplitudes_max5us(i) = max_amp;
            else
                amplitudes_peak(i) = NaN;
                amplitudes_pp(i) = NaN;
                amplitudes_rms(i) = NaN;
                amplitudes_max5us(i) = NaN;
            end
        end
        
        % 更新显示
        updateAmplitudePlot();
        updatePointsDisplayWithAmplitudes();
        
    end

    function [peak_amp, pp_amp, rms_amp, max_amp] = calculateFirstWavePacket(data, threshold)
        % 在指定时间范围内寻找第一个波包
        time = data.time;
        signal = data.signal;
        
        % 找到指定时间范围内的数据索引
        start_idx = find(time >= wavePacketTimeRange(1), 1, 'first');
        end_idx = find(time <= wavePacketTimeRange(2), 1, 'last');
        
        if isempty(start_idx)
            start_idx = 1;
        end
        if isempty(end_idx)
            end_idx = length(time);
        end
        
        time_range = time(start_idx:end_idx);
        signal_range = signal(start_idx:end_idx);
        
        % 计算指定时间范围内最大绝对值
        max_amp = max(abs(signal_range));
        
        % 寻找超过阈值的点
        above_threshold = abs(signal_range) > threshold;
        
        if ~any(above_threshold)
            % 如果没有超过阈值的点，返回整个时间范围的统计值
            peak_amp = max(abs(signal_range));
            pp_amp = max(signal_range) - min(signal_range);
            rms_amp = rms(signal_range);
            return;
        end
        
        % 找到第一个超过阈值的点
        first_idx = find(above_threshold, 1, 'first');
        
        % 定义波包范围
        wave_start = first_idx;
        
        % 寻找波包结束点
        wave_end = length(signal_range);
        for j = first_idx+1:length(signal_range)
            if abs(signal_range(j)) < threshold
                check_length = min(10, length(signal_range) - j + 1);
                if j+check_length-1 <= length(signal_range) && ...
                   all(abs(signal_range(j:j+check_length-1)) < threshold)
                    wave_end = j - 1;
                    break;
                end
            end
        end
        
        % 提取波包
        wave_packet = signal_range(wave_start:wave_end);
        
        % 计算幅值
        peak_amp = max(abs(wave_packet));
        pp_amp = max(wave_packet) - min(wave_packet);
        rms_amp = rms(wave_packet);
    end

    function updateAmplitudePlot(~, ~)
        handles = get(gcf, 'UserData');
        axes(handles.amplitudeAxes);
        cla;
        
        if isempty(amplitudes_peak) || numPoints == 0
            return;
        end
        
        ampType = get(handles.ampTypePopup, 'Value');
        
        switch ampType
            case 1 % 峰值
                amplitudes = amplitudes_peak;
                ylabel_str = '峰值幅值';
                title_str = '第一波包峰值幅值曲线';
            case 2 % 峰峰值
                amplitudes = amplitudes_pp;
                ylabel_str = '峰峰值幅值';
                title_str = '第一波包峰峰值幅值曲线';
            case 3 % RMS值
                amplitudes = amplitudes_rms;
                ylabel_str = 'RMS幅值';
                title_str = '第一波包RMS幅值曲线';
            case 4 % 最大绝对值
                amplitudes = amplitudes_max5us;
                ylabel_str = '最大绝对值幅值';
                title_str = '最大绝对值幅值曲线';
        end
        
        % 更新位置数组
        distance = str2double(get(handles.distanceEdit, 'String'));
        if isnan(distance)
            distance = 25;
        end
        positions = linspace(0, distance, numPoints);
        
        % 只显示有效数据点
        valid_idx = ~isnan(amplitudes);
        if any(valid_idx)
            plot(positions(valid_idx), amplitudes(valid_idx), 'b-o', 'LineWidth', 2, 'MarkerSize', 8);
        end
        
        if numPoints > 1
            xlim([min(positions), max(positions)]);
        end
        xlabel('位置 (mm)');
        ylabel(ylabel_str);
        title(title_str);
        grid on;
    end

    function updatePointsDisplay()
        if numPoints == 0
            return;
        end
        
        handles = get(gcf, 'UserData');
        axes(handles.pointsAxes);
        cla;
        
        % 更新位置数组
        distance = str2double(get(handles.distanceEdit, 'String'));
        if isnan(distance)
            distance = 25;
        end
        positions = linspace(0, distance, numPoints);
        
        % 显示测量点
        validPoints = ~cellfun(@isempty, signalData);
        if any(validPoints)
            scatter(positions(validPoints), zeros(sum(validPoints), 1), 100, 'b', 'filled');
        end
        if any(~validPoints)
            scatter(positions(~validPoints), zeros(sum(~validPoints), 1), 100, 'r', 'x');
        end
        
        % 设置点击回调
        for i = 1:numPoints
            if validPoints(i)
                h = scatter(positions(i), 0, 100, 'b', 'filled');
                set(h, 'ButtonDownFcn', {@showSignal, i});
            end
        end
        
        xlim([min(positions)-1, max(positions)+1]);
        ylim([-0.5, 0.5]);
        title('测量点分布 (蓝色=已加载, 红色=未加载, 点击蓝点查看信号)');
        xlabel('位置 (mm)');
        ylabel('');
        grid on;
    end

    function updatePointsDisplayWithAmplitudes()
        if isempty(amplitudes_peak) || numPoints == 0
            return;
        end
        
        handles = get(gcf, 'UserData');
        axes(handles.pointsAxes);
        cla;
        
        % 更新位置数组
        distance = str2double(get(handles.distanceEdit, 'String'));
        if isnan(distance)
            distance = 25;
        end
        positions = linspace(0, distance, numPoints);
        
        % 根据当前显示选项决定用哪个幅值进行归一化显示
        ampType = get(handles.ampTypePopup, 'Value');
        switch ampType
            case 1
                display_amplitudes = amplitudes_peak;
            case 2
                display_amplitudes = amplitudes_pp;
            case 3
                display_amplitudes = amplitudes_rms;
            case 4
                display_amplitudes = amplitudes_max5us;
            otherwise
                display_amplitudes = amplitudes_peak;
        end
        
        % 归一化幅值用于显示高度
        valid_idx = ~isnan(display_amplitudes);
        if any(valid_idx)
            norm_amplitudes = display_amplitudes / max(display_amplitudes(valid_idx)) * 0.4;
        else
            norm_amplitudes = zeros(size(display_amplitudes));
        end
        
        % 显示测量点和幅值
        for i = 1:numPoints
            if ~isempty(signalData{i}) && ~isnan(display_amplitudes(i))
                h = scatter(positions(i), norm_amplitudes(i), 100, 'b', 'filled');
                set(h, 'ButtonDownFcn', {@showSignal, i});
                % 添加数值标签
                text(positions(i), norm_amplitudes(i) + 0.05, sprintf('%.2e', display_amplitudes(i)), ...
                     'HorizontalAlignment', 'center', 'FontSize', 8);
            else
                scatter(positions(i), 0, 100, 'r', 'x');
            end
        end
        
        if numPoints > 1
            xlim([min(positions)-1, max(positions)+1]);
        end
        ylim([-0.1, 0.6]);
        title('测量点分布和幅值 (点击查看时域信号)');
        xlabel('位置 (mm)');
        ylabel('归一化幅值');
        grid on;
    end

    function showSignal(~, ~, pointIndex)
        if isempty(signalData{pointIndex})
            msgbox('该点数据未加载', '警告', 'warn');
            return;
        end
        
        % 更新位置数组
        handles = get(gcf, 'UserData');
        distance = str2double(get(handles.distanceEdit, 'String'));
        if isnan(distance)
            distance = 25;
        end
        positions = linspace(0, distance, numPoints);
        
        % 创建新窗口显示时域信号
        figSignal = figure('Name', sprintf('测量点 %d 的时域信号 (位置: %.2f mm)', pointIndex, positions(pointIndex)), ...
                          'NumberTitle', 'off', 'Position', [200, 200, 1000, 700]);
        
        data = signalData{pointIndex};
        
        % 如果有滤波，同时显示原始信号和滤波信号
        if isFiltered && ~isempty(originalSignalData{pointIndex})
            % 原始信号
            subplot(3, 1, 1);
            plot(originalSignalData{pointIndex}.time * 1e6, originalSignalData{pointIndex}.signal, 'b-', 'LineWidth', 1);
            xlabel('时间 (μs)');
            ylabel('振幅 (m)');
            title(sprintf('原始时域信号 - 测量点 %d', pointIndex));
            grid on;
            
            % 滤波后信号
            subplot(3, 1, 2);
            plot(data.time * 1e6, data.signal, 'r-', 'LineWidth', 1);
            xlabel('时间 (μs)');
            ylabel('振幅 (m)');
            title(sprintf('滤波后信号 (%.1f-%.1f Hz) - 测量点 %d', ...
                  filterParams.lowFreq, filterParams.highFreq, pointIndex));
            grid on;
            
            % 波包检测范围放大图（滤波后）
            subplot(3, 1, 3);
            ax_wavepacket = gca;
        else
            % 全信号图
            subplot(2, 1, 1);
            plot(data.time * 1e6, data.signal, 'b-', 'LineWidth', 1);
            xlabel('时间 (μs)');
            ylabel('振幅 (m)');
            if isFiltered
                title(sprintf('滤波后时域信号 (%.1f-%.1f Hz) - 测量点 %d', ...
                      filterParams.lowFreq, filterParams.highFreq, pointIndex));
            else
                title(sprintf('完整时域信号 - 测量点 %d', pointIndex));
            end
            grid on;
            
            % 波包检测范围放大图
            subplot(2, 1, 2);
            ax_wavepacket = gca;
        end
        
        % 显示波包检测范围内的信号
        start_idx = find(data.time >= wavePacketTimeRange(1), 1, 'first');
        end_idx = find(data.time <= wavePacketTimeRange(2), 1, 'last');
        
        if isempty(start_idx)
            start_idx = 1;
        end
        if isempty(end_idx)
            end_idx = length(data.time);
        end
        
        time_range_us = data.time(start_idx:end_idx) * 1e6;
        signal_range = data.signal(start_idx:end_idx);
        
        plot(time_range_us, signal_range, 'g-', 'LineWidth', 1.5);
        xlabel('时间 (μs)');
        ylabel('振幅 (m)');
        title(sprintf('波包检测范围 (%.1f-%.1f μs)', wavePacketTimeRange(1)*1e6, wavePacketTimeRange(2)*1e6));
        grid on;
        
        % 添加拖拽选择功能
        set(ax_wavepacket, 'ButtonDownFcn', {@startDrag, pointIndex, figSignal});
        
        % 如果已计算幅值，显示检测到的波包信息
        if ~isempty(amplitudes_peak) && ~isnan(amplitudes_peak(pointIndex))
            handles = get(gcf, 'UserData');
            threshold = str2double(get(handles.thresholdEdit, 'String'));
            
            % 添加阈值线
            hold on;
            ylim_current = ylim;
            time_range_display = wavePacketTimeRange * 1e6;
            plot(time_range_display, [threshold, threshold], 'k--', 'LineWidth', 1);
            plot(time_range_display, [-threshold, -threshold], 'k--', 'LineWidth', 1);
            
            % 显示幅值信息
            info_text = sprintf('峰值: %.2e\n峰峰值: %.2e\nRMS: %.2e\n最大绝对值: %.2e', ...
                 amplitudes_peak(pointIndex), amplitudes_pp(pointIndex), ...
                 amplitudes_rms(pointIndex), amplitudes_max5us(pointIndex));
            text(time_range_display(1) + 0.5, ylim_current(2)*0.8, info_text, ...
                 'FontSize', 10, 'BackgroundColor', 'white');
        end
    end

    function startDrag(src, ~, pointIndex, figSignal)
        % ...existing code...
    end

    function duringDrag(~, ~, ax, h_line1, h_line2, start_time_us)
        % ...existing code...
    end

    function endDrag(~, ~, ax, h_line1, h_line2, start_time_us, pointIndex, figSignal)
        % ...existing code...
    end

    function filteredData = applyBandpassFilter(data, lowFreq, highFreq, filterOrder)
        % 计算采样频率
        dt = mean(diff(data.time));
        fs = 1 / dt;
        
        % 归一化频率
        nyquist = fs / 2;
        lowNorm = lowFreq / nyquist;
        highNorm = highFreq / nyquist;
        
        % 检查频率范围
        if highNorm >= 1
            warning('高频截止频率过高，调整为0.95倍奈奎斯特频率');
            highNorm = 0.95;
        end
        if lowNorm <= 0
            warning('低频截止频率过低，调整为0.01倍奈奎斯特频率');
            lowNorm = 0.01;
        end
        
        % 设计带通滤波器
        [b, a] = butter(filterOrder, [lowNorm, highNorm], 'bandpass');
        
        % 应用滤波器
        filteredSignal = filtfilt(b, a, data.signal);
        
        % 创建滤波后的数据结构
        filteredData.time = data.time;
        filteredData.signal = filteredSignal;
    end

    function data = loadSignalFile(fileName)
        % 读取信号文件
        fid = fopen(fileName, 'r');
        if fid == -1
            error('无法打开文件: %s', fileName);
        end
        
        try
            % 跳过前5行标题
            for i = 1:5
                fgetl(fid);
            end
            
            % 读取数据
            dataArray = textscan(fid, '%f %f', 'Delimiter', '\t');
            fclose(fid);
            
            data.time = dataArray{1};
            data.signal = dataArray{2};
        catch ME
            fclose(fid);
            rethrow(ME);
        end
    end
end