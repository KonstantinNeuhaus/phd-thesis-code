%% Power Calculation    
function [fitParam,f] = fitPowerCurve(xData,yData,showPlot)
if nargin ==2
    showPlot = 1;
end
    % Based on Malus Law
    %I = I0(cosθ)2
    %Rotation of the 1/2 wave-plate by ø degrees leads to 2ødegrees of polarization rotation. 
    % --> I = I0(cos(2*θ)2
    ft = fittype('I*(cosd(2*x-offset))^2','coefficients',{'I','offset'});
    try
        [f, gof] =  fit(xData,yData,ft);
    catch
        [f, gof] =  fit(xData',yData',ft);
    end
    fitParam = [f.I, f.offset];

    % Show Plot
    if showPlot
        h1 = figure;
        h_ax = axes('Parent', h1, 'NextPlot', 'add');
        box on;
        plot(h_ax, xData, feval(f, xData), '-', 'Color', [0 0.4470 0.7410], 'LineWidth', 1.5)
        % plot(h_ax,f,xData,yData);
        plot(h_ax, xData(1:3:end), yData(1:3:end), 'o', 'MarkerSize', 6)
        xlabel('Angular Position [°]','Fontsize',16);
        ylabel('Laser Power [mW]','Fontsize',16);
        % yticks(0:200:1400);
        xticks(-10:10:60)
        % ylim([-50,1400])
        % disp(['R² = ', num2str(gof.rsquare, '%.6f')])
        % disp(['Adjusted R² = ', num2str(gof.adjrsquare, '%.6f')])
        % disp(['RMSE = ', num2str(gof.rmse, '%.2f'), ' mW'])
    end
end
