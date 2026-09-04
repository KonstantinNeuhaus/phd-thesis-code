% Measure Laserpower for each Wavelength
obj = MaiTai('COM2');
powermeter = Open_powermeter(powermeter,'COM9');
wavelengths = 710:5:820;
power_averages = 12;

mot = motor;
mot.connect('55249114');
mot.home();
% 
sh1 = shutter;
sh1.connect('68800231');  
sh1.operatingmode = 'singletoggle'; 
sh1.operatingmode ='manual';

h1 = figure;
h_ax = axes('Parent', h1, 'NextPlot', 'add');
box on;
xlabel('Wavelength [nm]','Fontsize',16);
ylabel('Laser Power [mW]','Fontsize',16);
h_ax.XLim = [700, 1000];
textprogressbar('Start Calibration of Power Control over wavelength!')
for k = 1:length(wavelengths)
    textprogressbar(k/length(wavelengths));
    % Move to wavelength 
    obj.changeWavelength(wavelengths(k));
    % Change Powermeter Wavelength
    powermeter = SetWavelength(powermeter, wavelengths(k));
    % wait for wavelength set?
    obj.waitForWavelength;
    obj.wavelength;
    % Measure Background
    closeShutter(obj);
    sh1.operatingstate = 'inactive';
    % Background Measurement with closed Shutter
    Background_t = average_single_acquisitions(powermeter,power_averages,1);
    Background = 1000*mean(Background_t(3:end));  
    openShutter(obj);
    sh1.operatingstate = 'active';
    pause(0.2);
    pause(10);
    data(k) = calibratePowerCurve(powermeter, mot, wavelengths(k), -10,sh1);
    save('temp.mat','data')

end
closeShutter(obj);
sh1.operatingstate = 'inactive';