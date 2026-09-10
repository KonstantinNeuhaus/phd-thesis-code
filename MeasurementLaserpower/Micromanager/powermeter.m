classdef powermeter < handle
    
    properties   
        port;
        session;
        unit = 'W';
        Interface = 'RS232'; 
        Correction = 'ON'
        background;
        status;
        response;
        wavelength;   
        table_of_wavelengths;
        time_pause = 0.3;
        time_laps = 0.01;  %??
        errorState = false;

    end
    methods
%         function powermeter = powermeter(port)
%             powermeter.port = port;
%         end
        function powermeter = Open_powermeter(powermeter,port)
            %% Setting up initial parameters for the com port
            powermeter.port = port;
            powermeter.session = serialport(port,115200,'Parity','none',StopBits=2,DataBits=8);
            configureTerminator(powermeter.session,'CR/LF','CR/LF')
        end       


        function powermeter = SetInterface(powermeter,Interface)
            command = sprintf('SYSTem:COMMunicate:INTerface %s',Interface);
            writeline(powermeter.session,command);
            pause(0.1);
        end


        function powermeter = SetUnit(powermeter,unit_)
            command = sprintf('CONFigure:MEASure %s',unit_);
            writeline(powermeter.session,command);
            powermeter.unit = unit_;
  
        end

        
        function powermeter = SetWavelengthCorrection(powermeter,Correction)
            command = sprintf('CONFigure:WAVElength:CORRection %s',Correction);
            writeline(powermeter.session,command);
            powermeter.Correction = Correction;
        end          
        
        function powermeter = SetWavelength(powermeter, Wavelength)
            command = sprintf('CONFigure:WAVElength:WAVElength %s',num2str(Wavelength));
            writeline(powermeter.session,command);
            powermeter.wavelength = Wavelength;
        end
        
        function powermeter = GetWavelength(powermeter)
            writeline(powermeter.session,'CONF:WAVElength:WAVElength? \n');
            powermeter.wavelength = str2double(readline(powermeter.session));
        end
        
        %abgezogen?
        function powermeter = GetOffset(powermeter)
            writeline(powermeter.session,'CONFigure:ZERO \n');
            % Get Background
            writeline(powermeter.session,'CONFigure:ZERO? \n');
            powermeter.background = fgets(powermeter.session);
        end
           
        function powermeter = Light(powermeter,light_status)
            if strcmpi(light_status,'off')
                disp('Light of Display will be turned off')
            elseif strcmpi(light_status,'on')
                disp('Light of Display will be turned on')
            else
                error(['Error changing Display Backlight! Non valid light state: ',light_status,' . Valid Options: [On/Off]']);
                return %#ok<UNRCH> 
            end
            command = sprintf('DISPlay:BACKlight %s',light_status);
            writeline(powermeter.session,command);
        end  
        
        %Set Remote Mode == Disable Buttons on Device
        function powermeter = remote_mode(powermeter)
            writeline(powermeter.session,'SYSTem:REMote \n');
        end
        
        %Get Table of Wavelengths
        function table_wavelength = Wavelengths_table(powermeter)
            writeline(powermeter.session,'CONFigure:WAVElength:LIST? \n');
            % Get comma separated list
            table_wavelength = readline(powermeter.session);
        end
      
        function measurement = single_acquisitions(powermeter)
            writeline(powermeter.session,'INIT \n');
            pause(0.1);
            writeline(powermeter.session,'FETC:NEXT? \n');
            pause(0.1);
            status_temp = checkStatus(powermeter);
            if strcmp(status_temp,'True')
                measurement = str2double(readline(powermeter.session));
            else
                measurement = 'none';
            end      
            while isnan(measurement)     
                writeline(powermeter.session,'INIT \n');
                pause(0.1);
                writeline(powermeter.session,'FETC:NEXT? \n');
                pause(0.1);
                status_temp = checkStatus(powermeter);
                if strcmp(status_temp,'True')
                    measurement = str2double(readline(powermeter.session));
                end                 
            end
        end

        
        %% Lösung mit BytesAvailable
        function data = average_single_acquisitions(powermeter,datapoints,mode)

                
            writeline(powermeter.session,'CONF:READ:HEAD OFF \n');
            data_temp = zeros(1,datapoints);
            for i = 1:datapoints
                    data_temp(i) = single_acquisitions(powermeter);
            end
            if nargin == 2
                data = mean(data_temp);       
            else
                data = data_temp;
            end

        end
        
