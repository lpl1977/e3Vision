classdef udpClientObj
    %UDPCLIENTOBJ Class for client communicating with watchtower UDP server
    %
    %  This class is written for MATLAB R2019b and so uses now deprecated
    %  functions to manage UDP socket.
    
    properties
        
        u
        
        remotehost = 'watchtower.local'
        remoteport = 9090
    end
    
    methods
        function obj = udpClientObj(varargin)            
            try
            catch
                obj.u = udp(obj.remotehost,obj.remoteport);
                fopen(obj.u);
                obj.u.Terminator = "CR";
            end
        end
        
        function sendstring(obj,stringtext)
            fprintf(obj.u,stringtext);
        end        
    end
end

