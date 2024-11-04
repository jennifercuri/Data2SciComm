%% Experimental code for the study reported in Müller, Husain, & Apps (2022, Scientific Reports)

% Note that this script calls some additional separate functions.

% The code is based on the experimental code for the Pre-Task in T. Müller,
% M.C. Klein-Flügge, S.G. Manohar, M. Husain, & M.A.J. Apps (2021, Nature Communications), and
% has been modified accordingly by T.M.

%%


function result = Fatigue(ex)

cd %insert accordingly;
addpath %insert accordingly;
ex.type               = 'Fatigue';

%% SETUP
ex.skipScreenCheck    = 0;
ex.displayNumber      = 0;             % for multiple monitors

%% STRUCTURE
ex.blockLen           = 96 ;    %%%%This is actually the number of trials (Practice = 18+3; Task = 75)
ex.blocks             = 1; % one for this experiment (put in breaks instead)
ex.trialVariables.hand    = 1; %  right hand
ex.Reward          = [1 2 4 6 8 10];     % Reward Values
ex.ForceLevel      = [0.001 0.3 0.39 0.48 0.57 0.66]; % Effort Values
  

ex.ResponseThreshold = 0.1; % Don't change - defines the level of squeezing required if making choices with the handles
ex.rewardFunction     = @(ex, rewardGain, force, stake, mvc) rewardGain * force/mvc * stake; % in case needed
ex.choiceDuration     = 2.5;  % Time that the Choice Screen is up
ex.firstChoiceDuration = 3.5;
ex.postChoiceTime   = 1;  % Interval after each Choice trial
ex.responseDuration   = 5;  
ex.ITI                = 0.5;
ex.rewardDuration     = 1;


ex.barCapacity        = 1.5;
ex.delayAfterEndofTrial = 0; %@() 1 + rand*1;
ex.selfeffortInstruc = { 'Effort1_bar.jpg', 'Effort2_bar_red.jpg', 'Effort3_bar_red.jpg', 'Effort4_bar_red.jpg', 'Effort5_bar_red.jpg', 'Effort6_bar_red.jpg'};

global maxF MVC trialIndex totalReward choiceOns firstChoiceOns firstButton_pre button_pre noButton_pre startresp endresp rewardFeedb missedFirstChoice
MVC=[5 5];% bar max forces for calibration
maxF=[0 0]';
trialIndex =0;
totalReward = 0;
choiceOns=[];
firstChoiceOns=[];
button_pre=[];
noButton_pre=[];
firstButton_pre=[];
startresp=[];
endresp=[];
rewardFeedb=[];
missedFirstChoice = 0;


%% DISPLAY
ex.bgColour             = [0 0 0];         % background
ex.fgColour             = [255 255 255];   % text colour, white
ex.yellow               = [255 255 0];
ex.size_text            = 36;              % size of text
ex.useSqueezy           = 1;    % Use Squeezies
ex.useEyelink           = 0;    % Don't use Eyelink
ex.showForceBars        = 1;
ex.forceColour  = [255 0 0];    % Bar colour for force feedback, red
ex.selfColour = [255 0 0];
ex.otherColour = [0 0 255];
ex.green = [0 255 0];
ex.barheight = 300 ;         % Bar Height (in pixels)
ex.barmaxforce = 0.80;       % Maximum % MVC to be displayed on bar

%% RUN EXPERIMENT
KbName('UnifyKeyNames'); % Enable unified mode of KbName, so KbName accepts identical key names on all operating systems:
if ~exist('params','var') params=struct(); end;
result = RunExperimentFR2_TC( @doTrial, ex, params, @blockfn);
result.MVC = MVC;

%% Interim analysis
if(isfield(result,'data'))
    d=result.data;
else fprintf('no experimental data\n');
end

function drawResponseNowFlip(scr, ex, colour, height, ForceLevel, stake)
height = max(0,min(1.5,height));        % height = Height of force 
x0=scr.centre(1); y0=scr.centre(2);
FC=ex.forceColour;
S=150*ForceLevel;
Screen('FillRect', scr.w, ex.bgColour, [x0-25 y0-ex.barheight/2 x0+25 y0+ex.barheight/2]);        % Draw the Vertical Bar
Screen('FrameRect', scr.w, ex.fgColour, [x0-25 y0-ex.barheight/2 x0+25 y0+ex.barheight/2], 4);    % Draw the Bar Outline
Screen('FillRect', scr.w, FC, [x0-25 y0+ex.barheight/2-height*ex.barheight/ex.barmaxforce x0+25 y0+ex.barheight/2]);        % Draws the Force Feedback Bar
Screen('Drawlines',scr.w,[ -25-50/8 +25+50/8; ex.barheight/2-ForceLevel*ex.barheight/ex.barmaxforce ex.barheight/2-ForceLevel*ex.barheight/ex.barmaxforce], 7, ex.yellow, [x0 y0], 0);    % Draw the Target Line 
Screen('Flip',scr.w)


