%% ============================================================
% Scanivalve Surface Pressure 3D Plotter (Normalized Version)
%
% CHAN1 -> S1 ... CHAN9 -> S9
% Gauge Pressure (psig) + barometric correction
% Now includes user-defined normalization pressure
%
% Generates mirrored cavity pressure field about Z = 0
%
%% ============================================================

clear;
clc;
close all;

%% ============================================================
% SELECT FILE
%% ============================================================

[fileName,filePath] = uigetfile('*.csv','Select Scanivalve CSV');

if isequal(fileName,0)
    error('No file selected.');
end

csvFile = fullfile(filePath,fileName);

%% ============================================================
% BAROMETRIC PRESSURE INPUT
%% ============================================================

answer = inputdlg( ...
    'Enter barometric pressure (inHg):', ...
    'Barometric Pressure', ...
    1, ...
    {'29.175'});

if isempty(answer)
    error('No barometric pressure entered.');
end

baro_inHg = str2double(answer{1});

if isnan(baro_inHg)
    error('Invalid barometric pressure.');
end

%% ============================================================
% NEW: NORMALIZATION PRESSURE INPUT
%% ============================================================

normAns = inputdlg( ...
    'Enter normalization pressure (psia):', ...
    'Normalization Pressure', ...
    1, ...
    {'30.0'});

if isempty(normAns)
    error('No normalization pressure entered.');
end

Pnorm = str2double(normAns{1});

% Convert psi -> Pa
Pnorm = Pnorm * 6894.757293;

if isnan(Pnorm) || Pnorm <= 0
    error('Invalid normalization pressure.');
end

%% ============================================================
% CONSTANTS
%% ============================================================

PSI_TO_PA  = 6894.757293;
INHG_TO_PA = 3386.389;

baroPa = baro_inHg * INHG_TO_PA;

%% ============================================================
% SENSOR LOCATIONS
%% ============================================================

sensorNames = { ...
    'S1','S2','S3',...
    'S4','S5','S6',...
    'S7','S8','S9'};

sensorXZ = [
    2.16000  -0.0635;
    2.16000  -0.0381;
    2.16000   0.0000;
    2.17143  -0.0635;
    2.17143  -0.0381;
    2.17143   0.0000;
    2.18286  -0.0635;
    2.18286  -0.0381;
    2.18286   0.0000];

%% ============================================================
% READ CSV
%% ============================================================

T = readtable(csvFile);
vars = strtrim(T.Properties.VariableNames);

%% ============================================================
% COMPUTE PRESSURES
%% ============================================================

sensorPressurePa  = zeros(9,1);
sensorPressurePsi = zeros(9,1);

for k = 1:9

    channelName = sprintf('CHAN%d',k);
    idx = find(strcmp(vars,channelName),1);

    if isempty(idx)
        error('Column %s not found.',channelName);
    end

    gaugePsi = mean(T{:,idx},'omitnan');
    gaugePa  = gaugePsi * PSI_TO_PA;

    sensorPressurePsi(k) = gaugePsi;
    sensorPressurePa(k)  = gaugePa + baroPa;

end

%% ============================================================
% DISPLAY RESULTS (ABSOLUTE)
%% ============================================================

fprintf('\n');
fprintf('Barometric Pressure = %.2f inHg\n',baro_inHg);
fprintf('Normalization Pressure = %.2f Pa\n\n',Pnorm);

for k = 1:9
    fprintf('%s: %.2f psig   %.2f Pa\n',...
        sensorNames{k},...
        sensorPressurePsi(k),...
        sensorPressurePa(k));
end

%% ============================================================
% MIRROR ABOUT Z = 0
%% ============================================================

sensorXZ_mirror = sensorXZ;
sensorXZ_mirror(:,2) = -sensorXZ_mirror(:,2);

interpX = [sensorXZ(:,1); sensorXZ_mirror(:,1)];
interpZ = [sensorXZ(:,2); sensorXZ_mirror(:,2)];
interpP = [sensorPressurePa; sensorPressurePa];

%% ============================================================
% BOUNDARY EXTENSION
%% ============================================================

xmin = 2.1485;
xmax = 2.19475;

zmin = -0.0765;
zmax = 0.0765;

