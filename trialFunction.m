function p = trialFunction(p, state, sn)
% function p = modules.e3Vision.trialFunction(p, state, sn)
%
%  This is a PLDAPS module trial function for the e3Vision cameras.  These
%  are some basic steps that are always done...

switch state
    
    case p.trial.pldaps.trialStates.experimentPreOpenScreen
        
        %  Default parameters
        def = struct( ...
            'auxChannel', 5, ...
            'channelSubs', [], ...
            'savepath',[], ...
            'segment',"10m", ...
            'rect',CenterRectOnPoint([0 0 30 30],1920-15,540),...
            'strobe',true);
        p.trial.(sn) = pds.applyDefaults(p.trial.(sn),def);
        
        %  Set the PLDAPS requested states for this module
        rsNames = {'experimentPostOpenScreen','trialSetup','frameUpdate','framePrepareDrawing','frameDraw','trialCleanUpandSave','experimentCleanUp'};
        p = pldapsModuleSetStates(p, sn, rsNames);
        
        
    case p.trial.pldaps.trialStates.experimentPostOpenScreen
        
        %  Find subscripted referencing for dynamic data access.  These can
        %  be cribbed from p.trial.datapixx.adc.channelMappingSubs
        S = p.trial.datapixx.adc.channelMappingSubs{1};
        [~,S(end).subs{1}] = find(p.trial.(sn).auxChannel==p.trial.datapixx.adc.channels);
        p.trial.(sn).channelSubs = S;
        
        %  Create the camera object
        fprintf('****************************************************************\n');
        fprintf('e3Vision module\n');
        
        %  Create the e3v object including the UDP client
        p.static.e3v = modules.e3Vision.e3vObj(p,sn);
        
        %  Login
        p.static.e3v.udpClient.sendstring("LOGIN");
        fprintf('e3Vision:  logged in\n');
        
        %  Set segment duration
        p.static.e3v.udpClient.sendstring(join(["segment" p.trial.(sn).segment]));
        fprintf('e3Vision:  set segment duration to %s\n',p.trial.(sn).segment);
        
        %  Set up the save path
        subjectStr = p.trial.session.subject;
        sessionDateStr = datestr(p.trial.session.initTime, 'yyyymmdd');
        sessionTimeStr = datestr(p.trial.session.initTime, 'HHMM');
        sessionStr = strcat(sessionDateStr,'T',sessionTimeStr);
        p.trial.(sn).savepath = sprintf('/%s/%s/',subjectStr,sessionStr);
        p.static.e3v.udpClient.sendstring(join(["savepath" p.trial.(sn).savepath]));
        fprintf('e3Vision:  setting the subject specific save path to:\n\t%s\n',p.trial.(sn).savepath);
        
        fprintf('****************************************************************\n');
        
    case p.trial.pldaps.trialStates.trialSetup
        
        %  Check and see if recording; if not, start
        if(~p.static.e3v.recording && p.trial.(sn).enabled)
            p.static.e3v.udpClient.sendstring(join(["START SerialGroup" p.trial.(sn).handGroup]));
            fprintf('e3Vision:  starting serial group %s\n',join(p.trial.(sn).handGroup));
        end
        
    case p.trial.pldaps.trialStates.trialCleanUpandSave
        
        if(p.trial.pldaps.quit==1)
            p.static.e3v.udpClient.sendstring("STOP");
            p.static.e3v.recording = false;
            fprintf('****************************************************************\n');
            fprintf('e3Vision:  stop recording due to pause\n');
            fprintf('****************************************************************\n');
        end
        
    case p.trial.pldaps.trialStates.frameUpdate
        
        if(p.trial.(sn).enabled)
            %  If the camera recording flag is not set, then check the
            %  recording state from the analog inputs and set the flag
            %  accordingly.
            adcIndx = p.trial.datapixx.adc.dataSampleCount;
            iSub = p.trial.(sn).channelSubs;
            iSub(end).subs{2}=adcIndx;
            syncHubAuxOutput = subsref(p,iSub);
            p.static.e3v.recording = syncHubAuxOutput > 3;            
        else
            p.static.e3v.recording = true;
        end
        
        
        %         case p.trial.pldaps.trialStates.frameDraw
        %
        %             if(p.static.e3v.recording)
        %                 Screen('FillOval',p.trial.display.ptr,[1 1 1],p.trial.(sn).rect');
        %             end
        %
        %             case p.trial.pldaps.trialStates.framePrepareDrawing
        %
        
    case p.trial.pldaps.trialStates.frameDraw
        
      %  if(p.static.e3v.recording)
            level = 0.25*cos(2*pi*4*p.static.display.ifi*(p.trial.iFrame-1)) + 0.75;
            Screen('FillRect', p.trial.display.ptr, [1 1 1]*level, p.trial.(sn).rect');
     %   end
        
    case p.trial.pldaps.trialStates.experimentCleanUp
        
        p.static.e3v.udpClient.sendstring("STOP");
        p.static.e3v.udpClient.sendstring("UPLOAD");
        p.static.e3v.recording = false;
        fprintf('****************************************************************\n');
        fprintf('e3Vision:  stop recording\n');
        fprintf('e3Vision:  upload data\n');
        fprintf('****************************************************************\n');
        
end