function drawCalibAndFlip(scr, ex, colour, colourlevel, height, ForceLevel)
height = max(0,min(1.5,height));
x0=scr.centre(1);
y0=scr.centre(2);
FC=ex.forceColour;
Screen('Drawlines',scr.w,[ -25-50/8 +25+50/8 ; 150-ForceLevel*200 150-ForceLevel*200], 7, colourlevel, [x0 y0], 0);  % These are the coordinates for the target line
Screen('FrameRect', scr.w, colour, [x0-25 y0-150 x0+25 y0+150], 4);  % These are the coordinates for the Bar Outline
Screen('FillRect', scr.w, FC, [x0-25 y0+150-height*200 x0+25 y0+150]);  % These are the coordinates for the Force Feedback Bar; Original height*S
Screen('Flip',scr.w)


function blockfn(scr, el, ex, tr)   %%% START OF BLOCK

global trialIndex

if (tr.block == 0) % on the first block, display the calibration. The calibration trials themselves are run with "block=0"
    x0=scr.centre(1); y0=scr.centre(2);
    if ~isfield(ex,'MVC') % check if MVC has already been provided?
        for calibration = 1:3    % 3 calibration trials
            tr.hand = 1;  % 1 IS RIGHT HAND
            tr.calibrIndex = calibration; % pass the calibration trial number to the trial function
            res = runSingleTrialAndProcess(scr, el, ex, tr, @doTrial,-1,1); % run calibration trial
            calibrationValues(calibration) = res.maximumForce; % save the max force on each calibration trial
        end % progress to next calibration trial
        global MVC
        MVC(1) = max(calibrationValues(1:2:end));
        MVC(2) = max(calibrationValues(2:2:end));
        tr = rmfield(tr, 'calibrIndex'); % remove the calibration index so that doTrial knows to move on to the practice.

    else % MVC provided
        MVC=ex.MVC;
    end
    
elseif tr.block == 1
    trialIndex  = 0;
    while(~KbCheck); WaitSecs(0.1); end              
end

function tr=doTrial(scr, el, ex, tr)  % TRIAL STRUCTURE FUNCTION

global MVC maxF trialIndex totalReward firstChoiceOns choiceOns firstButton_pre button_pre noButton_pre startresp endresp rewardFeedb missedFirstChoice

pa = combineStruct(ex, tr);
EXIT = 0;
x0=scr.centre(1); y0=scr.centre(2);    % Screen centre coords


CALIBRATING = tr.block == -1; % calibration trials have block number zero


tr.rewardDuration = ex.rewardDuration();
tr.delayAfterEndofTrial = ex.delayAfterEndofTrial();
tr=LogEvent(ex,el,tr,'starttrial');    % SIni, TrialOnsetlist

if CALIBRATING
    [keyisdown,secs,keycode] = KbCheck; % check for real key
    if(keycode(27)); EXIT=1; end         % check for ESCAPE; Keycodes: ESC 27; Space 32; Enter 13
    if isfield(tr, 'calibrIndex') % we have set calibrIndex, meaning this is a calibration trial

        calib = tr.calibrIndex;
        
        if calib == 1 %for first calib, instruct press as strongly as you can
            drawTextCentred(scr, 'Squeeze as strongly as you can', ex.fgColour);
            Screen('Flip',scr.w);
            WaitSecs(1);
            tr = LogEvent(ex,el,tr,'startresponse');
            fbfunc = @(f) drawCalibAndFlip(scr, ex, ex.fgColour, ex.bgColour, f(pa.hand)/4, 1 );
            [data]  = waitForForceData(ex,tr.startSqueezyAcquisition, 5, 20, 6, fbfunc);  %% CHANGE FIRST NUMBER TO CHANGE CALIBRATION DURATION (twice more below)
            tr.maximumForce = max(data(:,pa.hand));
            MVC(pa.hand) = tr.maximumForce;
            [keyisdown,secs,keycode] = KbCheck; % check for real key
            if(keycode(27)) EXIT=1; end         % check for ESCAPE
            tr=LogEvent(ex,el,tr,'endresponse');
            WaitSecs(ex.ITI); % blank Screen after response
            Screen('Flip', scr.w);
            tr.record1=data(:,1); tr.record2=data(:,2);   % store all force data
            tr.R=1;
        
        elseif calib ==2  % On the next calib (number 2), instruct to reach 1.1 * previous max reached
            drawTextCentred(scr, 'Reach the yellow line', ex.fgColour);
            Screen('Flip',scr.w);
            WaitSecs(1);
            tr = LogEvent(ex,el,tr,'startresponse');
            fbfunc = @(f) drawCalibAndFlip(scr,ex,ex.fgColour,ex.yellow, f(pa.hand)/MVC(pa.hand), 1.1 );
            [data]  = waitForForceData(ex,tr.startSqueezyAcquisition, 5, 20, 6, fbfunc);  %% CHANGE FIRST NUMBER TO CHANGE CALIBRATION DURATION (once more below)            
            tr.maximumForce = max(data(:,pa.hand));
            MVC(pa.hand) = tr.maximumForce;
            tr.record1=data(:,1); tr.record2=data(:,2);   % store all force data
            tr.R=1;
            
        elseif calib == 3
            drawTextCentred(scr, 'Reach the yellow line', ex.fgColour);
            Screen('Flip',scr.w);
            WaitSecs(1);
            tr = LogEvent(ex,el,tr,'startresponse');
            fbfunc = @(f) drawCalibAndFlip(scr,ex,ex.fgColour,ex.yellow, f(pa.hand)/MVC(pa.hand), 1.05 );
            [data]  = waitForForceData(ex,tr.startSqueezyAcquisition, 5, 20, 6, fbfunc);%% CHANGE FIRST NUMBER TO CHANGE CALIBRATION DURATION
            tr.maximumForce = max(data(:,pa.hand));
            MVC(pa.hand) = tr.maximumForce;
            tr.record1=data(:,1); tr.record2=data(:,2);   % store all force data
            tr.R=1;
        end
        
        if calib == 3 
            drawTextCentred(scr, 'Get ready to practice!', ex.fgColour);
            Screen('Flip',scr.w);
            GetChar()
            while(~KbCheck) WaitSecs(0.1); end
        end
    end
    
