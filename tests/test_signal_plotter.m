function test_signal_plotter()
    % 信号绘图器测试脚本
    
    fprintf('\n========================================\n');
    fprintf('信号绘图器测试开始\n');
    fprintf('========================================\n\n');
    
    % 添加路径
    project_root = fileparts(pwd);
    addpath(fullfile(project_root, 'ui', 'visualizers'));
    addpath(fullfile(project_root, 'io', 'data_loader'));
    addpath(fullfile(project_root, 'core', 'signal_analysis'));
    
    % 验证类加载
    if ~exist('signal_plotter', 'class')
        error('无法加载 signal_plotter 类！');
    end
    
    fprintf('✓ signal_plotter 类加载成功\n\n');
    
    % 测试计数器
    total_tests = 0;
    passed_tests = 0;
    
    %% 准备测试数据
    fs = 1e6;
    t = 0:1/fs:1e-3;
    signal = sin(2*pi*100e3*t)' + 0.5*sin(2*pi*200e3*t)';
    test_data = SignalData(signal, t', fs, 'single_point');
    
    %% 测试1: 时域绘图
    fprintf('【测试1】时域信号绘图...\n');
    total_tests = total_tests + 1;
    try
        fig = figure('Visible', 'on', 'Name', '测试1: 时域信号');  % 修复：设置为可见
        ax = axes(fig);
        
        signal_plotter.plot_time_domain(ax, test_data);
        
        % 验证
        if ~isempty(get(ax, 'Children'))
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
        
        pause(1);  % 添加：暂停1秒查看图形
        close(fig);
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试2: 频域绘图
    fprintf('\n【测试2】频域信号绘图...\n');
    total_tests = total_tests + 1;
    try
        fig = figure('Visible', 'on', 'Name', '测试2: 频域信号');
        ax = axes(fig);
        
        signal_plotter.plot_frequency_domain(ax, test_data, 'show_peaks', true);
        
        if ~isempty(get(ax, 'Children'))
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
        
        pause(1);
        close(fig);
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试3: 时频图绘图
    fprintf('\n【测试3】时频图绘图...\n');
    total_tests = total_tests + 1;
    try
        fig = figure('Visible', 'on', 'Name', '测试3: 时频图');
        ax = axes(fig);
        
        signal_plotter.plot_timefreq(ax, test_data);
        
        if ~isempty(get(ax, 'Children'))
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
        
        pause(1);
        close(fig);
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试4: 波场2D绘图
    fprintf('\n【测试4】波场2D绘图...\n');
    total_tests = total_tests + 1;
    try
        % 创建测试波场数据
        data_3d = randn(10, 15, length(t));
        wavefield_data = SignalData(data_3d, t', fs, 'wavefield');
        
        fig = figure('Visible', 'on', 'Name', '测试4: 波场2D');
        ax = axes(fig);
        
        signal_plotter.plot_wavefield_2d(ax, wavefield_data, 50);
        
        if ~isempty(get(ax, 'Children'))
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
        
        pause(1);
        close(fig);
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试5: 多信号绘图
    fprintf('\n【测试5】多信号叠加绘图...\n');
    total_tests = total_tests + 1;
    try
        % 创建多个信号
        signal_array = cell(3, 1);
        for i = 1:3
            sig = sin(2*pi*(50e3*i)*t)';
            signal_array{i} = SignalData(sig, t', fs, 'single_point');
        end
        
        fig = figure('Visible', 'on', 'Name', '测试5: 多信号叠加');
        ax = axes(fig);
        
        signal_plotter.plot_multi_signals(ax, signal_array, ...
            'legends', {'Signal 1', 'Signal 2', 'Signal 3'});
        
        if ~isempty(get(ax, 'Children'))
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
        
        pause(1);
        close(fig);
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试6: 幅值曲线绘图
    fprintf('\n【测试6】幅值曲线绘图...\n');
    total_tests = total_tests + 1;
    try
        amplitudes = [1, 2, 1.5, 1.8, 2.2, 1.9, 2.1, 1.7]';
        positions = linspace(0, 25, 8)';
        
        fig = figure('Visible', 'on', 'Name', '测试6: 幅值曲线');
        ax = axes(fig);
        
        signal_plotter.plot_amplitude_curve(ax, amplitudes, positions, ...
            'show_values', true);
        
        if ~isempty(get(ax, 'Children'))
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
        
        pause(1);
        close(fig);
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试总结
    fprintf('\n========================================\n');
    fprintf('测试完成: %d/%d 通过 (%.1f%%)\n', passed_tests, total_tests, passed_tests/total_tests*100);
    fprintf('========================================\n\n');
    
    if passed_tests == total_tests
        fprintf('✅ 所有测试通过！\n\n');
        
        % 添加：询问是否查看详细示例
        choice = input('是否显示详细绘图示例? (y/n): ', 's');
        if strcmpi(choice, 'y')
            show_detailed_examples(test_data);
        end
    else
        fprintf('⚠️  部分测试未通过\n\n');
    end
end

function show_detailed_examples(test_data)
    % 显示详细绘图示例
    fprintf('\n正在创建详细示例图形...\n');
    
    % 创建综合示例窗口
    demo_fig = figure('Name', 'Signal Plotter 功能演示', ...
                      'Position', [100, 50, 1400, 800]);
    
    % 时域信号
    ax1 = subplot(2, 3, 1);
    signal_plotter.plot_time_domain(ax1, test_data, ...
        'color', 'b', 'title', '时域信号示例');
    
    % 频域信号
    ax2 = subplot(2, 3, 2);
    signal_plotter.plot_frequency_domain(ax2, test_data, ...
        'show_peaks', true, 'title', '频域信号示例(带峰值标记)');
    
    % 时频图
    ax3 = subplot(2, 3, 3);
    signal_plotter.plot_timefreq(ax3, test_data, ...
        'colormap_name', 'jet', 'smooth_sigma', 1.5);
    
    % 多信号示例
    ax4 = subplot(2, 3, 4);
    fs = test_data.fs;
    t = test_data.time;
    signal_array = cell(3, 1);
    for i = 1:3
        sig = sin(2*pi*(50e3*i)*t);
        signal_array{i} = SignalData(sig, t, fs, 'single_point');
    end
    signal_plotter.plot_multi_signals(ax4, signal_array, ...
        'legends', {'50kHz', '100kHz', '150kHz'}, ...
        'highlight_range', [200, 400]);
    
    % 幅值曲线
    ax5 = subplot(2, 3, 5);
    amplitudes = [1, 1.5, 2, 1.8, 2.2, 1.9, 2.1, 1.7, 1.6, 1.4]';
    positions = linspace(0, 30, 10)';
    signal_plotter.plot_amplitude_curve(ax5, amplitudes, positions, ...
        'marker_style', 'o', 'line_color', 'r', 'show_values', false);
    
    % 波场2D示例
    ax6 = subplot(2, 3, 6);
    [m, n] = meshgrid(1:20, 1:20);
    wave_2d = sin(m/2) .* cos(n/2);
    data_3d = repmat(wave_2d, [1, 1, 10]);
    wavefield_data = SignalData(data_3d, t(1:10), fs, 'wavefield');
    signal_plotter.plot_wavefield_2d(ax6, wavefield_data, 5, ...
        'colormap_name', 'hot');
    
    fprintf('✅ 详细示例已显示\n');
    fprintf('   请查看图形窗口了解各种绘图功能\n');
    fprintf('   关闭图形窗口继续...\n\n');
end
