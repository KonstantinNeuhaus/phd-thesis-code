function data = calibratePowerCurve(powermeter, Motor_Waveplate, wavelength, homePosition,shutter)
    % This function acquires a series of power meausurements for different
    % halve wave plate orientations
    if nargin == 3
        homePosition = -5;
    end
    angular_stepsize = 2.5;
    power_averages = 11;
    % Set Shutter to closed
    shutter.operatingstate = 'inactive';
    % Background Measurement with closed Shutter
    Background_t = average_single_acquisitions(powermeter,power_averages,1);
    Background = 1000*mean(Background_t(2:end));
    shutter.operatingstate = 'active';
    % 
    data(:).Position = homePosition:angular_stepsize:homePosition+55;
    if data.Position(1)< 0
        Motor_Waveplate.moveto(data.Position(1)+360);
    else
        Motor_Waveplate.moveto(data.Position(1));
    end    
   pause(2);

    h1 = figure;
    h_ax = axes('Parent', h1, 'NextPlot', 'add');
    box on;
    xlabel('Angular Position','Fontsize',16);
    ylabel('Laser Power [mW]','Fontsize',16);
    h_ax.XLim = [homePosition, 95];
    title(num2str(wavelength))
    for k = 1:length(data.Position(:))
        % Move to position 
        if data.Position(k)< 0
            Motor_Waveplate.moveto(data.Position(k)+360);
        else
            Motor_Waveplate.moveto(data.Position(k));
        end
        % wait for motor
        pause(0.4);
    
        % Measure Power
        powerMeasurements_t = 1000*average_single_acquisitions(powermeter,power_averages,1);
        powerMeasurements = powerMeasurements_t(2:end);
    
        data.Measurement(k,:) = powerMeasurements;
        data.Measurement_BG_corrected(k,:) = powerMeasurements-Background;
        data.Mean_measurement(k) = mean(powerMeasurements);
        data.Mean_measurement_BG_corrected(k) = mean(data.Measurement_BG_corrected(k,:));
        data.StandardDeviation(k) = std(powerMeasurements);
        data.StandardDeviation_BG_corrected(k) = std(data.Measurement_BG_corrected(k,:));
        % Plot
        errorbar(h_ax,data.Position(k) ,data.Mean_measurement(k),data.StandardDeviation(k))
    end
    save('data.mat',"data")
end
