function ReadB()
    % ReadB主界面 - B扫多文件信号分析工具 (重构版)
    % 基于新架构：txt_loader + SignalData + signal_plotter + filter_engine
    %
    % 版本: 2.0 (重构版)
    % 作者: 重构团队
    % 日期: 2024
    
    % === 路径检查和初始化 ===
    if ~exist('signal_plotter', 'class') || ~exist('txt_loader', 'class')
        try
            current_dir = fileparts(mfilename('fullpath'));
            project_root = fileparts(fileparts(current_dir));
            
            old_dir = cd(project_root);
            init_project();
            cd(old_dir);
            
            if ~exist('signal_plotter', 'class')
                error('路径初始化失败，请手动运行 init_project');
            end
        catch ME
            errordlg(['无法初始化项目路径!' newline newline ...
                     '请先运行以下命令:' newline ...
                     'cd(''c:\Users\123\Documents\Projects\Signal_Processing_Tool'')' newline ...
                     'init_project' newline newline ...
                     '然后再运行 ReadB'], '路径初始化失败');
            error('ReadB:PathNotInitialized', ME.message);
        end
    end
    
    % 创建主界面
    main_fig = figure('Name', 'Signal Processing Tool - B-Scan Analysis', ...
                      'Position', [100, 50, 1400, 850], ...
                      'MenuBar', 'none', 'ToolBar', 'none', ...
                      'Resize', 'on', 'NumberTitle', 'off', ...
                      'CloseRequestFcn', @cleanup_and_close);
    
    % 应用数据
    app = struct();
    app.signal_array = [];          % SignalData对象数组
    app.original_signal_array = []; % 原始SignalData（滤波前）
    app.file_names = {};
    app.is_filtered = false;
    app.filter_params = struct('type', 'none', 'low_freq', 100e3, 'high_freq', 500e3, 'order', 4);
    app.time_range = [0, 100];      % 选择的时间范围(μs)
    app.amplitudes = [];            % 幅值数组
    
    % 创建UI
    create_ui();
    
    %% UI创建函数
    function create_ui()
        % 顶部标题栏
        title_panel = uipanel('Parent', main_fig, 'Position', [0.01, 0.94, 0.98, 0.05], ...
                             'BorderType', 'none');
        uicontrol('Parent', title_panel, 'Style', 'text', ...
                  'String', 'Signal Processing Tool - B-Scan Multi-File Analysis', ...
                  'Position', [350, 5, 700, 30], 'FontSize', 16, 'FontWeight', 'bold');
        
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
        uicontrol('Parent', parent, 'Style', 'text', 'String', '1. Load Signal Files', ...
                  'Position', [10, y_pos, 250, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        y_pos = y_pos - 30;
        
        uicontrol('Parent', parent, 'Style', 'pushbutton', 'String', 'Browse Folder', ...
                  'Position', [20, y_pos, 250, 35], 'FontSize', 10, ...
                  'BackgroundColor', [0.8 0.9 1.0], 'Callback', @load_folder);
        y_pos = y_pos - 40;
        
        app.folder_text = uicontrol('Parent', parent, 'Style', 'text', ...
                                    'String', 'No folder selected', ...
                                    'Position', [10, y_pos, 280, 40], ...
                                    'HorizontalAlignment', 'left', ...
                                    'BackgroundColor', [0.95 0.95 0.95], ...
                                    'FontSize', 9);
        y_pos = y_pos - 50;
        
        % === 时间范围选择 ===
        uicontrol('Parent', parent, 'Style', 'text', 'String', '2. Time Range Selection', ...
                  'Position', [10, y_pos, 250, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        y_pos = y_pos - 30;
        
        uicontrol('Parent', parent, 'Style', 'text', 'String', 'Start (μs):', ...
                  'Position', [20, y_pos, 80, 20], 'HorizontalAlignment', 'left');
        app.start_time_edit = uicontrol('Parent', parent, 'Style', 'edit', 'String', '0', ...
                                        'Position', [110, y_pos, 80, 25]);
        y_pos = y_pos - 30;
        
        uicontrol('Parent', parent, 'Style', 'text', 'String', 'End (μs):', ...
                  'Position', [20, y_pos, 80, 20], 'HorizontalAlignment', 'left');
        app.end_time_edit = uicontrol('Parent', parent, 'Style', 'edit', 'String', '100', ...
                                      'Position', [110, y_pos, 80, 25]);
        y_pos = y_pos - 35;
        
        uicontrol('Parent', parent, 'Style', 'pushbutton', 'String', 'Apply Range', ...
                  'Position', [20, y_pos, 120, 30], 'FontSize', 10, ...
                  'BackgroundColor', [0.9 1.0 0.8], 'Callback', @apply_time_range);
        
        app.range_status = uicontrol('Parent', parent, 'Style', 'text', ...
                                     'String', 'Full Range', ...
                                     'Position', [150, y_pos, 120, 30], ...
                                     'HorizontalAlignment', 'left', ...
                                     'ForegroundColor', 'blue');
        y_pos = y_pos - 50;
        
        % === 滤波控制区域 ===
        uicontrol('Parent', parent, 'Style', 'text', 'String', '3. Filter Settings', ...
                  'Position', [10, y_pos, 250, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        y_pos = y_pos - 30;
        
        filter_names = filter_engine.get_filter_names();
        app.filter_popup = uicontrol('Parent', parent, 'Style', 'popupmenu', ...
                                     'String', filter_names, ...
                                     'Value', 1, ...
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
        
        % === 幅值分析 ===
        uicontrol('Parent', parent, 'Style', 'text', 'String', '4. Amplitude Analysis', ...
                  'Position', [10, y_pos, 250, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        y_pos = y_pos - 35;
        
        uicontrol('Parent', parent, 'Style', 'pushbutton', 'String', 'Extract Peak-to-Peak', ...
                  'Position', [20, y_pos, 250, 35], 'FontSize', 10, ...
                  'BackgroundColor', [1.0 0.9 0.9], 'Callback', @extract_amplitudes);
        y_pos = y_pos - 50;
        
        % === 信息显示区域 ===
        uicontrol('Parent', parent, 'Style', 'text', 'String', 'File Information', ...
                  'Position', [10, y_pos, 250, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        y_pos = y_pos - 10;
        
        app.info_text = uicontrol('Parent', parent, 'Style', 'text', ...
                                  'String', 'Load folder to view information', ...
                                  'Position', [10, y_pos-150, 280, 150], ...
                                  'HorizontalAlignment', 'left', ...
                                  'BackgroundColor', [0.95 0.95 0.95], ...
                                  'FontSize', 9);
    end
    
    function create_display_panel(parent)
        % 时域信号叠加显示
        time_panel = uipanel('Parent', parent, 'Position', [0.02, 0.51, 0.96, 0.47], ...
                            'Title', 'Time Domain Signals (All Files)');
        app.time_axes = axes('Parent', time_panel, 'Position', [0.08, 0.15, 0.88, 0.75]);
        
        % 幅值曲线显示
        amp_panel = uipanel('Parent', parent, 'Position', [0.02, 0.02, 0.96, 0.47], ...
                           'Title', 'Peak-to-Peak Amplitude vs File Number');
        app.amp_axes = axes('Parent', amp_panel, 'Position', [0.08, 0.15, 0.88, 0.75]);
        
        % 初始化空白显示
        axes(app.amp_axes);
        text(0.5, 0.5, 'Click "Extract Peak-to-Peak" to generate amplitude plot', ...
             'Units', 'normalized', 'HorizontalAlignment', 'center', ...
             'FontSize', 12, 'Color', [0.5 0.5 0.5]);
    end
    
    %% 回调函数
    function load_folder(~, ~)
        folder_path = uigetdir('', 'Select folder containing numbered TXT files (1.txt, 2.txt, ...)');
        if folder_path == 0
            return;
        end
        
        try
            fprintf('正在加载文件夹: %s\n', folder_path);
            
            % 使用txt_loader批量加载
            [signal_array, file_list] = txt_loader.load_batch(folder_path, '', ...
                'show_progress', true);
            
            if isempty(signal_array)
                msgbox('No valid TXT files found in the folder!', 'Warning', 'warn');
                return;
            end
            
            app.signal_array = signal_array;
            app.original_signal_array = signal_array;
            app.file_names = file_list;
            app.is_filtered = false;
            
            % 更新文件夹显示
            [~, folder_name] = fileparts(folder_path);
            set(app.folder_text, 'String', sprintf('Folder: %s\n%d files loaded', ...
                folder_name, length(signal_array)));
            
            % 自动计算时间范围
            calculate_time_range();
            
            % 更新信息显示
            update_file_info();
            
            % 绘制信号
            plot_signals();
            
            % 重置状态
            set(app.filter_status, 'String', 'Status: No Filter', 'ForegroundColor', 'blue');
            set(app.filter_popup, 'Value', 1);
            app.amplitudes = [];
            clear_amplitude_plot();
            
            fprintf('成功加载 %d 个文件\n', length(signal_array));
            msgbox(sprintf('Successfully loaded %d files', length(signal_array)), 'Success');
            
        catch ME
            errordlg(['Error loading folder: ' ME.message], 'Load Error');
            fprintf('加载文件夹错误: %s\n', ME.getReport());
        end
    end
    
    function calculate_time_range()
        if isempty(app.signal_array)
            return;
        end
        
        % 计算所有信号的时间交集
        all_min_times = zeros(length(app.signal_array), 1);
        all_max_times = zeros(length(app.signal_array), 1);
        
        for i = 1:length(app.signal_array)
            all_min_times(i) = min(app.signal_array{i}.time) * 1e6;
            all_max_times(i) = max(app.signal_array{i}.time) * 1e6;
        end
        
        start_time = max(all_min_times);
        end_time = min(all_max_times);
        
        app.time_range = [start_time, end_time];
        set(app.start_time_edit, 'String', sprintf('%.2f', start_time));
        set(app.end_time_edit, 'String', sprintf('%.2f', end_time));
        set(app.range_status, 'String', sprintf('%.1f-%.1f μs', start_time, end_time));
    end
    
    function apply_time_range(~, ~)
        if isempty(app.signal_array)
            msgbox('Please load files first!', 'Warning', 'warn');
            return;
        end
        
        try
            start_time = str2double(get(app.start_time_edit, 'String'));
            end_time = str2double(get(app.end_time_edit, 'String'));
            
            if isnan(start_time) || isnan(end_time) || start_time >= end_time
                msgbox('Invalid time range!', 'Error', 'error');
                return;
            end
            
            app.time_range = [start_time, end_time];
            set(app.range_status, 'String', sprintf('%.1f-%.1f μs', start_time, end_time));
            
            plot_signals();
            
        catch ME
            msgbox(['Error applying time range: ' ME.message], 'Error', 'error');
        end
    end
    
    function apply_filter(~, ~)
        if isempty(app.signal_array)
            msgbox('Please load files first!', 'Warning', 'warn');
            return;
        end
        
        try
            filter_types = filter_engine.get_filter_types();
            popup_value = get(app.filter_popup, 'Value');
            selected_type = filter_types{popup_value};
            
            if strcmp(selected_type, 'none')
                msgbox('Please select a filter type!', 'Warning', 'warn');
                return;
            end
            
            low_freq = str2double(get(app.low_freq_edit, 'String')) * 1000;
            high_freq = str2double(get(app.high_freq_edit, 'String')) * 1000;
            
            % 对每个信号应用滤波
            h_wait = waitbar(0, 'Applying filter to all signals...');
            
            for i = 1:length(app.original_signal_array)
                signal = app.original_signal_array{i}.get_point(1, 1);
                fs = app.original_signal_array{i}.fs;
                
                params = struct('fs', fs, 'low_freq', low_freq, ...
                               'high_freq', high_freq, 'order', 4);
                
                filtered_signal = filter_engine.apply(signal, selected_type, params);
                
                app.signal_array{i} = SignalData(filtered_signal, ...
                                                 app.original_signal_array{i}.time, ...
                                                 fs, 'single_point');
                
                waitbar(i/length(app.original_signal_array), h_wait);
            end
            
            close(h_wait);
            
            app.is_filtered = true;
            app.filter_params.type = selected_type;
            app.filter_params.low_freq = low_freq;
            app.filter_params.high_freq = high_freq;
            
            filter_info = filter_engine.format_filter_info(selected_type, params);
            set(app.filter_status, 'String', ['Status: ' strrep(filter_info, sprintf('\n'), ', ')], ...
                'ForegroundColor', 'red');
            
            plot_signals();
            
            msgbox('Filter applied to all signals!', 'Success');
            
        catch ME
            msgbox(['Filter application failed: ' ME.message], 'Error', 'error');
        end
    end
    
    function remove_filter(~, ~)
        if isempty(app.original_signal_array)
            msgbox('No original signal data available!', 'Warning', 'warn');
            return;
        end
        
        app.signal_array = app.original_signal_array;
        app.is_filtered = false;
        
        set(app.filter_status, 'String', 'Status: No Filter', 'ForegroundColor', 'blue');
        set(app.filter_popup, 'Value', 1);
        
        plot_signals();
        
        msgbox('Filter removed. Original signals restored.', 'Info');
    end
    
    function update_filter_ui(~, ~)
        try
            popup_value = get(app.filter_popup, 'Value');
            
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
    
    function extract_amplitudes(~, ~)
        if isempty(app.signal_array)
            msgbox('Please load files first!', 'Warning', 'warn');
            return;
        end
        
        try
            num_files = length(app.signal_array);
            app.amplitudes = zeros(num_files, 1);
            
            % 提取选择时间范围内的峰峰值
            for i = 1:num_files
                time_vec = app.signal_array{i}.time * 1e6;  % 转换为μs
                signal = app.signal_array{i}.get_point(1, 1);
                
                % 找到时间范围内的索引
                start_idx = find(time_vec >= app.time_range(1), 1, 'first');
                end_idx = find(time_vec <= app.time_range(2), 1, 'last');
                
                if isempty(start_idx)
                    start_idx = 1;
                end
                if isempty(end_idx)
                    end_idx = length(time_vec);
                end
                
                % 计算峰峰值
                signal_range = signal(start_idx:end_idx);
                app.amplitudes(i) = max(signal_range) - min(signal_range);
            end
            
            % 绘制幅值曲线
            plot_amplitude_curve();
            
            msgbox(sprintf('Peak-to-peak amplitudes extracted for %d files', num_files), 'Success');
            
        catch ME
            msgbox(['Error extracting amplitudes: ' ME.message], 'Error', 'error');
        end
    end
    
    function plot_signals()
        if isempty(app.signal_array)
            return;
        end
        
        try
            % 使用signal_plotter绘制多信号
            [~, file_names_only] = cellfun(@fileparts, app.file_names, 'UniformOutput', false);
            
            signal_plotter.plot_multi_signals(app.time_axes, app.signal_array, ...
                'legends', file_names_only, ...
                'highlight_range', app.time_range);
            
        catch ME
            errordlg(['Plot error: ' ME.message], 'Plotting Error');
            fprintf('绘图错误: %s\n', ME.getReport());
        end
    end
    
    function plot_amplitude_curve()
        if isempty(app.amplitudes)
            return;
        end
        
        try
            positions = 1:length(app.amplitudes);
            
            signal_plotter.plot_amplitude_curve(app.amp_axes, app.amplitudes, positions, ...
                'marker_style', 'o', 'line_color', 'b', 'show_values', false, ...
                'title', sprintf('Peak-to-Peak Amplitude (Time Range: %.1f-%.1f μs)', ...
                                app.time_range(1), app.time_range(2)), ...
                'xlabel', 'File Number', ...
                'ylabel', 'Peak-to-Peak Amplitude');
            
        catch ME
            fprintf('绘制幅值曲线错误: %s\n', ME.message);
        end
    end
    
    function clear_amplitude_plot()
        axes(app.amp_axes);
        cla;
        text(0.5, 0.5, 'Click "Extract Peak-to-Peak" to generate amplitude plot', ...
             'Units', 'normalized', 'HorizontalAlignment', 'center', ...
             'FontSize', 12, 'Color', [0.5 0.5 0.5]);
        title('Peak-to-Peak Amplitude vs File Number');
        xlabel('File Number');
        ylabel('Peak-to-Peak Amplitude');
        grid on;
    end
    
    function update_file_info()
        if isempty(app.signal_array)
            return;
        end
        
        num_files = length(app.signal_array);
        
        % 获取第一个文件的信息作为参考
        first_signal = app.signal_array{1};
        
        info_str = sprintf('Files Loaded: %d\n\n', num_files);
        info_str = [info_str, sprintf('Sample Info:\nPoints: %d\nFs: %.2f MHz\nDuration: %.2f μs\n\n', ...
                                     length(first_signal.time), ...
                                     first_signal.fs/1e6, ...
                                     (first_signal.time(end)-first_signal.time(1))*1e6)];
        
        if app.is_filtered
            info_str = [info_str, sprintf('Filter Applied:\n%s', ...
                filter_engine.format_filter_info(app.filter_params.type, app.filter_params))];
        end
        
        set(app.info_text, 'String', info_str);
    end
    
    function cleanup_and_close(~, ~)
        try
            delete(main_fig);
        catch
            % 忽略错误
        end
    end
end