%% Status Check
      function ready = checkStatus(powermeter)
            bts = powermeter.session.NumBytesAvailable;  %%% checking number of bytes in the response

            while bts == 0 
                writeline(powermeter.session,'FETC:NEXT? \n');
                pause(0.1);
                bts = powermeter.session.NumBytesAvailable;  %%% checking number of bytes in the response
            end
            ready = 'True';
        end
        
      
%% Close Conncetion to Powermeter
        function powermeter = Close(powermeter)
            delete(powermeter.session);
            clear powermeter.session
            clear powermeter
        end
                     
        function checkError(powermeter)
            powermeter.errorState = false;
             if contains(powermeter.response,'-350')
                uiwait(msgbox('Queue overflow \n Error queue is full', 'Error', 'error'));
                powermeter.errorState = true;
             elseif contains(powermeter.response,'-321')
                 uiwait(msgbox('Out of memory \n Meter internal memory is exhausted', 'Error', 'error'));
                powermeter.errorState = true;
             elseif contains(powermeter.response,'-310')
                 uiwait(msgbox('System error \n Unexpected/unrecoverable hardware or software fault', 'Error', 'error'));
                 powermeter.errorState = true;
             elseif contains(powermeter.response,'-254')
                 uiwait(msgbox('Media full \n No more storage available on the mass storage volume ', 'Error', 'error'));
                 powermeter.errorState = true;
             elseif contains(powermeter.response,'-200')
                 uiwait(msgbox('Execution error \n Command is out of order', 'Error', 'error'));
                 powermeter.errorState = true;
             elseif contains(powermeter.response,'0')
                 uiwait(msgbox('No error \n No error', 'Error', 'error'));
                 powermeter.errorState = true;
             elseif contains(powermeter.response,'100')
                 uiwait(msgbox('Unrecognized command/query \n The command or query is not recognized', 'Error', 'error'));
                 powermeter.errorState = true;
             elseif contains(powermeter.response,'101')
                 uiwait(msgbox('Invalid parameter \n The command or query parameter is invalid ', 'Error', 'error'));
                 powermeter.errorState = true;
             elseif contains(powermeter.response,'200')
                 uiwait(msgbox('Directory does not exist \n The specified directory does not exist ', 'Error', 'error'));                 
                 powermeter.errorState = true;
             elseif contains(powermeter.response,'201')
                 uiwait(msgbox('File does not exist \n The specified file does not exist ', 'Error', 'error'));
                 powermeter.errorState = true;
             elseif contains(powermeter.response,'202')
                 uiwait(msgbox('Directory already exists \n The specified directory already exists ', 'Error', 'error'));
                 powermeter.errorState = true;
             elseif contains(powermeter.response,'203')
                 uiwait(msgbox('File already exists \n The specified file already exists', 'Error', 'error'));
                 powermeter.errorState = true;
             elseif contains(powermeter.response,'204')
                 uiwait(msgbox('Directory is not empty \n The specified directory is not empty', 'Error', 'error'));                 
                 powermeter.errorState = true;
             elseif contains(powermeter.response,'205')
                 uiwait(msgbox('File query is not possible \n The file query is not possible because the file is not opened', 'Error', 'error'));
                 powermeter.errorState = true;
             elseif contains(powermeter.response,'206')
                 uiwait(msgbox('File to open not named \n The file open is not possible because the named file has not been named', 'Error', 'error'));                
                 powermeter.errorState = true;
            end
        end
    end
end     
       