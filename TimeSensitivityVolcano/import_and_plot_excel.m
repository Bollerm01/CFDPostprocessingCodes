function import_and_plot_excel()

    %% --- Select Excel Files ---
    [files, path] = uigetfile({'*.xlsx;*.xls'}, ...
                              'Select 4 Excel Files (Same Format)', ...
                              'MultiSelect', 'on');

    if isequal(files,0)
        disp('No files selected.');
        return;
    end

    if ischar(files)
        files = {files};
    end

    if numel(files) ~= 4
        error('You must select exactly 4 Excel files.');
    end

    %% --- Select output folder ---
    outFolder = uigetdir("E:\Boller CFD\AVIATION CFD\TimeSensitivityData", 'Select Output Folder');
    if isequal(outFolder,0)
        disp('No output folder selected.');
        return;
    end

    %% --- Use ONLY first file's first token before "_" ---
    [~, nameOnly] = fileparts(files{1});
    tokens = split(string(nameOnly), "_");
    savePrefix = tokens{1};   % ONLY ONE DELIMITER used

    %% --- Load data ---
    Y  = cell(1,4);
    M  = cell(1,4);
    P  = cell(1,4);
    Vx = cell(1,4);

    for i = 1:4
        T = readtable(fullfile(path, files{i}));
        Y{i}  = T.y;
        M{i}  = T.machnumberavg;
        P{i}  = T.pressureavg;
        Vx{i} = T.velocityxavg;
    end

    %% --- Helper function for overlay plots ---
    function save_overlay(xData, yData, xLabel, titleText, tag)

        fig = figure('Visible','on');
        hold on; grid on;

        for k = 1:4
            plot(xData{k}, yData{k}, 'LineWidth', 2);  % axes flipped
        end

        xlabel(xLabel);
        ylabel('y (m)');
        title(titleText, 'Interpreter','none');

        legend(files, 'Interpreter','none', 'Location','northwest');

        % Save MATLAB FIG (more reliable than savefig for invisible figures)
        saveas(fig, fullfile(outFolder, sprintf('%s_%s.fig', savePrefix, tag)), 'fig');

        % Save JPG
        print(fig, fullfile(outFolder, sprintf('%s_%s.jpg', savePrefix, tag)), '-djpeg', '-r300');

        drawnow;  % ensure graphics updates before closing
        close(fig);

    end

    %% --- Generate & save overlay plots ---

    % Mach
    save_overlay(M, Y, 'machnumberavg', 'Overlay: Mach Number vs y', 'mach');

    % Pressure
    save_overlay(P, Y, 'pressureavg', 'Overlay: Pressure vs y', 'pressure');

    % Velocity X
    save_overlay(Vx, Y, 'velocityxavg', 'Overlay: Velocity X vs y', 'velocityx');

    disp('All plots saved successfully as .fig and .jpg');
end