leftX = xmin * ones(6,1);
leftZ = [-0.0635; -0.0381; 0.0; 0.0381; 0.0635; 0.0];
leftP = [
    sensorPressurePa(1);
    sensorPressurePa(2);
    sensorPressurePa(3);
    sensorPressurePa(2);
    sensorPressurePa(1);
    sensorPressurePa(3)];

rightX = xmax * ones(6,1);
rightZ = [-0.0635; -0.0381; 0.0; 0.0381; 0.0635; 0.0];
rightP = [
    sensorPressurePa(7);
    sensorPressurePa(8);
    sensorPressurePa(9);
    sensorPressurePa(8);
    sensorPressurePa(7);
    sensorPressurePa(9)];

bottomX = [2.16000; 2.17143; 2.18286];
bottomZ = zmin * ones(3,1);
bottomP = [sensorPressurePa(1); sensorPressurePa(4); sensorPressurePa(7)];

topX = [2.16000; 2.17143; 2.18286];
topZ = zmax * ones(3,1);
topP = [sensorPressurePa(1); sensorPressurePa(4); sensorPressurePa(7)];

interpX = [interpX; leftX; rightX; bottomX; topX];
interpZ = [interpZ; leftZ; rightZ; bottomZ; topZ];
interpP = [interpP; leftP; rightP; bottomP; topP];

%% ============================================================
% NORMALIZATION (NEW)
%% ============================================================

interpP = interpP ./ Pnorm;
sensorP_norm = sensorPressurePa ./ Pnorm;

%% ============================================================
% GRID INTERPOLATION
%% ============================================================

nx = 350;
nz = 350;

xg = linspace(min(interpX), max(interpX), nx);
zg = linspace(min(interpZ), max(interpZ), nz);

[XG,ZG] = meshgrid(xg,zg);

F = scatteredInterpolant(interpX, interpZ, interpP, 'natural','nearest');
PG = F(XG,ZG);

%% ============================================================
% 3D SURFACE (NORMALIZED)
%% ============================================================

figure('Color','w','Position',[100 100 1200 700]);

surf(XG,ZG,PG,'EdgeColor','none');
hold on;

scatter3(sensorXZ(:,1), sensorXZ(:,2), sensorP_norm, ...
    100,'k','filled');

for k = 1:length(sensorNames)
    text(sensorXZ(k,1),sensorXZ(k,2),sensorP_norm(k), ...
        ['  ' sensorNames{k}], ...
        'FontWeight','bold');
end

xlabel('X Location (m)')
ylabel('Spanwise Z (m)')
zlabel('Normalized Pressure')

title('Mirrored Surface Pressure Distribution (Normalized)')

view(45,30)
colormap(turbo)
colorbar

shading interp
grid on
box on
set(gca,'FontSize',12)
set(gca, 'YDir','reverse')

%% ============================================================
% CONTOUR PLOT (NORMALIZED)
%% ============================================================

figure('Color','w','Position',[150 150 1100 700]);

contourf(XG,ZG,PG,30,'LineColor','none');
hold on;

scatter(sensorXZ(:,1),sensorXZ(:,2),100,'k','filled');

for k = 1:length(sensorNames)
    text(sensorXZ(k,1),sensorXZ(k,2), ...
        [' ' sensorNames{k}], ...
        'FontWeight','bold');
end

xlabel('X Location (m)')
ylabel('Spanwise Location Z (m)')
title('Mirrored Surface Pressure Contours (Normalized)')

axis equal
xlim([xmin xmax])
ylim([zmin zmax])

colormap(turbo)

cb = colorbar;
cb.Label.String = 'P / P_{ref}';

grid on
box on
set(gca,'FontSize',12)
set(gca, 'YDir','reverse')

%% ============================================================
% SUMMARY TABLE (ABSOLUTE VALUES)
%% ============================================================

Results = table( ...
    sensorNames(:), ...
    sensorXZ(:,1), ...
    sensorXZ(:,2), ...
    sensorPressurePsi, ...
    sensorPressurePa, ...
    sensorP_norm, ...
    'VariableNames',{ ...
    'Sensor',...
    'X',...
    'Z',...
    'AvgGaugePressure_psig',...
    'AvgAbsolutePressure_Pa',...
    'NormalizedPressure'});

disp(' ');
disp(Results);