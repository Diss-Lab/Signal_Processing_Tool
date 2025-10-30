function init_project()
    % 项目路径初始化脚本
    % 将所有必要的模块路径添加到MATLAB搜索路径
    %
    % 使用方法：
    %   在项目根目录运行: init_project
    
    fprintf('\n========================================\n');
    fprintf('初始化信号处理工具项目路径\n');
    fprintf('========================================\n\n');
    
    % 获取当前脚本所在目录（项目根目录）
    project_root = fileparts(mfilename('fullpath'));
    
    % 定义需要添加的路径 - 只包含新架构路径
    paths_to_add = {
        % 新架构路径
        fullfile(project_root, 'core', 'signal_analysis'),
        fullfile(project_root, 'core', 'filtering'),
        fullfile(project_root, 'core', 'imaging'),
        fullfile(project_root, 'io', 'data_loader'),
        fullfile(project_root, 'io', 'data_converter'),
        fullfile(project_root, 'ui', 'main'),
        fullfile(project_root, 'ui', 'components'),
        fullfile(project_root, 'ui', 'visualizers'),
        fullfile(project_root, 'utils', 'math_tools'),
        fullfile(project_root, 'utils', 'ui_helpers'),
        fullfile(project_root, 'config'),
        fullfile(project_root, 'tests')
        % 移除: 不再添加A/B/C旧文件夹路径
    };
    
    % 添加路径
    added_count = 0;
    skipped_count = 0;
    
    for i = 1:length(paths_to_add)
        path_dir = paths_to_add{i};
        
        if exist(path_dir, 'dir')
            addpath(path_dir);
            fprintf('✓ 已添加路径: %s\n', path_dir);
            added_count = added_count + 1;
        else
            fprintf('⚠ 路径不存在（跳过）: %s\n', path_dir);
            skipped_count = skipped_count + 1;
        end
    end
    
    fprintf('\n========================================\n');
    fprintf('路径初始化完成\n');
    fprintf('成功添加: %d 个路径\n', added_count);
    fprintf('跳过: %d 个路径（不存在）\n', skipped_count);
    fprintf('========================================\n\n');
    
    % 验证关键类是否可用
    fprintf('验证核心模块...\n');
    
    classes_to_check = {
        'fft_analyzer', 'core/signal_analysis';
        'timefreq_analyzer', 'core/signal_analysis';
        'filter_engine', 'core/filtering';
        'SignalData', 'io/data_loader';
        'txt_loader', 'io/data_loader';
        'signal_plotter', 'ui/visualizers'
    };
    
    all_ok = true;
    for i = 1:size(classes_to_check, 1)
        class_name = classes_to_check{i, 1};
        if exist(class_name, 'class')
            fprintf('✅ %s 类可用\n', class_name);
        else
            fprintf('❌ %s 类不可用 (应在 %s)\n', class_name, classes_to_check{i, 2});
            all_ok = false;
        end
    end
    
    fprintf('\n');
    
    if all_ok
        fprintf('✅ 所有核心模块验证通过！可以开始使用。\n');
    else
        fprintf('⚠️  部分模块不可用，请检查文件是否存在。\n');
    end
    
    fprintf('\n提示：每次打开MATLAB时运行 init_project 来初始化路径\n');
    fprintf('或将此脚本添加到启动脚本中实现自动初始化\n\n');
end
