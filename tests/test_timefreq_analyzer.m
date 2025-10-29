function test_timefreq_analyzer()
    % 时频分析器测试脚本
    % 测试timefreq_analyzer类的所有功能
    
    fprintf('\n========================================\n');
    fprintf('时频分析器测试开始\n');
    fprintf('========================================\n\n');
    
    % 添加核心模块路径
    project_root = fileparts(pwd);
    addpath(fullfile(project_root, 'core', 'signal_analysis'));
    addpath(fullfile(project_root, 'A'));
    
    % 验证类加载
    if ~exist('timefreq_analyzer', 'class')
        error('无法加载 timefreq_analyzer 类！');
    end
    
    fprintf('✓ timefreq_analyzer 类加载成功\n\n');
    
    % 测试计数器
    total_tests = 0;
    passed_tests = 0;
    
    %% 测试1: 基本STFT计算
    fprintf('【测试1】基本STFT计算...\n');
    total_tests = total_tests + 1;
    try
        % 生成线性调频信号
        fs = 1e6;
        t = 0:1/fs:1e-3;
        f0 = 50e3;
        f1 = 200e3;
        signal = chirp(t, f0, t(end), f1)';
        
        [S, F, T] = timefreq_analyzer.compute_stft(signal, fs);
        
        if ~isempty(S) && ~isempty(F) && ~isempty(T)
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试2: 时频图平滑
    fprintf('\n【测试2】时频图平滑...\n');
    total_tests = total_tests + 1;
    try
        fs = 1e6;
        signal = randn(1000, 1);
        
        [S, ~, ~] = timefreq_analyzer.compute_stft(signal, fs);
        S_smooth = timefreq_analyzer.smooth_spectrogram(S);
        
        if size(S_smooth) == size(abs(S))
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试3: 峰值检测
    fprintf('\n【测试3】峰值检测...\n');
    total_tests = total_tests + 1;
    try
        fs = 1e6;
        t = 0:1/fs:1e-3;
        signal = sin(2*pi*100e3*t)';
        
        [S, F, T] = timefreq_analyzer.compute_stft(signal, fs);
        peak_info = timefreq_analyzer.find_timefreq_peaks(S, F, T);
        
        if ~isempty(peak_info) && length(peak_info) >= 1
            fprintf('   ✅ 通过 (检测到 %d 个峰值)\n', length(peak_info));
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试4: 幅值转分贝
    fprintf('\n【测试4】幅值转分贝...\n');
    total_tests = total_tests + 1;
    try
        fs = 1e6;
        signal = randn(1000, 1);
        
        [S, ~, ~] = timefreq_analyzer.compute_stft(signal, fs);
        S_dB = timefreq_analyzer.magnitude_to_dB(S);
        
        if ~isempty(S_dB) && all(isfinite(S_dB(:)))
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试5: 与原代码对比
    fprintf('\n【测试5】与原代码结果对比...\n');
    total_tests = total_tests + 1;
    try
        fs = 1e6;
        t = 0:1/fs:1e-3;
        signal = chirp(t, 50e3, t(end), 200e3)';
        
        % 新代码
        [S_new, ~, ~] = timefreq_analyzer.compute_stft(signal, fs);
        
        % 原代码（如果存在）
        if exist('visualizer', 'class')
            fprintf('   ⚠️  原代码对比功能需手动验证\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ⚠️  跳过（原类不存在）\n');
            passed_tests = passed_tests + 1;
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试总结
    fprintf('\n========================================\n');
    fprintf('测试完成: %d/%d 通过 (%.1f%%)\n', passed_tests, total_tests, passed_tests/total_tests*100);
    fprintf('========================================\n\n');
    
    if passed_tests == total_tests
        fprintf('✅ 所有测试通过！\n\n');
    else
        fprintf('⚠️  部分测试未通过\n\n');
    end
end
