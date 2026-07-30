%% OVERLAY_FORMULA_ON_FIG (script)
% Opens a GUI dialog to select a .fig file, then overlays a theoretical
% delta/x curve on the existing plot of delta/D vs x/L.
%
% Formula:
%   delta/x = 0.085*(1-r)/(1 + r*sqrt(s)) * ...
%             [1 + sqrt(s) - (1-sqrt(s))/(1 + 2.9*(1+r)/(1-r))]
%
% Notes on assumptions:
%   1) The formula gives delta/x as a CONSTANT for fixed (s, r) — x does
%      not appear elsewhere in the expression. So delta = (delta/x)*x is
%      a straight line through the origin; that line is what gets plotted
%      across the x-range of the existing figure.
%   2) "s = 0.16/0.23 and r = 0.3/2" is interpreted as two paired
%      parameter sets to overlay as two separate curves:
%           Curve 1: s = 0.16, r = 0.3
%           Curve 2: s = 0.23, r = 2
%      Edit the paramSets matrix below if you intended something else
%      (e.g. all four s/r combinations).
%   3) Normalization: y-values (delta) are divided by 0.018593 to get
%      delta/D, and x-values are divided by 0.068418 to get x/L, matching
%      the axes of the existing plot.

clear; clc;

%% ---- GUI: select the .fig file ----
[file, path] = uigetfile('*.fig', 'Select a .fig file to overlay onto');
if isequal(file, 0)
    disp('No file selected. Script cancelled.');
    return;
end
figFile = fullfile(path, file);

%% ---- Normalization constants (given) ----
D_norm = 0.018593;   % delta -> delta/D
L_norm = 0.068418;   % x -> x/L

%% ---- Parameter sets: each row is [s, r] ----
% paramSets = [0.16 , 0.3;
%              0.23, 2.0];

%% ---- Open existing figure and hold it for overlay ----
fig = openfig(figFile, 'reuse');
ax = gca(fig);
hold(ax, 'on');

% Use the current x/L axis range to build the overlay line(s)
xl = xlim(ax);
xL_vals = linspace(xl(1), xl(2), 200);   % normalized x/L values
x_vals  = xL_vals * L_norm;              % corresponding dimensional x

% colors = lines(size(paramSets, 1));
colors = lines(1);

% for k = 1:size(paramSets, 1)
% s = paramSets(k, 1);
% r = paramSets(k, 2);
s = 0.16 / 0.23 ; 
r = 0.3 / 2;

ratio = 0.085 * ((1 - r) / (1 + r*sqrt(s))) * (1 + sqrt(s) - ((1 - sqrt(s)) / (1 + 2.9*(1 + r)/(1 - r))));

delta_vals = ratio .* x_vals;     % delta = (delta/x) * x
delta_D    = delta_vals / D_norm; % normalized y (delta/D)

plot(ax, xL_vals, delta_D, 'LineWidth', 2, 'Color', 'k', 'LineStyle', '--',...
    'DisplayName', sprintf('2D Shear Layer Thy. (s = %.2f, r = %.2f)', s, r));
% end

legend(ax, 'show', 'Location', 'best');
hold(ax, 'off');