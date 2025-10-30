classdef wave_field_analyzer < handle
    % 波场分析器 - 提供波场可视化和分析功能
    
    methods (Static)
        function create_analysis_ui(data_xyt, data_time, fs)
            % 创建波场分析界面
            try
                % 创建分析窗口
                analysis_fig = figure('Name', 'Wave Field Analysis', 'Position', [100, 50, 1400, 800], ...
                                     'MenuBar', 'none', 'ToolBar', 'none');
                
                % 左侧控制面板
                control_panel = uipanel('Parent', analysis_fig, 'Position', [0.01, 0.01, 0.25, 0.98], ...
                                       'Title', 'Analysis Controls');
                
                % 时间控制
                uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Time Control:', ...
                          'Position', [10, 750, 100, 20], 'FontWeight', 'bold');
                
                time_slider = uicontrol('Parent', control_panel, 'Style', 'slider', ...
                                       'Position', [10, 720, 200, 20], ...
                                       'Min', 1, 'Max', length(data_time), 'Value', 1, ...
                                       'SliderStep', [1/(length(data_time)-1), 10/(length(data_time)-1)]);
                
                time_text = uicontrol('Parent', control_panel, 'Style', 'text', ...
                                     'String', sprintf('Time: %.2f μs', data_time(1)*1e6), ...
                                     'Position', [10, 695, 200, 20], ...
                                     'HorizontalAlignment', 'left');
                
                % 显示控制
                uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Display Options:', ...
                          'Position', [10, 650, 100, 20], 'FontWeight', 'bold');
                
                colormap_popup = uicontrol('Parent', control_panel, 'Style', 'popupmenu', ...
                                          'String', {'jet', 'hot', 'cool', 'gray', 'bone', 'parula'}, ...
                                          'Position', [10, 620, 150, 25]);
                
                % 滤波控制
                uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Filter Options:', ...
                          'Position', [10, 580, 100, 20], 'FontWeight', 'bold');
                
                filter_popup = uicontrol('Parent', control_panel, 'Style', 'popupmenu', ...
                                        'String', {'No Filter', 'High Pass', 'Low Pass', 'Band Pass'}, ...
                                        'Position', [10, 550, 100, 25]);
                
                uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Low Freq (kHz):', ...
                          'Position', [10, 520, 100, 20]);
                low_freq_edit = uicontrol('Parent', control_panel, 'Style', 'edit', 'String', '100', ...
                                         'Position', [110, 520, 60, 25]);
                
                uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'High Freq (kHz):', ...
                          'Position', [10, 490, 100, 20]);
                high_freq_edit = uicontrol('Parent', control_panel, 'Style', 'edit', 'String', '500', ...
                                          'Position', [110, 490, 60, 25]);
                
                uicontrol('Parent', control_panel, 'Style', 'pushbutton', 'String', 'Apply Filter', ...
                          'Position', [10, 450, 100, 30], 'BackgroundColor', [0.9 1.0 0.8], ...
                          'Callback', @apply_filter);
                
                % 动画控制
                uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Animation:', ...
                          'Position', [10, 400, 100, 20], 'FontWeight', 'bold');
                
                uicontrol('Parent', control_panel, 'Style', 'pushbutton', 'String', 'Play', ...
                          'Position', [10, 370, 60, 25], 'BackgroundColor', [0.8 1.0 0.8], ...
                          'Callback', @play_animation);
                
                uicontrol('Parent', control_panel, 'Style', 'pushbutton', 'String', 'Stop', ...
                          'Position', [80, 370, 60, 25], 'BackgroundColor', [1.0 0.8 0.8], ...
                          'Callback', @stop_animation);
                
                % 信息显示
                info_text = uicontrol('Parent', control_panel, 'Style', 'text', ...
                                     'String', sprintf('Data Info:\nSize: %dx%dx%d\nSampling: %.2f MHz\nDuration: %.2f ms', ...
                                                      size(data_xyt,1), size(data_xyt,2), size(data_xyt,3), ...
                                                      fs/1e6, (data_time(end)-data_time(1))*1000), ...
                                     'Position', [10, 250, 200, 100], ...
                                     'HorizontalAlignment', 'left', ...
                                     'BackgroundColor', [0.9 0.9 0.9]);
                
                % 点击信息显示
                click_text = uicontrol('Parent', control_panel, 'Style', 'text', ...
                                      'String', 'Click on wave field to analyze point', ...
                                      'Position', [10, 50, 200, 100], ...
                                      'HorizontalAlignment', 'left', ...
                                      'BackgroundColor', [0.9 0.9 0.9]);
                
                % 右侧显示区域
                display_panel = uipanel('Parent', analysis_fig, 'Position', [0.27, 0.01, 0.72, 0.98], ...
                                       'Title', 'Wave Field Visualization');
                
                % 波场显示轴
                wave_axes = axes('Parent', display_panel, 'Position', [0.05, 0.55, 0.9, 0.4]);
                
                % 时域信号显示轴
                time_axes = axes('Parent', display_panel, 'Position', [0.05, 0.05, 0.42, 0.4]);
                
                % 频域信号显示轴
                freq_axes = axes('Parent', display_panel, 'Position', [0.53, 0.05, 0.42, 0.4]);
                
                % 初始化变量
                current_time_idx = 1;
                filtered_data = data_xyt;
                animation_timer = [];
                
                % 初始显示
                update_wavefield();
                
                % 回调函数
                function apply_filter(~, ~)
                    filter_type = get(filter_popup, 'Value');
                    low_freq = str2double(get(low_freq_edit, 'String')) * 1000; % 转换为Hz
                    high_freq = str2double(get(high_freq_edit, 'String')) * 1000; % 转换为Hz
                    
                    try
                        if filter_type == 1 % No Filter
                            filtered_data = data_xyt;
                            msgbox('Filter removed', 'Info');
                        else
                            % 应用简单滤波（需要Signal Processing Toolbox）
                            filtered_data = apply_3d_filter(data_xyt, filter_type, low_freq, high_freq, fs);
                            msgbox('Filter applied successfully!', 'Success');
                        end
                        
                        update_wavefield();
                        
                    catch ME
                        msgbox(['Filter error: ' ME.message], 'Error', 'error');
                    end
                end
                
                function update_time(~, ~)
                    current_time_idx = round(get(time_slider, 'Value'));
                    set(time_text, 'String', sprintf('Time: %.2f μs', data_time(current_time_idx)*1e6));
                    update_wavefield();
                end
                
                function update_wavefield()
                    % 显示当前时刻的波场
                    axes(wave_axes);
                    cla;
                    
                    wave_field = squeeze(filtered_data(:, :, current_time_idx));
                    
                    imagesc(wave_field);
                    axis equal;
                    axis tight;
                    
                    % 设置颜色映射
                    colormap_names = get(colormap_popup, 'String');
                    colormap_idx = get(colormap_popup, 'Value');
                    colormap(wave_axes, colormap_names{colormap_idx});
                    colorbar(wave_axes);
                    
                    title(wave_axes, sprintf('Wave Field at t = %.2f μs', data_time(current_time_idx)*1e6));
                    xlabel(wave_axes, 'X Position');
                    ylabel(wave_axes, 'Y Position');
                    
                    % 设置点击回调
                    set(wave_axes, 'ButtonDownFcn', @wavefield_click);
                end
                
                function wavefield_click(~, ~)
                    point = get(wave_axes, 'CurrentPoint');
                    x_idx = round(point(1, 2));
                    y_idx = round(point(1, 1));
                    
                    [m_size, n_size, ~] = size(filtered_data);
                    if x_idx >= 1 && x_idx <= m_size && y_idx >= 1 && y_idx <= n_size
                        % 提取该点的时域信号
                        point_signal = squeeze(filtered_data(x_idx, y_idx, :));
                        
                        % 绘制时域信号
                        axes(time_axes);
                        cla;
                        plot(data_time * 1e6, point_signal, 'b-', 'LineWidth', 1.5);
                        title(sprintf('Time Domain Signal - Point (%d,%d)', x_idx, y_idx));
                        xlabel('Time (μs)');
                        ylabel('Amplitude');
                        grid on;
                        set(time_axes, 'ButtonDownFcn', @time_click);
                        
                        % 绘制频域信号
                        axes(freq_axes);
                        cla;
                        try
                            [freq_vector, magnitude] = compute_fft(point_signal, fs);
                            plot(freq_vector, magnitude, 'r-', 'LineWidth', 1.5);
                            title(sprintf('Frequency Spectrum - Point (%d,%d)', x_idx, y_idx));
                            xlabel('Frequency (kHz)');
                            ylabel('Magnitude');
                            grid on;
                            set(freq_axes, 'ButtonDownFcn', @freq_click);
                        catch
                            text(0.5, 0.5, 'FFT computation failed', 'Units', 'normalized', ...
                                 'HorizontalAlignment', 'center');
                        end
                        
                        % 更新点击信息
                        set(click_text, 'String', sprintf('Selected Point:\nPosition: (%d, %d)\nMax Amplitude: %.2e\nRMS: %.2e', ...
                                                         x_idx, y_idx, max(abs(point_signal)), rms(point_signal)));
                    end
                end
                
                function time_click(~, ~)
                    point = get(time_axes, 'CurrentPoint');
                    x_coord = point(1, 1); % 时间 (μs)
                    y_coord = point(1, 2); % 幅值
                    
                    set(click_text, 'String', sprintf('Time Domain Click:\nTime: %.2f μs\nAmplitude: %.4e', ...
                                                     x_coord, y_coord));
                end
                
                function freq_click(~, ~)
                    point = get(freq_axes, 'CurrentPoint');
                    x_coord = point(1, 1); % 频率 (kHz)
                    y_coord = point(1, 2); % 幅值
                    
                    set(click_text, 'String', sprintf('Frequency Domain Click:\nFrequency: %.1f kHz\nMagnitude: %.2e', ...
                                                     x_coord, y_coord));
                end
                
                function play_animation(~, ~)
                    if ~isempty(animation_timer)
                        stop(animation_timer);
                        delete(animation_timer);
                    end
                    
                    animation_timer = timer('ExecutionMode', 'fixedRate', 'Period', 0.1, ...
                                           'TimerFcn', @animate_frame);
                    start(animation_timer);
                end
                
                function stop_animation(~, ~)
                    if ~isempty(animation_timer)
                        stop(animation_timer);
                        delete(animation_timer);
                        animation_timer = [];
                    end
                end
                
                function animate_frame(~, ~)
                    current_time_idx = current_time_idx + 1;
                    if current_time_idx > length(data_time)
                        current_time_idx = 1;
                    end
                    
                    set(time_slider, 'Value', current_time_idx);
                    set(time_text, 'String', sprintf('Time: %.2f μs', data_time(current_time_idx)*1e6));
                    update_wavefield();
                end
                
                % 设置回调函数
                set(time_slider, 'Callback', @update_time);
                set(colormap_popup, 'Callback', @(~,~) update_wavefield());
                
                % 清理函数
                set(analysis_fig, 'CloseRequestFcn', @cleanup_and_close);
                
                function cleanup_and_close(~, ~)
                    if ~isempty(animation_timer)
                        stop(animation_timer);
                        delete(animation_timer);
                    end
                    delete(analysis_fig);
                end
                
            catch ME
                msgbox(['波场分析创建失败: ' ME.message], 'Error', 'error');
            end
        end
    end
