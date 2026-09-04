classdef filterwheel < handle
    % Matlab class to control Thorlabs FW100 Series Filter Wheels
    % Author: Konstantin Neuhaus
    % Biozentrum University Basel
    % Email: konstantin.neuhaus@unibas.ch
    %% PROPERTIES
    properties
        serialObj; % Serial port object
        position;
        triggerMode;
        sensorMode;
        firmware;
        model;
        newPosition;
    end

    properties (Constant)
        defaultBaudRate = 115200; % Default baud rate for the FW102
        terminator = "CR/LF"; % Communication terminator
    end
    %% CONSTRUCTOR/DESTRUCTOR
    methods
        function obj = filterwheel(portName)
            % Constructor - Initializes the connection to the FW102
            %   portName: The COM port of the FW102 (e.g., 'COM3').
            if nargin < 1
                error('Please specify the COM port for the FW102.');
            end
%             obj.serialObj = serialport(portName, obj.defaultBaudRate);
%             configureTerminator(obj.serialObj, obj.terminator);
%             flush(obj.serialObj);
            obj.serialObj =  serial('COM6','BaudRate',115200);
            obj.serialObj.StopBits = 1;
            obj.serialObj.DataBits = 8;
            obj.serialObj.Parity = 'none';
            obj.serialObj.Terminator = {'CR' 'CR'};%read and write
            fopen( obj.serialObj);
            disp('Connection to FW102 established.');
        end

        function delete(obj)
            % Destructor - Closes the connection to the FW102
            if ~isempty(obj.serialObj)
                fclose(obj.serialObj);
                delete(obj.serialObj);
            
                clear obj.serialObj
                clear obj
                disp('Connection to FW102 closed.');
            end
        end
    %% PROPERTY ACCESS
    % get Trigger state
    function val = get.triggerMode(obj)
        command = 'trig?';
    	fprintf(obj.serialObj,command);           
        val = str2double(readMessage(obj,command,10));
        obj.triggerMode = val;
    end
    % get Trigger state
    function val = get.sensorMode(obj)
	    command = 'sensors?';           
       	fprintf(obj.serialObj,command);           
        val =  str2double(readMessage(obj,command,13));
        obj.sensorMode = val;
    end

    % get Position
    function val = get.position(obj)
	    command = 'pos?';           
        fprintf(obj.serialObj,command);           
        val = str2double(readMessage(obj,command,9));
        obj.position = val;
    end

    % get ID and Firmware
    function val = get.model(obj)
        command = '*idn?';           
        fprintf(obj.serialObj,command);           
        val = readMessage(obj,command,57);
        substrings = strsplit(val,'/');
        obj.model = char(substrings(1));
        obj.firmware = char(substrings(2));
    end
%% Set Properties

      % Set Trigger mode
      function  obj = setTriggerMode(obj,newState)  
                % Check if new Mode is valid
                if newState == 0  || newState == 1
                    command = strjoin({'trig=',num2str(newState)});
%                     writeline(obj.serialObj,command);
                    fprintf(obj.serialObj,command);           

                    obj.triggerMode;
                else
                    warning('Trigger mode could not be changed. New state value not valid.');
                end
      end

        % Set Sensor mode
        function  obj = setSensorMode(obj,newState)  
                % Check if new Mode is valid
                if newState == 0  || newState == 1
                    command = strjoin({'sensors=',num2str(newState)});
%                     writeline(obj.serialObj,command);
                    fprintf(obj.serialObj,command);           

                    obj.triggerMode;
                else
                    warning('Sensors mode could not be changed. New state value not valid.');
                end
        end   

        % Set Position 
        function  obj = setPosition(obj,newPosition)  
                % Check if new Mode is valid
                if ismember(newPosition, 1:6)
                    command = strjoin({'pos=',num2str(newPosition)});
                    obj.newPosition = newPosition;
%                     writeline(obj.serialObj,command);
                    fprintf(obj.serialObj,command);           

                    obj.position;
                    % Wait until position is reached?
                else
                    warning('Could not move Filter Wheel to new position as input was not valid.');
                end
        end     
    end

  %% Helper Functions
    methods
        function  ready = checkStatus(obj,bytesNeeded)           
            bts = obj.serialObj.BytesAvailable;  % checking number of bytes in the response
            while bts < bytesNeeded
                bts = obj.serialObj.BytesAvailable;  % checking number of bytes in the response
            end
            ready = 'True';
        end
        
        function  message = readMessage(obj,command,bytesNeeded)
            % Check if command is correct
            bts = obj.serialObj.BytesAvailable;  % checking number of bytes in the response
            while bts < bytesNeeded
                bts = obj.serialObj.BytesAvailable;  % checking number of bytes in the response
            end
            % Read first the send command
            message_1 = strtrim(fgets(obj.serialObj));
            if strcmp(message_1,command)
                % Check if command is correct
                bts = obj.serialObj.BytesAvailable;  % checking number of bytes in the response
                while bts < 4
                    bts = obj.serialObj.BytesAvailable;  % checking number of bytes in the response
                end
                % Now read answer to command
                message = strtrim(fgets(obj.serialObj));
            else 
                message = 'Error!';
            end
            % Flush 
            try
                while obj.serialObj.BytesAvailable > 0
                    fscanf(obj.serialObj,'%e',obj.serialObj.BytesAvailable);
                end
            end
        end       
        
        function  ready = positionReached(obj) 
            currentPos = obj.position;

            while currentPos ~= obj.newPosition
                currentPos = obj.position;
            end
            ready = 'True';
        end
    end
end
