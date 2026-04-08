clc;
tic;

printname_this = 'Mie_curve_feb7.pdf';
outfile_this   = 'OPC-response_hr_feb7.dat';
outfile_this   = 'OPC-response_hr.dat';
figure(10);clf;hold on;set(gcf,'Color','w');


%% Model using Mie Code

% Lengths are all in nanometers

% ylimits = [1 8.5];    % log10 normalized pulse height
% xlimits = [100 20000]; % nm

ylimits = [1 5];    % log10 normalized pulse height
xlimits = [200 6000]; % nm
rerun = 0;
if rerun
    Dp = logspace(log10(xlimits(1)), log10(xlimits(2)), 10000)';
    lambda = 655.0; theta = [9 90];
    
    % PSL https://refractiveindex.info/?shelf=organic&book=polystyren&page=Sultanova
    n = 1.5858 + 0*1i;   % at 655 nm wavelength; Sultanova, Kasarova, Nikolov 2009 - website
    I1 = opc_response(Dp, lambda, n, theta);
    
    % Dry ammonium sulfate http://onlinelibrary.wiley.com/doi/10.1029/JC081i033p05733/epdf
    n = 1.525 + 0*1i; % at 656 nm wavelength; Toon, Pollack, Khare 1976
    I2 = opc_response(Dp, lambda, n, theta);
    
    % Dry succinic acid (Krishnan et al. 2008, doi 10.1002/crat.200711102
    % at 655.0 nm, WebPlotDigitizer, Figure 5.
    n = 0.52239 + 1 + 0*1i; % I added 1 to the number because it didn't make sense
    % see also https://www.atmos-chem-phys.net/4/1759/2004/acp-4-1759-2004.pdf
    % refractive index should be similar for all the acids
    I3 = opc_response(Dp, lambda, n, theta);
    
    log10_I1 = log10(I1);
    log10_I2 = log10(I2);
    log10_I3 = log10(I3);
    plot(Dp,log10_I3,'-b');
    
    % 
    % Second light window
    % 
    theta = [120 270];
    
    % PSL https://refractiveindex.info/?shelf=organic&book=polystyren&page=Sultanova
    n = 1.5858 + 0*1i;   % at 655 nm wavelength; Sultanova, Kasarova, Nikolov 2009 - website
    I1 = opc_response(Dp, lambda, n, theta);
    
    % Dry ammonium sulfate http://onlinelibrary.wiley.com/doi/10.1029/JC081i033p05733/epdf
    n = 1.525 + 0*1i; % at 656 nm wavelength; Toon, Pollack, Khare 1976
    I2 = opc_response(Dp, lambda, n, theta);
    
    % Dry succinic acid (Krishnan et al. 2008, doi 10.1002/crat.200711102
    % at 655.0 nm, WebPlotDigitizer, Figure 5.
    n = 0.52239 + 1 + 0*1i; % I added 1 to the number because it didn't make sense
    % see also https://www.atmos-chem-phys.net/4/1759/2004/acp-4-1759-2004.pdf
    % refractive index should be similar for all the acids
    I3 = opc_response(Dp, lambda, n, theta);
    
    plot(Dp,log10(I3),'-b');
    log10_I1 = log10_I1 + log10(I1);
    log10_I2 = log10_I2 + log10(I2);
    log10_I3 = log10_I3 + log10(I3);
    
    
    % Write to file
    fid = fopen(outfile_this,'w');
    format = '%11.6f\t%10.8f\t%10.8f\t%10.8f\n';
    fprintf(fid,format,[Dp,log10(I1),log10(I2),log10(I3)]');
    stat = fclose(fid); if stat~=0; fclose all; end
else
    data = load(outfile_this);
    Dp = data(:,1);
    log10_I1 = data(:,2);
    log10_I2 = data(:,3);
    log10_I3 = data(:,4);
end


%% Plot

data = load('OPC-response_hr.dat');
Dp_hr = data(:,1);log10_I3_hr = data(:,4);

plot(Dp, log10_I3, '.','Color','b', 'LineWidth', 0.75); % Blue is Succinic Acid
% plot(Dp_hr, log10_I3_hr, '-','Color','b', 'LineWidth', 0.75); % Blue is Succinic Acid

avgval = log10_I3_hr;
npts = 4;
for ii = npts+1:length(log10_I3_hr)-npts
    avgval(ii) = mean(log10_I3_hr(ii-npts:ii+npts));
end
plot(Dp_hr, avgval, '-','Color','r', 'LineWidth', 0.75); % Blue is Succinic Acid
return
avgval = log10_I3_hr;
npts = 70;
for ii = npts+1:length(log10_I3_hr)-npts
    avgval(ii) = mean(log10_I3_hr(ii-npts:ii+npts));
end
plot(Dp_hr, avgval, '-','Color','k', 'LineWidth', 0.75); % Blue is Succinic Acid

plot(Dp, log10_I2, '-','Color',[1 .5 0], 'LineWidth', 0.75); % Orange is Amm. Sulf.
plot(Dp, log10_I1, '-','Color','k', 'LineWidth', 0.75); % Black is PSL
% semilogx(Dp*1.3, log10(I2), '--k', 'Linewidth', 2);


thresholds = [0.25 0.28 0.3 0.35 0.4 0.45 0.5 0.58 ... % OPC bins
    0.65 0.7 0.8 1 1.3 1.6 2 2.5 3 3.5 4 5 6.5 7.5 8.5 10 12.5 15 ...
    17.5 20 25 30 32] * 1000; % in nanometers
for ii = 1:length(thresholds)
    plot(thresholds(ii)*[1 1],ylimits,'-','Color',[.5 .5 .5]);
end




% Axes settings
make_wide_figure = 0;
if make_wide_figure
    printsz_inch = [6.5 4];
    rows = 1; cols = 1;
    xlo = 0.07; xce = 0.065; xhi = 0.015; ylo = 0.12; yce = 0.03; yhi = 0.021;
    margins = [xlo xce xhi ylo yce yhi];
    ppos = getPlotPositionPrint(rows,cols,margins,printsz_inch);
else
    printsz_inch = [4 2.5];
    rows = 1; cols = 1;
    xlo = 0.10; xce = 0.065; xhi = 0.015; ylo = 0.20; yce = 0.03; yhi = 0.021;
    margins = [xlo xce xhi ylo yce yhi];
    ppos = getPlotPositionPrint(rows,cols,margins,printsz_inch);
end


% Axes
ylabel('log10 normalized pulse height'); xlabel('Diameter (nm)');
set(gca,'XScale','log','XLim',xlimits,'YLim',ylimits,'Color','none',...
    'Position',ppos,'TickLen',[0.03 0],'FontSize',12,'LineWidth',0.4);

% Print
set(gcf,'paperorientation','portrait','PaperUnits','inch',...
    'PaperSize',printsz_inch,'paperposition',[0 0 printsz_inch]);
print(printname_this, '-dpdf'); fprintf('%s\n',printname_this);



toc
