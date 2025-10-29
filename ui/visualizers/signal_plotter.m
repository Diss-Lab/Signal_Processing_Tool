classdef signal_plotter < handle
    % 统一信号绘图器 - 整合A/B/C模块的所有可视化功能
    % 
    % 功能:
    %   - 时域信号绘图
    %   - 频域信号绘图
    %   - 时频图绘图
    %   - 波场2D可视化
    %   - 多信号叠加
    %   - 幅值曲线绘图
    %
    % 使用示例:
    %   signal_plotter.plot_time_domain(axes_handle, signal_data);
    %   signal_plotter.plot_frequency_domain(axes_handle, signal_data);
    %
    % 版本: 1.0
    % 作者: 重构团队
    % 日期: 2024
    
    methods (Static)
        %% 基础绘图方法
        
        function plot_time_domain(axes_handle, signal_data, options)
            % 绘制时域信号
            %
            % 输入:
            %   axes_handle - 轴句柄
            %   signal_data - SignalData对象 或 结构体{.time, .signal}
            %   options - 可选参数
            %       .color - 线条颜色 (默认: 'b')
            %       .linewidth - 线宽 (默认: 1.5)
            %       .title - 标题 (默认: 'Time Domain Signal')
            %       .xlabel - x轴标签 (默认: 'Time (μs)')
            %       .ylabel - y轴标签 (默认: 'Amplitude')
            %       .grid - 是否显示网格 (默认: true)
            %       .click_callback - 点击回调函数
            
            arguments
                axes_handle
                signal_data
                options.color = 'b'
                options.linewidth (1,1) double = 1.5
                options.title (1,:) char = 'Time Domain Signal'
                options.xlabel (1,:) char = 'Time (μs)'
                options.ylabel (1,:) char = 'Amplitude'
                options.grid (1,1) logical = true
                options.click_callback = []
            end
            
            % 提取数据
            [time_us, signal] = signal_plotter.extract_time_signal(signal_data);
            
            % 绘图
            axes(axes_handle);
            cla;
            h = plot(time_us, signal, options.color, 'LineWidth', options.linewidth);
            
            % 设置标签
            xlabel(options.xlabel, 'FontSize', 12);
            ylabel(options.ylabel, 'FontSize', 12);
            title(options.title, 'FontSize', 14);
            
            if options.grid
                grid on;
            end
            
            % 设置点击回调
            if ~isempty(options.click_callback)
                set(h, 'ButtonDownFcn', options.click_callback);
                set(axes_handle, 'ButtonDownFcn', options.click_callback);
            end
        end
        
        function plot_frequency_domain(axes_handle, signal_data, options)
            % 绘制频域信号
            %
            % 输入:
            %   axes_handle - 轴句柄
            %   signal_data - SignalData对象 或 结构体
            %   options - 可选参数
            %       .color - 线条颜色 (默认: 'r')
            %       .linewidth - 线宽 (默认: 1.5)
            %       .title - 标题
            %       .show_peaks - 是否显示峰值 (默认: false)
            %       .peak_config - 峰值配置结构体
            %       .click_callback - 点击回调函数
            
            arguments
                axes_handle
                signal_data
                options.color = 'r'
                options.linewidth (1,1) double = 1.5
                options.title (1,:) char = 'Frequency Spectrum'
                options.show_peaks (1,1) logical = false
                options.peak_config = struct()
                options.click_callback = []
            end
            
            % 提取数据并计算FFT
            [signal, fs] = signal_plotter.extract_signal_and_fs(signal_data);
            [freq_kHz, magnitude] = fft_analyzer.compute(signal, fs, 'freq_unit', 'kHz');
            
            % 绘图
            axes(axes_handle);
            cla;
            h = plot(freq_kHz, magnitude, options.color, 'LineWidth', options.linewidth);
            
            xlabel('Frequency (kHz)', 'FontSize', 12);
            ylabel('Magnitude', 'FontSize', 12);
            title(options.title, 'FontSize', 14);
            grid on;
            
            % 显示峰值
            if options.show_peaks
                hold on;
                peaks = fft_analyzer.find_peaks(freq_kHz, magnitude, options.peak_config);
                for i = 1:length(peaks)
                    plot(peaks(i).frequency, peaks(i).magnitude, 'ro', ...
                         'MarkerSize', 8, 'MarkerFaceColor', 'r');
                    text(peaks(i).frequency, peaks(i).magnitude, ...
                         sprintf(' %.1f kHz', peaks(i).frequency), ...
                         'VerticalAlignment', 'bottom');
                end
                hold off;
            end
            
            % 设置点击回调
            if ~isempty(options.click_callback)
                set(h, 'ButtonDownFcn', options.click_callback);
                set(axes_handle, 'ButtonDownFcn', options.click_callback);
            end
        end
        
        function plot_timefreq(axes_handle, signal_data, options)
            % 绘制时频图
            %
            % 输入:
            %   axes_handle - 轴句柄
            %   signal_data - SignalData对象
            %   options - 可选参数
            %       .colormap_name - 颜色映射 (默认: 'jet')
            %       .smooth_sigma - 平滑参数 (默认: 1.0)
            %       .db_scale - 是否使用dB刻度 (默认: true)
            %       .show_colorbar - 是否显示颜色条 (默认: true)
            %       .click_callback - 点击回调函数
            
            arguments
                axes_handle
                signal_data
                options.colormap_name (1,:) char = 'jet'
                options.smooth_sigma (1,1) double = 1.0
                options.db_scale (1,1) logical = true
                options.show_colorbar (1,1) logical = true
                options.click_callback = []
            end
            
            % 提取数据
            [signal, fs] = signal_plotter.extract_signal_and_fs(signal_data);
            
            % 计算STFT
            [S, F, T] = timefreq_analyzer.compute_stft(signal, fs);
            
            % 平滑
            S_smooth = timefreq_analyzer.smooth_spectrogram(abs(S), ...
                'sigma', options.smooth_sigma);
            
            % 转换为dB
            if options.db_scale
                S_plot = timefreq_analyzer.magnitude_to_dB(S_smooth);
                ylabel_str = 'Magnitude (dB)';
            else
                S_plot = S_smooth;
                ylabel_str = 'Magnitude';
            end
            
            % 绘图
            axes(axes_handle);
            cla;
            h = pcolor(T, F, S_plot);
            shading(axes_handle, 'interp');
            axis(axes_handle, 'tight');
            
            % 设置颜色映射
            colormap(axes_handle, options.colormap_name);
            
            if options.show_colorbar
                h_colorbar = colorbar(axes_handle);
                ylabel(h_colorbar, ylabel_str, 'FontSize', 12);
            end
            
            xlabel('Time (μs)', 'FontSize', 12);
            ylabel('Frequency (kHz)', 'FontSize', 12);
            title('Time-Frequency Spectrogram', 'FontSize', 14);
            
            % 设置点击回调
            if ~isempty(options.click_callback)
                set(h, 'ButtonDownFcn', options.click_callback);
                set(axes_handle, 'ButtonDownFcn', options.click_callback);
            end
        end
        
        %% 专用绘图方法
        
        function plot_wavefield_2d(axes_handle, wavefield_data, time_idx, options)
            % 绘制波场2D伪彩色图
            %
            % 输入:
            %   axes_handle - 轴句柄
            %   wavefield_data - SignalData对象 (type='wavefield')
            %   time_idx - 时间索引
            %   options - 可选参数
            %       .colormap_name - 颜色映射 (默认: 'jet')
            %       .show_colorbar - 是否显示颜色条 (默认: true)
            %       .click_callback - 点击回调函数
            
            arguments
                axes_handle
                wavefield_data
                time_idx (1,1) double {mustBePositive, mustBeInteger}
                options.colormap_name (1,:) char = 'jet'
                options.show_colorbar (1,1) logical = true
                options.click_callback = []
            end
            
            % 提取指定时刻的波场
            wave_slice = squeeze(wavefield_data.data(:, :, time_idx));
            time_val = wavefield_data.time(time_idx);
            
            % 绘图
            axes(axes_handle);
            cla;
            imagesc(wave_slice);
            axis equal tight;
            colormap(axes_handle, options.colormap_name);
            
            if options.show_colorbar
                colorbar(axes_handle);
            end
            
            title(sprintf('Wave Field at %.2f μs', time_val * 1e6), 'FontSize', 14);
            xlabel('Width (pixels)', 'FontSize', 12);
            ylabel('Height (pixels)', 'FontSize', 12);
            
            % 设置点击回调
            if ~isempty(options.click_callback)
                set(axes_handle, 'ButtonDownFcn', options.click_callback);
                set(get(axes_handle, 'Children'), 'ButtonDownFcn', options.click_callback);
            end
        end
        
        function plot_multi_signals(axes_handle, signal_data_array, options)
            % 绘制多信号叠加图
            %
            % 输入:
            %   axes_handle - 轴句柄
            %   signal_data_array - SignalData对象的cell数组
            %   options - 可选参数
            %       .legends - 图例cell数组
            %       .highlight_range - 高亮时间范围 [start, end] (μs)
            %       .colormap_name - 颜色映射 (默认: 'lines')
            
            arguments
                axes_handle
                signal_data_array cell
                options.legends cell = {}
                options.highlight_range double = []  % 修复：移除大小限制，允许空数组
                options.colormap_name (1,:) char = 'lines'
            end
            
            axes(axes_handle);
            cla;
            hold on;
            
            num_signals = length(signal_data_array);
            colors = feval(options.colormap_name, num_signals);
            
            % 如果需要高亮时间范围，先绘制背景
            if ~isempty(options.highlight_range) && length(options.highlight_range) == 2  % 修复：添加长度检查
                ylims = signal_plotter.get_multi_signal_ylim(signal_data_array);
                fill([options.highlight_range(1), options.highlight_range(2), ...
                      options.highlight_range(2), options.highlight_range(1)], ...
                     [ylims(1), ylims(1), ylims(2), ylims(2)], ...
                     [1, 1, 0], 'FaceAlpha', 0.2, 'EdgeColor', 'none');
            end
            
            % 绘制所有信号
            for i = 1:num_signals
                [time_us, signal] = signal_plotter.extract_time_signal(signal_data_array{i});
                plot(time_us, signal, 'Color', colors(i, :), 'LineWidth', 1.5);
            end
            
            xlabel('Time (μs)', 'FontSize', 12);
            ylabel('Amplitude', 'FontSize', 12);
            title(sprintf('Multi-Signal Comparison (%d signals)', num_signals), 'FontSize', 14);
            grid on;
            hold off;
            
            % 添加图例
            if ~isempty(options.legends)
                legend(options.legends, 'Location', 'best');
            end
        end
        
        function plot_amplitude_curve(axes_handle, amplitudes, positions, options)
            % 绘制幅值曲线图
            %
            % 输入:
            %   axes_handle - 轴句柄
            %   amplitudes - 幅值数组
            %   positions - 位置数组 (可选，默认1:N)
            %   options - 可选参数
            %       .marker_style - 标记样式 (默认: 'o')
            %       .line_color - 线条颜色 (默认: 'b')
            %       .show_values - 是否显示数值标注 (默认: false)
            %       .title - 标题
            %       .xlabel - x轴标签
            %       .ylabel - y轴标签
            
            arguments
                axes_handle
                amplitudes (:,1) double
                positions (:,1) double = (1:length(amplitudes))'
                options.marker_style (1,:) char = 'o'
                options.line_color (1,:) char = 'b'
                options.show_values (1,1) logical = false
                options.title (1,:) char = 'Amplitude Curve'
                options.xlabel (1,:) char = 'Position'
                options.ylabel (1,:) char = 'Amplitude'
            end
            
            axes(axes_handle);
            cla;
            
            % 绘图
            plot(positions, amplitudes, ...
                [options.line_color, '-', options.marker_style], ...
                'LineWidth', 2, 'MarkerSize', 6, ...
                'MarkerFaceColor', options.line_color);
            
            xlabel(options.xlabel, 'FontSize', 12);
            ylabel(options.ylabel, 'FontSize', 12);
            title(options.title, 'FontSize', 14);
            grid on;
            
            % 显示数值标注
            if options.show_values && length(amplitudes) <= 20
                for i = 1:length(amplitudes)
                    text(positions(i), amplitudes(i), sprintf('%.3e', amplitudes(i)), ...
                         'HorizontalAlignment', 'center', ...
                         'VerticalAlignment', 'bottom', ...
                         'FontSize', 8);
                end
            end
            
            % 显示统计信息
            mean_amp = mean(amplitudes);
            std_amp = std(amplitudes);
            stats_text = sprintf('Mean: %.3e\nStd: %.3e', mean_amp, std_amp);
            text(0.02, 0.98, stats_text, 'Units', 'normalized', ...
                 'VerticalAlignment', 'top', 'BackgroundColor', 'white', ...
                 'FontSize', 10);
        end
        
        %% 辅助功能方法
        
        function add_time_range_marker(axes_handle, time_range, options)
            % 添加时间范围标记
            %
            % 输入:
            %   axes_handle - 轴句柄
            %   time_range - 时间范围 [start, end] (μs)
            %   options - 可选参数
            %       .color - 标记颜色 (默认: [1, 1, 0])
            %       .alpha - 透明度 (默认: 0.2)
            
            arguments
                axes_handle
                time_range (1,2) double
                options.color (1,3) double = [1, 1, 0]
                options.alpha (1,1) double = 0.2
            end
            
            axes(axes_handle);
            hold on;
            
            ylims = ylim;
            fill([time_range(1), time_range(2), time_range(2), time_range(1)], ...
                 [ylims(1), ylims(1), ylims(2), ylims(2)], ...
                 options.color, 'FaceAlpha', options.alpha, 'EdgeColor', 'none');
            
            hold off;
        end
        
        function add_peak_markers(axes_handle, peaks, options)
            % 添加峰值标记
            %
            % 输入:
            %   axes_handle - 轴句柄
            %   peaks - 峰值结构体数组 (from fft_analyzer.find_peaks)
            %   options - 可选参数
            %       .marker_color - 标记颜色 (默认: 'r')
            %       .marker_size - 标记大小 (默认: 8)
            %       .show_labels - 是否显示标签 (默认: true)
            
            arguments
                axes_handle
                peaks struct
                options.marker_color (1,:) char = 'r'
                options.marker_size (1,1) double = 8
                options.show_labels (1,1) logical = true
            end
            
            axes(axes_handle);
            hold on;
            
            for i = 1:length(peaks)
                plot(peaks(i).frequency, peaks(i).magnitude, ...
                     [options.marker_color, 'o'], ...
                     'MarkerSize', options.marker_size, ...
                     'MarkerFaceColor', options.marker_color);
                
                if options.show_labels
                    text(peaks(i).frequency, peaks(i).magnitude, ...
                         sprintf(' %.1f kHz', peaks(i).frequency), ...
                         'VerticalAlignment', 'bottom');
                end
            end
            
            hold off;
        end
        
        function setup_click_callback(axes_handle, callback_type, callback_data)
            % 设置点击回调
            %
            % 输入:
            %   axes_handle - 轴句柄
            %   callback_type - 回调类型 'time', 'freq', 'timefreq', 'wavefield'
            %   callback_data - 回调所需数据结构体
            %       .info_text - 信息显示文本框句柄
            %       .freq_vector - 频率向量 (for freq)
            %       .time_vector - 时间向量 (for timefreq)
            %       .signal_data - SignalData对象 (for wavefield)
            
            arguments
                axes_handle
                callback_type (1,:) char
                callback_data struct
            end
            
            switch callback_type
                case 'time'
                    callback_func = @(~,~) signal_plotter.time_click_handler(...
                        axes_handle, callback_data.info_text);
                    
                case 'freq'
                    callback_func = @(~,~) signal_plotter.freq_click_handler(...
                        axes_handle, callback_data.info_text);
                    
                case 'timefreq'
                    callback_func = @(~,~) signal_plotter.timefreq_click_handler(...
                        axes_handle, callback_data.info_text, ...
                        callback_data.freq_vector, callback_data.time_vector);
                    
                case 'wavefield'
                    callback_func = @(~,~) signal_plotter.wavefield_click_handler(...
                        axes_handle, callback_data.signal_data, callback_data.info_text);
                    
                otherwise
                    error('signal_plotter:setup_click_callback', ...
                          'Unknown callback type: %s', callback_type);
            end
            
            set(axes_handle, 'ButtonDownFcn', callback_func);
        end
        
        %% 私有辅助方法
        
    end
    
    methods (Static, Access = private)
        function [time_us, signal] = extract_time_signal(signal_data)
            % 提取时域信号数据
            if isa(signal_data, 'SignalData')
                signal = signal_data.get_point(1, 1);
                time_us = signal_data.time * 1e6;
            else
                % 假设是结构体 {.time, .signal}
                time_us = signal_data.time * 1e6;
                signal = signal_data.signal;
            end
        end
        
        function [signal, fs] = extract_signal_and_fs(signal_data)
            % 提取信号和采样率
            if isa(signal_data, 'SignalData')
                signal = signal_data.get_point(1, 1);
                fs = signal_data.fs;
            else
                signal = signal_data.signal;
                fs = signal_data.fs;
            end
        end
        
        function ylims = get_multi_signal_ylim(signal_data_array)
            % 计算多信号的y轴范围
            all_signals = [];
            for i = 1:length(signal_data_array)
                [~, signal] = signal_plotter.extract_time_signal(signal_data_array{i});
                all_signals = [all_signals; signal];
            end
            ylims = [min(all_signals), max(all_signals)];
            ylims = ylims + [-1, 1] * (ylims(2) - ylims(1)) * 0.1;
        end
        
        function time_click_handler(axes_handle, info_text)
            % 时域点击处理
            point = get(axes_handle, 'CurrentPoint');
            time_coord = point(1, 1);
            amp_coord = point(1, 2);
            
            if ~isempty(info_text) && ishandle(info_text)
                set(info_text, 'String', ...
                    sprintf('Time: %.2f μs\nAmplitude: %.4e', time_coord, amp_coord));
            end
        end
        
        function freq_click_handler(axes_handle, info_text)
            % 频域点击处理
            point = get(axes_handle, 'CurrentPoint');
            freq_coord = point(1, 1);
            mag_coord = point(1, 2);
            
            if ~isempty(info_text) && ishandle(info_text)
                set(info_text, 'String', ...
                    sprintf('Frequency: %.1f kHz\nMagnitude: %.2e', freq_coord, mag_coord));
            end
        end
        
        function timefreq_click_handler(axes_handle, info_text, freq_vector, time_vector)
            % 时频图点击处理
            point = get(axes_handle, 'CurrentPoint');
            time_coord = point(1, 1);
            freq_coord = point(1, 2);
            
            if ~isempty(info_text) && ishandle(info_text)
                set(info_text, 'String', ...
                    sprintf('Time: %.1f μs\nFrequency: %.1f kHz', time_coord, freq_coord));
            end
        end
        
        function wavefield_click_handler(axes_handle, signal_data, info_text)
            % 波场点击处理
            point = get(axes_handle, 'CurrentPoint');
            x_idx = round(point(1, 2));
            y_idx = round(point(1, 1));
            
            [m, n, ~] = size(signal_data.data);
            if x_idx >= 1 && x_idx <= m && y_idx >= 1 && y_idx <= n
                point_signal = signal_data.get_point(x_idx, y_idx);
                max_amp = max(abs(point_signal));
                
                if ~isempty(info_text) && ishandle(info_text)
                    set(info_text, 'String', ...
                        sprintf('Position: (%d, %d)\nMax Amplitude: %.2e', ...
                        x_idx, y_idx, max_amp));
                end
            end
        end
    end
end
