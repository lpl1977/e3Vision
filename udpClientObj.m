classdef udpClientObj
    %UDPCLIENTOBJ Class for client communicating with watchtower UDP server
    %
    %  This class is written for MATLAB R2019b and so uses now deprecated
    %  functions to manage UDP socket.

    properties

        u

        remotehost = 'leviathan.local'
        remoteport = 9090
    end

    methods
        %  Construct an instance of the UDP Client class
        function obj = udpClientObj(varargin)

            %  Update object properties if changed in call
            props = properties(obj);
            for i=1:2:nargin
                if(any(strcmp(varargin{i},props)))
                    obj.(varargin{i}) = varargin{i+1};
                end
            end

%            try
%            catch
                obj.u = udp(obj.remotehost,obj.remoteport);
                fopen(obj.u);
                obj.u.Terminator = "CR";
%            end
        end

        function sendstring(obj,stringtext)
            fprintf(obj.u,stringtext);
        end
    end
end