end

% 辅助函数
function filtered_data = apply_3d_filter(data_xyt, filter_type, low_freq, high_freq, fs)
    % 对3D数据应用滤波器
    [m, n, t] = size(data_xyt);
    filtered_data = zeros(size(data_xyt));
    
    for i = 1:m
        for j = 1:n
            signal = squeeze(data_xyt(i, j, :));
            filtered_data(i, j, :) = apply_1d_filter(signal, filter_type, low_freq, high_freq, fs);
        end
    end
end

function filtered_signal = apply_1d_filter(signal, filter_type, low_freq, high_freq, fs)
    % 对1D信号应用滤波器
    try
        nyquist = fs / 2;
        
        switch filter_type
            case 2 % High Pass
                low_norm = low_freq / nyquist;
                [b, a] = butter(4, low_norm, 'high');
            case 3 % Low Pass
                high_norm = high_freq / nyquist;
                [b, a] = butter(4, high_norm, 'low');
            case 4 % Band Pass
                low_norm = low_freq / nyquist;
                high_norm = high_freq / nyquist;
                [b, a] = butter(4, [low_norm, high_norm], 'bandpass');
            otherwise
                filtered_signal = signal;
                return;
        end
        
        filtered_signal = filtfilt(b, a, signal);
        
    catch
        filtered_signal = signal; % 如果滤波失败，返回原信号
    end
end

function [freq_vector, magnitude] = compute_fft(signal, fs)
    % 计算FFT
    N = length(signal);
    Y = fft(signal);
    freq_vector = (0:N-1) * fs / N / 1000; % 转换为 kHz
    magnitude = abs(Y);
    
    % 只返回前半部分（正频率）
    freq_vector = freq_vector(1:floor(N/2));
    magnitude = magnitude(1:floor(N/2));
end
