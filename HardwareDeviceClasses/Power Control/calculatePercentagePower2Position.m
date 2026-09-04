function angularPosition = calculatePercentagePower2Position(calibrationFit,wavelength,Power_percentage)

    % find index
    index = find([calibrationFit.wavelengths] == wavelength);
    
    if Power_percentage <= 100 && Power_percentage >= 0
        angularPosition = 0.5*(acosd(sqrt((Power_percentage/100)))+calibrationFit(index).Offset);
    else
        errordlg('Percentage Power cannot be set since value is below 0% or above 100%!!')
    end
    if angularPosition < 0
        angularPosition = 360+angularPosition;
    end
%         angularPosition = 0.5*(acosd(sqrt((Power/100)*calibrationFit(1)/calibrationFit(1)))+calibrationFit(2));
end