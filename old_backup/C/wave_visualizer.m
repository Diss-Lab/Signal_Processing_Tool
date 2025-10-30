classdef wave_visualizer < handle
    % 波场可视化模块 - 负责波场和信号的可视化
    
    methods (Static)
        function plot_wavefield(wave_axes, filtered_data, time_idx, data_time, click_callback)
            % 绘制波场图
            % 输入: wave_axes - 轴句柄, filtered_data - 滤波后数据, time_idx - 时间索引, data_time - 时间数据, click_callback - 点击回调
            
            axes(wave_axes);
            imagesc(squeeze(filtered_data(:, :, time_idx)));
            colorbar;
            axis equal tight;
            title(sprintf('Wave Field at %.2f ms', data_time(time_idx)*1000));
            xlabel('Width (pixels)');
            ylabel('Height (pixels)');
            
            % 设置点击回调
            set(wave_axes, 'ButtonDownFcn', click_callback);
            set(get(wave_axes, 'Children'), 'ButtonDownFcn', click_callback);
        end
        
        function plot_point_analysis(time_axes, freq_axes, point_signal, data_time, fs, x_idx, y_idx, time_click_callback, freq_click_callback)
            % 绘制点分析图（时域和频域）
            
            % 绘制时域信号
            axes(time_axes);
            h_time = plot(data_time * 1e6, point_signal);
            title(sprintf('Time Signal at Point (%d, %d)', x_idx, y_idx));
            xlabel('Time (μs)');
            ylabel('Amplitude');
            grid on;
            set(time_axes, 'ButtonDownFcn', time_click_callback);
            set(h_time, 'ButtonDownFcn', time_click_callback);
            
            % 计算并绘制频谱
            axes(freq_axes);
            [freq_vector, magnitude] = wave_visualizer.compute_fft(point_signal, fs);
            
            h_freq = plot(freq_vector, magnitude);
            title(sprintf('Frequency Spectrum at Point (%d, %d)', x_idx, y_idx));
            xlabel('Frequency (kHz)');
            ylabel('Magnitude');
            grid on;
            set(freq_axes, 'ButtonDownFcn', freq_click_callback);
            set(h_freq, 'ButtonDownFcn', freq_click_callback);
        end
        
        function [freq_vector, magnitude] = compute_fft(signal, fs)
            % 计算FFT
            % 输入: signal - 信号, fs - 采样频率
            % 输出: freq_vector - 频率向量(kHz), magnitude - 幅值
            
            N = length(signal);
            fft_signal = fft(signal);
            freq_vector = (0:N-1) * fs / N / 1000; % 转换为 kHz
            magnitude = abs(fft_signal);
            
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
                    peak_freqs = freq_vector(locs);
                    peak_info = sprintf('Peak Frequencies: %s kHz', sprintf('%.1f ', peak_freqs));
                end
            catch
                % 如果findpeaks函数不可用，跳过峰值检测
            end
        end
        
        function update_point_info(info_text, point_signal, x_idx, y_idx, fs)
            % 更新点信息显示
            
            % 计算峰值信息
            [freq_vector, magnitude] = wave_visualizer.compute_fft(point_signal, fs);
            peak_info = wave_visualizer.find_frequency_peaks(freq_vector, magnitude);
            
            % 更新信息显示
            info_str = sprintf('Analyzing Point: (%d, %d)\nMax Amplitude: %.4f\nSampling Rate: %.2f MHz', ...
                              x_idx, y_idx, max(abs(point_signal)), fs/1e6);
            
            if ~isempty(peak_info)
                info_str = [info_str, sprintf('\n\n%s', peak_info)];
            end
            
            set(info_text, 'String', info_str);
        end
    end
end
