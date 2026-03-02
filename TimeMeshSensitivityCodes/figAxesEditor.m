function figAxesEditor
% figAxesEditor
% GUI to:
%  - Load a .fig file
%  - Adjust axis limits via text boxes
%  - Toggle legend on/off
%  - Show grid
%  - Save as JPG
%
% Legend underscores are treated literally (Interpreter = 'none').

    % Main GUI figure
    hMain = figure('Name', 'FIG Axes Editor', ...
                   'NumberTitle', 'off', ...
                   'MenuBar', 'none', ...
                   'Toolbar', 'none', ...
                   'Units', 'pixels', ...
                   'Position', [100 100 900 600]);

    % Struct to store handles/state
    S = struct();
    S.loadedFig    = [];  % handle to loaded figure (invisible)
    S.axesHandle   = [];  % handle to axes in the hidden figure
    S.legendHandle = [];  % handle to legend in the displayAxes
    S.figFilePath  = '';  % full path to .fig file

    % Axes to display the loaded content (we will copy objects into this)
    S.displayAxes = axes('Parent', hMain, ...
                         'Units', 'normalized', ...
                         'Position', [0.30 0.15 0.65 0.80]);
    box(S.displayAxes, 'on');
    grid(S.displayAxes, 'on'); % GRID ON
    title(S.displayAxes, 'No figure loaded');

    % --- UI Controls ---

    % Button: Load FIG
    uicontrol('Parent', hMain, 'Style', 'pushbutton', ...
              'String', 'Load .FIG', ...
              'Units', 'normalized', ...
              'Position', [0.05 0.88 0.20 0.07], ...
              'FontSize', 11, ...
              'Callback', @(src,evt) onLoadFig());

    % Axis limit labels and edit boxes
    uicontrol('Parent', hMain, 'Style', 'text', ...
              'String', 'X min:', ...
              'Units', 'normalized', ...
              'HorizontalAlignment', 'left', ...
              'Position', [0.05 0.76 0.10 0.04]);
    S.editXmin = uicontrol('Parent', hMain, 'Style', 'edit', ...
                           'String', '', ...
                           'Units', 'normalized', ...
                           'Position', [0.15 0.76 0.10 0.04], ...
                           'Callback', @(src,evt) updateAxesLimits());

    uicontrol('Parent', hMain, 'Style', 'text', ...
              'String', 'X max:', ...
              'Units', 'normalized', ...
              'HorizontalAlignment', 'left', ...
              'Position', [0.05 0.70 0.10 0.04]);
    S.editXmax = uicontrol('Parent', hMain, 'Style', 'edit', ...
                           'String', '', ...
                           'Units', 'normalized', ...
                           'Position', [0.15 0.70 0.10 0.04], ...
                           'Callback', @(src,evt) updateAxesLimits());

    uicontrol('Parent', hMain, 'Style', 'text', ...
              'String', 'Y min:', ...
              'Units', 'normalized', ...
              'HorizontalAlignment', 'left', ...
              'Position', [0.05 0.64 0.10 0.04]);
    S.editYmin = uicontrol('Parent', hMain, 'Style', 'edit', ...
                           'String', '', ...
                           'Units', 'normalized', ...
                           'Position', [0.15 0.64 0.10 0.04], ...
                           'Callback', @(src,evt) updateAxesLimits());

    uicontrol('Parent', hMain, 'Style', 'text', ...
              'String', 'Y max:', ...
              'Units', 'normalized', ...
              'HorizontalAlignment', 'left', ...
              'Position', [0.05 0.58 0.10 0.04]);
    S.editYmax = uicontrol('Parent', hMain, 'Style', 'edit', ...
                           'String', '', ...
                           'Units', 'normalized', ...
                           'Position', [0.15 0.58 0.10 0.04], ...
                           'Callback', @(src,evt) updateAxesLimits());

    % Legend toggle checkbox
    S.cbLegend = uicontrol('Parent', hMain, 'Style', 'checkbox', ...
                           'String', 'Show Legend', ...
                           'Units', 'normalized', ...
                           'Position', [0.05 0.48 0.20 0.05], ...
                           'Value', 1, ...
                           'Enable', 'off', ...
                           'Callback', @(src,evt) toggleLegend());

    % Button: Apply axis limits explicitly (optional)
    uicontrol('Parent', hMain, 'Style', 'pushbutton', ...
              'String', 'Apply Axes', ...
              'Units', 'normalized', ...
              'Position', [0.05 0.40 0.20 0.06], ...
              'FontSize', 10, ...
              'Callback', @(src,evt) updateAxesLimits(true));

    % Button: Save as JPG
    uicontrol('Parent', hMain, 'Style', 'pushbutton', ...
              'String', 'Save as JPG', ...
              'Units', 'normalized', ...
              'Position', [0.05 0.28 0.20 0.07], ...
              'FontSize', 11, ...
              'Enable', 'off', ...
              'Tag', 'btnSaveJPG', ...
              'Callback', @(src,evt) onSaveJPG());

    % Store in guidata
    guidata(hMain, S);

    %==================== Nested callback functions ====================%

    function onLoadFig()
        S = guidata(hMain);

        [fName, fPath] = uigetfile('*.fig', 'Select a FIG file');
        if isequal(fName, 0)
            return;
        end

        S.figFilePath = fullfile(fPath, fName);

        % Close old hidden figure if exists
        if ~isempty(S.loadedFig) && isvalid(S.loadedFig)
            close(S.loadedFig);
        end

        % Open .fig as invisible figure
        S.loadedFig = openfig(S.figFilePath, 'new', 'invisible');

        % Try to get the first axes in the loaded figure
        axesInFig = findall(S.loadedFig, 'type', 'axes');
        if isempty(axesInFig)
            title(S.displayAxes, 'No axes found in FIG');
            guidata(hMain, S);
            return;
        end

        % Use the topmost axes (the last one found is usually on top)
        S.axesHandle = axesInFig(1);

        % Clear display axes and copy children into GUI axes
        cla(S.displayAxes, 'reset');
        copyobj(allchild(S.axesHandle), S.displayAxes);

        % Copy axis properties (limits, labels, etc.)
        set(S.displayAxes, 'XLim', get(S.axesHandle, 'XLim'), ...
                           'YLim', get(S.axesHandle, 'YLim'), ...
                           'XScale', get(S.axesHandle, 'XScale'), ...
                           'YScale', get(S.axesHandle, 'YScale'));
        xlabel(S.displayAxes, get(get(S.axesHandle,'XLabel'),'String'));
        ylabel(S.displayAxes, get(get(S.axesHandle,'YLabel'),'String'));
        title(S.displayAxes, get(get(S.axesHandle,'Title'),'String'));

        % Ensure grid is on in the display axes
        grid(S.displayAxes, 'on');

        % Handle legend if present in the original figure
        origLeg = findobj(S.loadedFig, 'Type', 'Legend');
        if ~isempty(origLeg)
            legString = origLeg.String;
            lines = findobj(S.displayAxes, 'Type', 'line');

            if ~isempty(lines)
                % Create legend in GUI axes and store the handle
                S.legendHandle = legend(S.displayAxes, flipud(lines), legString, ...
                                        'Interpreter', 'none');
                set(S.cbLegend, 'Enable', 'on', 'Value', 1);
            else
                S.legendHandle = [];
                set(S.cbLegend, 'Enable', 'off', 'Value', 0);
            end
        else
            S.legendHandle = [];
            set(S.cbLegend, 'Enable', 'off', 'Value', 0);
        end

        % Initialize axis limit text boxes
        xl = get(S.displayAxes, 'XLim');
        yl = get(S.displayAxes, 'YLim');
        set(S.editXmin, 'String', num2str(xl(1)));
        set(S.editXmax, 'String', num2str(xl(2)));
        set(S.editYmin, 'String', num2str(yl(1)));
        set(S.editYmax, 'String', num2str(yl(2)));

        % Enable Save button
        hSave = findobj(hMain, 'Tag', 'btnSaveJPG');
        set(hSave, 'Enable', 'on');

        title(S.displayAxes, fName);

        guidata(hMain, S);
    end


    function updateAxesLimits(~)
        S = guidata(hMain);
        if isempty(S.displayAxes) || ~ishandle(S.displayAxes)
            return;
        end

        % Read current text box values
        xminStr = get(S.editXmin, 'String');
        xmaxStr = get(S.editXmax, 'String');
        yminStr = get(S.editYmin, 'String');
        ymaxStr = get(S.editYmax, 'String');

        % Convert to numeric
        xmin = str2double(xminStr);
        xmax = str2double(xmaxStr);
        ymin = str2double(yminStr);
        ymax = str2double(ymaxStr);

        if ~isnan(xmin) && ~isnan(xmax) && xmin < xmax
            set(S.displayAxes, 'XLim', [xmin xmax]);
        end
        if ~isnan(ymin) && ~isnan(ymax) && ymin < ymax
            set(S.displayAxes, 'YLim', [ymin ymax]);
        end

        guidata(hMain, S);
    end


    function toggleLegend()
        S = guidata(hMain);
        if isempty(S.legendHandle) || ~ishandle(S.legendHandle)
            return;
        end

        val = get(S.cbLegend, 'Value');
        if val == 1
            set(S.legendHandle, 'Visible', 'on');
        else
            set(S.legendHandle, 'Visible', 'off');
        end

        guidata(hMain, S);
    end


    function onSaveJPG()
        S = guidata(hMain);
        if isempty(S.displayAxes) || ~ishandle(S.displayAxes)
            return;
        end

        % Suggest a filename based on the FIG name
        if ~isempty(S.figFilePath)
            [p, baseName, ~] = fileparts(S.figFilePath);
        else
            p = pwd;
            baseName = 'edited_figure';
        end

        [fName, fPath] = uiputfile('*.jpg', 'Save figure as JPG', ...
                                   fullfile(p, [baseName '.jpg']));
        if isequal(fName, 0)
            return;
        end

        outPath = fullfile(fPath, fName);

        % Create a temporary figure for clean export
        tempFig = figure('Visible', 'off');
        tempAx  = axes('Parent', tempFig);

        % Copy everything from displayAxes to the temp axes
        copyobj(allchild(S.displayAxes), tempAx);
        set(tempAx, 'XLim', get(S.displayAxes,'XLim'), ...
                    'YLim', get(S.displayAxes,'YLim'), ...
                    'XScale', get(S.displayAxes,'XScale'), ...
                    'YScale', get(S.displayAxes,'YScale'));
        xlabel(tempAx, get(get(S.displayAxes,'XLabel'),'String'));
        ylabel(tempAx, get(get(S.displayAxes,'YLabel'),'String'));
        title(tempAx, get(get(S.displayAxes,'Title'),'String'), "Interpreter","none");

        % Grid in exported figure
        grid(tempAx, 'on');

        % ---------- LEGEND EXPORT FIX ----------
        % Use the stored legend handle and checkbox state instead of findobj.
        showLegend = get(S.cbLegend, 'Value');   % 1 = show, 0 = hide

        if ~isempty(S.legendHandle) && ishandle(S.legendHandle) && showLegend == 1
            legStr = S.legendHandle.String;

            % Lines in the temp axes
            linesOut = findobj(tempAx, 'Type', 'line');

            if ~isempty(linesOut)
                newLeg = legend(tempAx, flipud(linesOut), legStr, ...
                                'Interpreter', 'none');
                set(newLeg, 'Visible', 'on');
            end
        end
        % If checkbox is off, no legend is created in the export.
        % --------------------------------------

        % Export as JPG
        try
            exportgraphics(tempFig, outPath, 'Resolution', 300);
        catch
            saveas(tempFig, outPath);
        end

        close(tempFig);

        fprintf('Saved JPG: %s\n', outPath);
    end

end