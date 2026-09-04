%% Fit power curve for multiple wavelength measurements


wavelengths = 710:5:820;
for k = 1:length(wavelengths)

    [fitParam,f] = fitPowerCurve(data(k).Position,data(k).Mean_measurement ,0);
    
    data_fit(k).wavelengths = wavelengths(k);
    data_fit(k).MaxPower = fitParam(1);
    data_fit(k).Offset = fitParam(2);
end

figure;



%% Calculate Motor Positions so power at each wavelenth is the same

power2Set = 200;
ft = fittype('I*(cosd(2*x-offset))^2','coefficients',{'I','offset'});

for k = 1:length(wavelengths)
    Position(1,k) = wavelengths(k);
    Position(2,k) = 0.5*(acosd(sqrt(power2Set/data_fit(k).MaxPower))+data_fit(k).Offset);
    Position(3,k) = 100*power2Set/data_fit(k).MaxPower;
end

%% Fit power curve for multiple wavelength measurements and show in same plot!
wavelengths = 710:5:820;
h1 = figure(Visible="off");
h_ax = axes('Parent', h1, 'NextPlot', 'add');
for k = 1:length(wavelengths)
    [fitParam,f] = fitPowerCurve_samePlot(data(k).Position,data(k).Mean_measurement ,h_ax);
    data_fit(k).wavelengths = wavelengths(k);
    data_fit(k).MaxPower = fitParam(1);
    data_fit(k).Offset = fitParam(2);
end

h1.Visible= 1;
