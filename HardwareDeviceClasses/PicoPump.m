classdef PicoPump < handle
     %% Class to controll Harvard Pump 11 Pico Plus Elite Programmable Syringe Pump 
    % Author: Konstantin Neuhaus
    % Biozentrum University Basel, Switzerland
    % Email: konstantin.neuhaus@unibas.ch
    % 
    %#ok<*MCSUP> 
    %% PROPERTIES
    properties
        port; % Serial Port
        baudRate; % Serial baud rate
        session; % Serial session
        serialNumber; % serial number of pump  
        firmware;
        pumpID;
        backlightLevel;
        force;
        echo;
        ver;
        version;
        infusionRate;
        withdrawRate;
        targetVolume;
        speed;
        status;
        runningState;
        syringeDiameter;
        syringeVolume;
        systemTime;   
        targetTime;
        triggerInput;
        footswitch;
        poll;
    end
    
      
    %% CONSTRUCTOR/DESTRUCTOR
    methods

        function obj = PicoPump(port)
%             obj.port = 'COM12';

            obj.port = port;
            obj.session = serialport(port,115200,'StopBits',1,'DataBits',8,'Parity','none','FlowControl','none','Timeout',1);

%             configureTerminator(obj.session,'LF', 'CR/LF');
            configureTerminator(obj.session,'CR/LF', 'CR/LF');

            disp('Established connection to Syringe Pump')
            % Set NVRAM NONe % Necessary according to manual:5420-002-REV 3.1
