%% ============================================================
% Floor + Ramp Surface Pressure Plotter
%
% Reads TWO surface pressure CSVs exported from ParaView:
%   - Floor surface (assumed flat, elevation ~constant)
%   - Ramp surface  (inclined 22.5 deg, elevation varies with x)
%
% FLOOR data:  Points_0 (x), Points_2 (z), pressureavg      -> x,z,p only
% RAMP  data:  Points_0 (x), Points_1 (y), Points_2 (z), pressureavg
%
% Ramp is filtered to 0.000216 <= y <= 0.018809 before plotting.
%
% Generates 3 figures:
%   1) 2D ramp pressure map in LOCAL ramp-face coordinates
%      (x,y rotated -22.5 deg so the incline reads as "flat")
%   2) 2D X-Z pressure map with floor + ramp overlaid
%   3) 3D combined floor + ramp surface, contoured by pressure
%
%% ============================================================

clear; clc; close all;

%% ============================================================
% USER INPUT — SELECT FILES
%% ============================================================

[floorFile, floorPath] = uigetfile('*.csv', 'Select FLOOR Surface Pressure CSV');
if isequal(floorFile, 0)
    error('No floor file selected.');
end

[rampFile, rampPath] = uigetfile('*.csv', 'Select RAMP Surface Pressure CSV');
if isequal(rampFile, 0)
    error('No ramp file selected.');
end

floorCsv = fullfile(floorPath, floorFile);
rampCsv  = fullfile(rampPath, rampFile);

%% ============================================================
% CONSTANTS
%% ============================================================

P_stag    = 159000.0;   % stagnation pressure for normalization [Pa]
rampAngle = 22.5;       % ramp incline angle [deg]

% Ramp elevation (Points_1) filter range
yMin = 0.000216;
yMax = 0.018809;

%% ============================================================
% READ FLOOR DATA (x, z, pressure only)
%% ============================================================

T_floor = readtable(floorCsv);

x_floor = T_floor.Points_0;
z_floor = T_floor.Points_2;
p_floor = T_floor.pressureavg;

p_floor = p_floor ./ P_stag;   % normalize

%% ============================================================
% READ RAMP DATA (x, y, z, pressure)
%% ============================================================

T_ramp = readtable(rampCsv);

x_ramp = T_ramp.Points_0;
y_ramp = T_ramp.Points_1;
z_ramp = T_ramp.Points_2;
p_ramp = T_ramp.pressureavg;

% Filter ramp by elevation (Points_1) range
idx_ramp = (y_ramp >= yMin) & (y_ramp <= yMax);

x_ramp = x_ramp(idx_ramp);
y_ramp = y_ramp(idx_ramp);
z_ramp = z_ramp(idx_ramp);
p_ramp = p_ramp(idx_ramp);

p_ramp = p_ramp ./ P_stag;   % normalize

%% ============================================================
% RAMP: LOCAL (UNROLLED) SURFACE COORDINATE
%
% Rotate (x,y) by the ramp incline angle so the ramp face reads
% as a flat plane. Spanwise coordinate (z) is unaffected by this
% rotation since the incline is assumed to run in the x-y plane.
%
%   s_ramp = distance along the ramp face (streamwise, in-plane)
%% ============================================================

s_ramp = x_ramp .* cosd(rampAngle) + y_ramp .* sind(rampAngle);

%% ============================================================
% =============================================================
% FIGURE 1: 2D RAMP PRESSURE MAP (local, incline-corrected)
% =============================================================
%% ============================================================

figure('Color', 'w');

scatter(s_ramp, z_ramp, 15, p_ramp, 'filled');

xlabel('Distance Along Ramp (s, m)');
ylabel('Spanwise Location (Z, m)');
title('Ramp Avg. Surface Pressure');

grid on; box on;
colormap(turbo);
cb = colorbar;
cb.Label.String = 'P/P_{ref}';
cb.Label.Rotation = 0.0;

set(gca, 'FontSize', 12);
set(gca, 'YDir', 'reverse');
axis tight;

%% ============================================================
% =============================================================
% FIGURE 2: 2D X-Z MAP — FLOOR + RAMP OVERLAID
% =============================================================
%% ============================================================

figure('Color', 'w');
hold on;

scatter(x_floor, z_floor, 12, p_floor, 'filled');
scatter(x_ramp,  z_ramp,  12, p_ramp,  'filled');

xlabel('Axial Location (X, m)');
ylabel('Spanwise Location (Z, m)');
title('Avg. Surface Pressure Field');

grid on; box on;
colormap(turbo);
cb = colorbar;
cb.Label.String = 'P/P_{ref}';
cb.Label.Rotation = 0.0;

set(gca, 'FontSize', 12);
set(gca, 'YDir', 'reverse');
axis tight;

%% ============================================================
% =============================================================
% FIGURE 3: 3D COMBINED FLOOR + RAMP, CONTOURED BY PRESSURE
%
% Floor has no elevation (Points_1) data — assumed flush with the
% base of the ramp, so y_floor is set to 0. Adjust P_stag/y_floor
% baseline below if the floor sits at a different reference height.
% =============================================================
%% ============================================================

y_floor = zeros(size(x_floor));   % assumed floor elevation baseline

figure('Color', 'w');
hold on;

% Triangulate each surface in its own natural 2D plane, then plot
% the real 3D coordinates so both surfaces appear as contoured
% patches rather than scattered points.

tri_floor = delaunay(x_floor, z_floor);
trisurf(tri_floor, x_floor, z_floor, y_floor, p_floor, ...
    'EdgeColor', 'none');

tri_ramp = delaunay(s_ramp, z_ramp);
trisurf(tri_ramp, x_ramp, z_ramp, y_ramp, p_ramp, ...
    'EdgeColor', 'none');

xlabel('Axial Loc. (m)');
ylabel('Spanwise Loc. (m)');
zlabel('Height (m)');
title('Avg. Surface Pressure Field');

grid on; box on;
view(-45, 30);
shading interp;
lighting none;

colormap(turbo);
cb = colorbar;
cb.Label.String = 'P/P_{ref}';
cb.Label.Rotation = 0.0;

set(gca, 'FontSize', 12);
axis tight; axis equal;