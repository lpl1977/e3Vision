classdef udpServerObj < handle
    %UDPSERVEROBJ Class for management of watchtower server

    %  This object is running on the same instance of MATLAB as the
    %  watchtower server.

    %  Note that I am writing this for the versions of MATLAB
    %  which use udpport for managing UDP ports (>= R2020b).

    %  With this class I need to
    %  1.  Get an API token for communication with watchtower server
    %  2.  Update path for saved files
    %  3.  Start saving the files
    %  4.  Stop saving the files
    %
    %  I could configure more than one UDP port so that each one has a
    %  unique callback.
    
    properties
        watchtowerurl = 'https://localhost:4343'
        username = 'watchtower'
        password = 'watchtower'
        datafolder = '/data/e3Vision/'

        apitoken        %  character vector
        filepath        %  character vector
        SerialGroup     %  string array
        segment         %  character vector, segment duration h m s

        uDatagram       %  UDP datagram port
        localhost = 'watchtower.local'
        localport = 9090
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

            %  Get an API token from the watchtower server running on this
            %  computer.
            obj.login;

            
            %  Connect to a UDP socket and create a udpport datagram object
            obj.uDatagram = udpport("datagram","LocalPort",obj.localport,"LocalHost",obj.localhost);
            obj.uDatagram.UserData = 0;

            %  Configure the terminator
            %            configureTerminator(obj.uByte,"CR");
            %configureCallback(obj.uDatagram,"datagram",2,@obj.readdatagram);
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
            catch ME
                fprintf(ME.message)
            end
        end

        %  Scan for cameras
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

        %  Scan for cameras
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
        function obj = startrecord(obj)
            try
                % Start simultaneous video recordings of cameras e3v8100 through e3v8103:
                response = webwrite([watchtowerurl, '/api/cameras/action'], ...
                    'SerialGroup[]', ["e3v8100", "e3v8101", "e3v8102", "e3v8103"], 'Action', 'RECORDGROUP', ...
                    weboptions('CertificateFilename','','ArrayFormat','repeating'));
            catch ME
                fprintf(ME.message);
            end
        end

        %  Stop recording
        function obj = stoprecording(obj)
            try
                % Stop simultaneous video recordings of cameras e3v8100 through e3v8103:
response = webwrite([watchtowerurl, '/api/cameras/action'], ...
        'SerialGroup[]', ["e3v8100", "e3v8101", "e3v8102", "e3v8103"], 'Action', 'STOPRECORDGROUP', ...
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
    end

    methods (Static)
                %  Callback function
        function data = readdatagram(src,~)
            disp('hi lee')
            src.UserData = src.UserData + 1;
            disp("Callback Call Count: " + num2str(src.UserData))
            data = read(src,1,"string");
disp(data)
        end
    end
end