function relativePower = calculateAbsolutePower2Percentage(calibrationFit,wavelength,absolutePower)
    % find index
    index = find([calibrationFit.wavelengths] == wavelength);
    relativePower = 100*absolutePower/calibrationFit(index).MaxPower;
end

