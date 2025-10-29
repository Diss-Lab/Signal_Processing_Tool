function ReadC()
    % ReadC主界面 - 波场数据分析工具 (重构版)
    % 基于新架构：wavefield_processor + SignalData + signal_plotter + filter_engine
    %
    % 版本: 2.0 (重构版)
    % 作者: 重构团队
    % 日期: 2024
    
    % === 路径检查和初始化 ===
    if ~exist('signal_plotter', 'class') || ~exist('wavefield_processor', 'class')
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
                     '然后再运行 ReadC'], '路径初始化失败');
            error('ReadC:PathNotInitialized', ME.message);
        end
    end
    
    % 创建主界面
    main_fig = figure('Name', 'Signal Processing Tool - Wave Field Analysis', ...
                      'Position', [100, 50, 1400, 850], ...
                      'MenuBar', 'none', 'ToolBar', 'none', ...
                      'Resize', 'on', 'NumberTitle', 'off', ...
                      'CloseRequestFcn', @cleanup_and_close);
    
    % 应用数据
    app = struct();
    app.signal_data = [];           % SignalData对象 (wavefield)
    app.original_signal_data = [];  % 原始SignalData（滤波前）
    app.current_file = '';
    app.is_filtered = false;
    app.current_time_idx = 1;
    app.animation_timer = [];
    app.selected_point = [1, 1];    % 当前选择的点
    app.is_interpolated = false;  % 添加：插值状态标记
    app.pre_interp_signal_data = [];  % 添加：插值前的数据
    
    % 创建UI
    create_ui();
    
    %% UI创建函数
    function create_ui()
        % 左侧控制面板
        control_panel = uipanel('Parent', main_fig, 'Position', [0.01, 0.01, 0.20, 0.98], ...
                               'Title', 'Control Panel', 'FontSize', 12, 'FontWeight', 'bold');
        
        create_control_panel(control_panel);
        
        % 右侧显示区域
        display_panel = uipanel('Parent', main_fig, 'Position', [0.22, 0.01, 0.77, 0.98], ...
                               'Title', 'Wave Field Visualization', 'FontSize', 12, 'FontWeight', 'bold');
        
        create_display_panel(display_panel);
    end
    
    function create_control_panel(parent)
        y_pos = 780;
        
        % === 文件加载区域 ===
        uicontrol('Parent', parent, 'Style', 'text', 'String', '1. Load Wave Field Data', ...
                  'Position', [10, y_pos, 250, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        y_pos = y_pos - 30;
        
        uicontrol('Parent', parent, 'Style', 'pushbutton', 'String', 'Browse MAT File', ...
                  'Position', [20, y_pos, 240, 35], 'FontSize', 10, ...
                  'BackgroundColor', [0.8 0.9 1.0], 'Callback', @load_mat_file);
        y_pos = y_pos - 40;
        
        app.file_text = uicontrol('Parent', parent, 'Style', 'text', ...
                                  'String', 'No file loaded', ...
                                  'Position', [10, y_pos, 260, 40], ...
                                  'HorizontalAlignment', 'left', ...
                                  'BackgroundColor', [0.95 0.95 0.95], ...
                                  'FontSize', 8);
        y_pos = y_pos - 45;
        
        % 网格参数
        uicontrol('Parent', parent, 'Style', 'text', 'String', 'Grid (m×n):', ...
                  'Position', [20, y_pos, 80, 20], 'HorizontalAlignment', 'left');
        app.m_edit = uicontrol('Parent', parent, 'Style', 'edit', 'String', '11', ...
                              'Position', [100, y_pos, 50, 25]);
        uicontrol('Parent', parent, 'Style', 'text', 'String', '×', ...
                  'Position', [155, y_pos, 15, 20]);
        app.n_edit = uicontrol('Parent', parent, 'Style', 'edit', 'String', '13', ...
                              'Position', [175, y_pos, 50, 25]);
        y_pos = y_pos - 40;
        
        % === 时间控制 ===
        uicontrol('Parent', parent, 'Style', 'text', 'String', '2. Time Control', ...
                  'Position', [10, y_pos, 250, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        y_pos = y_pos - 30;
        
        app.time_slider = uicontrol('Parent', parent, 'Style', 'slider', ...
                                    'Position', [20, y_pos, 240, 20], ...
                                    'Min', 1, 'Max', 100, 'Value', 1, ...
                                    'Enable', 'off', ...
                                    'Callback', @update_time);
        y_pos = y_pos - 25;
        
        app.time_text = uicontrol('Parent', parent, 'Style', 'text', ...
                                  'String', 'Time: 0.00 μs', ...
                                  'Position', [20, y_pos, 240, 20], ...
                                  'HorizontalAlignment', 'left');
        y_pos = y_pos - 35;
        
        % 动画控制
        uicontrol('Parent', parent, 'Style', 'pushbutton', 'String', 'Play', ...
                  'Position', [20, y_pos, 110, 30], ...
                  'BackgroundColor', [0.8 1.0 0.8], 'Callback', @play_animation);
        
        uicontrol('Parent', parent, 'Style', 'pushbutton', 'String', 'Stop', ...
                  'Position', [140, y_pos, 110, 30], ...
                  'BackgroundColor', [1.0 0.8 0.8], 'Callback', @stop_animation);
        y_pos = y_pos - 40;
        
        % === 显示控制 ===
        uicontrol('Parent', parent, 'Style', 'text', 'String', '3. Display Options', ...
                  'Position', [10, y_pos, 250, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        y_pos = y_pos - 30;
        
        uicontrol('Parent', parent, 'Style', 'text', 'String', 'Colormap:', ...
                  'Position', [20, y_pos, 80, 20], 'HorizontalAlignment', 'left');
        app.colormap_popup = uicontrol('Parent', parent, 'Style', 'popupmenu', ...
                                      'String', {'jet', 'hot', 'cool', 'parula', 'gray'}, ...
                                      'Position', [100, y_pos, 130, 25], ...
                                      'Callback', @update_wavefield_plot);
        y_pos = y_pos - 40;
        
        % === 插值控制 === 
        uicontrol('Parent', parent, 'Style', 'text', 'String', '4. Grid Interpolation', ...
                  'Position', [10, y_pos, 250, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        y_pos = y_pos - 30;
        
        uicontrol('Parent', parent, 'Style', 'text', 'String', 'Factor:', ...
                  'Position', [20, y_pos, 50, 20], 'HorizontalAlignment', 'left');
        app.interp_factor_popup = uicontrol('Parent', parent, 'Style', 'popupmenu', ...
                                            'String', {'2x', '4x', '8x', 'Custom'}, ...
                                            'Position', [75, y_pos, 85, 25], ...
                                            'Callback', @update_interp_ui);
        y_pos = y_pos - 30;
        
        uicontrol('Parent', parent, 'Style', 'text', 'String', 'Custom:', ...
                  'Position', [20, y_pos, 55, 20], 'HorizontalAlignment', 'left');
        app.custom_factor_edit = uicontrol('Parent', parent, 'Style', 'edit', 'String', '3', ...
                                           'Position', [75, y_pos, 50, 25], 'Enable', 'off');
        y_pos = y_pos - 25;
        
        app.smooth_edge_checkbox = uicontrol('Parent', parent, 'Style', 'checkbox', ...
                                             'String', 'Smooth Edges', ...
                                             'Position', [20, y_pos, 120, 20], ...
                                             'Value', 1);
        y_pos = y_pos - 30;
        
        uicontrol('Parent', parent, 'Style', 'pushbutton', 'String', 'Apply', ...
                  'Position', [20, y_pos, 110, 25], 'FontSize', 9, ...
                  'BackgroundColor', [0.8 0.9 1.0], 'Callback', @apply_interpolation);
        
        uicontrol('Parent', parent, 'Style', 'pushbutton', 'String', 'Remove', ...
                  'Position', [140, y_pos, 110, 25], 'FontSize', 9, ...
                  'BackgroundColor', [1.0 0.9 0.9], 'Callback', @remove_interpolation);
        y_pos = y_pos - 30;
        
        app.interp_status = uicontrol('Parent', parent, 'Style', 'text', ...
                                      'String', 'Status: Original', ...
                                      'Position', [20, y_pos, 240, 20], ...
                                      'HorizontalAlignment', 'left', ...
                                      'ForegroundColor', 'blue', ...
                                      'FontSize', 9);
        y_pos = y_pos - 40;
        
        % === 滤波控制 ===
        uicontrol('Parent', parent, 'Style', 'text', 'String', '5. Filter Settings', ...
                  'Position', [10, y_pos, 250, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        y_pos = y_pos - 30;
        
        filter_names = filter_engine.get_filter_names();
        app.filter_popup = uicontrol('Parent', parent, 'Style', 'popupmenu', ...
                                     'String', filter_names, ...
                                     'Value', 1, ...
                                     'Position', [20, y_pos, 130, 25], ...
                                     'Callback', @update_filter_ui);
        y_pos = y_pos - 30;
        
        uicontrol('Parent', parent, 'Style', 'text', 'String', 'Low (kHz):', ...
                  'Position', [20, y_pos, 70, 20], 'HorizontalAlignment', 'left');
        app.low_freq_edit = uicontrol('Parent', parent, 'Style', 'edit', 'String', '100', ...
                                      'Position', [90, y_pos, 70, 25], 'Enable', 'off');
        y_pos = y_pos - 30;
        
        uicontrol('Parent', parent, 'Style', 'text', 'String', 'High (kHz):', ...
                  'Position', [20, y_pos, 70, 20], 'HorizontalAlignment', 'left');
        app.high_freq_edit = uicontrol('Parent', parent, 'Style', 'edit', 'String', '400', ...
                                       'Position', [90, y_pos, 70, 25], 'Enable', 'off');
        y_pos = y_pos - 30;
        
        uicontrol('Parent', parent, 'Style', 'pushbutton', 'String', 'Apply', ...
                  'Position', [20, y_pos, 110, 25], 'FontSize', 9, ...
                  'BackgroundColor', [0.9 1.0 0.8], 'Callback', @apply_filter);
        
        uicontrol('Parent', parent, 'Style', 'pushbutton', 'String', 'Remove', ...
                  'Position', [140, y_pos, 110, 25], 'FontSize', 9, ...
                  'BackgroundColor', [1.0 0.9 0.8], 'Callback', @remove_filter);
        y_pos = y_pos - 30;
        
        app.filter_status = uicontrol('Parent', parent, 'Style', 'text', ...
                                      'String', 'Status: No Filter', ...
                                      'Position', [20, y_pos, 240, 20], ...
                                      'HorizontalAlignment', 'left', ...
                                      'ForegroundColor', 'blue', ...
                                      'FontSize', 9);
        y_pos = y_pos - 40;
        
        % === 信息显示 ===
        % 修复：计算剩余高度，确保不为负
        remaining_height = max(50, y_pos - 20);  % 至少50像素高度，底部留20像素边距
        
        uicontrol('Parent', parent, 'Style', 'text', 'String', 'Information', ...
                  'Position', [10, remaining_height + 10, 250, 20], 'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');
        
        app.info_text = uicontrol('Parent', parent, 'Style', 'text', ...
                                  'String', 'Load MAT file to start analysis', ...
                                  'Position', [10, 20, 260, remaining_height - 10], ...
                                  'HorizontalAlignment', 'left', ...
                                  'BackgroundColor', [0.95 0.95 0.95], ...
                                  'FontSize', 9);
    end
    
    function create_display_panel(parent)
        % 波场2D显示
        wave_panel = uipanel('Parent', parent, 'Position', [0.02, 0.51, 0.96, 0.47], ...
                            'Title', 'Wave Field (Click to select point)');
        app.wave_axes = axes('Parent', wave_panel, 'Position', [0.08, 0.12, 0.80, 0.80]);
        
        % 时域信号显示
        time_panel = uipanel('Parent', parent, 'Position', [0.02, 0.26, 0.47, 0.23], ...
                            'Title', 'Time Domain Signal');
        app.time_axes = axes('Parent', time_panel, 'Position', [0.12, 0.20, 0.82, 0.70]);
        
        % 频域信号显示
        freq_panel = uipanel('Parent', parent, 'Position', [0.51, 0.26, 0.47, 0.23], ...
                            'Title', 'Frequency Spectrum');
        app.freq_axes = axes('Parent', freq_panel, 'Position', [0.12, 0.20, 0.82, 0.70]);
        
        % 时频分析按钮和信息
        info_panel = uipanel('Parent', parent, 'Position', [0.02, 0.02, 0.96, 0.22], ...
                            'Title', 'Point Analysis');
        
        uicontrol('Parent', info_panel, 'Style', 'pushbutton', ...
                  'String', 'Time-Frequency Analysis', ...
                  'Position', [20, 130, 200, 35], ...
                  'BackgroundColor', [1.0 0.9 0.9], ...
                  'Callback', @show_point_timefreq);
        
        app.point_info = uicontrol('Parent', info_panel, 'Style', 'text', ...
                                   'String', 'Click on wave field to analyze point', ...
                                   'Position', [20, 10, 1000, 110], ...
                                   'HorizontalAlignment', 'left', ...
                                   'BackgroundColor', [0.95 0.95 0.95], ...
                                   'FontSize', 10);
    end
    
    %% 回调函数
    function load_mat_file(~, ~)
        [filename, pathname] = uigetfile('*.mat', 'Select MAT wave field file');
        if filename == 0
            return;
        end
        
        file_path = fullfile(pathname, filename);
        
        try
            % 获取网格参数
            m = str2double(get(app.m_edit, 'String'));
            n = str2double(get(app.n_edit, 'String'));
            
            if isnan(m) || isnan(n) || m <= 0 || n <= 0
                msgbox('Please enter valid grid dimensions!', 'Error', 'error');
                return;
            end
            
            grid_params = struct('m', m, 'n', n);
            
            fprintf('正在加载波场文件: %s\n', file_path);
            
            % 使用wavefield_processor加载
            app.signal_data = wavefield_processor.load_and_process(file_path, grid_params, ...
                'show_progress', true);
            app.original_signal_data = app.signal_data;
            app.current_file = file_path;
            app.is_filtered = false;
            
            % 更新UI
            set(app.file_text, 'String', sprintf('File: %s\nLoaded: %d×%d', filename, m, n));
            
            % 设置时间滑块
            num_time_points = length(app.signal_data.time);
            set(app.time_slider, 'Max', num_time_points, 'Value', 1, ...
                'SliderStep', [1/(num_time_points-1), 10/(num_time_points-1)], ...
                'Enable', 'on');
            app.current_time_idx = 1;
            
            % 更新显示
            update_signal_info();
            update_wavefield_plot();
            
            % 默认选择中心点
            app.selected_point = [ceil(m/2), ceil(n/2)];
            update_point_analysis();
            
            % 重置滤波状态
            set(app.filter_status, 'String', 'Status: No Filter', 'ForegroundColor', 'blue');
            set(app.filter_popup, 'Value', 1);
            
            fprintf('波场加载成功\n');
            msgbox(sprintf('Successfully loaded wave field: %d×%d×%d', ...
                   m, n, num_time_points), 'Success');
            
        catch ME
            errordlg(['Error loading file: ' ME.message], 'Load Error');
            fprintf('加载文件错误: %s\n', ME.getReport());
        end
    end
    
    function update_time(~, ~)
        if isempty(app.signal_data)
            return;
        end
        
        app.current_time_idx = round(get(app.time_slider, 'Value'));
        time_val = app.signal_data.time(app.current_time_idx) * 1e6;
        set(app.time_text, 'String', sprintf('Time: %.2f μs', time_val));
        
        update_wavefield_plot();
    end
    
    function update_wavefield_plot(~, ~)
        if isempty(app.signal_data)
            return;
        end
        
        try
            % 获取颜色映射
            colormap_names = get(app.colormap_popup, 'String');
            colormap_idx = get(app.colormap_popup, 'Value');
            colormap_name = colormap_names{colormap_idx};
            
            % 绘制波场
            signal_plotter.plot_wavefield_2d(app.wave_axes, app.signal_data, ...
                app.current_time_idx, ...
                'colormap_name', colormap_name, ...
                'show_colorbar', true, ...
                'click_callback', @wavefield_click);
            
            % 标记当前选择的点
            hold(app.wave_axes, 'on');
            plot(app.wave_axes, app.selected_point(2), app.selected_point(1), ...
                'rx', 'MarkerSize', 15, 'LineWidth', 3);
            hold(app.wave_axes, 'off');
            
        catch ME
            fprintf('绘制波场错误: %s\n', ME.message);
        end
    end
    
    function wavefield_click(~, ~)
        point = get(app.wave_axes, 'CurrentPoint');
        y_idx = round(point(1, 2));  % 行
        x_idx = round(point(1, 1));  % 列
        
        [m, n, ~] = size(app.signal_data.data);
        
        if y_idx >= 1 && y_idx <= m && x_idx >= 1 && x_idx <= n
            app.selected_point = [y_idx, x_idx];
            update_point_analysis();
            update_wavefield_plot();  % 重新绘制以更新标记
        end
    end
    
    function update_point_analysis()
        if isempty(app.signal_data)
            return;
        end
        
        try
            m_idx = app.selected_point(1);
            n_idx = app.selected_point(2);
            
            % 提取点信号
            point_signal = app.signal_data.get_point(m_idx, n_idx);
            
            % 时域信号
            signal_plotter.plot_time_domain(app.time_axes, ...
                struct('time', app.signal_data.time, 'signal', point_signal, 'fs', app.signal_data.fs), ...
                'color', 'b', 'title', sprintf('Time Domain - Point (%d,%d)', m_idx, n_idx));
            
            % 频域信号
            signal_plotter.plot_frequency_domain(app.freq_axes, ...
                struct('signal', point_signal, 'fs', app.signal_data.fs), ...
                'color', 'r', 'show_peaks', true, ...
                'title', sprintf('Frequency Spectrum - Point (%d,%d)', m_idx, n_idx));
            
            % 更新点信息
            update_point_info(point_signal, m_idx, n_idx);
            
        catch ME
            fprintf('更新点分析错误: %s\n', ME.message);
        end
    end
    
    function update_point_info(point_signal, m_idx, n_idx)
        try
            % 计算统计信息
            max_amp = max(abs(point_signal));
            rms_amp = rms(point_signal);
            
            % 计算频率峰值
            [freq, mag] = fft_analyzer.compute(point_signal, app.signal_data.fs);
            peaks = fft_analyzer.find_peaks(freq, mag, struct('num_peaks', 2));
            peak_str = fft_analyzer.format_peak_info(peaks, 'compact');
            
            info_str = sprintf(['Selected Point: (%d, %d)\n\n' ...
                               'Max Amplitude: %.2e\n' ...
                               'RMS Amplitude: %.2e\n' ...
                               'Sampling Rate: %.2f MHz\n\n' ...
                               '%s'], ...
                              m_idx, n_idx, max_amp, rms_amp, ...
                              app.signal_data.fs/1e6, peak_str);
            
            set(app.point_info, 'String', info_str);
            
        catch ME
            fprintf('更新点信息错误: %s\n', ME.message);
        end
    end
    
    function apply_filter(~, ~)
        if isempty(app.signal_data)
            msgbox('Please load file first!', 'Warning', 'warn');
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
            
            params = struct('fs', app.original_signal_data.fs, ...
                           'low_freq', low_freq, 'high_freq', high_freq, 'order', 4);
            
            % 对3D波场应用滤波
            fprintf('正在对波场应用滤波...\n');
            filtered_3d = filter_engine.apply_3d(app.original_signal_data.data, ...
                selected_type, params, true);
            
            % 创建新的SignalData对象
            app.signal_data = SignalData(filtered_3d, ...
                                        app.original_signal_data.time, ...
                                        app.original_signal_data.fs, ...
                                        'wavefield');
            app.signal_data.metadata = app.original_signal_data.metadata;
            
            app.is_filtered = true;
            
            filter_info = filter_engine.format_filter_info(selected_type, params);
            set(app.filter_status, 'String', ['Status: ' strrep(filter_info, sprintf('\n'), ', ')], ...
                'ForegroundColor', 'red');
            
            % 更新显示
            update_wavefield_plot();
            update_point_analysis();
            
            msgbox('Filter applied to wave field!', 'Success');
            
        catch ME
            msgbox(['Filter application failed: ' ME.message], 'Error', 'error');
        end
    end
    
    function remove_filter(~, ~)
        if isempty(app.original_signal_data)
            msgbox('No original data available!', 'Warning', 'warn');
            return;
        end
        
        app.signal_data = app.original_signal_data;
        app.is_filtered = false;
        
        set(app.filter_status, 'String', 'Status: No Filter', 'ForegroundColor', 'blue');
        set(app.filter_popup, 'Value', 1);
        
        update_wavefield_plot();
        update_point_analysis();
        
        msgbox('Filter removed. Original data restored.', 'Info');
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
    
    function update_interp_ui(~, ~)
        try
            factor_idx = get(app.interp_factor_popup, 'Value');
            
            if factor_idx == 4  % Custom
                set(app.custom_factor_edit, 'Enable', 'on');
            else
                set(app.custom_factor_edit, 'Enable', 'off');
            end
        catch ME
            fprintf('更新插值UI错误: %s\n', ME.message);
        end
    end
    
    function apply_interpolation(~, ~)
        if isempty(app.signal_data)
            msgbox('Please load wave field data first!', 'Warning', 'warn');
            return;
        end
        
        % 如果已经插值，先提示
        if app.is_interpolated
            choice = questdlg('Data is already interpolated. Apply new interpolation?', ...
                             'Confirm', 'Yes', 'No', 'No');
            if ~strcmp(choice, 'Yes')
                return;
            end
            % 恢复到插值前的状态
            app.signal_data = app.pre_interp_signal_data;
            app.is_interpolated = false;
        end
        
        try
            % 获取插值倍数
            factor_idx = get(app.interp_factor_popup, 'Value');
            switch factor_idx
                case 1
                    interp_factor = 2;
                case 2
                    interp_factor = 4;
                case 3
                    interp_factor = 8;
                case 4
                    interp_factor = str2double(get(app.custom_factor_edit, 'String'));
                    if isnan(interp_factor) || interp_factor < 1 || interp_factor > 20
                        msgbox('Custom factor must be between 1 and 20!', 'Error', 'error');
                        return;
                    end
            end
            
            % 获取边缘平滑选项
            smooth_edges = get(app.smooth_edge_checkbox, 'Value');
            
            % 保存插值前的数据
            app.pre_interp_signal_data = app.signal_data;
            
            fprintf('开始插值: 倍数=%dx, 边缘平滑=%d\n', interp_factor, smooth_edges);
            
            % 执行插值
            interpolated_data = interpolate_wavefield_3d(app.signal_data.data, ...
                                                         interp_factor, smooth_edges);
            
            % 创建新的SignalData对象
            app.signal_data = SignalData(interpolated_data, ...
                                        app.pre_interp_signal_data.time, ...
                                        app.pre_interp_signal_data.fs, ...
                                        'wavefield');
            app.signal_data.metadata = app.pre_interp_signal_data.metadata;
            app.signal_data.metadata.interpolated = true;
            app.signal_data.metadata.interp_factor = interp_factor;
            
            % 更新状态
            app.is_interpolated = true;
            [new_m, new_n, ~] = size(interpolated_data);
            set(app.interp_status, 'String', ...
                sprintf('Status: Interpolated %dx (%d×%d)', interp_factor, new_m, new_n), ...
                'ForegroundColor', [0, 0.6, 0]);
            
            % 更新显示
            update_wavefield_plot();
            
            % 重置选择点到中心
            app.selected_point = [ceil(new_m/2), ceil(new_n/2)];
            update_point_analysis();
            
            msgbox(sprintf('Interpolation complete!\nOriginal: %d×%d\nNew: %d×%d', ...
                   app.pre_interp_signal_data.metadata.dimensions(1), ...
                   app.pre_interp_signal_data.metadata.dimensions(2), ...
                   new_m, new_n), 'Success');
            
        catch ME
            msgbox(['Interpolation failed: ' ME.message], 'Error', 'error');
            fprintf('插值错误: %s\n', ME.getReport());
        end
    end
    
    function remove_interpolation(~, ~)
        if ~app.is_interpolated
            msgbox('Data is not interpolated!', 'Info', 'warn');
            return;
        end
        
        if isempty(app.pre_interp_signal_data)
            msgbox('Original data not available!', 'Error', 'error');
            return;
        end
        
        % 恢复原始数据
        app.signal_data = app.pre_interp_signal_data;
        app.is_interpolated = false;
        
        set(app.interp_status, 'String', 'Status: Original', 'ForegroundColor', 'blue');
        
        % 更新显示
        update_wavefield_plot();
        
        % 重置选择点
        [m, n, ~] = size(app.signal_data.data);
        app.selected_point = [ceil(m/2), ceil(n/2)];
        update_point_analysis();
        
        msgbox('Interpolation removed. Original grid restored.', 'Info');
    end
    
    %% 插值核心函数
    
    function interpolated_3d = interpolate_wavefield_3d(data_3d, factor, smooth_edges)
        % 对3D波场数据进行空间插值
        % 输入:
        %   data_3d - 原始3D数据 (m×n×t)
        %   factor - 插值倍数
        %   smooth_edges - 是否平滑边缘
        % 输出:
        %   interpolated_3d - 插值后的3D数据
        
        [m, n, t] = size(data_3d);
        new_m = (m - 1) * factor + 1;
        new_n = (n - 1) * factor + 1;
        
        interpolated_3d = zeros(new_m, new_n, t);
        
        % 创建进度条
        h_wait = waitbar(0, 'Interpolating wave field...');
        
        try
            % 原始网格坐标
            [X_orig, Y_orig] = meshgrid(1:n, 1:m);
            
            % 新网格坐标
            x_new = linspace(1, n, new_n);
            y_new = linspace(1, m, new_m);
            [X_new, Y_new] = meshgrid(x_new, y_new);
            
            % 对每个时间点进行插值
            for time_idx = 1:t
                % 提取当前时刻的2D数据
                slice_2d = data_3d(:, :, time_idx);
                
                % 线性插值
                interpolated_slice = interp2(X_orig, Y_orig, slice_2d, X_new, Y_new, 'linear');
                
                % 边缘平滑处理
                if smooth_edges
                    interpolated_slice = smooth_edge_region(interpolated_slice, factor);
                end
                
                interpolated_3d(:, :, time_idx) = interpolated_slice;
                
                % 更新进度条
                waitbar(time_idx/t, h_wait, sprintf('Interpolating... %d/%d', time_idx, t));
            end
            
            close(h_wait);
            
            fprintf('插值完成: %d×%d×%d → %d×%d×%d\n', m, n, t, new_m, new_n, t);
            
        catch ME
            if ishandle(h_wait)
                close(h_wait);
            end
            rethrow(ME);
        end
    end
    
    function smoothed = smooth_edge_region(data_2d, factor)
        % 平滑边缘区域
        % 输入:
        %   data_2d - 2D数据
        %   factor - 插值倍数
        % 输出:
        %   smoothed - 平滑后的数据
        
        [m, n] = size(data_2d);
        smoothed = data_2d;
        
        % 边缘平滑宽度（根据插值倍数调整）
        edge_width = max(2, round(factor / 2));
        
        try
            % 使用高斯滤波平滑边缘
            if exist('imgaussfilt', 'file')
                % 只对边缘区域应用平滑
                sigma = factor * 0.5;
                
                % 创建边缘掩码
                mask = zeros(m, n);
                mask(1:edge_width, :) = 1;
                mask(end-edge_width+1:end, :) = 1;
                mask(:, 1:edge_width) = 1;
                mask(:, end-edge_width+1:end) = 1;
                
                % 对整个图像应用轻微平滑
                smoothed_full = imgaussfilt(data_2d, sigma * 0.3);
                
                % 在边缘区域应用更强的平滑
                smoothed_edge = imgaussfilt(data_2d, sigma);
                
                % 混合
                smoothed = data_2d .* (1 - mask) + smoothed_edge .* mask;
                
            elseif exist('imfilter', 'file')
                % 使用均值滤波作为替代
                h_size = max(3, round(factor));
                h = fspecial('average', [h_size, h_size]);
                smoothed = imfilter(data_2d, h, 'replicate');
            end
            
        catch ME
            fprintf('边缘平滑警告: %s，返回原数据\n', ME.message);
            smoothed = data_2d;
        end
    end
    
    function play_animation(~, ~)
        if isempty(app.signal_data)
            msgbox('Please load file first!', 'Warning', 'warn');
            return;
        end
        
        % 停止现有动画
        stop_animation();
        
        % 创建定时器
        app.animation_timer = timer('ExecutionMode', 'fixedRate', ...
                                   'Period', 0.1, ...
                                   'TimerFcn', @animate_frame);
        start(app.animation_timer);
    end
    
    function stop_animation(~, ~)
        if ~isempty(app.animation_timer) && isvalid(app.animation_timer)
            stop(app.animation_timer);
            delete(app.animation_timer);
            app.animation_timer = [];
        end
    end
    
    function animate_frame(~, ~)
        if isempty(app.signal_data)
            stop_animation();
            return;
        end
        
        num_time_points = length(app.signal_data.time);
        app.current_time_idx = app.current_time_idx + 1;
        
        if app.current_time_idx > num_time_points
            app.current_time_idx = 1;
        end
        
        set(app.time_slider, 'Value', app.current_time_idx);
        time_val = app.signal_data.time(app.current_time_idx) * 1e6;
        set(app.time_text, 'String', sprintf('Time: %.2f μs', time_val));
        
        update_wavefield_plot();
    end
    
    function update_signal_info()
        if isempty(app.signal_data)
            return;
        end
        
        try
            info_str = wavefield_processor.get_wavefield_info(app.signal_data);
            
            if app.is_filtered
                info_str = [info_str, sprintf('\n\n[FILTERED]')];
            end
            
            set(app.info_text, 'String', info_str);
            
        catch ME
            fprintf('更新信息错误: %s\n', ME.message);
        end
    end
    
    function cleanup_and_close(~, ~)
        % 清理资源
        stop_animation();
        
        try
            delete(main_fig);
        catch
            % 忽略错误
        end
    end
end
