function ReadA()
    % ReadA主界面 - 单点信号分析工具 (重构版)
    % 基于新架构：txt_loader + SignalData + signal_plotter + filter_engine
    %
    % 版本: 2.0 (重构版)
    % 作者: 重构团队
    % 日期: 2024
    
    % === 路径检查和初始化 ===
    if ~exist('signal_plotter', 'class') || ~exist('fft_analyzer', 'class')
        % 尝试自动初始化路径
        try
            % 查找项目根目录
            current_dir = fileparts(mfilename('fullpath'));
            project_root = fileparts(fileparts(current_dir)); % 上两级目录
            
            % 切换到项目根目录并运行初始化
            old_dir = cd(project_root);
            init_project();
            cd(old_dir);
            
            % 再次检查
            if ~exist('signal_plotter', 'class')
                error('路径初始化失败,请手动运行 init_project');
            end
        catch ME
            errordlg(['无法初始化项目路径!' newline newline ...
                     '请先运行以下命令:' newline ...
                     'cd(''c:\Users\123\Documents\Projects\Signal_Processing_Tool'')' newline ...
                     'init_project' newline newline ...
                     '然后再运行 ReadA'], '路径初始化失败');
            error('ReadA:PathNotInitialized', ME.message);
        end
    end
    
    % 创建主界面
    main_fig = figure('Name', 'Signal Processing Tool - Module A', ...
                      'Position', [100, 50, 1400, 850], ...
                      'MenuBar', 'none', 'ToolBar', 'none', ...
                      'Resize', 'on', 'NumberTitle', 'off', ...
                      'CloseRequestFcn', @cleanup_and_close);
    
    % 应用数据
    app = struct();
    app.signal_data = [];           % SignalData对象
    app.original_signal_data = [];  % 原始SignalData（滤波前）
    app.current_file = '';
    app.is_filtered = false;
    app.filter_params = struct('type', 'none', 'low_freq', 100e3, 'high_freq', 500e3, 'order', 4);
    
    % 创建UI
    create_ui();
    
    %% UI创建函数
    function create_ui()
        % 顶部标题栏
        title_panel = uipanel('Parent', main_fig, 'Position', [0.01, 0.94, 0.98, 0.05], ...
                             'BorderType', 'none');
        uicontrol('Parent', title_panel, 'Style', 'text', ...
                  'String', 'Signal Processing Tool - Single Point Analysis', ...
                  'Position', [400, 5, 600, 30], 'FontSize', 16, 'FontWeight', 'bold');
        
        % 左侧控制面板
        control_panel = uipanel('Parent', main_fig, 'Position', [0.01, 0.01, 0.22, 0.92], ...
                               'Title', 'Control Panel', 'FontSize', 12, 'FontWeight', 'bold');
        
        create_control_panel(control_panel);
        
        % 右侧显示区域
        display_panel = uipanel('Parent', main_fig, 'Position', [0.24, 0.01, 0.75, 0.92], ...
                               'Title', 'Signal Visualization', 'FontSize', 12, 'FontWeight', 'bold');
        
        create_display_panel(display_panel);
    end
    
    function create_control_panel(parent)
        y_pos = 720;
        
        % === 文件加载区域 ===
        uicontrol('Parent', parent, 'Style', 'text', 'String', '1. Load Signal Data', ...
                  'Position', [10, y_pos, 250, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        y_pos = y_pos - 30;
        
        uicontrol('Parent', parent, 'Style', 'pushbutton', 'String', 'Browse TXT File', ...
                  'Position', [20, y_pos, 250, 35], 'FontSize', 10, ...
                  'BackgroundColor', [0.8 0.9 1.0], 'Callback', @load_txt_file);
        y_pos = y_pos - 40;
        
        app.file_text = uicontrol('Parent', parent, 'Style', 'text', ...
                                  'String', 'No file loaded', ...
                                  'Position', [10, y_pos, 280, 40], ...
                                  'HorizontalAlignment', 'left', ...
                                  'BackgroundColor', [0.95 0.95 0.95], ...
                                  'FontSize', 9);
        y_pos = y_pos - 50;
        
        % === 滤波控制区域 ===
        uicontrol('Parent', parent, 'Style', 'text', 'String', '2. Filter Settings', ...
                  'Position', [10, y_pos, 250, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        y_pos = y_pos - 30;
        
        % 修复：获取滤波器名称并设置默认值为1（No Filter）
        filter_names = filter_engine.get_filter_names();
        app.filter_popup = uicontrol('Parent', parent, 'Style', 'popupmenu', ...
                                     'String', filter_names, ...
                                     'Value', 1, ... % 修复：显式设置初始值为1
                                     'Position', [20, y_pos, 150, 25], ...
                                     'Callback', @update_filter_ui);
        y_pos = y_pos - 35;
        
        uicontrol('Parent', parent, 'Style', 'text', 'String', 'Low Freq (kHz):', ...
                  'Position', [20, y_pos, 100, 20], 'HorizontalAlignment', 'left');
        app.low_freq_edit = uicontrol('Parent', parent, 'Style', 'edit', 'String', '100', ...
                                      'Position', [130, y_pos, 80, 25], 'Enable', 'off');
        y_pos = y_pos - 30;
        
        uicontrol('Parent', parent, 'Style', 'text', 'String', 'High Freq (kHz):', ...
                  'Position', [20, y_pos, 100, 20], 'HorizontalAlignment', 'left');
        app.high_freq_edit = uicontrol('Parent', parent, 'Style', 'edit', 'String', '500', ...
                                       'Position', [130, y_pos, 80, 25], 'Enable', 'off');
        y_pos = y_pos - 35;
        
        uicontrol('Parent', parent, 'Style', 'pushbutton', 'String', 'Apply Filter', ...
                  'Position', [20, y_pos, 120, 30], 'FontSize', 10, ...
                  'BackgroundColor', [0.9 1.0 0.8], 'Callback', @apply_filter);
        
        uicontrol('Parent', parent, 'Style', 'pushbutton', 'String', 'Remove Filter', ...
                  'Position', [150, y_pos, 120, 30], 'FontSize', 10, ...
                  'BackgroundColor', [1.0 0.9 0.8], 'Callback', @remove_filter);
        y_pos = y_pos - 40;
        
        app.filter_status = uicontrol('Parent', parent, 'Style', 'text', ...
                                      'String', 'Status: No Filter', ...
                                      'Position', [20, y_pos, 250, 20], ...
                                      'HorizontalAlignment', 'left', ...
                                      'ForegroundColor', 'blue');
        y_pos = y_pos - 50;
        
        % === 分析功能区域 ===
        uicontrol('Parent', parent, 'Style', 'text', 'String', '3. Analysis Functions', ...
                  'Position', [10, y_pos, 250, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        y_pos = y_pos - 35;
        
        uicontrol('Parent', parent, 'Style', 'pushbutton', 'String', 'Time-Frequency Analysis', ...
                  'Position', [20, y_pos, 250, 35], 'FontSize', 10, ...
                  'BackgroundColor', [1.0 0.9 0.9], 'Callback', @show_timefreq);
        y_pos = y_pos - 40;
        
        uicontrol('Parent', parent, 'Style', 'pushbutton', 'String', 'Multi-Signal Comparison', ...
                  'Position', [20, y_pos, 250, 35], 'FontSize', 10, ...
                  'BackgroundColor', [0.9 0.9 1.0], 'Callback', @show_comparison);
        y_pos = y_pos - 50;
        
        % === 信息显示区域 ===
        uicontrol('Parent', parent, 'Style', 'text', 'String', 'Signal Information', ...
                  'Position', [10, y_pos, 250, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        y_pos = y_pos - 10;
        
        app.info_text = uicontrol('Parent', parent, 'Style', 'text', ...
                                  'String', 'Load a file to view information', ...
                                  'Position', [10, y_pos-150, 280, 150], ...
                                  'HorizontalAlignment', 'left', ...
                                  'BackgroundColor', [0.95 0.95 0.95], ...
                                  'FontSize', 9);
    end
    
    function create_display_panel(parent)
        % 时域信号显示
        time_panel = uipanel('Parent', parent, 'Position', [0.02, 0.67, 0.96, 0.31], ...
                            'Title', 'Time Domain Signal');
        app.time_axes = axes('Parent', time_panel, 'Position', [0.08, 0.18, 0.88, 0.75]);
        
        % 频域信号显示
        freq_panel = uipanel('Parent', parent, 'Position', [0.02, 0.34, 0.96, 0.31], ...
                            'Title', 'Frequency Spectrum');
        app.freq_axes = axes('Parent', freq_panel, 'Position', [0.08, 0.18, 0.88, 0.75]);
        
        % 点击信息显示
        info_panel = uipanel('Parent', parent, 'Position', [0.02, 0.02, 0.96, 0.30], ...
                            'Title', 'Click Information & Peak Detection');
        app.click_info = uicontrol('Parent', info_panel, 'Style', 'text', ...
                                   'String', 'Click on plots to see detailed information', ...
                                   'Position', [10, 10, 1000, 210], ...
                                   'HorizontalAlignment', 'left', ...
                                   'BackgroundColor', [0.95 0.95 0.95], ...
                                   'FontSize', 10);
    end
    
    %% 回调函数
    function load_txt_file(~, ~)
        [filename, pathname] = uigetfile('*.txt', 'Select TXT signal file');
        if filename == 0
            return;
        end
        
        file_path = fullfile(pathname, filename);
        
        try
            % 使用txt_loader加载文件
            fprintf('正在加载文件: %s\n', file_path);
            app.signal_data = txt_loader.load_single(file_path);
            app.original_signal_data = app.signal_data;
            app.current_file = file_path;
            app.is_filtered = false;
            
            % 验证采样率
            if app.signal_data.fs == 0 || isnan(app.signal_data.fs)
                % 尝试重新计算
                time_vec = app.signal_data.time;
                if length(time_vec) > 1
                    dt = median(diff(time_vec));
                    if dt > 0
                        app.signal_data.fs = 1 / dt;
                        app.original_signal_data.fs = 1 / dt;
                        fprintf('重新计算采样率: %.2f MHz\n', app.signal_data.fs/1e6);
                    else
                        app.signal_data.fs = 1e6;
                        app.original_signal_data.fs = 1e6;
                        warning('采样率计算失败,使用默认值 1MHz');
                    end
                else
                    app.signal_data.fs = 1e6;
                    app.original_signal_data.fs = 1e6;
                end
            end
            
            % 更新文件显示
            set(app.file_text, 'String', sprintf('File: %s\nLoaded successfully', filename));
            
            % 更新信号信息
            update_signal_info();
            
            % 绘制信号
            plot_signals();
            
            % 重置滤波状态
            set(app.filter_status, 'String', 'Status: No Filter', 'ForegroundColor', 'blue');
            set(app.filter_popup, 'Value', 1);
            
            fprintf('文件加载成功,采样率: %.2f MHz\n', app.signal_data.fs/1e6);
            
        catch ME
            errordlg(['Error loading file: ' ME.message], 'Load Error');
            fprintf('加载文件错误: %s\n', ME.getReport());
        end
    end
    
    function apply_filter(~, ~)
        if isempty(app.signal_data)
            msgbox('Please load a signal file first!', 'Warning', 'warn');
            return;
        end
        
        try
            filter_types = filter_engine.get_filter_types();
            popup_value = get(app.filter_popup, 'Value');
            
            if popup_value < 1 || popup_value > length(filter_types)
                popup_value = 1;
                set(app.filter_popup, 'Value', 1);
            end
            
            selected_type = filter_types{popup_value};
            
        catch ME
            errordlg(['Filter type selection error: ' ME.message], 'Error');
            fprintf('滤波器类型选择错误: %s\n', ME.getReport());
            return;
        end
        
        if strcmp(selected_type, 'none')
            msgbox('Please select a filter type!', 'Warning', 'warn');
            return;
        end
        
        low_freq = str2double(get(app.low_freq_edit, 'String')) * 1000;
        high_freq = str2double(get(app.high_freq_edit, 'String')) * 1000;
        
        params = struct('fs', app.original_signal_data.fs, ...
                       'low_freq', low_freq, 'high_freq', high_freq, 'order', 4);
        validation = filter_engine.validate_params(params);
        
        if ~validation.valid
            msgbox(validation.message, 'Invalid Parameters', 'error');
            return;
        end
        
        try
            % 应用滤波
            signal = app.original_signal_data.get_point(1, 1);
            filtered_signal = filter_engine.apply(signal, selected_type, params);
            
            % 创建新的SignalData对象
            app.signal_data = SignalData(filtered_signal, ...
                                        app.original_signal_data.time, ...
                                        app.original_signal_data.fs, ...
                                        'single_point');
            app.signal_data.metadata = app.original_signal_data.metadata;
            
            % 更新状态
            app.is_filtered = true;
            app.filter_params.type = selected_type;
            app.filter_params.low_freq = low_freq;
            app.filter_params.high_freq = high_freq;
            
            % 更新显示
            filter_info = filter_engine.format_filter_info(selected_type, params);
            set(app.filter_status, 'String', ['Status: ' strrep(filter_info, sprintf('\n'), ', ')], ...
                'ForegroundColor', 'red');
            
            plot_signals();
            update_signal_info();
            
            msgbox('Filter applied successfully!', 'Success');
            
        catch ME
            msgbox(['Filter application failed: ' ME.message], 'Error', 'error');
        end
    end
    
    function remove_filter(~, ~)
        if isempty(app.original_signal_data)
            msgbox('No original signal data available!', 'Warning', 'warn');
            return;
        end
        
        app.signal_data = app.original_signal_data;
        app.is_filtered = false;
        
        set(app.filter_status, 'String', 'Status: No Filter', 'ForegroundColor', 'blue');
        set(app.filter_popup, 'Value', 1);
        
        plot_signals();
        update_signal_info();
        
        msgbox('Filter removed. Original signal restored.', 'Info');
    end
    
    function update_filter_ui(~, ~)
        try
            popup_value = get(app.filter_popup, 'Value');
            
            if isempty(popup_value) || popup_value < 1
                popup_value = 1;
                set(app.filter_popup, 'Value', 1);
            end
            
            if popup_value == 1  % No Filter
                set(app.low_freq_edit, 'Enable', 'off');
                set(app.high_freq_edit, 'Enable', 'off');
            else
                set(app.low_freq_edit, 'Enable', 'on');
                set(app.high_freq_edit, 'Enable', 'on');
            end
            
        catch ME
            fprintf('更新滤波UI错误: %s\n', ME.message);
        end
    end
    
    function show_timefreq(~, ~)
        if isempty(app.signal_data)
            msgbox('Please load a signal file first!', 'Warning', 'warn');
            return;
        end
        
        % 创建时频分析窗口
        tf_fig = figure('Name', 'Time-Frequency Analysis', ...
                       'Position', [200, 100, 900, 650], ...
                       'MenuBar', 'none', 'ToolBar', 'none');
        
        % 时频图
        tf_axes = axes('Parent', tf_fig, 'Position', [0.1, 0.15, 0.75, 0.75]);
        signal_plotter.plot_timefreq(tf_axes, app.signal_data, ...
            'colormap_name', 'jet', 'smooth_sigma', 1.0, 'db_scale', true);
        
        % 信息面板
        info_panel = uipanel('Parent', tf_fig, 'Position', [0.87, 0.15, 0.12, 0.75], ...
                            'Title', 'Info');
        
        % 峰值信息
        [signal, fs] = extract_signal_and_fs();
        [S, F, T] = timefreq_analyzer.compute_stft(signal, fs);
        peak_info = timefreq_analyzer.find_timefreq_peaks(abs(S), F, T);
        
        peak_str = timefreq_analyzer.format_peak_info(peak_info, 'detailed');
        
        uicontrol('Parent', info_panel, 'Style', 'text', ...
                  'String', peak_str, ...
                  'Position', [5, 300, 100, 200], ...
                  'HorizontalAlignment', 'left', ...
                  'FontSize', 9);
        
        % 点击信息
        click_text = uicontrol('Parent', info_panel, 'Style', 'text', ...
                              'String', 'Click on spectrogram', ...
                              'Position', [5, 50, 100, 150], ...
                              'HorizontalAlignment', 'left', ...
                              'FontSize', 9, ...
                              'BackgroundColor', [0.95 0.95 0.95]);
        
        % 设置点击回调
        callback_data = struct('info_text', click_text, 'freq_vector', F, 'time_vector', T);
        signal_plotter.setup_click_callback(tf_axes, 'timefreq', callback_data);
    end
    
    function show_comparison(~, ~)
        % 打开多信号对比窗口
        comparison_window();
    end
    
    function plot_signals()
        if isempty(app.signal_data)
            return;
        end
        
        try
            % 时域信号
            signal_plotter.plot_time_domain(app.time_axes, app.signal_data, ...
                'color', 'b', 'linewidth', 1.5);
            
            % 设置时域点击回调
            callback_data = struct('info_text', app.click_info);
            signal_plotter.setup_click_callback(app.time_axes, 'time', callback_data);
            
            % 频域信号
            signal_plotter.plot_frequency_domain(app.freq_axes, app.signal_data, ...
                'color', 'r', 'show_peaks', true);
            
            % 设置频域点击回调
            signal_plotter.setup_click_callback(app.freq_axes, 'freq', callback_data);
            
            % 更新峰值信息
            update_peak_info();
            
        catch ME
            errordlg(['Plot error: ' ME.message], 'Plotting Error');
            fprintf('绘图错误: %s\n', ME.getReport());
        end
    end
    
    function update_signal_info()
        if isempty(app.signal_data)
            return;
        end
        
        try
            info_str = app.signal_data.get_summary();
            
            if app.is_filtered
                info_str = [info_str, sprintf('\n\nFilter Applied:\n%s', ...
                    filter_engine.format_filter_info(app.filter_params.type, app.filter_params))];
            end
            
            set(app.info_text, 'String', info_str);
            
        catch ME
            fprintf('更新信息错误: %s\n', ME.message);
        end
    end
    
    function update_peak_info()
        try
            [signal, fs] = extract_signal_and_fs();
            [freq, mag] = fft_analyzer.compute(signal, fs);
            
            peaks = fft_analyzer.find_peaks(freq, mag, struct('num_peaks', 2));
            peak_str = fft_analyzer.format_peak_info(peaks, 'detailed');
            
            current_info = get(app.info_text, 'String');
            set(app.info_text, 'String', [current_info, sprintf('\n\n%s', peak_str)]);
            
        catch ME
            fprintf('更新峰值信息错误: %s\n', ME.message);
        end
    end
    
    function [signal, fs] = extract_signal_and_fs()
        try
            signal = app.signal_data.get_point(1, 1);
            fs = app.signal_data.fs;
        catch ME
            error('提取信号数据失败: %s', ME.message);
        end
    end
    
    %% 多信号对比窗口
    function comparison_window()
        % 创建对比分析窗口
        comp_fig = figure('Name', 'Multi-Signal Comparison', ...
                         'Position', [150, 50, 1400, 800], ...
                         'MenuBar', 'none', 'ToolBar', 'none');
        
        % 对比数据
        comp_data = struct();
        comp_data.signal_array = {};
        comp_data.original_signal_array = {};  % 添加：保存原始信号
        comp_data.file_names = {};
        comp_data.is_filtered = false;  % 添加：滤波状态
        
        % 控制面板
        ctrl_panel = uipanel('Parent', comp_fig, 'Position', [0.01, 0.01, 0.20, 0.98], ...
                            'Title', 'Control');
        
        y = 720;
        
        % === 文件管理区域 ===
        uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', '1. File Management', ...
                  'Position', [10, y, 200, 20], 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        y = y - 25;
        
        uicontrol('Parent', ctrl_panel, 'Style', 'pushbutton', 'String', 'Load TXT Files', ...
                  'Position', [10, y, 120, 30], 'BackgroundColor', [0.8 0.9 1.0], ...
                  'Callback', @load_comparison_files);
        
        uicontrol('Parent', ctrl_panel, 'Style', 'pushbutton', 'String', 'Remove Selected', ...
                  'Position', [140, y, 120, 30], 'BackgroundColor', [1.0 0.8 0.8], ...
                  'Callback', @remove_selected_files);
        y = y - 35;
        
        % 文件列表
        file_listbox = uicontrol('Parent', ctrl_panel, 'Style', 'listbox', ...
                                'Position', [10, y-120, 260, 120], 'Max', 2, 'Min', 0);
        y = y - 130;
        
        % === 滤波控制区域 ===
        uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', '2. Filter Settings', ...
                  'Position', [10, y, 200, 20], 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        y = y - 25;
        
        filter_names = filter_engine.get_filter_names();
        filter_popup = uicontrol('Parent', ctrl_panel, 'Style', 'popupmenu', ...
                                'String', filter_names, ...
                                'Value', 1, ...
                                'Position', [10, y, 140, 25], ...
                                'Callback', @update_filter_ui_comp);
        y = y - 30;
        
        uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', 'Low Freq (kHz):', ...
                  'Position', [10, y, 100, 20], 'HorizontalAlignment', 'left');
        low_freq_edit = uicontrol('Parent', ctrl_panel, 'Style', 'edit', 'String', '100', ...
                                  'Position', [120, y, 80, 25], 'Enable', 'off');
        y = y - 30;
        
        uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', 'High Freq (kHz):', ...
                  'Position', [10, y, 100, 20], 'HorizontalAlignment', 'left');
        high_freq_edit = uicontrol('Parent', ctrl_panel, 'Style', 'edit', 'String', '400', ...
                                   'Position', [120, y, 80, 25], 'Enable', 'off');
        y = y - 35;
        
        uicontrol('Parent', ctrl_panel, 'Style', 'pushbutton', 'String', 'Apply Filter', ...
                  'Position', [10, y, 120, 30], 'FontSize', 10, ...
                  'BackgroundColor', [0.9 1.0 0.8], 'Callback', @apply_comparison_filter);
        
        uicontrol('Parent', ctrl_panel, 'Style', 'pushbutton', 'String', 'Remove Filter', ...
                  'Position', [140, y, 120, 30], 'FontSize', 10, ...
                  'BackgroundColor', [1.0 0.9 0.8], 'Callback', @remove_comparison_filter);
        y = y - 35;
        
        filter_status = uicontrol('Parent', ctrl_panel, 'Style', 'text', ...
                                 'String', 'Status: No Filter', ...
                                 'Position', [10, y, 250, 20], ...
                                 'HorizontalAlignment', 'left', ...
                                 'ForegroundColor', 'blue');
        y = y - 30;
        
        % === 更新按钮 ===
        uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', '3. Update Display', ...
                  'Position', [10, y, 200, 20], 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        y = y - 30;
        
        uicontrol('Parent', ctrl_panel, 'Style', 'pushbutton', 'String', 'Update Plot', ...
                  'Position', [10, y, 120, 30], 'BackgroundColor', [0.9 0.9 1.0], ...
                  'Callback', @update_comparison_plot);
        y = y - 40;
        
        % === 信息显示 ===
        info_text = uicontrol('Parent', ctrl_panel, 'Style', 'text', ...
                             'String', 'Load files to start comparison', ...
                             'Position', [10, 50, 260, y-50], ...
                             'HorizontalAlignment', 'left', ...
                             'BackgroundColor', [0.95 0.95 0.95], ...
                             'FontSize', 9);
        
        % 显示面板
        disp_panel = uipanel('Parent', comp_fig, 'Position', [0.22, 0.01, 0.77, 0.98], ...
                            'Title', 'Comparison View');
        
        % 时域对比
        time_comp_axes = axes('Parent', disp_panel, 'Position', [0.08, 0.55, 0.88, 0.40]);
        title('Time Domain Comparison');
        
        % 频域对比
        freq_comp_axes = axes('Parent', disp_panel, 'Position', [0.08, 0.08, 0.88, 0.40]);
        title('Frequency Spectrum Comparison');
        
        function load_comparison_files(~, ~)
            [filenames, pathname] = uigetfile('*.txt', 'Select TXT files', 'MultiSelect', 'on');
            if isequal(filenames, 0)
                return;
            end
            
            if ischar(filenames)
                filenames = {filenames};
            end
            
            % 加载所有文件
            h_wait = waitbar(0, 'Loading files...');
            
            for i = 1:length(filenames)
                try
                    file_path = fullfile(pathname, filenames{i});
                    signal_data = txt_loader.load_single(file_path);
                    
                    % 验证采样率
                    if signal_data.fs == 0 || isnan(signal_data.fs)
                        time_vec = signal_data.time;
                        if length(time_vec) > 1
                            dt = median(diff(time_vec));
                            if dt > 0
                                signal_data.fs = 1 / dt;
                            else
                                signal_data.fs = 1e6;
                            end
                        end
                    end
                    
                    comp_data.signal_array{end+1} = signal_data;
                    comp_data.original_signal_array{end+1} = signal_data;  % 保存原始数据
                    comp_data.file_names{end+1} = filenames{i};
                    
                    waitbar(i/length(filenames), h_wait);
                catch ME
                    warning('Failed to load %s: %s', filenames{i}, ME.message);
                end
            end
            
            close(h_wait);
            
            % 更新列表
            set(file_listbox, 'String', comp_data.file_names);
            
            % 重置滤波状态
            comp_data.is_filtered = false;
            set(filter_status, 'String', 'Status: No Filter', 'ForegroundColor', 'blue');
            set(filter_popup, 'Value', 1);
            
            % 更新信息显示
            update_info_display();
            
            % 自动绘图
            update_comparison_plot();
            
            msgbox(sprintf('Successfully loaded %d files', length(comp_data.signal_array)), 'Success');
        end
        
        function remove_selected_files(~, ~)
            selected_idx = get(file_listbox, 'Value');
            
            if isempty(selected_idx) || isempty(comp_data.signal_array)
                msgbox('Please select files to remove', 'Info', 'warn');
                return;
            end
            
            % 确认删除
            if length(selected_idx) == 1
                msg = sprintf('Remove file: %s?', comp_data.file_names{selected_idx});
            else
                msg = sprintf('Remove %d selected files?', length(selected_idx));
            end
            
            choice = questdlg(msg, 'Confirm Removal', 'Yes', 'No', 'No');
            if ~strcmp(choice, 'Yes')
                return;
            end
            
            % 删除选中的文件
            keep_idx = setdiff(1:length(comp_data.signal_array), selected_idx);
            
            comp_data.signal_array = comp_data.signal_array(keep_idx);
            comp_data.original_signal_array = comp_data.original_signal_array(keep_idx);
            comp_data.file_names = comp_data.file_names(keep_idx);
            
            % 更新列表
            set(file_listbox, 'String', comp_data.file_names, 'Value', 1);
            
            % 重置滤波状态
            comp_data.is_filtered = false;
            set(filter_status, 'String', 'Status: No Filter', 'ForegroundColor', 'blue');
            set(filter_popup, 'Value', 1);
            
            % 更新显示
            update_info_display();
            update_comparison_plot();
            
            msgbox(sprintf('Removed %d file(s). %d files remaining.', ...
                   length(selected_idx), length(comp_data.signal_array)), 'Info');
        end
        
        function apply_comparison_filter(~, ~)
            if isempty(comp_data.original_signal_array)
                msgbox('Please load files first!', 'Warning', 'warn');
                return;
            end
            
            try
                filter_types = filter_engine.get_filter_types();
                popup_value = get(filter_popup, 'Value');
                selected_type = filter_types{popup_value};
                
                if strcmp(selected_type, 'none')
                    msgbox('Please select a filter type!', 'Warning', 'warn');
                    return;
                end
                
                low_freq = str2double(get(low_freq_edit, 'String')) * 1000;
                high_freq = str2double(get(high_freq_edit, 'String')) * 1000;
                
                % 对每个信号应用滤波
                h_wait = waitbar(0, 'Applying filter...');
                
                for i = 1:length(comp_data.original_signal_array)
                    signal = comp_data.original_signal_array{i}.get_point(1, 1);
                    fs = comp_data.original_signal_array{i}.fs;
                    
                    params = struct('fs', fs, ...
                                   'low_freq', low_freq, ...
                                   'high_freq', high_freq, ...
                                   'order', 4);
                    
                    filtered_signal = filter_engine.apply(signal, selected_type, params);
                    
                    % 创建新的SignalData对象
                    comp_data.signal_array{i} = SignalData(filtered_signal, ...
                                                           comp_data.original_signal_array{i}.time, ...
                                                           fs, 'single_point');
                    
                    waitbar(i/length(comp_data.original_signal_array), h_wait);
                end
                
                close(h_wait);
                
                % 更新滤波状态
                comp_data.is_filtered = true;
                filter_info = filter_engine.format_filter_info(selected_type, params);
                set(filter_status, 'String', ['Status: ' strrep(filter_info, sprintf('\n'), ', ')], ...
                    'ForegroundColor', 'red');
                
                % 更新绘图
                update_comparison_plot();
                
                msgbox('Filter applied to all signals!', 'Success');
                
            catch ME
                msgbox(['Filter application failed: ' ME.message], 'Error', 'error');
            end
        end
        
        function remove_comparison_filter(~, ~)
            if isempty(comp_data.original_signal_array)
                msgbox('No original signal data available!', 'Warning', 'warn');
                return;
            end
            
            % 恢复原始信号
            comp_data.signal_array = comp_data.original_signal_array;
            comp_data.is_filtered = false;
            
            set(filter_status, 'String', 'Status: No Filter', 'ForegroundColor', 'blue');
            set(filter_popup, 'Value', 1);
            
            % 更新绘图
            update_comparison_plot();
            
            msgbox('Filter removed. Original signals restored.', 'Info');
        end
        
        function update_filter_ui_comp(~, ~)
            try
                popup_value = get(filter_popup, 'Value');
                
                if popup_value == 1  % No Filter
                    set(low_freq_edit, 'Enable', 'off');
                    set(high_freq_edit, 'Enable', 'off');
                else
                    set(low_freq_edit, 'Enable', 'on');
                    set(high_freq_edit, 'Enable', 'on');
                end
            catch ME
                fprintf('更新滤波UI错误: %s\n', ME.message);
            end
        end
        
        function update_comparison_plot(~, ~)
            if isempty(comp_data.signal_array)
                msgbox('Please load files first!', 'Warning', 'warn');
                return;
            end
            
            try
                % 时域对比
                signal_plotter.plot_multi_signals(time_comp_axes, comp_data.signal_array, ...
                    'legends', comp_data.file_names);
                
                % 频域对比
                axes(freq_comp_axes);
                cla;
                hold on;
                
                colors = lines(length(comp_data.signal_array));
                
                for i = 1:length(comp_data.signal_array)
                    signal = comp_data.signal_array{i}.get_point(1, 1);
                    fs = comp_data.signal_array{i}.fs;
                    
                    [freq, mag] = fft_analyzer.compute(signal, fs);
                    plot(freq, mag, 'Color', colors(i,:), 'LineWidth', 1.5);
                end
                
                xlabel('Frequency (kHz)', 'FontSize', 12);
                ylabel('Magnitude', 'FontSize', 12);
                title('Frequency Spectrum Comparison', 'FontSize', 14);
                legend(comp_data.file_names, 'Location', 'best');
                grid on;
                hold off;
                
            catch ME
                errordlg(['Plot error: ' ME.message], 'Plotting Error');
            end
        end
        
        function update_info_display()
            if isempty(comp_data.signal_array)
                set(info_text, 'String', 'Load files to start comparison');
                return;
            end
            
            info_str = sprintf('Loaded Files: %d\n\n', length(comp_data.signal_array));
            
            for i = 1:min(10, length(comp_data.signal_array))  % 最多显示10个
                sig_data = comp_data.signal_array{i};
                info_str = [info_str, sprintf('%d. %s\n   Points: %d\n   Fs: %.2f MHz\n\n', ...
                                             i, comp_data.file_names{i}, ...
                                             length(sig_data.time), sig_data.fs/1e6)];
            end
            
            if length(comp_data.signal_array) > 10
                info_str = [info_str, sprintf('... and %d more files', ...
                                             length(comp_data.signal_array) - 10)];
            end
            
            if comp_data.is_filtered
                info_str = [info_str, sprintf('\n\n[FILTERED]')];
            end
            
            set(info_text, 'String', info_str);
        end
    end
    
    function cleanup_and_close(~, ~)
        % 清理函数
        try
            delete(main_fig);
        catch
            % 忽略错误
        end
    end
end