elseif ~CALIBRATING

% The main Experiment.
    trialIndex = trialIndex+1;   
    tr.trialIndex = trialIndex;
    tr.hand = 1;
    pa.hand = 1;
    tr.delayAfterEndofTrial  = ex.delayAfterEndofTrial();
    tr=LogEvent(ex,el,tr,'starttrial');   
     
   
   % note: offerLocation 1=right, 2=left
   % note: rewardLocation 1=right, 2=left
    
    trialtype =  [0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;];
    TM =         [1;2;3;4;5;6;1;2;3;4;5;6;1;2;3;4;5;6;2;3;2;5;2;6;4;4;6;3;4;5;3;5;3;2;4;4;6;4;6;3;2;4;4;5;3;3;6;6;4;5;3;6;5;3;2;4;4;2;3;5;2;2;5;5;2;6;2;6;5;5;4;5;6;2;4;6;5;4;3;3;3;2;6;3;4;3;3;2;6;2;6;5;6;5;2;2;];  % Randomised effort levels
    stakes =     [1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;6;2;3;4;4;5;5;3;6;5;6;4;4;6;4;5;2;2;4;3;2;3;5;4;6;3;2;2;5;4;2;5;2;5;3;5;6;4;5;3;4;5;5;6;2;4;4;6;2;3;6;2;6;3;2;2;4;2;6;5;3;5;6;6;4;3;3;6;6;3;3;2;3;5;6;2;4;3;];  % Randomised reward levels
    offerLoc =   [1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;2;2;2;1;2;1;2;1;2;1;1;2;1;1;1;1;1;1;1;1;1;2;2;2;1;1;1;2;1;2;2;2;2;1;2;1;1;1;2;2;1;1;2;1;1;2;1;1;2;2;2;2;1;2;1;2;2;2;2;2;1;1;2;2;2;2;2;2;1;1;2;1;2;1;1;1;];
    rewardLoc =  [1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;2;1;2;2;2;1;2;2;2;1;2;2;1;1;1;2;2;1;1;2;2;1;2;1;2;1;1;2;1;2;1;2;2;2;2;1;1;1;1;1;2;1;2;1;1;1;2;1;1;1;1;2;2;2;1;1;1;2;2;2;1;2;1;1;2;1;2;2;1;2;2;2;2;1;2;1;2;1;];
    
    tr.effort = ex.ForceLevel(TM(trialIndex));  % Selects an effort level for this trial
    tr.effortLevel = TM(trialIndex);
    tr.stake = ex.Reward(stakes(trialIndex));  % The stake is always 1 for each training trial.
    tr.rewardDuration = ex.rewardDuration;
    tr.discOrFat = trialtype(trialIndex);
    tr.offerLocation = offerLoc(trialIndex);
    tr.rewardLocation = rewardLoc(trialIndex);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% For the Practice Block %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if tr.discOrFat ==  0
        ima=imread(ex.selfeffortInstruc{TM(trialIndex)}, 'jpg');
        Screen('PutImage', scr.w, ima, [x0-27 y0-154 x0+27 y0+154]);
        myimgfile = ex.selfeffortInstruc{TM(trialIndex)};
        ima=imread(myimgfile, 'jpg');
        drawTextCentred( scr, '1 credit', ex.selfColour, scr.centre + [0 -200])
        Screen('Flip',scr.w)
        WaitSecs(1)
        Screen('Flip',scr.w)
        WaitSecs(1)
        [keyisdown,secs,keycode] = KbCheck; % check for real key
        if(keycode(27)); EXIT=1; end         % check for ESCAPE
        pa.hand = 1;
        tr.stake = 0;  % Stake level
        tr.effort = ex.ForceLevel(TM(trialIndex));
      
        tr = LogEvent(ex,el,tr,'startresponse');
        fbfunc = @(f) drawResponseNowFlip(scr, ex, ex.bgColour, f(pa.hand)/MVC(pa.hand), tr.effort , tr.stake); 
        [data, ~, tr.startSqueezyAcquisition]  = waitForForceData(ex, tr.startSqueezyAcquisition, ex.responseDuration, 2*MVC(pa.hand), 4, fbfunc); 
        tr.maximumForce = max(data(:,pa.hand));
        tr.maximumTime =  find(data(:,pa.hand)==tr.maximumForce,1); %units are samples
        tr.MVC = MVC;
        
        Screen('Flip',scr.w);
        tr=LogEvent(ex,el,tr,'endresponse');
        
        tr.timeInWindowRew = sum(abs(data(:,pa.hand)/MVC(pa.hand) > tr.effort)) * (5/length(data(:,pa.hand)));  % Each practice trial is 7 seconds (1 sec pie; 1 sec ISI; 5 sec response)
        

        if (tr.timeInWindowRew >= 3) || (tr.effortLevel == 1)   
            drawTextCentred( scr, '1 credit', ex.selfColour, scr.centre );
        else
            drawTextCentred( scr, '0 credits', ex.selfColour, scr.centre );
        end  
    
        Screen('Flip',scr.w);
        
        WaitSecs(ex.ITI);
        tr.data1=data(:,1); %tr.data2=data(:,2);   % store all force data
        tr.R=1;     % pa.R_NEEDS_REPEATING_LATER to repeat the trial
        [keyisdown,secs,keycode] = KbCheck; % check for key press
        if(keycode(27)); EXIT = 1; end         % check for ESCAPE
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% For the Choice Block %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    elseif tr.discOrFat ==  1 
        
   % This is for the first choice phase
        
      if tr.rewardLocation == 1                  % reward presented on the right
        x0=scr.centre(1); y0=scr.centre(2);
        ima=imread('Effort0_bar.jpg', 'jpg');
        Screen('PutImage', scr.w, ima, [x0-177 y0-154 x0-123 y0+154])
        drawTextCentred( scr, 'credits', ex.fgColour, scr.centre + [150 0]);

      elseif tr.rewardLocation == 2              % reward presented on the left
        x0=scr.centre(1); y0=scr.centre(2);
        ima=imread('Effort0_bar.jpg', 'jpg');
        Screen('PutImage', scr.w, ima, [x0+123 y0-154 x0+177 y0+154])
        drawTextCentred( scr, 'credits', ex.fgColour, scr.centre + [-150 0]);  
        
      end
        
        
        tr.firstResponseKey = 'z'; %default = no response
        Screen('Flip',scr.w)
        tr=LogEvent(ex,el,tr,'firstChoiceOnset');     %Note: corresponds to the options onset
        firstChoiceOns = [firstChoiceOns;GetSecs];
        tr.firstChoiceOns = firstChoiceOns;
        tic 
        
        while toc < ex.firstChoiceDuration
            [keyIsDown, secs, keyCode] = KbCheck;
          if keyIsDown == 1
            tr.firstResponseKey = GetChar();
            if tr.firstResponseKey == 'b' || tr.firstResponseKey == 'n'     
                
                resp_time = toc;
                tr.firstRT = resp_time;
                tr=LogEvent(ex,el,tr,'firstButton_press');     %Note: corresponds to the decision / button press
                firstButton_pre = [firstButton_pre;GetSecs];    
                tr.firstButton_pre = firstButton_pre;
                
                
                if (tr.rewardLocation == 1) && (tr.firstResponseKey == 'b')    % If they choose the effort option
                    x0=scr.centre(1); y0=scr.centre(2);
                    Screen('FrameRect', scr.w, [0 255 0], [x0-250 y0-180 x0-50 y0+180], 6);
                    ima=imread('Effort0_bar.jpg', 'jpg');
                    Screen('PutImage', scr.w, ima, [x0-177 y0-154 x0-123 y0+154])
                    tr.firstChoice = 0;
                    Screen('Flip',scr.w)
                    WaitSecs(ex.firstChoiceDuration-resp_time + 0.5)  % Waits for a total duration of 4s, so choice period is always 4s
                    
                elseif (tr.rewardLocation == 1) && (tr.firstResponseKey == 'n')    % If they choose the reward option
                    x0=scr.centre(1); y0=scr.centre(2);
                    Screen('FrameRect', scr.w, [0 255 0], [x0+50 y0-180 x0+250 y0+180], 6);
                    drawTextCentred( scr, 'credits', ex.fgColour, scr.centre + [150 0]);
                    tr.firstChoice = 1;
                    Screen('Flip',scr.w)
                    WaitSecs(ex.firstChoiceDuration-resp_time + 0.5)                                        
                    
                elseif (tr.rewardLocation == 2) && (tr.firstResponseKey == 'n')    % If they choose the effort option
                    x0=scr.centre(1); y0=scr.centre(2);
                    Screen('FrameRect', scr.w, [0 255 0], [x0+50 y0-180 x0+250 y0+180], 6); 
                    ima=imread('Effort0_bar.jpg', 'jpg');
                    Screen('PutImage', scr.w, ima, [x0+123 y0-154 x0+177 y0+154])
                    tr.firstChoice = 0;
                    Screen('Flip',scr.w)
                    WaitSecs(ex.firstChoiceDuration-resp_time + 0.5)                  % add the time screen is displayed 0.5 (SEE BELOW)
                    
                elseif (tr.rewardLocation == 2) && (tr.firstResponseKey == 'b')    % If they choose the reward option               
                    x0=scr.centre(1); y0=scr.centre(2);   % inserted, but don't think this is actually needed here
                    Screen('FrameRect', scr.w, [0 255 0], [x0-250 y0-180 x0-50 y0+180], 6);  % These are the coordinates for the Bar Outline
                    drawTextCentred( scr, 'credits', ex.fgColour, scr.centre + [-150 0]);
                    tr.firstChoice = 1;
                    Screen('Flip',scr.w)
                    WaitSecs(ex.firstChoiceDuration-resp_time + 0.5)
                    
                end                                                                                
                
                break;                                                                                             
            end
          end
        end

        KbQueueRelease()
       
       if tr.firstResponseKey == 'z' %If they did not make a choice
           drawTextCentred( scr, 'Please respond!', ex.green, scr.centre);
           missedFirstChoice = missedFirstChoice + 1;
           tr.missedFirstChoice = missedFirstChoice;
           Screen('Flip',scr.w)
           WaitSecs(1)                                                   
        
        
      if tr.rewardLocation == 1                  % reward presented on the right
        x0=scr.centre(1); y0=scr.centre(2);
        ima=imread('Effort0_bar.jpg', 'jpg');
        Screen('PutImage', scr.w, ima, [x0-177 y0-154 x0-123 y0+154])
        drawTextCentred( scr, 'credits', ex.fgColour, scr.centre + [150 0]);

      elseif tr.rewardLocation == 2              % reward presented on the left
        x0=scr.centre(1); y0=scr.centre(2);
        ima=imread('Effort0_bar.jpg', 'jpg');
        Screen('PutImage', scr.w, ima, [x0+123 y0-154 x0+177 y0+154])
        drawTextCentred( scr, 'credits', ex.fgColour, scr.centre + [-150 0]);  
        
      end
        
        
        Screen('Flip',scr.w)
        tr=LogEvent(ex,el,tr,'firstChoiceOnset');     %Note: corresponds to the options onset
        firstChoiceOns = [firstChoiceOns;GetSecs];
        tr.firstChoiceOns = firstChoiceOns;
        tic 
        
        while toc < ex.firstChoiceDuration
            [keyIsDown, secs, keyCode] = KbCheck;
          if keyIsDown == 1
            tr.firstResponseKey = GetChar();
            if tr.firstResponseKey == 'b' || tr.firstResponseKey == 'n'     
                
                resp_time = toc;
                tr.firstRT = resp_time;
                tr=LogEvent(ex,el,tr,'firstButton_press');     %Note: corresponds to the decision / button press
                firstButton_pre = [firstButton_pre;GetSecs];    
                tr.firstButton_pre = firstButton_pre;
                
                
                if (tr.rewardLocation == 1) && (tr.firstResponseKey == 'b')    % If they choose the effort option
                    x0=scr.centre(1); y0=scr.centre(2);
                    Screen('FrameRect', scr.w, [0 255 0], [x0-250 y0-180 x0-50 y0+180], 6);
                    ima=imread('Effort0_bar.jpg', 'jpg');
                    Screen('PutImage', scr.w, ima, [x0-177 y0-154 x0-123 y0+154])
                    tr.firstChoice = 0;
                    Screen('Flip',scr.w)
                    WaitSecs(ex.firstChoiceDuration-resp_time + 0.5)  % Waits for a total duration of 4s, so choice period is always 4s
                    
                elseif (tr.rewardLocation == 1) && (tr.firstResponseKey == 'n')    % If they choose the reward option
                    x0=scr.centre(1); y0=scr.centre(2);
                    Screen('FrameRect', scr.w, [0 255 0], [x0+50 y0-180 x0+250 y0+180], 6);
                    drawTextCentred( scr, 'credits', ex.fgColour, scr.centre + [150 0]);
                    tr.firstChoice = 1;
                    Screen('Flip',scr.w)
                    WaitSecs(ex.firstChoiceDuration-resp_time + 0.5)                                        
                    
                elseif (tr.rewardLocation == 2) && (tr.firstResponseKey == 'n')    % If they choose the effort option
                    x0=scr.centre(1); y0=scr.centre(2);
                    Screen('FrameRect', scr.w, [0 255 0], [x0+50 y0-180 x0+250 y0+180], 6); 
                    ima=imread('Effort0_bar.jpg', 'jpg');
                    Screen('PutImage', scr.w, ima, [x0+123 y0-154 x0+177 y0+154])
                    tr.firstChoice = 0;
                    Screen('Flip',scr.w)
                    WaitSecs(ex.firstChoiceDuration-resp_time + 0.5)                  % add the time screen is displayed 0.5 (SEE BELOW)
                    
                elseif (tr.rewardLocation == 2) && (tr.firstResponseKey == 'b')    % If they choose the reward option               
                    x0=scr.centre(1); y0=scr.centre(2);   % inserted, but don't think this is actually needed here
                    Screen('FrameRect', scr.w, [0 255 0], [x0-250 y0-180 x0-50 y0+180], 6);  % These are the coordinates for the Bar Outline
                    drawTextCentred( scr, 'credits', ex.fgColour, scr.centre + [-150 0]);
                    tr.firstChoice = 1;
                    Screen('Flip',scr.w)
                    WaitSecs(ex.firstChoiceDuration-resp_time + 0.5)
                    
                end                                                                                
                
                break;                                                                                             
            end
          end
        end
        
       end
        
        
        KbQueueRelease()     
        
        
        if tr.firstResponseKey == 'b' || tr.firstResponseKey == 'n' 
        
        if (tr.rewardLocation == 1 && tr.firstResponseKey == 'b')  
            
            myimgfile = ex.selfeffortInstruc{TM(trialIndex)};
            ima=imread(myimgfile, 'jpg');
            Screen('PutImage', scr.w, ima, [x0-177 y0-154 x0-123 y0+154])
             Screen('Flip',scr.w)
            WaitSecs(2)  
             Screen('Flip',scr.w)
            WaitSecs(1)  
             Screen('Flip',scr.w)
            x0=scr.centre(1); y0=scr.centre(2);
            drawTextCentred( scr, sprintf('%d credits', tr.stake), ex.selfColour, scr.centre + [150 0]); 
             Screen('Flip',scr.w)
            WaitSecs(2)  
             Screen('Flip',scr.w)
            WaitSecs(1)  
             Screen('Flip',scr.w)
             
        elseif (tr.rewardLocation == 2 && tr.firstResponseKey == 'n')
            
             myimgfile = ex.selfeffortInstruc{TM(trialIndex)};
            ima=imread(myimgfile, 'jpg');
            Screen('PutImage', scr.w, ima, [x0+123 y0-154 x0+177 y0+154])
             Screen('Flip',scr.w)
            WaitSecs(2)  
             Screen('Flip',scr.w)
            WaitSecs(1)  
             Screen('Flip',scr.w)
            x0=scr.centre(1); y0=scr.centre(2);
            drawTextCentred( scr, sprintf('%d credits', tr.stake), ex.selfColour,  scr.centre + [-150 0]); 
             Screen('Flip',scr.w)
            WaitSecs(2)  
             Screen('Flip',scr.w)
            WaitSecs(1)  
             Screen('Flip',scr.w)
             
        elseif (tr.rewardLocation == 1 && tr.firstResponseKey == 'n') % present reward first
            
            x0=scr.centre(1); y0=scr.centre(2);
            drawTextCentred( scr, sprintf('%d credits', tr.stake), ex.selfColour, scr.centre + [150 0]); 
             Screen('Flip',scr.w)
            WaitSecs(2)  
             Screen('Flip',scr.w)
            WaitSecs(1)  
             Screen('Flip',scr.w)
            myimgfile = ex.selfeffortInstruc{TM(trialIndex)};
            ima=imread(myimgfile, 'jpg');
            Screen('PutImage', scr.w, ima, [x0-177 y0-154 x0-123 y0+154])
             Screen('Flip',scr.w)
            WaitSecs(2)  
             Screen('Flip',scr.w)
            WaitSecs(1)  
             Screen('Flip',scr.w)
             
        elseif (tr.rewardLocation == 2 && tr.firstResponseKey == 'b')   % present reward first
           
            x0=scr.centre(1); y0=scr.centre(2);
            drawTextCentred( scr, sprintf('%d credits', tr.stake), ex.selfColour, scr.centre + [-150 0]); 
             Screen('Flip',scr.w)
            WaitSecs(2)  
             Screen('Flip',scr.w)
            WaitSecs(1)  
             Screen('Flip',scr.w)
            myimgfile = ex.selfeffortInstruc{TM(trialIndex)};
            ima=imread(myimgfile, 'jpg');
            Screen('PutImage', scr.w, ima, [x0+123 y0-154 x0+177 y0+154])
             Screen('Flip',scr.w)
            WaitSecs(2)  
             Screen('Flip',scr.w)
            WaitSecs(1)  
             Screen('Flip',scr.w)
            
        end
        
     KbQueueRelease()     
        
     
   % This is for the second choice phase
    
      if tr.offerLocation == 1                  % offer presented on the right
        x0=scr.centre(1); y0=scr.centre(2);
        drawTextCentred( scr, 'Reject', ex.fgColour, scr.centre + [-150 0])  % Present baseline reward
        drawTextCentred( scr, 'Accept', ex.fgColour, scr.centre + [150 0]);    % Present alternative reward

      elseif tr.offerLocation == 2              % offer presented on the left
        x0=scr.centre(1); y0=scr.centre(2);
        drawTextCentred( scr, 'Reject', ex.fgColour, scr.centre + [150 0])   % Present baseline reward
        drawTextCentred( scr, 'Accept', ex.fgColour, scr.centre + [-150 0]);  % Present alternative reward
        
      end
        
        Screen('Flip',scr.w)
        tic 
        tr=LogEvent(ex,el,tr,'choiceOnset');     %Note: corresponds to the picture onset
        choiceOns = [choiceOns;GetSecs];
        tr.choiceOns = choiceOns;
        tr.responseKey = 'z'; %default = no response
        
        while toc < ex.choiceDuration
            [keyIsDown, secs, keyCode] = KbCheck;
          if keyIsDown == 1
            tr.responseKey = GetChar();
            if tr.responseKey == 'b' || tr.responseKey == 'n'     
                
                resp_time = toc;
                tr.RT = resp_time;
                tr=LogEvent(ex,el,tr,'button_press');     %Note: corresponds to the decision / button press
                button_pre = [button_pre;GetSecs];    
                tr.button_pre = button_pre;
                
                
                if (tr.offerLocation == 1) && (tr.responseKey == 'b')    % If they choose the baseline option
                    Screen('FrameRect', scr.w, [0 255 0], [x0-250 y0-180 x0-50 y0+180], 6);
                    drawTextCentred( scr, 'Reject', ex.fgColour, scr.centre + [-150 0]);
                    tr.choice = 0;
                    tr.reward = 1;  
                    Screen('Flip',scr.w)
                    WaitSecs(ex.choiceDuration-resp_time + 0.5)  % Waits for a total duration of 4s, so choice period is always 4s
                    
                elseif (tr.offerLocation == 1) && (tr.responseKey == 'n')    % If they choose the other option
                    Screen('FrameRect', scr.w, [0 255 0], [x0+50 y0-180 x0+250 y0+180], 6);
                    drawTextCentred( scr, 'Accept', ex.fgColour, scr.centre + [150 0]);
                    tr.choice = 1;
                    tr.reward = tr.stake;  
                    Screen('Flip',scr.w)
                    WaitSecs(ex.choiceDuration-resp_time + 0.5)                                        
                    
                elseif (tr.offerLocation == 2) && (tr.responseKey == 'n')    % If they choose the baseline option
                    Screen('FrameRect', scr.w, [0 255 0], [x0+50 y0-180 x0+250 y0+180], 6); 
                    drawTextCentred( scr, 'Reject', ex.fgColour, scr.centre + [150 0]);
                    tr.choice = 0;
                    tr.reward = 1;  
                    Screen('Flip',scr.w)
                    WaitSecs(ex.choiceDuration-resp_time + 0.5)                  % add the time screen is displayed 0.5 (SEE BELOW)
                    
                elseif (tr.offerLocation == 2) && (tr.responseKey == 'b')    % If they choose the other option                
                    Screen('FrameRect', scr.w, [0 255 0], [x0-250 y0-180 x0-50 y0+180], 6);  % These are the coordinates for the Bar Outline
                    drawTextCentred( scr, 'Accept', ex.fgColour, scr.centre + [-150 0]);
                    tr.choice = 1;
                    tr.reward = tr.stake;   
                    Screen('Flip',scr.w)
                    WaitSecs(ex.choiceDuration-resp_time + 0.5)
                    
                end                                                                                
                
                break;                                                                                             
            end
          end
        
        end

        if tr.responseKey == 'z' %If they did not make a choice
           drawTextCentred( scr, 'Respond faster!', ex.green, scr.centre);
           tr.choice = 2;
           tr.reward = 0;   
           tr=LogEvent(ex,el,tr,'noButton_press');                        % note: corresponds to the time when they get the feedback that the decision phase is over, i.e. they were too slow in responding
           noButton_pre = [noButton_pre;GetSecs];    
           tr.noButton_pre = noButton_pre;
           Screen('Flip',scr.w)
           WaitSecs(0.5)                                                  
        end
        
        KbQueueRelease()
        
        
        Screen('Flip',scr.w)             
        WaitSecs(ex.postChoiceTime)
        
        % Select trials on which squeezing would be required
        if trialIndex == 21 || trialIndex == 25 || trialIndex == 27 || trialIndex == 28 || trialIndex == 30 || trialIndex == 33 || trialIndex == 34 || trialIndex == 37 || trialIndex == 40 || trialIndex == 41 || trialIndex == 42 || trialIndex == 43 || trialIndex == 44 || trialIndex == 45 || trialIndex == 47 || trialIndex == 49 || trialIndex == 50 || trialIndex == 52 || trialIndex == 53 || trialIndex == 54 || trialIndex == 57 || trialIndex == 59 || trialIndex == 60 || trialIndex == 61 || trialIndex == 64 || trialIndex == 65 || trialIndex == 67 || trialIndex == 72 || trialIndex == 77 || trialIndex == 79 || trialIndex == 80 || trialIndex == 81 || trialIndex == 85 || trialIndex == 86 || trialIndex == 87 || trialIndex == 89 || trialIndex == 91 || trialIndex == 96
            if (tr.offerLocation == 1 && tr.responseKey == 'b') || (tr.offerLocation == 2 && tr.responseKey == 'n') 
                tr = LogEvent(ex, el, tr, 'startresponse');      % note: corresponds to the effort start (actually the time when the bar is presented and they could start squeezing)
                startresp = [startresp;GetSecs];
                tr.startresp = startresp;
                ex.forceColour = ex.selfColour;
                tr.effort = ex.ForceLevel(1);
                fbfunc = @(f) drawResponseNowFlip(scr, ex, ex.bgColour, f(pa.hand)/MVC(pa.hand), tr.effort , tr.stake);
                [data, ~, tr.startSqueezyAcquisition]  = waitForForceData(ex, tr.startSqueezyAcquisition, ex.responseDuration, 2*MVC(pa.hand), 4, fbfunc);
            elseif (tr.offerLocation == 1 && tr.responseKey == 'n') || (tr.offerLocation == 2 && tr.responseKey == 'b')
                tr = LogEvent(ex, el, tr, 'startresponse');
                startresp = [startresp;GetSecs];
                tr.startresp = startresp;
                ex.forceColour = ex.selfColour;
                fbfunc = @(f) drawResponseNowFlip(scr, ex, ex.bgColour, f(pa.hand)/MVC(pa.hand), tr.effort , tr.stake); 
                [data, ~, tr.startSqueezyAcquisition]  = waitForForceData(ex, tr.startSqueezyAcquisition, ex.responseDuration, 2*MVC(pa.hand), 4, fbfunc);
            else
                tr = LogEvent(ex, el, tr, 'startresponse');
                startresp = [startresp;GetSecs];
                tr.startresp = startresp;
                ex.forceColour = ex.selfColour;
                tr.effort = ex.ForceLevel(1);
                fbfunc = @(f) drawResponseNowFlip(scr, ex, ex.bgColour, f(pa.hand)/MVC(pa.hand), tr.effort , tr.stake);
                [data, ~, tr.startSqueezyAcquisition]  = waitForForceData(ex, tr.startSqueezyAcquisition, ex.responseDuration, 2*MVC(pa.hand), 4, fbfunc);
            end
        % RECORD DATA
            tr.maximumForce = max(data(:,pa.hand)); % maximumForce is the Maximum Force in BioPac Units
            tr.maximumTime =  find(data(:,pa.hand)==tr.maximumForce,1) * ex.responseDuration / length(data(:,pa.hand)); % Time at which maximumForce is reached

            if tr.choice == 1
                tr.timeInWindowRew = sum(abs(data(:,pa.hand)/MVC(pa.hand) > tr.effort)) * (5/length(data(:,pa.hand)));  
            elseif tr.choice == 0
                tr.timeInWindowRew = 3;
            elseif tr.choice == 2
                tr.timeInWindowRew = 0;
            end

            tr.MVC = MVC;
            tr.data1=data(:,1); % tr.data2=data(:,2);   % store all force data

            [keyisdown,secs,keycode] = KbCheck; % check for keypresses
            if(keycode(27)) EXIT=1; end         % check for ESCAPE
            Screen('Flip',scr.w);

            tr=LogEvent(ex,el,tr,'endresponse');        % Note: corresponds to the effort end (actually the end of bar being presented)
            endresp = [endresp;GetSecs];
            tr.endresp = endresp;

            maximumForce=[tr.maximumForce 0]';
            maxF=horzcat(maxF, maximumForce);
            
            WaitSecs(0.5)                % wait 0.5 second between end of bar presentation and reward feedback

            if tr.timeInWindowRew >= 3  % Need to stay over for 3 seconds
                if tr.reward == 1
                    drawTextCentred( scr, sprintf('%d credit', tr.reward), ex.selfColour, scr.centre );
                tr.outcome = 1;           
                elseif tr.reward > 1
                    drawTextCentred( scr, sprintf('%d credits', tr.reward), ex.selfColour, scr.centre );
                tr.outcome = tr.stake;
                end
            elseif (tr.timeInWindowRew < 3) && (tr.choice ~= 2)   
                drawTextCentred( scr, '0 credits', ex.selfColour, scr.centre );
                tr.outcome = 0;
            else drawTextCentred( scr, '0 credits - Respond faster!', ex.selfColour, scr.centre );
                 tr.outcome = 0;
            end

            Screen('Flip',scr.w);
            
            
            tr=LogEvent(ex,el,tr,'rewardFeedback');       %Note: corresponds to the reward onset
            rewardFeedb = [rewardFeedb;GetSecs];
            tr.rewardFeedb = rewardFeedb;
            
            totalReward = totalReward + tr.outcome;       %inserted in order to get the total reward earned
            tr.totalReward = totalReward;
            
        
            WaitSecs(tr.rewardDuration);
            KbQueueRelease()
            Screen('Flip',scr.w);
            
            
        else
            drawTextCentred( scr, 'Next trial...', ex.fgColour, scr.centre);
            Screen('Flip',scr.w)
            WaitSecs(ex.rewardDuration+0.5)
            tr.outcome = 0;        
            tr.timeInWindowRew = 0;
            tr.maximumForce = 0;
            tr.maximumTime = 0;
            tr=LogEvent(ex,el,tr,'startresponse');
            startresp = [startresp;GetSecs];
            tr.startresp = startresp;
            tr=LogEvent(ex,el,tr,'endresponse');
            endresp = [endresp;GetSecs];
            tr.endresp = endresp;
        end
        
        
        else tr.firstChoice = 2;
            drawTextCentred( scr, 'Missed trial - Respond faster!', ex.selfColour, scr.centre ); 
            Screen('Flip',scr.w)
            WaitSecs(5)
        end
        
       
    Screen('Flip',scr.w);    
    
        WaitSecs(1)                    
        
        tr.R=1;     % pa.R_NEEDS_REPEATING_LATER to repeat the trial

    
   end

        
    if trialIndex == 18
        drawTextCentred( scr, sprintf('Start of 3 practice trials'), pa.fgColour, scr.centre );
        Screen('Flip', scr.w)
        KbWait;
        KbQueueRelease()
        Screen('Flip',scr.w);
    end
   
     if trialIndex == 21
        drawTextCentred( scr, sprintf('Start of experiment'), pa.fgColour, scr.centre );
        Screen('Flip', scr.w)
        KbWait;
        KbQueueRelease()
        Screen('Flip',scr.w);
    end
  
    if trialIndex == 46 || trialIndex == 71
        drawTextCentred( scr, sprintf('Relax. Tell the experimenter when you are ready to start again.'), pa.fgColour, scr.centre );
        Screen('Flip', scr.w)
        KbWait;
        KbQueueRelease()
        Screen('Flip',scr.w);
    end
   
    while trialIndex == 96      
        drawTextCentred( scr, sprintf('End of experiment'), pa.fgColour, scr.centre );
        Screen('Flip', scr.w)
        [~,~,kcode]=KbCheck; % allows escaping from expt
        if kcode(88)==1 % 'x' to exit the experiment
           break
        end
    end

    
end                                                                                                
