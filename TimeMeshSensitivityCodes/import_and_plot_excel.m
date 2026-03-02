% Function to take in subfolders (currently 6 due to 6 line locations) and cross-plot them on separate axes
% Input: Root folder with subfolders from "xlsxSorterv3.py"
% Output: Labelled plots for each location with the runs requested overlaid 

function import_and_plot_excel()

    %% --- Select MAIN folder containing 6 subfolders ---
    mainFolder = uigetdir('E:\Boller CFD\AVIATION CFD\TimeSensitivityData',...
                          'Select the MAIN folder with 6 subfolders');
    if isequal(mainFolder,0)
        disp('No folder selected.');
        return;
    end

    %% --- Select output folder ---
    outFolder = uigetdir('E:\Boller CFD\AVIATION CFD\TimeSensitivityData\output',...
                         'Select Output Folder');
    if isequal(outFolder,0)
        disp('No output folder selected.');
        return;
    end

    %% --- List subfolders (expect 6) ---
    folderInfo = dir(mainFolder);
    subfolders = folderInfo([folderInfo.isdir] &...
                            ~ismember({folderInfo.name},{'.','..'}));

    if numel(subfolders) ~= 6
        error('Expected exactly 6 subfolders, but found %d.', numel(subfolders));
    end

    %% --- Ask user for number of Excel files (constant across folders) ---
    answer = inputdlg(...
        'Number of Excel files in EACH subfolder:',...
        'Excel File Count',...
        [1 50],...
        {'4'} );

    if isempty(answer)
        disp('User cancelled file count input.');
        return;
    end

    nFiles = str2double(answer{1});

    if isnan(nFiles) || nFiles <= 0 || mod(nFiles,1) ~= 0
        error('Number of Excel files must be a positive integer.');
    end

    %% --- Ask user for optional x-axis ranges (Mach, Pressure, Velocity) ---
    % Leave blank for any plot type to use automatic x-limits
    xRangeAns = inputdlg(...
        {...
         'Mach x-min (leave blank for auto):',    'Mach x-max (leave blank for auto):';...
         'Pressure x-min (leave blank for auto):','Pressure x-max (leave blank for auto):';...
         'Velocity x-min (leave blank for auto):','Velocity x-max (leave blank for auto):'...
        },...
        'Optional X-Axis Ranges',...
        [1 50],...
        {'','','','','',''} );

    if isempty(xRangeAns)
        % User closed dialog; default all to auto
        xRangeMach     = [];
        xRangePressure = [];
        xRangeVelocity = [];
    else
        % Mach
        xRangeMach     = parseRange(xRangeAns{1}, xRangeAns{2}, 'Mach');
        % Pressure
        xRangePressure = parseRange(xRangeAns{3}, xRangeAns{4}, 'Pressure');
        % Velocity
        xRangeVelocity = parseRange(xRangeAns{5}, xRangeAns{6}, 'Velocity');
    end

    %% --- Loop through each subfolder ---
    for f = 1:6
        folderPath = fullfile(mainFolder, subfolders(f).name);

        fprintf('\n=============================\n');
        fprintf('Processing Folder %d: %s\n', f, subfolders(f).name);
        fprintf('Expected Excel files: %d\n', nFiles);
        fprintf('=============================\n');

        %% --- Find Excel files ---
        excelFiles = dir(fullfile(folderPath,'*.xlsx'));
        excelFiles = [excelFiles; dir(fullfile(folderPath,'*.xls'))];

        if numel(excelFiles) ~= nFiles
            error('Folder "%s" must contain exactly %d Excel files (found %d).',...
                  subfolders(f).name, nFiles, numel(excelFiles));
        end

        files = {excelFiles.name};
        path  = folderPath;

        %% --- Prefix based on first file ---
        [~, nameOnly] = fileparts(files{1});
        tokens = split(string(nameOnly), "_");
        savePrefix = tokens{1};

        %% --- Load data ---
        Y  = cell(1,nFiles);
        M  = cell(1,nFiles);
        P  = cell(1,nFiles);
        Vx = cell(1,nFiles);

        for i = 1:nFiles
            T = readtable(fullfile(path, files{i}));
            Y{i}  = T.y;
            M{i}  = T.machnumberavg;
            P{i}  = T.pressureavg;
            Vx{i} = T.velocityxavg;
        end

        %% --- Create output subfolder ---
        saveSub = fullfile(outFolder, subfolders(f).name);
        if ~isfolder(saveSub)
            mkdir(saveSub);
        end

        %% --- Generate plots ---
        % Mach
        save_overlay(M, Y, files, savePrefix, saveSub,...
                     'machnumberavg', 'Overlay: Mach Number vs y', 'mach', xRangeMach);

        % Pressure
        save_overlay(P, Y, files, savePrefix, saveSub,...
                     'pressureavg (Pa)', 'Overlay: Pressure vs y', 'pressure', xRangePressure);

        % Velocity
        save_overlay(Vx, Y, files, savePrefix, saveSub,...
                     'velocityxavg (m/s)', 'Overlay: Velocity X vs y', 'velocityx', xRangeVelocity);

        fprintf('Folder "%s" processed successfully.\n', subfolders(f).name);
    end

    disp('=============================================');
    disp('All 6 folders processed. Plots saved.');
    disp('=============================================');
end


%% --- Helper: parse a pair of strings into a numeric [xmin xmax] or [] ---
function xRange = parseRange(xMinStr, xMaxStr, label)

    xMinStr = strtrim(xMinStr);
    xMaxStr = strtrim(xMaxStr);

    if isempty(xMinStr) || isempty(xMaxStr)
        % One or both empty → use auto-fit
        xRange = [];
        return;
    end

    xMinVal = str2double(xMinStr);
    xMaxVal = str2double(xMaxStr);

    if isnan(xMinVal) || isnan(xMaxVal) || xMinVal >= xMaxVal
        warning('%s x-axis range invalid. Using auto-fit for %s.', label, label);
        xRange = [];
    else
        xRange = [xMinVal, xMaxVal];
    end
end


%%                 Helper Function (Subfunction)
function save_overlay(xData, yData, files, savePrefix, saveFolder, xLabel, titleText, tag, xRange)

    fig = figure('Visible','on');
    hold on; grid on;

    nCurves = numel(xData);
    legendLabels = cell(1,nCurves);

    for k = 1:nCurves
        plot(xData{k}, yData{k}, 'LineWidth', 2);

        % --- Get filename without extension ---
        [~, nameOnly] = fileparts(files{k});

        % --- Split by underscore ---
        parts = split(string(nameOnly), "_");

        firstString = parts(1);  % first token before "_"

        % --- Extract testXX ---
        match = regexp(nameOnly, 'test\d+', 'match');

        if ~isempty(match)
            legendLabels{k} = firstString + "_" + match{1};
        else
            legendLabels{k} = firstString;  % fallback
        end
    end

    xlabel(xLabel);
    ylabel('y (m)');
    title(titleText, 'Interpreter','none');
    legend(legendLabels, 'Interpreter','none', 'Location','northwest');

    % --- Apply x-axis limits only if specified for this plot type ---
    if ~isempty(xRange)
        xlim(xRange);
    end

    % Save FIG
    saveas(fig, fullfile(saveFolder, sprintf('%s_%s.fig', savePrefix, tag)), 'fig');

    % Save JPEG
    print(fig, fullfile(saveFolder, sprintf('%s_%s.jpg', savePrefix, tag)),...
          '-djpeg','-r300');

    close(fig);
end