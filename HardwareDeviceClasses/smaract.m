 classdef smaract < handle
    % Class to control Smaract smaracts via ASCII Comamnds over the Ethernet Port
    % Written by Konstantin Neuhaus (konneuhaus@gmail.com)
    
    %% Class Propertys
    properties   
        port = 55551; % TCP Port  for ASCII 
        session;
        status;
        response;
        time_pause = 0.3;
        time_laps = 0.01;  %??
        terminator;
        device;
        errormessage = false;
        channels;        
        ConnectedStages;
        stage_states = {'Actively moving','Closed Loop Active', 'Calibrating', 'Referencing', ...
                'Move Delayed', 'Sensor Present', 'Is Calibrated', 'Is Referenced', 'End Stop Reached', ...
                'Range Limit Reached', 'Following Limit Reached', 'Movement Failed', 'Is Streaming', ...
                'Empty State Flag','Over Temperature', 'Reference Mark','Movement Mode','Stage Position','Stage Velocity','Stage Acceleration'};
    end
    
    %% Class Methods
    methods
        %% Initialize Controller
        function smaract = Init(smaract)
            smaract.session = tcpip('192.168.1.200',smaract.port);
            smaract.session.Terminator = {'CR/LF' 'CR/LF'};%read and write
            fopen(smaract.session);
            smaract.status = 'Open';
            % Get some device Properties 
