%% ============================================================
% Surface Pressure 3D + 2D Plotter
%
% Reads surface pressure CSV exported from ParaView and generates:
%
%   1) 3D scatter plot (X-Z-P colored by pressure)
%   2) 2D pressure map (X-Z colored by normalized pressure)
%   3) Optional interpolated surface
%
% Only Points_2 < 0 are retained.
%
% Nine hard-coded sensor locations are overlaid and annotated.
%
%% ============================================================

clear; clc; close all;

%% ============================================================
% USER INPUT
%% ============================================================

[fileName,filePath] = uigetfile('*.csv','Select Surface Pressure CSV');

if isequal(fileName,0)
    error('No file selected.');
end

csvFile = fullfile(filePath,fileName);

%% ============================================================
% SENSOR LOCATIONS
%% ============================================================

sensorNames = { ...
    'S1','S2','S3','S4','S5','S6','S7','S8','S9'};

sensorXZ = [
    2.16     -0.0635;
    2.16     -0.0381;
    2.16      0.0;
    2.17143  -0.0635;
    2.17143  -0.0381;
    2.17143   0.0;
    2.18286  -0.0635;
    2.18286  -0.0381;
    2.18286   0.0];

%% ============================================================
% READ DATA
%% ============================================================

T = readtable(csvFile);

x = T.Points_0;
z = T.Points_2;
p = T.pressureavg;

%% ============================================================
% FILTER
%% ============================================================

idx = z < 1;

x = x(idx);
z = z(idx);
p = p(idx);

%% ============================================================
% NORMALIZATION
%% ============================================================

p = p ./ 159000.0; % stagnation pressure normalization

%% ============================================================
% SENSOR PRESSURE EXTRACTION
%% ============================================================

sensorPressure = zeros(size(sensorXZ,1),1);

for k = 1:size(sensorXZ,1)

    dx = x - sensorXZ(k,1);
    dz = z - sensorXZ(k,2);

    dist = sqrt(dx.^2 + dz.^2);

    [~,I] = min(dist);

    sensorPressure(k) = p(I);

end

%% ============================================================
% =============================================================
% 3D SCATTER PLOT
% =============================================================
%% ============================================================

figure('Color','w');

scatter3(x, z, p, 10, p, 'filled');
hold on;

scatter3(sensorXZ(:,1), sensorXZ(:,2), sensorPressure, ...
    120, 'k', 'filled');

for k = 1:length(sensorNames)
    text(sensorXZ(k,1), sensorXZ(k,2), sensorPressure(k), ...
        ['  ' sensorNames{k}], ...
        'FontSize',10,'FontWeight','bold','Color','k');
end

xlabel('X Location');
ylabel('Z Location');
zlabel('Normalized Pressure');

title('Surface Pressure Distribution (3D)');

grid on; box on;
view(45,30);

cb = colorbar;
cb.Label.String = 'Normalized Pressure';

colormap(turbo);
set(gca,'FontSize',12);
set(gca, 'YDir','reverse');

%% ============================================================
% =============================================================
% NEW: 2D PRESSURE MAP (X-Z colored by pressure)
% =============================================================
%% ============================================================

figure('Color','w');

scatter(x, z, 15, p, 'filled');

hold on;

scatter(sensorXZ(:,1), sensorXZ(:,2), 80, 'k', 'filled');

for k = 1:length(sensorNames)
    text(sensorXZ(k,1), sensorXZ(k,2), ...
        ['  ' sensorNames{k}], ...
        'FontSize',10,'FontWeight','bold','Color','k');
end

xlabel('X Location');
ylabel('Z Location');
title('2D Pressure Field (Normalized)');

grid on; box on;

colormap(turbo);
cb = colorbar;
cb.Label.String = 'Normalized Pressure';

set(gca,'FontSize',12);
set(gca, 'YDir','reverse')
axis tight;

%% ============================================================
% OPTIONAL: INTERPOLATED 2D CONTOUR MAP
%% ============================================================

figure('Color','w');

F = scatteredInterpolant(x, z, p, 'natural', 'none');

xg = linspace(min(x), max(x), 300);
zg = linspace(min(z), max(z), 300);

[XG, ZG] = meshgrid(xg, zg);
PG = F(XG, ZG);

contourf(XG, ZG, PG, 50, 'LineColor', 'none');
hold on;

scatter(sensorXZ(:,1), sensorXZ(:,2), 60, 'k', 'filled');

for k = 1:length(sensorNames)
    text(sensorXZ(k,1), sensorXZ(k,2), ...
        ['  ' sensorNames{k}], ...
        'FontSize',10,'FontWeight','bold','Color','k');
end

xlabel('X Location');
ylabel('Z Location');
title('Interpolated 2D Pressure Field');

colormap(turbo);
colorbar;
grid on; box on;
set(gca, 'YDir','reverse');
axis tight;