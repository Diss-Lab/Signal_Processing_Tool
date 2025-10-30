classdef visualizer < handle
    % 可视化模块 - 负责各种图形绘制和时频分析
    
    methods (Static)
        function [freq_vector, magnitude] = compute_fft(signal, fs)
            % 计算FFT
            % 输入: signal - 信号, fs - 采样频率
            % 输出: freq_vector - 频率向量(kHz), magnitude - 幅值
            
            N = length(signal);
            Y = fft(signal);
            freq_vector = (0:N-1) * fs / N / 1000; % 转换为 kHz
            magnitude = abs(Y);
            
            % 只返回前半部分（正频率）
            freq_vector = freq_vector(1:floor(N/2));
            magnitude = magnitude(1:floor(N/2));
        end
        
        function peak_info = find_frequency_peaks(freq_vector, magnitude)
            % 查找频率峰值
            % 输入: freq_vector - 频率向量, magnitude - 幅值
            % 输出: peak_info - 峰值信息字符串
            
            peak_info = '';
            
            try
                % 找到峰值
                min_peak_distance = max(10, round(length(magnitude) / 100));
                [peaks, locs] = findpeaks(magnitude, 'MinPeakHeight', max(magnitude)*0.1, ...
                                         'MinPeakDistance', min_peak_distance, 'SortStr', 'descend');
                
                if length(peaks) >= 1
                    peak_info = sprintf('Highest Peak: %.1f kHz', freq_vector(locs(1)));
                end
                if length(peaks) >= 2
                    peak_info = [peak_info, sprintf('\nSecond Peak: %.1f kHz', freq_vector(locs(2)))];
                end
            catch
                % 如果findpeaks函数不可用，跳过峰值检测
            end
        end
        
        function create_timefreq_window(signal, time_data, fs)
            % 创建时频分析窗口
            % 输入: signal - 信号, time_data - 时间数据, fs - 采样频率
            
            % 创建时频分析窗口
            tf_fig = figure('Name', 'Time-Frequency Analysis', 'Position', [300, 100, 900, 650], ...
                           'MenuBar', 'none', 'ToolBar', 'none');
            
            % 计算短时傅里叶变换
            window_length = round(length(signal) / 20);
            overlap = round(window_length * 0.75);
            nfft = max(256, 2^nextpow2(window_length));
            
            % 使用汉宁窗
            window = hann(window_length);
            
            try
                [S, F, T] = spectrogram(signal, window, overlap, nfft, fs);
                
                % 转换单位
                F_kHz = F / 1000;
                T_us = (T + time_data(1)) * 1e6;
                
                % 计算幅值矩阵并进行平滑处理
                S_magnitude = abs(S);
                S_dB = 20*log10(S_magnitude + eps); % 加eps避免log(0)
                
                % 对时频图进行平滑处理
                S_dB_smooth = visualizer.smooth_spectrogram(S_dB);
                
                % 创建主轴和信息显示区域
                main_axes = axes('Parent', tf_fig, 'Position', [0.1, 0.15, 0.75, 0.75]);
                
                % 使用pcolor进行伪颜色映射显示
                h_timefreq = pcolor(main_axes, T_us, F_kHz, S_dB_smooth);
                shading(main_axes, 'interp');
                axis(main_axes, 'tight');
                colormap(main_axes, jet);
                
                % 设置颜色条
                h_colorbar = colorbar(main_axes);
                ylabel(h_colorbar, 'Magnitude (dB)', 'FontSize', 12);
                
                xlabel(main_axes, 'Time (μs)', 'FontSize', 12);
                ylabel(main_axes, 'Frequency (kHz)', 'FontSize', 12);
                title(main_axes, 'Time-Frequency Spectrogram', 'FontSize', 14);
                
                % 找到峰值信息
                [peak_info_str, tf_click_text] = visualizer.create_timefreq_info_panel(tf_fig, S_magnitude, F_kHz, T_us);
                
                % 设置点击功能
                set(h_timefreq, 'ButtonDownFcn', @(~,~) visualizer.timefreq_click(main_axes, F_kHz, T_us, S_dB_smooth, tf_click_text));
                set(main_axes, 'ButtonDownFcn', @(~,~) visualizer.timefreq_click(main_axes, F_kHz, T_us, S_dB_smooth, tf_click_text));
                
            catch ME
                msgbox(['Time-frequency analysis error: ' ME.message], 'Error', 'error');
            end
        end
        
        function S_dB_smooth = smooth_spectrogram(S_dB)
            % 平滑时频图
            if size(S_dB, 1) > 3 && size(S_dB, 2) > 3
                % 使用2D高斯滤波器进行平滑
                sigma = 1.0; % 平滑参数
                try
                    S_dB_smooth = imgaussfilt(S_dB, sigma);
                catch
                    % 如果没有imgaussfilt函数，使用原始数据
                    S_dB_smooth = S_dB;
                end
            else
                S_dB_smooth = S_dB;
            end
        end
        
        function [peak_info_str, tf_click_text] = create_timefreq_info_panel(tf_fig, S_magnitude, F_kHz, T_us)
            % 创建时频分析信息面板
            
            % 找到最大和第二大幅值位置
            [max_val, max_idx] = max(S_magnitude(:));
            [max_row, max_col] = ind2sub(size(S_magnitude), max_idx);
            max_freq = F_kHz(max_row);
            max_time = T_us(max_col);
            
            S_temp = S_magnitude;
            exclude_freq_range = max(1, round(length(F_kHz) * 0.05));
            exclude_time_range = max(1, round(length(T_us) * 0.05));
            
            row_start = max(1, max_row - exclude_freq_range);
            row_end = min(size(S_temp, 1), max_row + exclude_freq_range);
            col_start = max(1, max_col - exclude_time_range);
            col_end = min(size(S_temp, 2), max_col + exclude_time_range);
            
            S_temp(row_start:row_end, col_start:col_end) = 0;
            
            [second_max_val, second_max_idx] = max(S_temp(:));
            [second_max_row, second_max_col] = ind2sub(size(S_temp), second_max_idx);
            second_max_freq = F_kHz(second_max_row);
            second_max_time = T_us(second_max_col);
            
            % 创建信息显示区域
            % 调整信息面板位置（Units 使用 normalized；[left bottom width height]）
            % 需要改变显示位置时，仅修改 info_panel_pos 数组即可
            info_panel_pos = [0.85, 0.12, 0.14, 0.78];  % ← 按需调整
            info_panel = uipanel('Parent', tf_fig, ...
                                 'Units', 'normalized', ...
                                 'Position', info_panel_pos, ...
                                 'Title', 'Information');

            % 峰值信息显示文本（内容）
            peak_info_str = sprintf('Peak Values:\n\nMax:(%.1f μs, %.1f kHz)\n\n2nd Max:(%.1f μs, %.1f kHz)', ...
                                    max_time, max_freq, second_max_val, second_max_freq);

            peak_info_text = uicontrol('Parent', info_panel, 'Style', 'text', ...
                                      'String', peak_info_str, ...
                                      'Position', [5, 200, 100, 120], ...
                                      'HorizontalAlignment', 'left', ...
                                      'FontSize', 9);
            set(peak_info_text, 'Units', 'pixels');

            % 点击信息显示
            tf_click_text = uicontrol('Parent', info_panel, 'Style', 'text', ...
                                     'String', 'Click on spectrogram to see coordinates', ...
                                     'Position', [5, 50, 120, 110], ...
                                     'HorizontalAlignment', 'left', ...
                                     'FontSize', 9, ...
                                     'BackgroundColor', [0.9 0.9 0.9]);
        end
        
        function timefreq_click(main_axes, F_kHz, T_us, S_dB_smooth, tf_click_text)
            % 时频图点击回调函数
            if ishandle(main_axes)
                point = get(main_axes, 'CurrentPoint');
                time_coord = point(1, 1); % 时间 (μs)
                freq_coord = point(1, 2); % 频率 (kHz)
                
                % 找到最接近的数据点的幅值
                [~, time_idx] = min(abs(T_us - time_coord));
                [~, freq_idx] = min(abs(F_kHz - freq_coord));
                
                if time_idx <= size(S_dB_smooth, 2) && freq_idx <= size(S_dB_smooth, 1)
                    magnitude_val = S_dB_smooth(freq_idx, time_idx);
                    
                    click_info = sprintf('Time-Frequency Click:\n\nTime: %.1f μs\nFrequency: %.1f kHz\nMagnitude: %.1f dB', ...
                                        time_coord, freq_coord, magnitude_val);
                    if ishandle(tf_click_text)
                        set(tf_click_text, 'String', click_info);
                    end
                end
            end
        end
    end
end
