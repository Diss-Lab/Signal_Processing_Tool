classdef b_scan_processor < handle
    % B扫数据处理器 - 处理多个TXT文件并生成data.mat
    
    methods (Static)
        function [success, processed_data] = process_folder(folder_path)
            % 处理文件夹中的TXT文件
            success = false;
            processed_data = struct();
            
            try
                % 检查文件夹
                if ~exist(folder_path, 'dir')
                    error('文件夹不存在: %s', folder_path);
                end
                
                % 查找所有编号的TXT文件
                txt_files = [];
                max_file_num = 0;
                
                % 搜索1.txt, 2.txt, ... 格式的文件
                for i = 1:1000  % 假设最多1000个文件
                    file_path = fullfile(folder_path, sprintf('%d.txt', i));
                    if exist(file_path, 'file')
                        txt_files{end+1} = file_path;
                        max_file_num = i;
                    end
                end
                
                if isempty(txt_files)
                    error('未找到编号的TXT文件 (1.txt, 2.txt, ...)');
                end
                
                fprintf('找到 %d 个TXT文件\n', length(txt_files));
                
                % 读取第一个文件获取时间信息
                first_data = b_scan_processor.load_single_txt(txt_files{1});
                data_time = first_data.time;
                time_points = length(data_time);
                fs = first_data.fs;
                
                % 初始化数据矩阵 [1 x file_count x time_points]
                file_count = length(txt_files);
                data_xyt = zeros(1, file_count, time_points);
                
                % 加载所有文件
                h_wait = waitbar(0, 'Loading TXT files...');
                for i = 1:file_count
                    try
                        file_data = b_scan_processor.load_single_txt(txt_files{i});
                        
                        % 确保时间长度一致
                        if length(file_data.signal) == time_points
                            data_xyt(1, i, :) = file_data.signal;
                        else
                            % 处理长度不一致的情况
                            min_len = min(length(file_data.signal), time_points);
                            data_xyt(1, i, 1:min_len) = file_data.signal(1:min_len);
                        end
                        
                    catch ME
                        warning('加载文件失败: %s, 错误: %s', txt_files{i}, ME.message);
                    end
                    
                    waitbar(i/file_count, h_wait);
                end
                close(h_wait);
                
                % 保存data.mat文件
                save_path = fullfile(folder_path, 'data.mat');
                save(save_path, 'data_xyt', 'data_time', 'fs');
                
                % 返回处理结果
                processed_data.data_xyt = data_xyt;
                processed_data.data_time = data_time;
                processed_data.fs = fs;
                processed_data.file_count = file_count;
                
                success = true;
                fprintf('数据处理完成，保存到: %s\n', save_path);
                
            catch ME
                fprintf('处理失败: %s\n', ME.message);
            end
        end
        
        function data = load_single_txt(file_path)
            % 加载单个TXT文件
            try
                % 尝试不同的读取方式
                if exist('readmatrix', 'file')
                    raw_data = readmatrix(file_path);
                else
                    raw_data = dlmread(file_path);
                end
                
                % 检查数据格式
                if size(raw_data, 2) < 2
                    error('文件格式错误，需要至少两列数据');
                end
                
                time = raw_data(:, 1);
                signal = raw_data(:, 2);
                
                % 移除NaN值
                valid_idx = ~isnan(time) & ~isnan(signal);
                time = time(valid_idx);
                signal = signal(valid_idx);
                
                % 计算采样频率
                if length(time) > 1
                    dt = mean(diff(time));
                    fs = 1 / dt;
                else
                    fs = 1e6; % 默认1MHz
                end
                
                data.time = time;
                data.signal = signal;
                data.fs = fs;
                
            catch ME
                error('读取文件失败: %s', ME.message);
            end
        end
    end
end
%                 % 读取数据
%                 data = readmatrix(file_path);
                
%                 if size(data, 2) < 2
%                     warning('File format error: %s. Expected at least 2 columns.', file_path);
%                     return;
%                 end
                
%                 time_data = data(:, 1);
%                 signal_data = data(:, 2);
                
%                 % 移除NaN值 - 与file_processor.m保持一致
%                 valid_idx = ~isnan(time_data) & ~isnan(signal_data);
%                 time_data = time_data(valid_idx);
%                 signal_data = signal_data(valid_idx);
                
%                 % 计算采样率 - 与file_processor.m保持一致
%                 if length(time_data) > 1
%                     dt = mean(diff(time_data));
%                     fs = 1 / dt;
%                 else
%                     warning('Insufficient data points in file: %s', file_path);
%                     return;
%                 end
                
%             catch ME
%                 warning('Error reading file %s: %s', file_path, ME.message);
%                 % 确保返回空值
%                 time_data = [];
%                 signal_data = [];
%                 fs = 0;
%             end
%         end
%     end
% end
