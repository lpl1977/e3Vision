classdef udpServerObj < handle
    %UDPSERVEROBJ Class for management of watchtower server
    %
    %  This object is created in an instance of MATLAB running on the same
    %  machine as the watchtower server.
    %
    %  Note that this class is written for versions of MATLAB >= R202b,
    %  which use udpport for managing UDP ports.
    %
    %  This class creates a UDP broadcast sender and receiver so that the
    %  host name of the computer running the watchtower server can be
    %  unknown to the client sending commands.
    %
    %  Typical use:
    %  1.  Create an instance of the class; this generates a UDP receiver
    %  which will execute the commands defined in the callback based on the
    %  input received.
    %  2.  Obtain an API token
    %  3.  Set the serial group
    %  4.  Start / stop recording
    
    properties
        watchtowerurl = 'https://localhost:4343'
        username = 'watchtower'
        password = 'watchtower'
        datafolder = '/data/'

        apitoken        %  character vector
        filepath        %  character vector
        SerialGroup     %  string array
        segment         %  character vector, segment duration h m s

        uReceiver       %  UDP byte port broadcast receiver
        localhost
        localport = 31416

        inputStringArray    %  array of strings corresponding to input data
        inputSourceAddress  %  address of input source
    end
    
    methods
        function obj = udpServerObj(varargin)
            %UDPSERVEROBJ Construct an instance of this class

            %  Update object properties if changed in call
            props = properties(obj);
            for i=1:2:nargin
                if(any(strcmp(varargin{i},props)))
                    obj.(varargin{i}) = varargin{i+1};
                end
            end

            %  Create a byte port receiver for broadcast commands
            obj.uReceiver = udpport("byte","LocalPort",obj.localport);

            %  Configure terminator
            configureTerminator(obj.uReceiver,"CR");

            %  Configure callback 
            configureCallback(obj.uReceiver,"terminator",@obj.readUDPdata);
        end


        %  Login and get an api token            
        function obj = login(obj)
            try
                loginresponse = webwrite(...
                    [obj.watchtowerurl, '/api/login'], ...
                    'username',obj.username, ...
                    'password',obj.password, ...
                    weboptions('CertificateFilename',''));
                obj.apitoken = loginresponse.apitoken;
                fprintf('Log in from %s; obtained API token %s\n',...
                    obj.inputSourceAddress,obj.apitoken);
            catch ME
                fprintf(ME.message)
            end
        end

        %  Scan for cameras and return camera names and IP addresses
        function response = scan(obj)
            try
                response = webread( ...
                    [obj.watchtowerurl, '/api/cameras/scan'], ...
                    'apitoken',obj.apitoken, ...
                    weboptions('CertificateFilename',''));
                disp(response)
            catch ME
                fprintf(ME.message);
            end
        end

        %  Get camera state information
        function response = getcamerastate(obj)
            try
                response = webread( ...
                    [obj.watchtowerurl, '/api/cameras'], ...
                    'apitoken',obj.apitoken, ...
                    weboptions('CertificateFilename',''));
                disp(response)
            catch ME
                fprintf(ME.message);
            end
        end

        %  Start recording
        function obj = startrecording(obj)
            try
                % Start simultaneous video recordings of cameras in
                % SerialGroup
                webwrite( ...
                    [obj.watchtowerurl, '/api/cameras/action'], ...
                    'SerialGroup[]', obj.SerialGroup, ...
                    'Action', 'RECORDGROUP', ...
                    'apitoken', obj.apitoken, ...
                    weboptions('CertificateFilename','','ArrayFormat','repeating'));
            catch ME
                fprintf(ME.message);
            end
        end

        %  Stop recording
        function obj = stoprecording(obj)
            try
                % Stop simultaneous video recordings of cameras in
                % SerialGroup
                webwrite( ...
                    [obj.watchtowerurl, '/api/cameras/action'], ...
                    'SerialGroup[]', obj.SerialGroup, ...
                    'Action', 'STOPRECORDGROUP', ...
                    'apitoken', obj.apitoken, ...
                    weboptions('CertificateFilename','','ArrayFormat','repeating'));
            catch ME
                fprintf(ME.message);
            end
        end

        %  Set global save path
        function obj = setsavepath(obj)
            try
                webwrite( ...
                    [obj.watchtowerurl, '/api/sessions/rename'], ...
                    'Filepath', fullfile(obj.datafolder,obj.filepath), ...
                    'apitoken', obj.apitoken, ...
                    weboptions('CertificateFilename',''));
            catch ME
                fprintf(ME.message);
            end
        end

        %  Set segment duration
        function obj = setsegmentduration(obj)
            try
                webwrite( ...
                    [obj.watchtowerurl, '/api/sessions/segment'], ...
                    'Segment', obj.segment, ...
                    'apitoken', obj.apitoken, ...
                    weboptions('CertificateFilename',''));
            catch ME
                fprintf(ME.message);
            end
        end
   
        %  Callback function
        %  read UDP data and then interpret the input string
        function obj = readUDPdata(obj,data,src)
            obj.inputStringArray = split(readline(data));
            obj.inputSourceAddress = src.Address;
            obj.interpretInputStringArray;
        end

        %  Interpret input string array.  Clear input string array
        %  when done.
        function obj = interpretInputStringArray(obj)

            switch obj.inputStringArray(1)
                case "LOGIN"
                    obj.login;
                case "START"
                    obj.startrecording;                    
                case "STOP"
                    obj.stoprecording;
                case "SerialGroup"
                    obj.SerialGroup = obj.inputStringArray(2:end)';
                case "Filepath"
                    obj.filepath = obj.inputStringArray(2:end)';
                    obj.setsavepath;
                case "Segment"
                    obj.segment = obj.inputStringArray(2);
                    obj.setsegmentduration;
            end
            obj.inputStringArray = [];
        end
    end
end
