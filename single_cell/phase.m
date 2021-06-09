%close all;
%clearvars;

intensity = 1000;
% the phase diagram is generatred by taking the literature accepted values
% and scaling them by the below constants, then determining the equilibrium
% constants
alpha_lower_mult = 1e-6; % lowest multiple of alpha to use
alpha_upper_mult = 1e6; % highest multiple of alpha to use
beta_lower_mult = 1e-4; % lowest multiple of beta to use
beta_upper_mult = 1e4; % highest multiple of beta to use

% number of test values to compute in the phase space
nalphas = 90;
nbetas = 50;


plot_time_series = false; % whether to plot time evolution
runtime = 60; %time to run model for in seconds

currvals = phase_diagram('curr_model', intensity, alpha_lower_mult, alpha_upper_mult, beta_lower_mult, beta_upper_mult, nalphas, nbetas, plot_time_series, runtime);