%             smaract = getDeviceNumberOfConnectedStages(smaract);
%             smaract = getDeviceSerialNumber(smaract);
%             smaract = getDeviceName(smaract);
        end
        

    %% Device/Controler Propertys
      % Get Device Propertys
        function smaract = getDeviceNumberOfChannels(smaract)
            command = strjoin({':DEVice:NOCHannels?','\n'});
            fprintf(smaract.session, command);
            smaract.device.channels = str2double(getAnswer(smaract));
        end     
        
        function smaract = getDeviceNumberOfConnectedStages(smaract)
            command = strjoin({':DEVice:NOBModules?','\n'});
            fprintf(smaract.session, command);
            detectedStages = str2double(getAnswer(smaract));
            smaract.ConnectedStages = 0;
            % Check if a Stage is connected to input
            for idx = 1:detectedStages
                smaract = getStageState(smaract,idx-1);
                if smaract.stage_states{idx,6} == 'Sensor Present'
                    smaract.ConnectedStages = smaract.ConnectedStages +1;
                end
            end
        end     
        
        function smaract = getDeviceState(smaract)
            command = strjoin({':DEVice:STATe?','\n'});
            fprintf(smaract.session,command);
            answer_bit = getAnswer(smaract); 
            bits = bitget(str2double(answer_bit),1:16);
            state_flags = {'Hand Control Module attached','Movement Locked',...
                'No State Flag','No State Flag','No State Flag','No State Flag',...
                'No State Flag','No State Flag','Internal Communication Failure',...
                'No State Flag','No State Flag','No State Flag','Is Streaming'};
            for idx = 1:13
                if bits(idx) 
                    smaract.device.state{idx} = state_flags{idx};
                else
                   smaract.device.state{idx} = '0';
                end  
            end
            if smaract.device.state{1} == 'Hand Control Module attached'
                disp('Hand Control attached');
            end
            if smaract.device.state{2} == 'Movement Locked'
                disp('Movement is Locked due to an emergency stop condition');
            end
            if smaract.device.state{9} == 'Internal Communication Failure'
                disp('Internal Communication Failure');
            end
            if smaract.device.state{13} == 'Is Streaming'
                disp('Device is Streaming');
            end
        end
        
        function smaract = getDeviceSerialNumber(smaract)
            command = strjoin({':PROPerty:DEVice:SNUMber?','\n'});
            fprintf(smaract.session, command);
            smaract.device.serial_number = getAnswer(smaract);
        end     
        
        function smaract = getDeviceName(smaract)
            command = strjoin({':DEVice:NAME?','\n'});
            fprintf(smaract.session, command);
            smaract.device.DeviceName = getAnswer(smaract);
        end
        
        function smaract = getDeviceEmergencyStopMode(smaract)
            command = strjoin({':DEVice:ESTop:MODE?','\n'});
            fprintf(smaract.session, command);
            answer = getAnswer(smaract);
            disp(answer)
            if answer == '0'
                % All Movement is stopped. Afterwards smaract behaves normally
                smaract.device.EmergencyStopMode = 'Default'; 
            elseif answer == '1'
                % All Movement is stopped. Afterwards all smaracts has to be released before they can move again
                smaract.device.EmergencyStopMode = 'Restricted'; 
            elseif answer == '2'
                %All Movement is stopped. Details in Handbook
                smaract.device.EmergencyStopMode = 'Auto Release'; 
            end
        end    
        
        function smaract = getDeviceNetworkDiscoverMode(smaract)
            command = strjoin({':DEVice:NETWork:DISCover:MODE?','\n'});
            fprintf(smaract.session,command);
            answer = getAnswer(smaract); 
            if answer == '0'
                smaract.device.NetworkDiscoverMode = 'network discover mode disabled';
            elseif answer == '1'
                smaract.device.NetworkDiscoverMode = 'network discover mode is passive';
            elseif answer == '2'
                smaract.device.NetworkDiscoverMode = 'network discover mode is  active';        
            end
        end        
        
        % Streaming
        
        function smaract = getDeviceStreamingBaserate(smaract)
            command = strjoin({':DEVice:STReaming:BASerate?','\n'});
            fprintf(smaract.session,command);
            smaract.device.StreamingBaserate = getAnswer(smaract);
            disp(num2str(smaract.device.StreamingBaserate));
        end
        
        function smaract = getDeviceStreamingOptions(smaract)
            command = strjoin({':DEVice:STReaming:Options?','\n'});
            fprintf(smaract.session,command);
            answer_bit = getAnswer(smaract); 
            if bitget(str2double(answer_bit),1)
                smaract.device.StreamingOptions = 'Disable Linear Interpolation';
            else
                smaract.device.StreamingOptions = 0;
            end
        end
        
        % Hand Controle Module
        function smaract = getDeviceHandControlLockOptions(smaract)
            command = strjoin({':DEVice:HMODule:LOPTions?','\n'});
            fprintf(smaract.session,command);            
            answer_bit = getAnswer(smaract); 
            bits = bitget(str2double(answer_bit),1:20);
            state_flags = {'contol over the hand controler fully disabled','Controller input disabled',...
                'No State Flag','No State Flag','Channel Settings Menu hidden','Group Settings Menu hidden',...
                'General Settings Menu hidden','Load Config menu hidden','Save Config menu hidden',...
                'generic control mode parameter menu hidden','No State Flag','No State Flag',...
                'Set Channel Name menu entry hidden','Positioner Type menu entry hidden',...
                'Safe Direction menu entry hidden','Sensor Calibration menu hidden',...
                'Find Reference menu entry hidden','Set Zero Position menu entry hidden',...
                'Max Closed-Loop Frequency menu entry hidden','Sensor Power mode menu entry hidden',...
                'Actuator Mode menu entry hiden'};
            for idx = 1:20
                if bits(idx) 
                    smaract.device.HandControlLockOptions{idx} = state_flags{idx};
                else
                   smaract.device.HandControlLockOptions{idx} = '0';
                end  
            end
        end
    
        function smaract = getDeviceHandControlLockDefault(smaract)
            command = strjoin({':DEVice:HMODule:LOPTions?','\n'});
            fprintf(smaract.session,command);            
            answer_bit = getAnswer(smaract); 
            bits = bitget(str2double(answer_bit),1:20);
            state_flags = {'contol over the hand controler fully disabled','Controller input disabled',...
                'No State Flag','No State Flag','Channel Settings Menu hidden','Group Settings Menu hidden',...
                'General Settings Menu hidden','Load Config menu hidden','Save Config menu hidden',...
                'generic control mode parameter menu hidden','No State Flag','No State Flag',...
                'Set Channel Name menu entry hidden','Positioner Type menu entry hidden',...
                'Safe Direction menu entry hidden','Sensor Calibration menu hidden',...
                'Find Reference menu entry hidden','Set Zero Position menu entry hidden',...
                'Max Closed-Loop Frequency menu entry hidden','Sensor Power mode menu entry hidden',...
                'Actuator Mode menu entry hiden'};
            for idx = 1:20
                if bits(idx) 
                    smaract.device.HandControlLockOptions{idx} = state_flags{idx};
                else
                   smaract.device.HandControlLockOptions{idx} = '0';
                end  
            end
        end
        
        %Trigger
        
        
        
        function NumberOfBusModuleChannels = getNumberOfBusModuleChannels(smaract)
            command = strjoin({':MODule0:NOMChannels?','\n'});
            fprintf(smaract.session, command);
            NumberOfBusModuleChannels = str2double(getAnswer(smaract));
            smaract.device.NumberOfBusModules = NumberOfBusModuleChannels;
        end             
        
        
        
    % Set Device Propertys
    
        function smaract = setDeviceEmergencyStopMode(smaract,stopmode)
            if stopmode == 'Default'
                % All Movement is stopped. Afterwards smaract behaves normally
                smaract.device.EmergencyStopMode = 'Default'; 
                command = strjoin({':DEVice:ESTop:MODE0','\n'});
                fprintf(smaract.session, command);
            elseif stopmode == 'Restricted'
                % All Movement is stopped. Afterwards all smaracts has to be released before they can move again
                smaract.device.EmergencyStopMode = 'Restricted'; 
                command = strjoin({':DEVice:ESTop:MODE1','\n'});
                fprintf(smaract.session, command);
            elseif stopmode =='Auto Release'
                %All Movement is stopped. Details in Handbook
                smaract.device.EmergencyStopMode = 'Auto Release'; 
                command = strjoin({':DEVice:ESTop:MODE2','\n'});
                fprintf(smaract.session, command);
            else
                error('Not a valid Stopmode!');
            end
        end    
    
        function smaract = setDeviceStreamingBaserate(smaract,rate)
            if rate < 10 | rate > 1000
                error('Input Streaming Baserate is not in Valid Range!');
            else
                command = [':DEVice:STReaming:BASerate',num2str(rate),'\n'];
                fprintf(smaract.session,command);
                smaract.device.StreamingBaserate = getAnswer(smaract);
                smaract.device.StreamingBaserate = rate;
            end
        end
    
        function smaract = setDeviceStreamingOptions(smaract,streamingOption)
            if streamingOption == 'Disable Linear Interpolation'
                smaract.device.StreamingOptions = 'Disable Linear Interpolation';
                command = [':DEVice:STReaming:Options0','\n'];
                fprintf(smaract.session,command);
            else
                error('Not a valid Streaming Option!');
            end
        end
        
        
        % Hand Controle Module
        % Changes with this Function are volatile and are reset during
        % startup of the device
