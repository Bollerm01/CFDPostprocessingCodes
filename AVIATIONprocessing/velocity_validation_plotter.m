% Function to take in several .XLSX files with normalized y/d vs. U/U_inf and plot them over each other for velocity validation
% Input: Root folder containing .XLSX files to x-plot
% Output: Labelled plots for U/U_inf and (maybe) U_rms/Uinf 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% BEGIN BY FIXING BELOW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function import_and_plot_excel()

    %% --- Select MAIN folder containing 6 subfolders ---
    mainFolder = uigetdir('E:\Boller CFD\AVIATION CFD\TimeSensitivityData', ...
                          'Select the MAIN folder with 6 subfolders');
    if isequal(mainFolder,0)
        disp('No folder selected.');
        return;
    end

    %% --- Select output folder ---
    outFolder = uigetdir('E:\Boller CFD\AVIATION CFD\TimeSensitivityData\output', ...
                         'Select Output Folder');
    if isequal(outFolder,0)
        disp('No output folder selected.');
        return;
    end

    %% --- List subfolders (expect 6) ---
    folderInfo = dir(mainFolder);
    subfolders = folderInfo([folderInfo.isdir] & ...
                            ~ismember({folderInfo.name},{'.','..'}));

    if numel(subfolders) ~= 6
        error('Expected exactly 6 subfolders, but found %d.', numel(subfolders));
    end

    %% --- Ask user for number of Excel files (constant across folders) ---
    answer = inputdlg( ...
        'Number of Excel files in EACH subfolder:', ...
        'Excel File Count', ...
        [1 50], ...
        {'4'} );

    if isempty(answer)
        disp('User cancelled file count input.');
        return;
    end

    nFiles = str2double(answer{1});

    if isnan(nFiles) || nFiles <= 0 || mod(nFiles,1) ~= 0
        error('Number of Excel files must be a positive integer.');
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
            error('Folder "%s" must contain exactly %d Excel files (found %d).', ...
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
        save_overlay(M, Y, files, savePrefix, saveSub, ...
                     'machnumberavg', 'Overlay: Mach Number vs y', 'mach');

        save_overlay(P, Y, files, savePrefix, saveSub, ...
                     'pressureavg', 'Overlay: Pressure vs y', 'pressure');

        save_overlay(Vx, Y, files, savePrefix, saveSub, ...
                     'velocityxavg', 'Overlay: Velocity X vs y', 'velocityx');

        fprintf('Folder "%s" processed successfully.\n', subfolders(f).name);
    end

    disp('=============================================');
    disp('All 6 folders processed. Plots saved.');
    disp('=============================================');
end


%%                 Helper Function (Subfunction)
function save_overlay(xData, yData, files, savePrefix, saveFolder, xLabel, titleText, tag)

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

    % Save FIG
    saveas(fig, fullfile(saveFolder, sprintf('%s_%s.fig', savePrefix, tag)), 'fig');

    % Save JPEG
    print(fig, fullfile(saveFolder, sprintf('%s_%s.jpg', savePrefix, tag)), ...
          '-djpeg','-r300');

    close(fig);
end







