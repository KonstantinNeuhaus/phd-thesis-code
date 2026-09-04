classdef MaiTai < handle
    %% Class to controll Spectra Physics Mai Tai Laser 
    % Tested with Mai Tai BB Laser
    % Author: Konstantin Neuhaus
    % Biozentrum University Basel, Switzerland
    % Email: konstantin.neuhaus@unibas.ch
    % 
    %#ok<*MCSUP> 
    
    %% PROPERTIES
    properties
        port; % Serial Port
        session; % Serial Communication Port
        humidity; % Humidity inside Laser Head
        warmupState; % Warm up state of Laser Diodes
        pumpLaserPower; % current Pump Laser Power in W
        pumpLaserPowerPercentage;  % Current Pump Laser Power in %
        wavelengthMin; % minimum wavelength of tuning range in nm
        wavelengthMax; % maximum wavelength of tuning range in nm    
        lastWavelengthSet; % Last issued wavelength in nm
        wavelength; % current wavelength in nm
        laserPower; % current TiSa output power in W
        serialNumber; % serial number of laser        
        status; % status code 
        diodeCurrent1; % current Current of laser diode 1
        diodeCurrent2; % current Current of laser diode 2
        diodeTemperature1; % current temperature of laser diode 1 in °C
        diodeTemperature2; % current temperature of laser diode 2 in °C
        shutterOpen; % current state of the shutter (logical)
        modelocker; % current state of the modelocker (logical) (allways keep on)
        phase; % current RF Phase 
        mode; % current laser mode (Constant pump power, constant infrared power, constant pump current)
        shgStatus; % SHG heating status
    end
    
      
    %% CONSTRUCTOR/DESTRUCTOR
    methods

        function obj = MaiTai(port)
            obj.port = port;
            % obj.session = serialport(port,9600,'StopBits',1,'DataBits',8,'Parity','none','FlowControl','software');
            obj.session = serialport(port,38400,'StopBits',1,'DataBits',8,'Parity','none','FlowControl','software');

            configureTerminator(obj.session,'LF', 'CR/LF');
        end                       
        
        function disconnectMaiTai(obj)
            %Delete associated objects (they don't auto-delete for some reason)
            delete(obj.session);
            delete(obj);
            disp('Mai Tai was disconnected.')
            clear('obj');
        end

    end
    
    %% PROPERTY ACCESS
    methods
        % get Shutter state
        function val = get.shutterOpen(obj)
        	writeline(obj.session,'SHUTter?');           
            checkStatus(obj,2);
            val = str2double(readline(obj.session));
            obj.shutterOpen = val;
        end
        
        % get warm up state
        function val = get.warmupState(obj)
            writeline(obj.session,'READ:PCTWarmedup?');
            checkStatus(obj,6);
            str = readline(obj.session);
            % Deal with different answers!!
            val = str2double(extractBefore(str,'%'));
            obj.warmupState = val;
        end

        % get pulsed laser power
        function val = get.laserPower(obj)
            writeline(obj.session,'READ:POWer?');
            % Check answer
            checkStatus(obj,7);
            str = readline(obj.session);
            val = str2double(extractBefore(str,'W'));
            obj.laserPower = val;
        end

        % get current wavelength
        function val = get.wavelength(obj)
            writeline(obj.session,'READ:WAVelength?');
            checkStatus(obj,6);
            str = readline(obj.session);
            val = str2double(extractBefore(str,'nm'));
            obj.wavelength = val;
        end
   
        % get last commanded wavelength
        function val = get.lastWavelengthSet(obj)
            writeline(obj.session,'WAVelength?');
            checkStatus(obj,6);
            str = readline(obj.session);
            val = str2double(extractBefore(str,'nm'));
            obj.lastWavelengthSet = val;
        end     

        % get System ID
        function str = get.serialNumber(obj)
            writeline(obj.session,'*IDN?');
            checkStatus(obj,11);
            str = readline(obj.session);
            obj.serialNumber = extractBetween(str,'MaiTai,',',');
        end

        % get Humidity
        function val = get.humidity(obj)
            writeline(obj.session,'READ:HUM?');
            checkStatus(obj,10);
            str = readline(obj.session);
            val = str2double(extractBefore(str,' HUM'));
            obj.humidity = val;
        end
        
        % get Wavelength min
        function val = get.wavelengthMin(obj)
            writeline(obj.session,'WAVelength:MIN?');
            checkStatus(obj,10);
            str = readline(obj.session);
            val = str2double(extractBefore(str,'nm'));
            obj.wavelengthMin = val;
        end
                
        % get Wavelength max
        function val = get.wavelengthMax(obj)
            writeline(obj.session,'WAVelength:MAX?');
            checkStatus(obj,10);
            str = readline(obj.session);
            val = str2double(extractBefore(str,'nm'));
            obj.wavelengthMax = val;
        end

        % get status byte
        function str = get.status(obj)
            writeline(obj.session,'*STB?');
            checkStatus(obj,2);
            str = readline(obj.session);
            obj.status = str;    
        end

        % get pump laser power
        function val = get.pumpLaserPower(obj)
            writeline(obj.session,'READ:PLASer:POWer?');
            checkStatus(obj,7);
            str = readline(obj.session);
            val = str2double(extractBefore(str,'W'));
            obj.pumpLaserPower = val;
        end

        % get pump diode current 1
        function val = get.diodeCurrent1(obj)
            writeline(obj.session,'READ:PLASer:DIODe1:CURRent?');
            checkStatus(obj,7);
            str = readline(obj.session);
            val = str2double(extractBefore(str,'A1'));
            obj.diodeCurrent1 = val;
        end

        % get pump diode current 2
        function val = get.diodeCurrent2(obj)
            writeline(obj.session,'READ:PLASer:DIODe2:CURRent?');
            checkStatus(obj,7);
            str = readline(obj.session);
            val = str2double(extractBefore(str,'A2'));
            obj.diodeCurrent2 = val;
        end

        % get pump diode temperature 1
        function val = get.diodeTemperature1(obj)
            writeline(obj.session,'READ:PLASer:DIODe1:TEMPerature?');
            checkStatus(obj,7);
            str = readline(obj.session);
            val = str2double(extractBefore(str,'C1'));
            obj.diodeTemperature1 = val;
        end

        % get pump diode temperature 2
        function val = get.diodeTemperature2(obj)
            writeline(obj.session,'READ:PLASer:DIODe2:TEMPerature?');
            checkStatus(obj,7);
            str = readline(obj.session);
            val = str2double(extractBefore(str,'C2'));
            obj.diodeTemperature2 = val;
        end

        % get Mode locker State
        function val = get.modelocker(obj)
            writeline(obj.session,'CONTrol:MLENable?');
            checkStatus(obj,2);
            str = readline(obj.session);
            val = str2double(str);
            obj.modelocker = val;
        end

        % get RF Phase Value
        function val = get.phase(obj)
            writeline(obj.session,'CONTrol:PHAse?');
%             checkStatus(obj,6);
            str = readline(obj.session);
            val = str2double(extractBefore(str,'%'));
            obj.phase = val;
        end

        % get System Mode
        function str = get.mode(obj)
            writeline(obj.session,'MODE?');
            checkStatus(obj,3);
            str = readline(obj.session);
            obj.mode = str;
        end

        % get SHF Status
        function str = get.shgStatus(obj)
            writeline(obj.session,'READ:PLASer:SHGS?');
            checkStatus(obj,3);
            str = readline(obj.session);
            if strcmp(str, '3S')
                obj.shgStatus = 'Tempature is settling';
            elseif strcmp(str,'1S')
                obj.shgStatus = 'Oven is heating';
        	elseif strcmp(str,'2S')
                obj.shgStatus = 'Oven is cooling';
            elseif strcmp(str,'0S')
                obj.shgStatus = 'Oven is not on';
            else
                warning(['Status Code for SHG reads: ',char(str),' indicating an error! Check manual']);
            end
        end

        % read Pump Laser Percentage Current
        function val = get.pumpLaserPowerPercentage(obj)
            writeline(obj.session,'READ:PLASer:PCURrent?');
            checkStatus(obj,6);
            str = readline(obj.session);
            val = str2double(extractBefore(str,'%'));
            obj.pumpLaserPowerPercentage = val;
        end
    end
       
    %% Action Functions
    methods
        % Open Shutter
        function  obj = openShutter(obj)           
            writeline(obj.session,'SHUTter 1');
            obj.shutterOpen();
        end

        % Close Shutter
        function  obj = closeShutter(obj)           
            writeline(obj.session,'SHUTter 0');
            obj.shutterOpen();
        end

        % Change Wavelength
        function  obj = changeWavelength(obj,newWavelength)      
            % Check if wavelength to check is within range of the device
            if newWavelength >= obj.wavelengthMin && newWavelength <=    obj.wavelengthMax
                command = strjoin({'WAVelength ',num2str(newWavelength)});
                writeline(obj.session,command);
            else
                warning(['Cannot set the wavelength to ',num2str(newWavelength),...
                    'nm. This lies outside of the lasers tuning Range: ',...
                    num2str(obj.wavelengthMin),'nm to ',num2str(obj.wavelengthMax),'nm']);
            end
        end

        % Wait for new Wavelength
        function  obj = waitForWavelength(obj)    
            while obj.wavelength() ~= obj.lastWavelengthSet
                pause(0.5);
            end
        end

        % Turn on Pump laser
        function  obj = powerOnPumpLaser(obj)    
            % First check if System is already warmed up, else throw a
            % warning
            val = obj.warmupState;
            if val == 100
                writeline(obj.session,'ON');
            elseif val == 0
                disp('Laser is not warmed up yet. Starting warmup now')
                writeline(obj.session,'ON');

            else
                warning('System is not warmed up yet! Pump laser cannot be started!');
            end
        end

        % Turn off Pump laser
        function  obj = powerOffPumpLaser(obj)    
            writeline(obj.session,'OFF');
        end


        % Save current Status of Mai Tai to return to this mode after unit
        % is powered off and on
        function  obj = saveStatus(obj)    
            write(obj.session,'SAVe');
        end

        % Turn Off/On Mode Locker
        function  obj = setModelocker(obj,newState)  
            if newState == 1
                writeline(obj.session,'CONTrol:MLENable 1');
            elseif newstate == 0
                writeline(obj.session,'CONTrol:MLENable 0');
            end
            obj.modelocker;
        end

        % Set RF Phas Percentage
        function  obj = setRFPhase(obj,newValue)  
            opts.Interpreter = 'tex';
            opts.Default = 'No, keep factory set value';
            answer = questdlg('This value should not be changed by the user! Are you sure you want to change the value from the factory set value?',...
                'Warning!','Yes, change anyway','No, keep factory set value',opts);
            switch answer
                case 'No, keep factory set value'
                    disp('RF Phase was not changed!');
                case 'Yes, change anyway'
                      disp('RF Phase was changed!');
                      command = strjoin({'CONTrol:PHAse',sprintf(newValue,'%.2f')});
                      writeline(obj.session,command);
            end
            obj.phase;
        end

        % Set system operating mode
        function  obj = setMode(obj,newValue)  
            % Check if new Mode is valid
            if strcmp(newValue,'PCURrent') || strcmp(newValue,'PPOWer') || strcmp(newValue,'POWer')
                command = strjoin({'MODE ',newValue});
                writeline(obj.session,command);
                obj.mode;
            else
                warning('Laser Mode could not be changed. User input was invalid. Valid options are: PCURrent, PPower, POWer');
            end
        end

        % Set baut Rate
        function obj = setBaudRate(obj,newValue)
            % Default is 9600 upon power up
            validValues = [300,600,1200,4800,9600,19200,38400,57600];
            isValid = max(newValue == validValues);
            if isValid
                command = strjoin({'SYSTem:COMMunications:SERial:BAUD ',num2str(newValue)});
    
                writeline(obj.session,command);
%                 obj.session.Baudrate =  newValue   
            else
                warning('Baud Rate could not be changed. User input was invalid. Valid options are: 300,600,1200,4800,19200,38400,57600');
            end
        end

        % Get History Buffer of J40/J80 Power Supply
        function buffer = getHistory(obj)
            writeline(obj.session,'PLASer:AHISTory?');
            checkStatus(obj,33);
            str = readline(obj.session);
            buffer = str;
        end
          % Get History Buffer of Laser Head
        function buffer = getHistoryLaserHead(obj)
            writeline(obj.session,'PLASer:AHIS?');
            checkStatus(obj,33);
            str = readline(obj.session);
            buffer = str;
        end      
    end    
   %% Helper Functions
    methods
        function  ready = checkStatus(obj,bytesNeeded)           
            bts = obj.session.NumBytesAvailable;  % checking number of bytes in the response
            while bts < bytesNeeded
                bts = obj.session.NumBytesAvailable;  % checking number of bytes in the response
            end
            ready = 'True';
        end
    end
        

end

% Missing Functions 
% PLASer:ERRCode?
% PLASer:PCURrent
% PLASer:PCURrent?
% PLASer:POWer
% PLASer:POWer?
% SYSTem:ERR?
% TIMer:WATChdog (n)