%         function smaract = setDeviceHandControlLockOptions(smaract)
%             command = strjoin({':DEVice:HMODule:LOPTions?','\n'});
%             fprintf(smaract.session,command);            
%             answer_bit = getAnswer(smaract); 
%             bits = bitget(str2double(answer_bit),1:20);
%             state_flags = {'contol over the hand controler fully disabled','Controller input disabled',...
%                 'No State Flag','No State Flag','Channel Settings Menu hidden','Group Settings Menu hidden',...
%                 'General Settings Menu hidden','Load Config menu hidden','Save Config menu hidden',...
%                 'generic control mode parameter menu hidden','No State Flag','No State Flag',...
%                 'Set Channel Name menu entry hidden','Positioner Type menu entry hidden',...
%                 'Safe Direction menu entry hidden','Sensor Calibration menu hidden',...
%                 'Find Reference menu entry hidden','Set Zero Position menu entry hidden',...
%                 'Max Closed-Loop Frequency menu entry hidden','Sensor Power mode menu entry hidden',...
%                 'Actuator Mode menu entry hiden'};
%             for idx = 1:20
%                 if bits(idx) 
%                     smaract.device.HandCotnrolLockOptions{idx} = state_flags{idx};
%                 else
%                    smaract.device.HandCotnrolLockOptions{idx} = '0';
%                 end  
%             end
%         end
        
        %Functions for the following Propertys are missing
        % :Streaming:Syncrate, 
        

        %% Module Propertys
         %Get Module Propertys
            % Power Supply
        function smaract = getModulePowerSupply(smaract,moduleID)
            command = [':MODule',num2str(moduleID),':PSUPly?','\n'];
            fprintf(smaract.session,command);
            smaract.module{moduleID}.PowerSupply = getAnswer(smaract);
            disp(num2str(smaract.module{moduleID}.PowerSupply));
        end
        

        
        
         %Set Module propertys
                     % Power Supply
        function smaract = setModulePowerSupply(smaract,moduleID,state)
            command = [':MODule',str2num(moduleID),':PSUPly','\n'];
            fprintf(smaract.session,command);
            smaract.module{moduleID}.PowerSupply = getAnswer(smaract);
            disp(num2str(smaract.module{moduleID}.PowerSupply));
        end
        
        
        
        
            
        % Not Implemented propertys (see manual): 4.3.1 Power Supply
        % Enabled, 4.3.2 Module State, 4.3.3 Number of Bus Module Channels
        
        %% Positioner/Channel Propertys
        
        
        %% More Propertys include: Scale Propertys, Calibration Propertys, Referencing Propertys
        %% Positioner Tuning, Streaming Properties, Diagnostic Properties, Auxiliary Properties,
        %% I/O Module Properties, Input Trigger Properties, Output Trigger Properties, 
        %% Hand Control Module Properties, API Properties
        
    %% Channel/Stage Propertys
        %% Get Stage Propertys
        
        % Get Speed of smaract/Channel in pm/s
        function stagespeed = getStageSpeed(smaract,stageID)
            command = [':CHANnel',num2str(stageID),':VELocity?',' \n'];
            fprintf(smaract.session, command);
            stagespeed = getAnswer(smaract);
            smaract.stage_states{stageID+2,19} = stagespeed;
        end
        
        % Get Current Position of smaract/Channel
        
        function position = getStagePosition(smaract,stageID)
            command = [':CHANnel',num2str(stageID),':POSition?',' \n'];
            fprintf(smaract.session, command);
            position = getAnswer(smaract);
            smaract.stage_states{stageID+2,18} = position;
        end
    
        function smaract = getStageState(smaract,stageID)
            command = [':CHANnel',num2str(stageID),':STATe?',' \n'];
            fprintf(smaract.session, command);
            answer_bit = getAnswer(smaract); 
            bits = bitget(str2double(answer_bit),1:16);
            state_flags = {'Actively moving','Closed Loop Active', 'Calibrating', 'Referencing', ...
                'Move Delayed', 'Sensor Present', 'Is Calibrated', 'Is Referenced', 'End Stop Reached', ...
                'Range Limit Reached', 'Following Limit Reached', 'Movement Failed', 'Is Streaming', ...
                'No State Flag','Over Temperature', 'Reference Mark'};
            for idx = 1:16
                if bits(idx) 
                    smaract.stage_states{stageID+2,idx} = state_flags{idx};
                else
                    smaract.stage_states{stageID+2,idx} = '0';
                end  
            end
        end
        
        function smaract = getMovementMode(smaract, stageID)
            command = [':CHAN',num2str(stageID),':MMODe?',' \n'];
            fprintf(smaract.session,command);
            mode = getAnswer(smaract);
            if mode == 0
                smaract.stage_states{stageID+2,17} = 'Closed Loop Absolute Movement';
            elseif mode == 1
                smaract.stage_states{stageID+2,17} = 'Closed Loop Relative Movement';
            elseif mode == 2
                smaract.stage_states{stageID+2,17} = 'Open Loop Scan Mode Relative Movement';
            elseif mode == 3
                smaract.stage_states{stageID+2,17} = 'Open Loop Scan Mode Absolute Movement';            
            elseif mode == 4
                smaract.stage_states{stageID+2,17} = 'Open Loop step movement';
            end
            disp(['Movement Mode of Stage: ',num2str(stageID),'is',smaract.stage_states{stageID+2,17}]);
        end        

        
        
        
        
        %% Set Channel Propertys
            % With these Functions Propertys like speed, acceleration,...
            % are set
        
        % Set Speed of smaract/Channel in mm/s
        function smaract = setMovementSpeed(smaract, stageID, speed)
            command = [':CHAN',num2str(stageID),':VEL ',num2str(speed*1000000),' \n'];
            fprintf(smaract.session,command);
