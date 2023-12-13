classdef udpClientObj < handle
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
            
            obj.u = udp(obj.remotehost,obj.remoteport);
            fopen(obj.u);
            obj.u.Terminator = "CR";
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

