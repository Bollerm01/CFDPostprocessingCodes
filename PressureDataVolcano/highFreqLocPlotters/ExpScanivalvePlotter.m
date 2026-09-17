%% ============================================================
% Scanivalve Surface Pressure 3D Plotter (Normalized Version)
%
% CHAN1 -> S1 ... CHAN9 -> S9
% Gauge Pressure (psig) + barometric correction
% Includes user-defined normalization pressure
%
% CHANGE: Interpolation is now performed on the HALF domain
% (Z <= 0), using only the real (non-mirrored) sensor data.
% The resulting interpolated GRID is then mirrored about
% Z = 0 to build the full field, instead of mirroring the
% raw sensor point cloud before interpolating.
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
    {'29.24'});

if isempty(answer)
    error('No barometric pressure entered.');
end

baro_inHg = str2double(answer{1});

if isnan(baro_inHg)
    error('Invalid barometric pressure.');
end

%% ============================================================
% NORMALIZATION PRESSURE INPUT
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
% SENSOR LOCATIONS (real, physical locations only — Z <= 0)
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
% DOMAIN BOUNDS (full, symmetric domain)
%% ============================================================

xmin = 2.1485;
xmax = 2.19475;

zmin = -0.0765;
zmax =  0.0765;   % must equal -zmin for the mirror step to be valid

%% ============================================================
% HALF-DOMAIN DATA (Z <= 0 ONLY) — real sensors, no mirroring
%% ============================================================

interpX = sensorXZ(:,1);
interpZ = sensorXZ(:,2);
interpP = sensorPressurePa;

%% ============================================================
% BOUNDARY EXTENSION (half domain only, Z <= 0)
%% ============================================================

% Left edge (x = xmin), z from zmin up to 0 (no positive-Z points)
leftX = xmin * ones(3,1);
leftZ = [-0.0635; -0.0381; 0.0];
leftP = [
    sensorPressurePa(1);
    sensorPressurePa(2);
    sensorPressurePa(3)];

% Right edge (x = xmax), z from zmin up to 0
rightX = xmax * ones(3,1);
rightZ = [-0.0635; -0.0381; 0.0];
rightP = [
    sensorPressurePa(7);
    sensorPressurePa(8);
    sensorPressurePa(9)];

% Bottom edge (z = zmin), spans x
bottomX = [2.16000; 2.17143; 2.18286];
bottomZ = zmin * ones(3,1);
bottomP = [sensorPressurePa(1); sensorPressurePa(4); sensorPressurePa(7)];

% NOTE: no "top" boundary needed here — the top of the half
% domain is Z = 0, which is already populated by the real
% sensors S3, S6, S9.

interpX = [interpX; leftX; rightX; bottomX];
interpZ = [interpZ; leftZ; rightZ; bottomZ];
interpP = [interpP; leftP; rightP; bottomP];

%% ============================================================
% NORMALIZATION
%% ============================================================

interpP = interpP ./ Pnorm;
sensorP_norm = sensorPressurePa ./ Pnorm;

%% ============================================================
% GRID INTERPOLATION — HALF DOMAIN ONLY (Z <= 0)
%% ============================================================

nx      = 350;
nz_half = 176;   % zmin ... 0 inclusive

xg      = linspace(xmin, xmax, nx);
zg_half = linspace(zmin, 0, nz_half);

[XG_half, ZG_half] = meshgrid(xg, zg_half);

F = scatteredInterpolant(interpX, interpZ, interpP, 'linear','nearest');
PG_half = F(XG_half, ZG_half);

%% ============================================================
% MIRROR THE INTERPOLATED GRID ABOUT Z = 0
%% ============================================================

% Reflect all rows except the Z = 0 row (avoid duplicating it)
zg_mirror = -fliplr(zg_half(1:end-1));      % ascending, (0, zmax]
PG_mirror = flipud(PG_half(1:end-1,:));     % matching reflected rows

zg = [zg_half, zg_mirror];                  % full Z vector, zmin..zmax
PG = [PG_half; PG_mirror];                  % full interpolated field

[XG,ZG] = meshgrid(xg, zg);

%% ============================================================
% 3D SURFACE (NORMALIZED)
%% ============================================================

figure('Color','w','Position',[930 381 768 500]);

surf(XG,ZG,PG,'EdgeColor','none');
hold on;



xlabel('X Location (m)')
ylabel('Spanwise Z (m)')
zlabel('Normalized Pressure')

title('Experimental Cavity Floor Pressure Distribution')

view(45,30)
colormap(turbo)
cb = colorbar;
cb.Label.String = 'P / P_{ref}';
clim([0.1380 0.1412]);

scatter3(sensorXZ(:,1), sensorXZ(:,2), sensorP_norm, ...
    100,'k','filled');

% for k = 1:length(sensorNames)
%     text(sensorXZ(k,1),sensorXZ(k,2),sensorP_norm(k), ...
%         ['        ' sensorNames{k}], ...
%         'FontWeight','bold');
% end

shading interp
grid on
box on
set(gca,'FontSize',12)
set(gca, 'YDir','reverse')


%% ============================================================
% CONTOUR PLOT (NORMALIZED)
%% ============================================================

figure('Color','w','Position',[150 150 1100 700]);

% contourf(XG,ZG,PG,500,'LineColor','none');
pcolor(XG,ZG,PG);
hold on;

scatter(sensorXZ(:,1),sensorXZ(:,2),100,'white','filled');

for k = 1:length(sensorNames)
    text(sensorXZ(k,1),sensorXZ(k,2), ...
        ['    ' sensorNames{k}], ...
        'FontWeight','bold', 'Color', 'w');
end

xlabel('X Location (m)')
ylabel('Spanwise Location Z (m)')
title('Experimental Cavity Floor Surface Pressure Contours')

axis equal
shading interp
xlim([xmin xmax])
ylim([zmin zmax])

colormap(turbo)

cb = colorbar;
cb.Label.String = 'P / P_{ref}';
clim([0.1380 0.1412]);

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