%             checkError(smaract)
            smaract.stage_states{stageID+2,19} = speed;
        end
        
        % Set Movement Mode of Channel 
        function smaract = setMovementMode(smaract, stageID, mode)
            command = [':CHAN',num2str(stageID),':MMODe ',num2str(mode),' \n'];
            fprintf(smaract.session,command);
%             checkError(smaract)
            if mode == 0
                smaract.stage_states{stageID+2,17} = 'Closed Loop Absolute Movement';
            elseif mode == 1
                smaract.stage_states{stageID+2,17} = 'Closed Loop Relative Movement';
            elseif mode == 2
                smaract.stage_states{stageID+2,17} = 'Open Loop Scan Mode Relative Movement';
            elseif mode == 3
                smaract.stage_states{stageID+2,17} = 'Open Loop Scan Mode Absolute Movement';            
            elseif mode == 4
                smaract.stage_states{stageID+2,17} = 'Open Loop step movement';
            end
        end        
        

        %% Movement Funtions       
        
        function smaract = move_step(smaract, stepsize,stageID)
            %set move mode to closed-loop relative for channel 0 (1)
            fprintf(smaract.session,[':CHAN',num2str(stageID),':MMOD 1']);
            %disable acceleration control
            fprintf(smaract.session,[':CHAN',num2str(stageID),'VEL 1000000000']);
            % Acc = 0 --> this leads to fastest possible acceleration
            fprintf(smaract.session,[':CHAN',num2str(stageID),':ACC 0']);
            %start movement, value is interpreted as relative position (in mm)
            command = [':MOVE',num2str(stageID),' ', num2str(stepsize*1000000),'\n'];
            fprintf(smaract.session,command);
