function absolutePower = calculatePosition2absolutePower(calibrationFit,wavelength,Position)
    % find index
    index = find([calibrationFit.wavelengths] == wavelength);
    
    absolutePower = calibrationFit(index).MaxPower*cosd(2*Position-calibrationFit(index).Offset)^2;

end

