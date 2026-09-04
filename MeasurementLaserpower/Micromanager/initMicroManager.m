function MM = initMicroManager
    % Start Micromanager 
    MM.gui = org.micromanager.internal.MMStudio(false);
    try % for MicroManager 2.0 Beta 
        MM.mmc = MM.gui.getCore;
    catch % for MicroManager 2.0.0 and newer
        MM.mmc = MM.gui.getCMMCore;
    end
    MM.acq = MM.gui.getAcquisitionEngine;
    try % for MicroManager 2
        MM.disp = org.micromanager.internal.MMUIManager(MM.gui);
        MM.version = 2.01;
    catch
        MM.version = 2;
    end
    disp('Micro-Manager started');
end
% MM.snapLive = MM.gui.getSnapLiveManager
% MM.snapLive.isLiveModeOn
% MM.snapLive.snap(1)
% org.micromanager.internal.
% MM.snapLive.setLiveModeOn(1)