%             checkError(smaract)
        end
        
          % Not ready      
        function smaract = move_position(smaract, position,stageID)
            %set move mode to closed-loop absolute mode for stageID
            fprintf(smaract.session,[':CHAN',num2str(stageID),':MMOD 0']);
            %disable acceleration control
            fprintf(smaract.session,[':CHAN',num2str(stageID),'VEL 1000000000']);
            % Acc = 0 --> this leads to fastest possible acceleration
            fprintf(smaract.session,[':CHAN',num2str(stageID),':ACC 0']);
            %start movement, value is interpreted as relative position (in mm)
            command = [':MOVE',num2str(stageID),' ', num2str(position),'\n'];
            fprintf(smaract.session,command);
%             checkError(smaract)
        end        
        
        
       
        function smaract = stop(smaract)
            for i = 1:9
                command = [':STOP',num2str(i)]';
                fprintf(smaract.session, command);
            end
        end

% %% Status Check

        %% Utility Functions
        function tElapsed = checkStatus(smaract)
            bts = smaract.session.BytesAvailable;  %%% checking number of bytes in the response
            tStart = tic;
            tElapsed = 0;
            while (bts ==0) || (tElapsed >5)
                bts = smaract.session.BytesAvailable;  %%% checking number of bytes in the response
                pause(smaract.time_laps);
                tElapsed = toc(tStart);
            end
        end
        
        function answer = getAnswer(smaract)
            tElapsed = checkStatus(smaract);
%             checkError(smaract);
%             if smaract.error == true
%                 disp('Error')
%             end
            answer = fgetl(smaract.session);
        end
%       
% %% Close Conncetion to Powermeter
        function status = Close(smaract)
            fclose(smaract.session);
            delete(smaract.session);
            status = 'closed';
            clear smaract.session
            clear smaract
        end

        function checkError(smaract)
            smaract.errormessage = false;
            command = ':SYSTem:ERRor:COUNt?'; % Check Number of Errrors
            fprintf(smaract.session, command);
            answer = getAnswer(smaract);
            if answer ~= 0
                command = ':SYSTem:ERRor[:NEXT]?'; % Get next Error
                fprintf(smaract.session, command);
                answer = fscanf(smaract.session);
                if answer > 0
                    disp('SmarAct Error, details not yet implemented!')
                    smaract.errormessage = true;
                elseif answer < 0
                    disp('SCPI Error, details not yet implemented!')
                    smaract.errormessage = true;               
                end
            end
        end
        
        % wait until all stages stopped moving
        function WaitForStages(smaract)
            for idx = 1:smaract.ConnectedStages
                smaract = getStageState(smaract,idx-1);
                while smaract.stage_states{idx,1} == 'Actively moving'
                    pause(0.05);
                    smaract = getStageState(smaract,idx-1);
                end
            end
        end
    end
end     
       