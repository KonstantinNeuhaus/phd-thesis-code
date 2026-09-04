function Power_percentage = calculatePosition2PercentagePower(calibrationFit,wavelength,Position)
    
    % find index
    index = find([calibrationFit.wavelengths] == wavelength);

    Power_percentage = 100*cosd(2*Position-calibrationFit(index).Offset)^2;
end


