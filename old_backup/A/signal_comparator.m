classdef signal_comparator < handle
    % 信号对比模块 - 提供多信号对比分析功能
    
    methods (Static)
        function create_comparison_ui_with_files(auto_files)
            % 创建带自动加载文件的对比界面
            if nargin < 1
                auto_files = {};
            end
            
            % 创建对比界面
            comp_fig = figure('Name', 'Signal Comparison Tool', 'Position', [150, 50, 1400, 800], ...
                             'MenuBar', 'none', 'ToolBar', 'none');
            
            % 存储对比数据
            comp_data = [];
            comp_files = {};
            filtered_data = [];
            selected_time_range = []; % 选择的时间范围
            
            % 左侧控制面板
            control_panel = uipanel('Parent', comp_fig, 'Position', [0.01, 0.01, 0.25, 0.98], ...
                                   'Title', 'Control Panel');
            
            % 文件选择区域
            uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Select MAT files for comparison:', ...
                      'Position', [10, 750, 200, 20], 'FontWeight', 'bold');
            
            uicontrol('Parent', control_panel, 'Style', 'pushbutton', 'String', 'Browse MAT Files', ...
                      'Position', [10, 720, 120, 25], 'BackgroundColor', [0.8 0.9 1.0], ...
                      'Callback', @select_comparison_files);
            
            % 文件列表
            file_listbox = uicontrol('Parent', control_panel, 'Style', 'listbox', ...
                                    'Position', [10, 600, 320, 110], 'Max', 2);
            
            % 时间段选择
            uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Time Range Selection (μs):', ...
                      'Position', [10, 570, 160, 20], 'FontWeight', 'bold');
            
            uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Start Time:', ...
                      'Position', [10, 540, 80, 20]);
            start_time_edit = uicontrol('Parent', control_panel, 'Style', 'edit', 'String', '0', ...
                                       'Position', [100, 540, 80, 25]);
            
            uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'End Time:', ...
                      'Position', [10, 510, 80, 20]);
            end_time_edit = uicontrol('Parent', control_panel, 'Style', 'edit', 'String', '100', ...
                                     'Position', [100, 510, 80, 25]);
            
            uicontrol('Parent', control_panel, 'Style', 'pushbutton', 'String', 'Apply Time Range', ...
                      'Position', [200, 525, 100, 25], 'BackgroundColor', [0.9 1.0 0.8], ...
                      'Callback', @apply_time_range);
            
            % 选择的时间范围显示
            range_text = uicontrol('Parent', control_panel, 'Style', 'text', ...
                                  'String', 'Selected Range:\nFull Range', ...
                                  'Position', [10, 470, 200, 30], ...
                                  'HorizontalAlignment', 'left', ...
                                  'BackgroundColor', [0.9 0.9 0.9]);
            
            % 滤波控制
            uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Filter Settings:', ...
                      'Position', [10, 430, 100, 20], 'FontWeight', 'bold');
            
            filter_popup = uicontrol('Parent', control_panel, 'Style', 'popupmenu', ...
                                    'String', filters.get_filter_names(), ...
                                    'Position', [10, 400, 120, 25]);
            
            uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Low Freq (kHz):', ...
                      'Position', [10, 370, 80, 30]);
            comp_low_freq_edit = uicontrol('Parent', control_panel, 'Style', 'edit', 'String', '100', ...
                                          'Position', [100, 370, 80, 25]);
            
            uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'High Freq (kHz):', ...
                      'Position', [10, 340, 80, 30]);
            comp_high_freq_edit = uicontrol('Parent', control_panel, 'Style', 'edit', 'String', '500', ...
                                           'Position', [100, 340, 80, 25]);
            
            uicontrol('Parent', control_panel, 'Style', 'pushbutton', 'String', 'Apply Filter', ...
                      'Position', [200, 355, 100, 25], 'BackgroundColor', [1.0 0.9 0.8], ...
                      'Callback', @apply_comparison_filter);
            
            % FFT和时频分析按钮
            uicontrol('Parent', control_panel, 'Style', 'pushbutton', 'String', 'Update FFT', ...
                      'Position', [10, 300, 100, 30], 'BackgroundColor', [0.9 0.9 1.0], ...
                      'Callback', @update_fft_with_filter);
            
            uicontrol('Parent', control_panel, 'Style', 'pushbutton', 'String', 'Time-Frequency', ...
                      'Position', [120, 300, 100, 30], 'BackgroundColor', [1.0 0.9 0.9], ...
                      'Callback', @show_comparison_timefreq);
            
            % 信息显示
            comp_info_text = uicontrol('Parent', control_panel, 'Style', 'text', ...
                                       'String', 'Select files to start comparison', ...
                                       'Position', [10, 160, 320, 120], ...
                                       'HorizontalAlignment', 'left', ...
                                       'BackgroundColor', [0.9 0.9 0.9]);
            
            % 右侧显示区域 - 时域信号
            time_panel = uipanel('Parent', comp_fig, 'Position', [0.27, 0.51, 0.72, 0.48], ...
                                'Title', 'Time Domain Signals Comparison');
            time_axes = axes('Parent', time_panel, 'Position', [0.08, 0.15, 0.88, 0.75]);
            
            % 频域信号
            freq_panel = uipanel('Parent', comp_fig, 'Position', [0.27, 0.01, 0.72, 0.48], ...
                                'Title', 'Frequency Spectrum Comparison');
            freq_axes = axes('Parent', freq_panel, 'Position', [0.08, 0.15, 0.88, 0.75]);
            
            % 如果有自动加载文件，立即处理
            if ~isempty(auto_files)
                % 验证文件存在性
                valid_files = {};
                for i = 1:length(auto_files)
                    if exist(auto_files{i}, 'file')
                        valid_files{end+1} = auto_files{i};
                    end
                end
                
                if ~isempty(valid_files)
                    % 立即加载文件
                    comp_files = valid_files;
                    comp_data = signal_comparator.load_comparison_files(comp_files);
                    filtered_data = comp_data;
                    
                    if ~isempty(comp_data)
                        % 更新文件列表显示
                        [~, names, ~] = cellfun(@fileparts, comp_files, 'UniformOutput', false);
                        set(file_listbox, 'String', names);
                        
                        % 更新时间范围
                        [min_time, max_time] = signal_comparator.calculate_time_intersection(comp_data);
                        set(start_time_edit, 'String', sprintf('%.2f', min_time));
                        set(end_time_edit, 'String', sprintf('%.2f', max_time));
                        selected_time_range = [min_time, max_time];
                        set(range_text, 'String', sprintf('Selected Range:\n%.2f - %.2f μs', min_time, max_time));
                        
                        % 立即更新显示
                        signal_comparator.plot_comparison_signals(filtered_data, comp_files, time_axes, freq_axes, comp_info_text, selected_time_range);
                        
                        % 显示成功消息
                        [~, file_names, ~] = cellfun(@fileparts, valid_files, 'UniformOutput', false);
                        success_msg = sprintf('已自动加载 %d 个文件进行对比分析：\n\n%s', ...
                                            length(valid_files), strjoin(file_names, '\n'));
                        
                    end
                end
            end
            
            
            function select_comparison_files(~, ~)
                [filenames, pathname] = uigetfile('*.mat', 'Select MAT files for comparison', 'MultiSelect', 'on');
                if ~isequal(filenames, 0)
                    if ischar(filenames)
                        filenames = {filenames};
                    end
                    
                    comp_files = cellfun(@(x) fullfile(pathname, x), filenames, 'UniformOutput', false);
                    comp_data = signal_comparator.load_comparison_files(comp_files);
                    filtered_data = comp_data;
                    
                    % 更新文件列表显示
                    [~, names, ~] = cellfun(@fileparts, comp_files, 'UniformOutput', false);
                    set(file_listbox, 'String', names);
                    
                    if ~isempty(comp_data)
                        % 更新时间范围 - 计算所有信号的时间交集
                        [min_time, max_time] = signal_comparator.calculate_time_intersection(comp_data);
                        set(start_time_edit, 'String', sprintf('%.2f', min_time));
                        set(end_time_edit, 'String', sprintf('%.2f', max_time));
                        selected_time_range = [min_time, max_time];
                        set(range_text, 'String', sprintf('Selected Range:\n%.2f - %.2f μs', min_time, max_time));
                        
                        update_comparison_plots();
                    end
                end
            end
            
            function apply_time_range(~, ~)
                if ~isempty(comp_data)
                    try
                        start_time = str2double(get(start_time_edit, 'String'));
                        end_time = str2double(get(end_time_edit, 'String'));
                        
                        if isnan(start_time) || isnan(end_time) || start_time >= end_time
                            msgbox('Invalid time range! Please enter valid start and end times.', 'Error', 'error');
                            return;
                        end
                        
                        % 验证时间范围是否在所有信号的交集内
                        [min_intersect, max_intersect] = signal_comparator.calculate_time_intersection(comp_data);
                        if start_time < min_intersect || end_time > max_intersect
                            msgbox(sprintf('Time range must be within intersection %.2f - %.2f μs', min_intersect, max_intersect), 'Error', 'error');
                            return;
                        end
                        
                        selected_time_range = [start_time, end_time];
                        set(range_text, 'String', sprintf('Selected Range:\n%.2f - %.2f μs', start_time, end_time));
                        
                        % 更新显示
                        update_comparison_plots();
                        
                    catch ME
                        msgbox(['Error applying time range: ' ME.message], 'Error', 'error');
                    end
                end
            end
            
            function apply_comparison_filter(~, ~)
                if ~isempty(comp_data)
                    filtered_data = signal_comparator.apply_frequency_filter(comp_data, filter_popup, comp_low_freq_edit, comp_high_freq_edit, selected_time_range);
                    update_comparison_plots();
                end
            end
            
            function update_comparison_plots()
                signal_comparator.plot_comparison_signals(filtered_data, comp_files, time_axes, freq_axes, comp_info_text, selected_time_range);
            end
            
            function update_fft_with_filter(~, ~)
                if ~isempty(comp_data)
                    filtered_data = signal_comparator.apply_frequency_filter(comp_data, filter_popup, comp_low_freq_edit, comp_high_freq_edit, selected_time_range);
                    update_comparison_plots();
                    signal_comparator.show_filter_status(filter_popup, comp_low_freq_edit, comp_high_freq_edit);
                end
            end
            
            function show_comparison_timefreq(~, ~)
                if ~isempty(filtered_data)
                    signal_comparator.create_timefreq_comparison(filtered_data, comp_files, selected_time_range);
                else
                    msgbox('Please select files first!', 'Error', 'error');
                end
            end
        end
        
        function create_comparison_ui()
            % 创建普通对比界面（向后兼容）
            signal_comparator.create_comparison_ui_with_files({});
        end
        
        function auto_load_files(comp_fig, mat_files)
            % 自动加载文件到对比界面的公共方法
            try
                % 验证文件存在性
                valid_files = {};
                for i = 1:length(mat_files)
                    if exist(mat_files{i}, 'file')
                        valid_files{end+1} = mat_files{i};
                    end
                end
                
                if isempty(valid_files)
                    msgbox('没有找到有效的MAT文件', 'Warning', 'warn');
                    return;
                end
                
                % 设置自动加载标记
                setappdata(comp_fig, 'auto_load_files', valid_files);
                
            catch ME
                fprintf('自动加载设置失败: %s\n', ME.message);
            end
        end
        
        function comp_data = load_comparison_files(comp_files)
            % 加载对比文件
            comp_data = {};
            
            for i = 1:length(comp_files)
                try
                    loaded = load(comp_files{i});
                    if isfield(loaded, 'data_xyt') && isfield(loaded, 'data_time')
                        % 从3D数据中提取1D信号
                        signal_1d = squeeze(loaded.data_xyt(1, 1, :));
                        comp_data{end+1} = struct('signal', signal_1d, 'time', loaded.data_time, 'fs', loaded.fs);
                    end
                catch
                    fprintf('Failed to load: %s\n', comp_files{i});
                end
            end
        end
        
        function update_time_range(comp_data, start_time_edit, end_time_edit)
            % 更新时间范围控件
            if ~isempty(comp_data)
                all_times = cellfun(@(x) x.time, comp_data, 'UniformOutput', false);
                min_time = min(cellfun(@min, all_times)) * 1e6;
                max_time = max(cellfun(@max, all_times)) * 1e6;
                
                set(start_time_edit, 'String', num2str(min_time, '%.2f'));
                set(end_time_edit, 'String', num2str(max_time, '%.2f'));
            end
        end
        
        function [min_time, max_time] = calculate_time_intersection(comp_data)
            % 计算所有信号的时间交集
            if isempty(comp_data)
                min_time = 0;
                max_time = 100;
                return;
            end
            
            all_min_times = cellfun(@(x) min(x.time), comp_data) * 1e6;
            all_max_times = cellfun(@(x) max(x.time), comp_data) * 1e6;
            
            min_time = max(all_min_times); % 取最大的最小值（交集的开始）
            max_time = min(all_max_times); % 取最小的最大值（交集的结束）
        end
        
        function filtered_data = apply_time_filter(comp_data, start_time_edit, end_time_edit)
            % 应用时间范围滤波
            filtered_data = comp_data;
            
            start_time = str2double(get(start_time_edit, 'String')) / 1e6; % 转换为秒
            end_time = str2double(get(end_time_edit, 'String')) / 1e6;
            
            % 对所有数据应用时间范围
            for i = 1:length(filtered_data)
                time_vec = filtered_data{i}.time;
                time_idx = (time_vec >= start_time) & (time_vec <= end_time);
                
                filtered_data{i}.time = time_vec(time_idx);
                filtered_data{i}.signal = filtered_data{i}.signal(time_idx);
            end
        end
        
        function filtered_data = apply_frequency_filter(comp_data, filter_popup, comp_low_freq_edit, comp_high_freq_edit, selected_time_range)
            % 应用频率滤波（只对选择的时间范围）
            filtered_data = comp_data;
            
            filter_type = get(filter_popup, 'Value');
            low_freq = str2double(get(comp_low_freq_edit, 'String')) * 1000; % 转换为Hz
            high_freq = str2double(get(comp_high_freq_edit, 'String')) * 1000; % 转换为Hz
            
            if filter_type > 1 % 有滤波
                for i = 1:length(filtered_data)
                    % 提取选择时间范围内的数据进行滤波
                    if ~isempty(selected_time_range)
                        start_time = selected_time_range(1) / 1e6; % 转换为秒
                        end_time = selected_time_range(2) / 1e6;
                        
                        time_vec = filtered_data{i}.time;
                        time_idx = (time_vec >= start_time) & (time_vec <= end_time);
                        
                        selected_signal = filtered_data{i}.signal(time_idx);
                        selected_time = time_vec(time_idx);
                        
                        % 只对选择的时间段进行滤波
                        fs_current = filtered_data{i}.fs;
                        filtered_signal = filters.apply_filter(selected_signal, filter_type, low_freq, high_freq, fs_current);
                        
                        % 更新数据为滤波后的时间段
                        filtered_data{i}.signal = filtered_signal;
                        filtered_data{i}.time = selected_time;
                    else
                        % 如果没有选择时间范围，对整个信号滤波
                        fs_current = filtered_data{i}.fs;
                        filtered_data{i}.signal = filters.apply_filter(filtered_data{i}.signal, filter_type, low_freq, high_freq, fs_current);
                    end
                end
            else
                % 无滤波时，如果有选择时间范围，也要应用
                if ~isempty(selected_time_range)
                    filtered_data = signal_comparator.apply_time_filter_by_range(filtered_data, selected_time_range);
                end
            end
        end
        
        function filtered_data = apply_time_filter_by_range(comp_data, selected_time_range)
            % 根据时间范围滤波数据
            filtered_data = comp_data;
            
            start_time = selected_time_range(1) / 1e6; % 转换为秒
            end_time = selected_time_range(2) / 1e6;
            
            for i = 1:length(filtered_data)
                time_vec = filtered_data{i}.time;
                time_idx = (time_vec >= start_time) & (time_vec <= end_time);
                
                filtered_data{i}.time = time_vec(time_idx);
                filtered_data{i}.signal = filtered_data{i}.signal(time_idx);
            end
        end
        
        function plot_comparison_signals(filtered_data, comp_files, time_axes, freq_axes, comp_info_text, selected_time_range)
            % 绘制对比信号（带时间范围标示）
            if isempty(filtered_data)
                return;
            end
            
            % 绘制时域信号对比
            axes(time_axes);
            cla;
            hold on;
            
            colors = lines(length(filtered_data));
            legends = {};
            
            % 首先标记选择的时间范围（如果有选择且不是全范围）
            if ~isempty(selected_time_range)
                % 获取y轴范围用于绘制时间范围标示
                all_signals = [];
                for i = 1:length(filtered_data)
                    all_signals = [all_signals; filtered_data{i}.signal];
                end
                if ~isempty(all_signals)
                    ylims = [min(all_signals), max(all_signals)];
                    ylims = ylims + [-1, 1] * (ylims(2) - ylims(1)) * 0.1; % 扩展一点范围
                    
                    % 绘制时间范围背景
                    fill([selected_time_range(1), selected_time_range(2), selected_time_range(2), selected_time_range(1)], ...
                         [ylims(1), ylims(1), ylims(2), ylims(2)], ...
                         [1, 1, 0], 'FaceAlpha', 0.2, 'EdgeColor', 'none');
                end
            end
            
            % 绘制信号
            for i = 1:length(filtered_data)
                h_time = plot(filtered_data{i}.time * 1e6, filtered_data{i}.signal, ...
                     'Color', colors(i,:), 'LineWidth', 1.5);
                set(h_time, 'ButtonDownFcn', @(~,~) signal_comparator.time_click(time_axes, comp_info_text));
                [~, name, ~] = fileparts(comp_files{i});
                legends{i} = name;
            end
            
            xlabel('Time (μs)');
            ylabel('Amplitude');
            title('Time Domain Signals Comparison');
            legend(legends, 'Location', 'best');
            grid on;
            hold off;
            set(time_axes, 'ButtonDownFcn', @(~,~) signal_comparator.time_click(time_axes, comp_info_text));
            
            % 绘制频域信号对比（只对选择时间范围内的数据）
            axes(freq_axes);
            cla;
            hold on;
            
            for i = 1:length(filtered_data)
                [freq_vector, magnitude] = visualizer.compute_fft(filtered_data{i}.signal, filtered_data{i}.fs);
                
                h_freq = plot(freq_vector, magnitude, 'Color', colors(i,:), 'LineWidth', 1.5);
                set(h_freq, 'ButtonDownFcn', @(~,~) signal_comparator.freq_click(freq_axes, comp_info_text));
            end
            
            xlabel('Frequency (kHz)');
            ylabel('Magnitude');
            title('Frequency Spectrum Comparison');
            legend(legends, 'Location', 'best');
            grid on;
            hold off;
            set(freq_axes, 'ButtonDownFcn', @(~,~) signal_comparator.freq_click(freq_axes, comp_info_text));
            
            % 更新信息显示
            signal_comparator.update_comparison_info(filtered_data, comp_files, comp_info_text);
        end
        
        function update_comparison_info(filtered_data, comp_files, comp_info_text)
            % 更新对比信息显示
            info_str = sprintf('Loaded %d signals for comparison\n\n', length(filtered_data));
            for i = 1:length(filtered_data)
                [~, name, ~] = fileparts(comp_files{i});
                info_str = [info_str, sprintf('%d. %s\n   Points: %d\n   Fs: %.2f MHz\n\n', ...
                                             i, name, length(filtered_data{i}.signal), filtered_data{i}.fs/1e6)];
            end
            set(comp_info_text, 'String', info_str);
        end
        
        function time_click(time_axes, comp_info_text)
            % 时域点击回调
            point = get(time_axes, 'CurrentPoint');
            x_coord = point(1, 1); % 时间 (μs)
            y_coord = point(1, 2); % 幅值
            
            click_info = sprintf('Time Domain Click:\nTime: %.2f μs\nAmplitude: %.4f', ...
                                x_coord, y_coord);
            set(comp_info_text, 'String', click_info);
        end
        
        function freq_click(freq_axes, comp_info_text)
            % 频域点击回调
            point = get(freq_axes, 'CurrentPoint');
            x_coord = point(1, 1); % 频率 (kHz)
            y_coord = point(1, 2); % 幅值
            
            click_info = sprintf('Frequency Domain Click:\nFrequency: %.1f kHz\nMagnitude: %.2f', ...
                                x_coord, y_coord);
            set(comp_info_text, 'String', click_info);
        end
        
        function show_filter_status(filter_popup, comp_low_freq_edit, comp_high_freq_edit)
            % 显示滤波状态
            filter_type = get(filter_popup, 'Value');
            low_freq = str2double(get(comp_low_freq_edit, 'String'));
            high_freq = str2double(get(comp_high_freq_edit, 'String'));
            
            filter_names = filters.get_filter_names();
            
            if filter_type == 1
                msgbox('FFT updated with no filter applied', 'Update Complete');
            else
                if filter_type == 4 % Band Pass
                    msgbox(sprintf('FFT updated with %s filter (%.1f - %.1f kHz)', ...
                                  filter_names{filter_type}, low_freq, high_freq), 'Update Complete');
                else
                    freq_value = low_freq; % 对于高通和低通滤波器
                    msgbox(sprintf('FFT updated with %s filter (%.1f kHz)', ...
                                  filter_names{filter_type}, freq_value), 'Update Complete');
                end
            end
        end
        
        function create_timefreq_comparison(filtered_data, comp_files, selected_time_range)
            % 创建时频对比窗口（只对选择时间范围内的数据）
            tf_comp_fig = figure('Name', 'Time-Frequency Comparison', 'Position', [200, 50, 1400, 800], ...
                                'MenuBar', 'none', 'ToolBar', 'none');
            
            num_signals = length(filtered_data);
            rows = ceil(sqrt(num_signals));
            cols = ceil(num_signals / rows);
            
            for i = 1:num_signals
                subplot(rows, cols, i);
                
                signal = filtered_data{i}.signal;
                time_data = filtered_data{i}.time;
                fs_current = filtered_data{i}.fs;
                
                % 计算时频图
                window_length = round(length(signal) / 20);
                overlap = round(window_length * 0.75);
                nfft = max(256, 2^nextpow2(window_length));
                
                try
                    [S, F, T] = spectrogram(signal, hann(window_length), overlap, nfft, fs_current);
                    
                    F_kHz = F / 1000;
                    T_us = (T + time_data(1)) * 1e6;
                    
                    S_dB = 20*log10(abs(S) + eps);
                    
                    pcolor(T_us, F_kHz, S_dB);
                    shading interp;
                    colormap jet;
                    
                    xlabel('Time (μs)');
                    ylabel('Frequency (kHz)');
                    [~, name, ~] = fileparts(comp_files{i});
                    if ~isempty(selected_time_range)
                        title(sprintf('%s (%.1f-%.1f μs)', name, selected_time_range(1), selected_time_range(2)), 'Interpreter', 'none');
                    else
                        title(name, 'Interpreter', 'none');
                    end
                    
                    if i == num_signals
                        colorbar;
                    end
                    
                catch ME
                    text(0.5, 0.5, ['Error: ' ME.message], 'Units', 'normalized', ...
                         'HorizontalAlignment', 'center');
                end
            end
        end
    end
end