%             writeline(obj.session,'NVRAM NONE');
            writeline(obj.session,'@NVRAM off');
            pause(0.5)
            read(obj.session,obj.session.NumBytesAvailable,'char');
        end                       
        
        function disconnectPicoPump(obj)
            %Delete associated objects (they don't auto-delete for some reason)
            delete(obj.session);
            delete(obj);
            disp('pico_pump was disconnected.')
            clear('obj.session');
            clear('obj')
        end

    end
    
    %% PROPERTY ACCESS
    methods     
     
        % get system id
        function val = get.pumpID(obj)
            writeline(obj.session,'@address');
            checkStatus(obj,'get.pumpID');
            str = readAnswer(obj);
            val = str2double(strip(extractAfter(str,'Pump address is ')));
        end

        % get baud rate
        function str = get.baudRate(obj)
            writeline(obj.session,'@baud');
            checkStatus(obj,'get.BaudRate');
            str = readAnswer(obj);
            str = str2double(strip(extractBefore(str,' baud')));
        end      

        % get display brightness
        function val = get.backlightLevel(obj)
            writeline(obj.session,'@dim');
            checkStatus(obj,'get.backlightLevel');
            str = readAnswer(obj);
            val = str2double(strip(extractBefore(str,'%')));
        end      

        % get force
        function val = get.force(obj)
            writeline(obj.session,'@force');
            checkStatus(obj,'get.force');
            str = readAnswer(obj);
            val = str2double(strip(extractBefore(str,'%')));
        end      

        % get echo state
        function str = get.echo(obj)
            writeline(obj.session,'@echo');
            checkStatus(obj,'get.echo');
            str = strip(readAnswer(obj));
        end

        % get ver
        function str = get.ver(obj)
            writeline(obj.session,'@ver');
            checkStatus(obj,'get.ver');
            str = strip(readAnswer(obj));
        end     

        % get version
        function str = get.version(obj)
            writeline(obj.session,'@version');
            checkStatus(obj,'get.version');
            pause(0.1)
            str = readAnswer(obj);
            strparts = strsplit(str,'\n');
            strparts = strparts(~cellfun('isempty',strparts));
            obj.firmware = char(strip(extractAfter(strparts(1),'Firmware:')));
            obj.serialNumber = char(strip(extractAfter(strparts(3),'Serial number:')));
        end      

         % get infusion rate
         function val = get.infusionRate(obj)
            writeline(obj.session,'@irate');
            checkStatus(obj,'get.infusionRate');
            str = readAnswer(obj);
            val = strip(str);
         end      

         % get withdraw rate
         function val = get.withdrawRate(obj)
            writeline(obj.session,'@wrate');
            checkStatus(obj,'get.withdrawRate');
            str = readAnswer(obj);
            val = strip(str);
         end       

         % get target volume
         function val = get.targetVolume(obj)
            writeline(obj.session,'@tvolume');
            checkStatus(obj,'get.targetVolume');
            str = readAnswer(obj);
            val = strip(str);
         end      

        % get speed
         function str = get.speed(obj)
            writeline(obj.session,'@crate');
            checkStatus(obj,'get.speed');
            str = readAnswer(obj);
            if contains(str,'Infusing')
                str = extractAfter(str,'Infusing at ');
                str = strip(str,' ');
            elseif contains(str,'Withdrawing')
                str = extractAfter(str,'Infusing at ');
                str = strip(str,' ');
            end
           str =char(str);
         end      

        % get syringe diameter
        function val = get.syringeDiameter(obj)
            writeline(obj.session,'@diameter');
            checkStatus(obj,'get.speed');
            val = strip(readAnswer(obj));    
        end      

        % get syringe volume
        function val = get.syringeVolume(obj)
            writeline(obj.session,'@svolume');
            checkStatus(obj,'get.svolume');
            val = strip(readAnswer(obj));    
        end  

        % get systemTime of pump [mm/dd/yy] [hh:mm:ss]*
        function val = get.systemTime(obj)
            writeline(obj.session,'@time');
            checkStatus(obj,'get.time');
            val = strip(readAnswer(obj));    
            try
                val = datetime(val,'InputFormat','MM/dd/yy hh:mm:ss a');
            catch
                val = datetime(val,'InputFormat','MM/dd/yy hh:mm:ss');
            end

        end

        % get target time
        function val = get.targetTime(obj)
            writeline(obj.session,'@ttime');
            checkStatus(obj,'get.ttime');
            val = strip(readAnswer(obj));    
        end      

        % get trigger input
        function val = get.triggerInput(obj)
            writeline(obj.session,'@input');
            checkStatus(obj,'get.input');
            val = strip(readAnswer(obj));    
        end      

        % get footswitch
        function val = get.footswitch(obj)
            writeline(obj.session,'@ftswitch ');
            checkStatus(obj,'get.input');
            val = strip(readAnswer(obj));    
        end      

        % get status (several pump parameters)
        function str = get.status(obj)
            writeline(obj.session,'@status');
            checkStatus(obj,'get.status');
            str = readAnswer(obj);
            str2 = strsplit(strip(str),' ');
            disp('State of Pump')
            disp(['Current flow rate: ', char(str2(1)),' fl/s'])
            disp(['Current infused volume: ', char(str2(2)),' fl/s'])   
            disp(['Current infused time: ', char(str2(3)),' ms'])  
            
            % split status string into the current rate/ infuse time/ infused volume in femtoliter /ms
            % 6 different status flags
            % flag 1: Motor Direction i/r/I/R (small=idle capital=running)
            % flag 2: limit switch state (this pump no switch -> "." always
            % flag 3: stall state "S" if stalled else .
            % flag 4: trigger input state "T"= high, "." = low
            % flag 5: direction port state i/r/I/R
            % flag 6: target reached state "T"= reached else "."
        end

        % get poll state (several pump parameters)
        % When polling mode is off, prompts are displayed when an event 
        % happens, such as a target being reached.
        % when polling mode is on, prompts are not displayed
        % when an event happens, and a XON character is output
        % when the pump is ready for another command
        % When polling mode is in remote mode, the following occurs
        % • Prompts are not displayed
        % • Carraige returns are not displayed
        % • The pump address is displayed even if 0
        % • Echo is forced off and the echo command is illegal
        function str = get.poll(obj)
            writeline(obj.session,'@poll');
            checkStatus(obj,'get.poll');
            str = strip(readAnswer(obj));
        end
        
    end
       
    %% set property functions
    methods
        % set system id
        function set.pumpID(obj,newID)
            % ToDo: check if input is valid
            writeline(obj.session,['@address ',num2str(newID)]); 
            obj.pumpID;
        end

        % set baud rate
        function set.baudRate(obj,newRate)
            % ToDo: check if input is valid
            writeline(obj.session,['@baud ',num2str(newRate)]);
            obj.baudRate;
        end      

        % set display brightness
        function set.backlightLevel(obj,level)
            % ToDo: check if input is valid
            writeline(obj.session,['dim ',num2str(level)]);
            obj.backlightLevel;
        end     

        % set force
        function set.force(obj,newForce)
            % ToDo: Check if input is valid
            writeline(obj.session,['force ',num2str(newForce)]);
            obj.force;
        end      

        % set target volume
        function set.targetVolume(obj,newTarget)
            % needs error catching of input
            writeline(obj.session,['tvolume ',newTarget]);
            obj.targetVolume;
        end      


         % set syringe diameter
        function set.syringeDiameter(obj,value)
            % ToDo: Check if input is valid
            writeline(obj.session,['diameter ',value]);
            obj.syringeDiameter;
        end      

        % set syringe volume
        function set.syringeVolume(obj,value)
            % ToDo: Check if input is valid
            writeline(obj.session,['svolume ',value]);
            obj.syringeVolume;
        end      

        % Set echo
        function set.echo(obj,newState)        
            if strcmp(newState,'on')
                writeline(obj.session,'echo on');
            elseif strcmp(newState,'off')
                writeline(obj.session,'echo off');
            else 
                warning(['Input for setEcho was not valid. User input was:"',newState,'" . Valid inputs are "on" or "off"'])
            end
            obj.echo;
        end

        % Set infusion rate
        function  set.infusionRate(obj,value) 
            % ToDo: Check if input is valid
            writeline(obj.session,['irate ',value]);
        end  

        % Set withdraw rate
        function  set.withdrawRate(obj,value) 
            % ToDo: Check if input is valid
            writeline(obj.session,['wrate ',value]);
        end  

        % set target time
        function set.targetTime(obj,value)
            % ToDo: Check if input is valid
            writeline(obj.session,['ttime ',value]);
            obj.targetTime;
        end      

        % set trigger input
        function set.triggerInput(obj,value)
            if strcmp(value,'low')
                writeline(obj.session,'input low');
            elseif trcmp(value,'high')
                writeline(obj.session,'input high');
            end
            obj.triggerInput;
        end      

        % set footswitch
        function set.footswitch(obj,value)
            if strcmp(value,'mom') | strcmp(value,'rise') | strcmp(value,'fall')
                writeline(obj.session,['ftswitch ',value]);
            else
                warning('Could not set new footswitch setting. Input not a valid option.')
            end
            obj.footswitch;
        end     

        % set systemTime of pump [mm/dd/yy] [hh:mm:ss]*
        function set.systemTime(obj,newTime)
            df = assertDateTimeFormat(newTime);
            if isempty(df)
                warning('Could not set new system time setting. Input not valid.')
            else
                writeline(obj.session,['time ',df]);
                obj.systemTime;
            end
        end

%         % set poll mode
%         function set.poll(obj,newState)
%             if strcmp(newState,'on') | strcmp(newState,'off') 
%                 writeline(obj.session,['poll ',value]);
%                 obj.poll;
%             else
%                 warning('Could not set new poll mode. Input not a valid option.')
%             end
%         end
    end
    %% action functions
    methods
    
        % calibrate tilt sensor
        function  obj = CalibrateTiltSensor(obj) 
            writeline(obj.session,'TILT');
        end      

        % clear target volume
        function  obj = ClearTargetVolume(obj) 
            writeline(obj.session,'CTVOLUME');
            obj.targetVolume;
        end      

        % clear infused and withdrawn volumes
        function  obj = ClearVolumes(obj) 
            writeline(obj.session,'cvolume');
% ToDo
        end        

        % clear withdrawn volume
        function  obj = ClearWithdrawnVolume(obj) 
            writeline(obj.session,'cwvolume');
% ToDo
        end        

        % clear infused volume
        function  obj = ClearInfusedVolume(obj) 
            writeline(obj.session,'civolume');
% ToDo
        end        

         % clear infused and withdrawn times
        function  obj = ClearTimes(obj) 
            writeline(obj.session,'ctime');
% ToDo
        end        

        % clear infused time
        function  obj = ClearInfusedTime(obj) 
            writeline(obj.session,'citime');
% ToDo
        end   

         % clear withdrawn time
         function  obj = ClearWithdrawnTime(obj) 
            writeline(obj.session,'cwtime');
% ToDo
         end    

         % clear target time
         function  obj = ClearTargetTime(obj) 
            writeline(obj.session,'cttime');
% ToDo
         end        

       % display infusion time
       function DisplayInfusionTime(obj) 
            writeline(obj.session,'itime');
            checkStatus(obj,1)          
             str = readAnswer(obj);
            disp(['Infusion Time: ',strip(str)])
% ToDo
       end        

       % display withdrawn time
       function DisplayWithdrawnTime(obj) 
            writeline(obj.session,'wtime');
            checkStatus(obj,1);          
            str = readAnswer(obj);
            disp(['Withdrawn Time: ',strip(str)])
% ToDo
       end        

       % display pump metrics
       function DisplayPumpMetrics(obj) 
            writeline(obj.session,'metrics');
            checkStatus(obj,1)          
            str = readAnswer(obj);
            disp(['Pump Metrics: ',strip(str)])
% ToDo
       end     

       % display infused volume
       function DisplayInfusedVolume(obj) 
            writeline(obj.session,'ivolume');
            checkStatus(obj,1)          
            str = strip(readAnswer(obj));
            disp(['Infused Volume: ',str]);
% ToDo
       end     

       % display withdrawn volume
       function DisplayWithdrawnVolume(obj) 
            writeline(obj.session,'wvolume');
            checkStatus(obj,1)          
            str = strip(readAnswer(obj));
            disp(['Withdrawn Volume: ',str]);
% ToDo
       end     

       % set trigger output
       function SetTriggerOutput(obj,value) 
            if strcmp(value,'low')
                writeline(obj.session,'output low');
            elseif trcmp(value,'high')
                writeline(obj.session,'output high');
            end
       end   
    
       % run pump in withdraw direction
       function RunPumpWithdraw(obj) 
           %Todo: check if pump is already running
            writeline(obj.session,'wrun');

       end             
 
       % run pump in infuse direction
       function RunPumpInfuse(obj) 
           %Todo: check if pump is already running
            writeline(obj.session,'irun');

       end  
       
        % run pump in infuse direction
        function RunPumpReverseDirection(obj) 
           %Todo: check if pump is already running
            writeline(obj.session,'rrun');
        
        end       

%         % check state of pump
%         function state = isRunning(obj) 
%            %Todo: check if pump is already running
%             writeline(obj.session,'rrun');
% 
%         end     

        % start pump
        function obj = StartRun(obj)           
            writeline(obj.session,'run');
        end      

        % stop Pump
        function obj = Stop(obj)           
            writeline(obj.session,'stop');
        end    
        
    end    
   %% Helper Functions
    methods

        function  ready = checkStatus(obj,bytesNeeded) %#ok<INUSD> 
%             disp(['Function call:',bytesNeeded])

            bytesNeeded = 2;
            bts = obj.session.NumBytesAvailable;  % checking number of bytes in the response
            while bts < bytesNeeded
%                 disp('Waiting for bytes available')
                pause(0.001);
                bts = obj.session.NumBytesAvailable;  % checking number of bytes in the response
            en
            ready = 'True';
        end

        function  answer = readAnswer(obj)           
            str = read(obj.session,obj.session.NumBytesAvailable,'char');
            if strcmp(str(end),':')
                obj.runningState = 'idle';
            elseif strcmp(str(end),'>')
                obj.runningState = 'infusing';
            elseif strcmp(str(end),'<')
                obj.runningState = 'withdrawing';
            elseif strcmp(str(end),'*')
                if strcmp(str(end-1:end),'T*')
                    obj.runningState = 'target reached';
                    str = str(1:end-1);
                else
                    obj.runningState = 'stalled';
                end
            else
                warning('No status was given by pump')
            end

            answer = str(1:end-1);

        end
        function df = assertDateTimeFormat(str)
            f1 = 'MM/dd/yy HH:mm:ss a';
            f2 = 'MM/dd/yy HH:mm:ss';
            df = '';
            try
                datetime(str, 'InputFormat', f1);
                df = str;
            end
            try
                datetime(str, 'InputFormat', f2);
                df = [str,'*'];
            end
        end

    end
%% Missing
% DELMETHOD
% CATALOG
% SYRMANU
% IRAMP
% WRAMP
% STATUS
end