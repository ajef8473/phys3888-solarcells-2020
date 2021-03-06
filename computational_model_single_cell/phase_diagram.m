function results = phase_diagram(model, I, alpha_lower_mult, alpha_upper_mult, beta_lower_mult, beta_upper_mult, nalphas, nbetas, plot_time_series, runtime)
%% Generate the equilibrium short circuit current phase diagram by scaling constants from the literature, usese the specified model and incident intensity
% model:              The model of the solar cell to use
% I:                     The incident intensity to model in W/m^2
% alpha_lower:    The lower multiple of alpha (min value is alpha * alpha_lower)
% alpha_upper:    The upper multiple of alpha (max value is alpha * alpha_upper)
% beta_lower:     The lower multiple of beta (min value is beta * beta_lower)
% beta_upper:     The upper multiple of beta (max value is beta * beta_upper)
% nalphas:            Number of alphas to test in the range
% nbetas:             Number of betas to test in the range
% plot_time_series: Whether to plot the time evolution of the cells (disable for large numbers of Nalphas/Nbetas)
% runtime:            Time in seconds to run simulation for (use longer times for more sensitive equilibria / large alpha/beta)
% 
                            
%% set up simulation and rate constants

switch model
    case 'ajtraps'
        % intial trapping model
        fun = @aj_simple_model;
        
    case 'simple_traps'
        % more advanced trapping model with no loss of carriers due to current
        fun = @trap_model;
        
    case 'curr_model'
        % most advanced model accounting for (linear) trapping/detrapping as well as short circuit current
        fun = @curr_model;
        
end


%% constants
e = 1.602e-19; % fundamental charge in coulombs
% retrieve literature constants
[ks, epsilon, mu_h, mu_e, d] = aj_constants_fun(I);

% define alpha and beta
alpha0 = ks(5) / ks(6);
beta0 = ks(1) / ks(4); 

% setup range of parameters to test
alphas = alpha0 * 10.^ linspace(log10(alpha_lower_mult), log10(alpha_upper_mult), nalphas) ;
betas =  beta0 * 10 .^ linspace(log10(beta_lower_mult), log10(beta_upper_mult), nbetas) ;

% intialise results arrays
results = zeros(nalphas, nbetas);
currs = zeros(nalphas, nbetas);


if plot_time_series
    figure()
end
%% simulate
for i = 1:nalphas
    for j = 1:nbetas
        alpha = alphas(i);
        beta = betas(j);

        % generate a new set of constants ks, and plug them into the ode
        ks = phase_constants(alpha, beta, ks);
        dydt = fun(I, ks, epsilon, mu_h, mu_e, d);
        
        % time interval
        tspan = [0,runtime];

        % inital conditions [conc exitons, conc occupied traps, conc of free electrons] 
        y0 = [1e10;1e10;1e10];

        % integrate
        [ts, ys] = ode15s(dydt, tspan, y0);
        
     %% calculate results
        ne = ys(:,3);
        nt = ys(:,2);
        nx = ys(:,1);
        nh = ne + nt;
        Jsc = e^2 * d * (mu_h* nh + mu_e * ne).* (nh - ne)/ epsilon;
        
        h = 6.626e-34; %Planck's constant, m^2 kg / s
        c = physconst("Lightspeed"); 

        incidentWavelength = 500e-9; %m

        photonEnergy = (h * c) ./ incidentWavelength; %energy of the given incident photons, J
        photonFluxDensity = I ./ photonEnergy; %photon flux density, #photons.m^-2.s^-1

        quantum_efficiency = (Jsc(end) / e) / photonFluxDensity;
        
        % store caclulations
        results(i,j) = quantum_efficiency;
        currs(i,j) = Jsc(end);

        %% Plot time evolution
        if plot_time_series
            % not physical, mostly for debugging purposes
            subplot(2,2,1)
            plot(ts(:) * 1e6, nx)
            hold on;

            ylabel("Exciton Concentration")
            xlabel("t (\mu s)")

            subplot(2,2,2)
            plot(ts(:) * 1e6, nt)
            hold on;

            ylabel("Occupied Trap Concentration")
            xlabel("t (\mu s)")

            subplot(2,2,3)
            plot(ts(:) * 1e6, ne)
            hold on;

            ylabel("Free Electron Concentration")
            xlabel("t (\mu s)")

            subplot(2,2,4)
            plot(ts(:) * 1e6, Jsc)
            hold on;

            ylabel("Current density")
            xlabel("t (\mu s)")
        end
    end
end
% plot legend for time series
if plot_time_series
    subplot(3,1,1)
    names = string(ints);
    l = legend(names);
    title(l, 'Intensity (watts)')
end
   
% plot phase diagram
[XS, YS] = meshgrid(log10(alphas / alpha0), log10(betas / beta0));
figure()
hold on;
colormap(hsv)
results = currs;

p =pcolor(XS, YS, log10(abs(results')));
set(p, 'EdgeColor', 'none');
plot([0], [0], 'xk', 'MarkerSize', 30) % plot lit values


xlabel('Multiple of literature trapping / detrapping rate (kT / kdT)')
ylabel('Multiple of literature exciton dissociation / free charge recombination rate (k1 / kr)')
%title(sprintf("Phase diagram at I=%dW/m^2, X is literature constants", I) )

f = gca();
xs = f.XTickLabel;
ys = f.YTickLabel;


% Make the scale labels multiples rather than log10(multiple)
for i = 1:length(xs)
    xs{i} = sprintf("10^{%s}", xs{i});
end

for i = 1:length(ys)
    ys{i} = sprintf("10^{%s}", ys{i});
end

f.XTickLabel = xs;
f.YTickLabel = ys;

c = colorbar();
c.Label.String = 'log10(Jsc)';

% Adjust font size for readability
f.FontSize = 16;
c.FontSize = 18;
