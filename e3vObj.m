classdef e3vObj
    %E3VOBJ Object for management of White Matter e3Vision cameras
    %
    %  RESTful web service
    %  https://www.mathworks.com/help/matlab/ref/weboptions.html
    
    properties        
        udpClient = modules.e3Vision.udpClientObj        
        recording = false        
    end
    
    methods
        function obj = e3vObj(varargin)
            %E3VOBJ Construct an instance of this class
        end
    end
end          