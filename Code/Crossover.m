function Crossover

% Crossover
%
% Authors: David E. Fencsik, Evan M. Palmer, Jeremy M. Wolfe

% 2010-06 revision to manipulate stim-sets within block
% Todo:
%  + Revise staircase code
%  + Output data
%  + Palmer-style setsize manipulation: show all stim with precue
%  + Fix pedestal/stim size (stim are currently too big)
%  + Cleanup keypress handling
%    + Switch loops to KbStrokeWait or the like
%    + Process response more intelligently
%  + Reduce response set-up code and switch to a/' keys
%  + Calculate and save actual exposure duration
%  + Use bulk texture etc. drawing functions wherever possible
%  + Change sound to PortAudio
%  + Use new DrawFormattedText for all text drawing
%  - Allow for pauses ever so often
%  + Generate masks only when needed
%  + Remove test drawing commands
%  - Fix how noise level is controlled
%    + noise is a settable parameter
%    - Add noise-MCS variable to control how noise is manipulated on 
%      non-staircase runs
%    - On staircase runs, MCS variable is ignored and the first provided
%      noise level is used to start the staircase
%    - On non-staircase runs with MCS turned off, there can be one noise
%      level or one per task
%  + Adjust timing for refresh duration
%  - Allow responses during stimulus presentation?
%  - Finalize dialog box parameters
%  - Set fixed parameters to reasonable values
%  - Add progress bar
%  - Test

    experiment = 'Crossover05';
    Version = '1.0-rc2';

    % get user input
    [subject, praTrials, expTrialsPerCell, staircaseFlag, ...
     noiseLevelList, stimSetList, setSizeList, palmerFlag] = ...
        DialogBox(sprintf('%s Parameters', experiment), ...
                  'Subject:', 'xxx', 0, ...
                  'Practice trials', '8', 1, ...
                  'Exp trials per cell', '2', 1, ...
                  'Run staircase? (0=no)', '1', 1, ...
                  'Noise levels', '0.5', 1, ...
                  'Stimulus sets (2=ori,7=2v5)', '2 7', 1, ...
                  'Set sizes', '1 2 4 8', 1, ...
                  'Palmer-style precues? (1=yes,0=no)', '0', 1);

    %% Set any remaining parameters
    expTrials = 4;
    targetList = [0 1];

    % staircase parameters
    nStaircaseTracks = 1;
    nReversals = 20;
    nReversalsDropped = 10;
    staircaseStart = noiseLevelList(1);
    staircaseSteps = [-0.1, 0.025]; % Error, Correct
    staircaseRange = [0 1];

    % noiseMCS controls how noise-level is manipulated.
    % 0: either one noise level or one level per task was provided
    % 1: balance noise levels with all other factors
    % Note: When a staircase is run, then noiseMCS is ignored and the first
    %       value of noiseLevelList is used to start the staircases.
    noiseMCS = 0;

    % noiseType controls how noise is drawn over the stimuli.  With Palmer
    % precues, noiseType 1 and 2 are both set to 1.
    % 0: draw noise field over the entire display
    % 1: draw over every stimulus cell
    % 2: draw over stimulus cells with stimuli in them
    noiseType = 1;

    % maskFlag controls whether and how masks are drawn after stim offset.
    % Note that masks are square regardless of pedestal shape.
    % 0: none
    % 1: mask only stim positions
    % 2: mask all cells
    % 3: mask whole display (not implemented)
    maskFlag = 0;

    % pedestalFlag. 1: draw pedestals, 0: don't draw them
    pedestalFlag = 1;

    % pedestalShape. 1: square; 2: circle
    pedestalShape = 1;

    % balanceFlag controls how stimuli are placed on the display
    % 0: random stim locations
    % 1: equally spaced on the display (depending on SS)
    balanceFlag = 1;

    % define timings (sec)
    durPreTrial   = 0.745;
    durFixation   = 0.745;
    durSSCues     = 0.160;
    durPostSSCues = 0.440;
    durStim       = 0.080;
    durISI        = 0.080;
    durFeedback   = 0.745;
    durPostTrial  = 0.745;

    % stimulus set-up
    % Note: distance -> pixel sizes (17 in. monitor, 1024x768 resolution)
    % 106 cm -> 60.14 pix/deg --- 105 cm -> 59.58 pix/deg
    %  89 cm -> 50.50 pix/deg ---  88 cm -> 49.93 pix/deg
    %  53 cm -> 30.07 pix/deg ---  52 cm -> 29.50 pix/deg
    nStimCells = 8;
    pedestalRadius = 256;
    pedestalSize = 150; % make sure pedestalSize - stimulusSize >= 0 and is even
    stimSize = 100;
    stimWidth = 20;

    % response set-up
    KbName('UnifyKeyNames'); % standardize across Mac, Win, and Linux
    response0 = KbName('a'); % absent
    response1 = KbName('''"'); % present
    respQuit = KbName('ESCAPE');

    % stimulus presentation modes
    mdDetect = 1; % target present on half of trials, remaining stim are distractors
    mdIdentify = 2; % two target classes, one present on every trial, remaining are distractors

    % audio setup
    InitializePsychSound;
    samplingRate = 44100;
    buzzerDuration = 1/5; % seconds
    paClick = PsychPortAudio('Open', [], [], [], samplingRate, 1);
    PsychPortAudio('FillBuffer', paClick, MakeBeep(1000, .01));
    paBuzz = PsychPortAudio('Open', [], [], [], samplingRate, 1);
    PsychPortAudio('FillBuffer', paBuzz, MakeBuzz(buzzerDuration, samplingRate));

    % misc set-up
    rand('twister', 100 * sum(clock));
    dataFileName = sprintf('%sData-%s.txt', experiment, subject);
    [status, result] = system('echo $HOSTNAME');
    if status == 0
        computer = strtok(result, '.');
        computer = computer(isletter(computer)); % remove any spaces or newlines
    else
        computer = 'unknown';
    end
    blocktime = now;

    % system tests
    if exist('IsOSX') ~= 2 || ~IsOSX
        error('%s can only be run in OSX versions of Psychtoolbox', mfilename);
    end
    AssertOpenGL;

    try
        % Open main window, double-buffered fullscreen window
        Screen('Preference', 'SkipSyncTests', 0);
        Screen('Preference', 'VisualDebugLevel', 4);
        screenNumber=max(Screen('Screens'));
        [winMain, rectMain] = Screen('OpenWindow', screenNumber, 0, [], 32, 2);
        refreshDuration = Screen('GetFlipInterval', winMain);
        durSlack = refreshDuration / 2.0;
        Screen(winMain, 'BlendFunction', GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        [centerX, centerY] = RectCenter(rectMain);

        HideCursor;
        ListenChar(2); % no keypresses on the command window

        % signal end of graphics initialization
        PsychPortAudio('Start', paClick);
        PsychPortAudio('Stop', paClick, 1);

        % Some window set-up
        Screen('TextFont', winMain, 'Arial');
        Screen('TextSize', winMain, 18);
        Screen('TextStyle', winMain, 1); % 0=normal, 1=bold, 2=italic, 4=underlined, 8=outline

        % Define colors
        colWhite = [255 255 255];
        colBlack = [0 0 0];
        colGray = [128 128 128];
        colLightGray = round( (colWhite + colGray) ./ 2 ) + 1;
        colDarkGray = round( (colBlack + colGray) ./ 2 );
        colRed = [255 0 0];
        colBlue = [0 0 255];
        colGreen = [0 150 0];
        colYellow = [255 255 0];
        colForeground = colBlack;
        colBackground = colLightGray;
        colFrame = colBackground;
        colPedestal = colGray;
        colFixation = colRed;
        colCue = colBlack;
        colStim = [170 170 170];
        if (~pedestalFlag)
            colPedestal = colBackground;
        end

        % other rects
        rectFixation = CenterRect([0 0 6 6], rectMain);

        % blank screen and issue wait notice
        Screen('FillRect', winMain, colBackground);
        DrawFormattedText(winMain, 'Please wait...', 'center', 'center', ...
                          colForeground);
        Screen('Flip', winMain);

        % Generate stimuli
        bg = colBackground;
        if numel(bg) == 1
            bg = repmat(bg, 1, 3);
        end
        edgeOffset = round((pedestalSize - stimSize) / 2); % distance from edge of pedestal to edge of stimulus
        middle = ceil(pedestalSize / 2); % middle of the pedestal
        stimRadius = stimWidth / 2; % distance from stimulus edge to its middle
        nStimSets = numel(stimSetList);
        stim = struct('texT', cell(1, nStimSets), ...
                      'texD', cell(1, nStimSets), ...
                      'angleT', cell(1, nStimSets), ...
                      'angleD', cell(1, nStimSets), ...
                      'mode', cell(1, nStimSets), ...
                      'resp', cell(1, nStimSets));
        stimString = cell(nStimSets, 1);
        for i = 1:nStimSets
            switch stimSetList(i)
              case 2
                % orientation
                stimString{i} = 'orientation';
                mat = repmat(0, [pedestalSize, pedestalSize, 4]);
                mat(edgeOffset+1:pedestalSize-edgeOffset, ...
                    middle-stimRadius+1:middle+stimRadius, :) = ...
                    repmat(reshape([colStim 255], 1, 1, 4), ...
                           [stimSize, stimWidth, 1]);
                stim(i).texT = Screen('MakeTexture', winMain, mat);
                stim(i).texD = stim(i).texT;
                stim(i).angleT = 20;
                stim(i).angleD = 0;
                stim(i).mode = mdDetect;
                stim(i).response = {'absent', 'present'};
                clear mat;
              case 7
                %%% 2 vs. 5
                stimString{i} = '2v5';
                % generate basic components
                col = reshape([colStim 255], 1, 1, 4);
                hbar = repmat(col, [stimWidth, stimSize, 1]);
                vbar = repmat(col, [middle - edgeOffset,  stimWidth, 1]);
                % generate common horizontal lines
                mat = repmat(0, [pedestalSize, pedestalSize, 4]);
                mat(edgeOffset+1:edgeOffset+stimWidth, ...
                    edgeOffset+1:pedestalSize-edgeOffset, :) = hbar;
                mat(middle-stimRadius+1:middle+stimRadius, ...
                    edgeOffset+1:pedestalSize-edgeOffset, :) = hbar;
                mat(pedestalSize-edgeOffset-stimWidth+1:...
                    pedestalSize-edgeOffset, ...
                    edgeOffset+1:pedestalSize-edgeOffset, :) = hbar;
                % generate 2
                mat2 = mat;
                mat2(edgeOffset+1:middle, ...
                     pedestalSize-edgeOffset-stimWidth+1:...
                     pedestalSize-edgeOffset, :) = vbar;
                mat2(middle+1:pedestalSize-edgeOffset, ...
                     edgeOffset+1:edgeOffset+stimWidth, :) = vbar;
                stim(i).texT = Screen('MakeTexture', winMain, mat2);
                stim(i).angleT = 0;
                % generate 5
                mat5 = mat;
                mat5(edgeOffset+1:middle, ...
                     edgeOffset+1:edgeOffset+stimWidth, :) = vbar;
                mat5(middle+1:pedestalSize-edgeOffset, ...
                     pedestalSize-edgeOffset-stimWidth+1:...
                     pedestalSize-edgeOffset, :) = vbar;
                stim(i).texD = Screen('MakeTexture', winMain, mat5);
                stim(i).angleD = 0;
                % miscellaneous
                stim(i).mode = mdDetect;
                stim(i).response = {'absent', 'present'};
                clear mat mat2 mat5;
              otherwise
                error('stimulus set %d does not exist', stimSetList(i));
            end
        end

        % define stimulus presentation cells
        expansionFactor = 1.0;
        rectPedestal = [0 0 pedestalSize pedestalSize];
        stimCells = zeros(nStimCells, 4);
        for n = 1:nStimCells
            stimCells(n, :) = CenterRectOnPoint(rectPedestal, ...
                                                centerX + round(pedestalRadius * sin((n - 1) * 2 * pi / nStimCells)), ...
                                                centerY + round(pedestalRadius * cos((n - 1) * 2 * pi / nStimCells)));
        end

        % compute square rect needed to contain all stimulus cells
        extraRadius = ceil( sqrt( (.5 * RectWidth(stimCells(1, :)))^2 + (.5 * RectHeight(stimCells(1, :)))^2 ) );
        stimAreaDiameter = ceil(2 * expansionFactor * (pedestalRadius + extraRadius));
        rectDisplay = CenterRect([0 0 stimAreaDiameter stimAreaDiameter], rectMain);

        % define matrices for alpha channel of noise fields, to restrict their shape
        if noiseType == 1 || noiseType == 2
            % each cell gets its own noise field
            matNoiseTransparency = repmat(255, [pedestalSize, pedestalSize]);
            if pedestalShape == 2
                radius = pedestalSize / 2;
                for x = 1:pedestalSize
                    for y = 1:pedestalSize
                        if floor(sqrt( (x - pedestalSize / 2)^2 + (y - pedestalSize / 2)^2 )) > radius
                            matNoiseTransparency(y, x) = 0;
                        end
                    end
                end
            end
        elseif noiseType == 0
            % one noise field for the whole display
            matNoiseTransparency = repmat(255, [stimAreaDiameter, stimAreaDiameter]);
            if pedestalShape == 2
                radius = stimAreaDiameter / 2;
                for x = 1:stimAreaDiameter
                    for y = 1:stimAreaDiameter
                        if floor(sqrt( (x - stimAreaDiameter / 2)^2 + (y - stimAreaDiameter / 2)^2 )) > radius
                            matNoiseTransparency(y, x) = 0;
                        end
                    end
                end
            end
        else
            error('noise type %d not supported', noiseType);
        end

        % generate mask textures
        if (maskFlag == 0)
            % do nothing
        elseif (any(maskFlag == [1 2]))
            nMaskTextures = nStimCells * 2;
            nLines = 100;
            texMasks = zeros(nMaskTextures, 1);
            for n = 1:nMaskTextures
                texMasks(n) = Screen('OpenOffscreenWindow', winMain, [], ...
                                     [0 0 pedestalSize pedestalSize]);
                Screen('BlendFunction', texMasks(n), ...
                       GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                Screen('FillRect', texMasks(n), colBackground);
                Screen('DrawLines', texMasks(n), ...
                       Randi(pedestalSize + 1, [2, nLines * 2]) - 1, ...
                       Randi(10, [1, nLines]), ...
                       reshape(repmat(Randi(256, [3, nLines]) - 1, [2, 1]), ...
                               [3, nLines * 2]), ...
                       [], 1);
            end
        else
            error('maskFlag values of %d are not supported', maskFlag);
        end

        % set-up pedestal drawings
        if pedestalShape == 1
            pedestalCommand = 'FillRect';
        elseif pedestalShape == 2
            pedestalCommand = 'FillOval';
        else
            error('pedestal shape of %d is not supported', pedestalShape);
        end

        Screen('FillRect', winMain, colBackground);
        DrawFormattedText(winMain, 'Press any key to begin', ...
                          'center', 'center', colForeground);
        Screen('Flip', winMain);
        [t, keyCode] = KbStrokeWait();
        if (any(find(keyCode) == respQuit))
            error('Abort key pressed');
        end

        blockPhaseStrings = {'practice', 'staircase', 'fixed'};
        blockPhases = 1:3;
        for phase = blockPhases
            if (phase == 1 && praTrials > 0)
                phaseName = 'practice';
                nTrials = praTrials;
                doStaircase = 0;
            elseif (phase == 2 && staircaseFlag)
                %% Optional staircasing trials
                phaseName = 'staircase';
                doStaircase = 1;
                %% initialize staircase
                staircase = zeros(nStimSets, 1);
                staircaseIsDone = zeros(nStimSets, 1);
                for i = 1:nStimSets
                    staircase(i) = ...
                        Staircaser('Create', 1, nReversals, ...
                                   staircaseStart, staircaseSteps, ...
                                   nReversalsDropped, ...
                                   nStaircaseTracks, staircaseRange);
                end
                nTrials = 0;
                staircaseTrialCounter = nTrials;
            elseif (phase == 3 && expTrials > 0)
                %% Experimental trials, with noise level determined by
                %% staircase phase or by fixed values
                phaseName = 'fixed';
                nTrials = expTrials;
                doStaircase = 0;
            else
                % none of the phases are applicable
                continue;
            end

            % set up handling of noise levels (see explanation of noiseMCS
            % variable)
            if (staircaseFlag)
                if (strcmp(phaseName, 'fixed'))
                    tempNoiseList = NaN();
                else
                    tempNoiseList = noiseLevelList(1);
                end
            elseif (noiseMCS)
                tempNoiseList = noiseLevelList;
            else
                % set up so noise level varies with stim set
                if (numel(noiseLevelList) ~= numel(stimSetList))
                    error(['if no staircase is being run, then you must '...
                           'provide one noise level per stimulus set']);
                end
                tempNoiseList = NaN();
            end

            % balance independent variables; note that the staircase phase
            % does this within the trial loop
            switch phaseName
              case 'practice'
                [target, setSize, noiseLevel, stimSet] = ...
                    BalanceTrials(nTrials, 1, targetList, ...
                                  setSizeList, tempNoiseList, ...
                                  1:numel(stimSetList));
              case 'fixed'
                [target, setSize, noiseLevel, stimSet] = ...
                    BalanceFactors(expTrialsPerCell, 1, targetList, ...
                                   setSizeList, tempNoiseList, ...
                                   1:numel(stimSetList));
                nTrials = numel(target);
            end

            % fix noise level by stimulus set
            if (isnan(noiseLevel(1)))
                for (i = 1:numel(stimSetList))
                    noiseLevel(stimSet == i) = noiseLevelList(i);
                end
            end

            % set priority level
            priorityLevel = MaxPriority(winMain, 'KbCheck', 'GetSecs');
            % Priority(priorityLevel);
            Priority(0);

            trial = 0;
            blockDone = 0;
            while (~blockDone)
                trial = trial + 1;
                trialtime = datestr(now, 'yyyymmdd.HHMMSS');

                if (doStaircase)
                    staircaseTrialCounter = staircaseTrialCounter + 1;
                    if (staircaseTrialCounter > nTrials)
                        [target, setSize, stimSet] = ...
                            BalanceFactors(10, 1, ...
                                           targetList, setSizeList, ...
                                           1:numel(stimSetList));
                        nTrials = numel(target);
                    end
                    ss = setSize(staircaseTrialCounter);
                    targ = target(staircaseTrialCounter);
                    stimIndex = stimSet(staircaseTrialCounter);
                    [success, noise, trackLabel] = ...
                        Staircaser('StartTrial', staircase(stimIndex));
                    if (~success)
                        error('Staircaser StartTrial failed on trial %d', ...
                              trial);
                    end
                else
                    ss = setSize(trial);
                    targ = target(trial);
                    stimIndex = stimSet(trial);
                    noise = noiseLevel(trial);
                    trackLabel = 0;
                end

                %% Setup display layout
                if (balanceFlag == 0)
                    stimloc = stimCells(randperm(nStimCells), :);
                elseif (balanceFlag == 1 && nStimCells == 8)
                    start = Randi(nStimCells);
                    switch ss
                      case 1
                        i = start;
                        j = start+1:start+7;
                      case 2
                        i = [start, start + 4];
                        j = [start+1:start+3, start+5:start+7];
                      case 4
                        i = start:2:start+6;
                        j = start+1:2:start+7;
                      case 6
                        i = [start:start+2, start+4:start+6];
                        j = [start + 3, start + 7];
                      case 8
                        i = start:start+7;
                        j = [];
                      otherwise
                        error(['balancing setsize %d in %d cells is not '...
                               'supported'], ss, nStimCells);
                    end
                    i = Shuffle(mod(i - 1, nStimCells) + 1);
                    j = Shuffle(mod(j - 1, nStimCells) + 1);
                    stimloc = stimCells([i, j], :);
                else
                    error(['balanceFlag values of %d are not supported ' ...
                           'for %d cells'], balanceFlag, ss);
                end
                stimloc = stimloc';

                colCueMatrix = repmat(colPedestal', 1, nStimCells);
                if palmerFlag
                    % present all stimuli, regardless of setsize
                    nStim = nStimCells;
                    colCueMatrix(:, 1:ss) = repmat(colCue', 1, ss);
                else
                    % present only SS stimuli
                    nStim = ss;
                end

                texture = zeros(nStimCells, 1);
                angle = zeros(nStimCells, 1);
                if stim(stimIndex).mode == mdDetect
                    if targ
                        % select target stimuli
                        index = Randi(length(stim(stimIndex).texT));
                        texture(1) = stim(stimIndex).texT(index);
                        angle(1) = stim(stimIndex).angleT(index);
                        % define index for remaining stimuli
                        index = Randi(length(stim(stimIndex).texD), ...
                                      [numel(texture) - 1, 1]);
                        texture(2:nStimCells) = ...
                            stim(stimIndex).texD(index);
                        angle(2:nStimCells) = ...
                            stim(stimIndex).angleD(index);
                    else
                        index = Randi(length(stim(stimIndex).texD), ...
                                      size(texture));
                        texture = stim(stimIndex).texD(index);
                        angle = stim(stimIndex).angleD(index);
                    end
                else
                    error('stim mode %d not supported', stimMode);
                end

                % generate noise fields
                if noiseType == 0
                    % whole display
                    matNoise = repmat(Randi(256, [stimAreaDiameter, stimAreaDiameter]) - 1, [1, 1, 4]);
                    matNoise(:, :, 4) = matNoiseTransparency;
                    texNoise = Screen('MakeTexture', winMain, matNoise);
                else
                    % one per stim cell
                    if noiseType == 1 || palmerFlag
                        n = nStimCells;
                    else
                        n = ss;
                    end
                    matNoise = repmat(matNoiseTransparency, [1, 1, 4]);
                    texNoise = zeros(n, 1);
                    for i = 1:n
                        matNoise(:, :, 1:3) = repmat(Randi(256, [pedestalSize, pedestalSize]) - 1, [1, 1, 3]);
                        texNoise(i) = Screen('MakeTexture', winMain, matNoise);
                    end
                end

                % generate indexes for mask textures
                if any(maskFlag == [1 2])
                    maskIndex = randperm(nMaskTextures);
                end

                % Reset suppression of keypress output on every trial,
                % since Windows intermittently resets suppression.
                ListenChar(2);

                % make sure no keys are pressed
                KbReleaseWait();

                % pretrial blank
                Screen('FillRect', winMain, colBackground);
                Screen(pedestalCommand, winMain, colPedestal, stimloc);
                Screen('DrawingFinished', winMain);
                tLastOnset = Screen('Flip', winMain);
                tNextOnset = tLastOnset + durPreTrial - durSlack;

                % fixation
                Screen('FillRect', winMain, colBackground, rectDisplay);
                Screen(pedestalCommand, winMain, colPedestal, stimloc);
                Screen('FillOval', winMain, colFixation, rectFixation);
                Screen('DrawingFinished', winMain);
                tLastOnset = Screen('Flip', winMain, tNextOnset);
                PsychPortAudio('Start', paClick);
                PsychPortAudio('Stop', paClick, 1);
                tNextOnset = tLastOnset + durFixation - durSlack;

                % draw pre-cues; note that when palmerFlags == 0, then
                % colCueMatrix is just colPedestal
                Screen('FillRect', winMain, colBackground, rectDisplay);
                Screen(pedestalCommand, winMain, colCueMatrix, stimloc);
                Screen('FillOval', winMain, colFixation, rectFixation);
                Screen('DrawingFinished', winMain);
                tLastOnset = Screen('Flip', winMain, tNextOnset);
                tNextOnset = tLastOnset + durSSCues - durSlack;

                % post pre-cue blank
                Screen('FillRect', winMain, colBackground, rectDisplay);
                Screen(pedestalCommand, winMain, colPedestal, stimloc);
                Screen('FillOval', winMain, colFixation, rectFixation);
                Screen('DrawingFinished', winMain);
                tLastOnset = Screen('Flip', winMain, tNextOnset);
                tNextOnset = tLastOnset + durPostSSCues - durSlack;

                % draw display
                Screen('FillRect', winMain, colBackground, rectDisplay);
                Screen(pedestalCommand, winMain, colPedestal, stimloc);
                Screen('DrawTextures', winMain, texture(1:nStim), [], ...
                       stimloc(:, 1:nStim), angle(1:nStim));
                if noiseType == 0
                    Screen('DrawTexture', winMain, texNoise, [], ...
                           rectDisplay, [], [], noise);
                elseif any(noiseType == [1 2])
                    Screen('DrawTextures', winMain, texNoise, [], ...
                           stimloc(:, 1:numel(texNoise)), [], [], noise);
                end
                Screen('FillOval', winMain, colFixation, rectFixation);
                Screen('DrawingFinished', winMain);
                tLastOnset = Screen('Flip', winMain, tNextOnset);
                tOnsetStimuli = tLastOnset;
                tNextOnset = tLastOnset + durStim - durSlack;

                % ISI
                Screen('FillRect', winMain, colBackground, rectDisplay);
                Screen(pedestalCommand, winMain, colPedestal, stimloc);
                Screen('FillOval', winMain, colFixation, rectFixation);
                Screen('DrawingFinished', winMain);
                tLastOnset = Screen('Flip', winMain, tNextOnset);
                actualExposureDur = 1000 * (tLastOnset - tOnsetStimuli);
                tNextOnset = tLastOnset + durISI - durSlack;

                % mask
                Screen('FillRect', winMain, colBackground, rectDisplay);
                Screen(pedestalCommand, winMain, colPedestal, stimloc);
                if any(maskFlag == [1 2])
                    n = nStim;
                    if maskFlag == 2, n = nStimCells; end
                    Screen('DrawTextures', winMain, ...
                           texMasks(maskIndex(1:n)), [], stimloc(:, 1:n));
                end
                Screen('FillOval', winMain, colFixation, rectFixation);
                Screen('DrawingFinished', winMain);
                tLastOnset = Screen('Flip', winMain, tNextOnset);

                % collect response
                [keyTime, keyCode] = KbStrokeWait();
                Screen('FillRect', winMain, colBackground, rectDisplay);
                tLastOnset = Screen('Flip', winMain);
                responseOnsetTime = keyTime;
                responseCode = find(keyCode);
                if (responseCode == respQuit)
                    error('Abort key pressed');
                end

                % process response
                rt = (responseOnsetTime - tOnsetStimuli) * 1000;
                if isempty(responseCode)
                    responseString = 'none';
                    acc = -1;
                elseif numel(responseCode) > 1
                    responseString = 'multi';
                    acc = -2;
                elseif responseCode == response0
                    responseString = stim(stimIndex).response{1};
                    if targ
                        acc = 0;
                    else
                        acc = 1;
                    end
                elseif responseCode == response1
                    responseString = stim(stimIndex).response{2};
                    if targ
                        acc = 1;
                    else
                        acc = 0;
                    end
                else
                    % non-response key pressed
                    responseString = sprintf('%d', responseCode);
                    acc = -3;
                end

                % prepare feedback
                switch acc
                  case 0
                    feedback = sprintf('TRIAL %d - ERROR', trial);
                    colFeedback = colRed;
                  case 1
                    feedback = sprintf('TRIAL %d - CORRECT', trial);
                    colFeedback = colGreen;
                  case -1
                    feedback = 'NO RESPONSE';
                    colFeedback = colRed;
                  case -2
                    feedback = 'MULTIPLE KEYS PRESSED';
                    colFeedback = colRed;
                  case -3
                    feedback = 'NON-RESPONSE KEY PRESSED';
                    colFeedback = colRed;
                end

                % present feedback
                Screen('FillRect', winMain, colBackground, rectDisplay);
                DrawFormattedText(winMain, feedback, ...
                                  'center', 'center', colFeedback);
                tLastOnset = Screen('Flip', winMain);

                durExtraFeedback = 0;
                if acc < 0
                    durExtraFeedback = buzzerDuration;
                    PsychPortAudio('Start', paBuzz);
                    PsychPortAudio('Stop', paBuzz, 1);
                end
                tNextOnset = tLastOnset + durFeedback + ...
                    durExtraFeedback - durSlack;

                % update staircase
                reversal = 0;
                if doStaircase
                    if any(acc == [0 1])
                        r = acc + 1;
                    else
                        r = 0;
                    end
                    [success, done, reversal] = ...
                        Staircaser('EndTrial', staircase(stimIndex), r);
                    if (~success)
                        error('Staircaser EndTrial failed on trial %d', ...
                              trial);
                    end
                    staircaseIsDone(stimIndex) = done;
                end

                %% output data
                if (~exist(dataFileName, 'file'))
                    %% open new file and print header
                    fid = fopen(dataFileName, 'w');
                    fprintf(fid, ['Subject\tCode\tVersion\t' ...
                                  'Timestamp\tBlock\tTrial\t' ...
                                  'Target\tSetSize\tStimSet\tNoise\t' ...
                                  'Precue\t' ...
                                  'StairTrack\tReversal\t' ...
                                  'Response\tAccuracy\tRT\t' ...
                                  'ActualExpDur\n']);
                else
                    %% open file for appending
                    fid = fopen(dataFileName, 'a');
                end
                fprintf(fid, ['%s\t%s\t%s\t%s\t%s\t%d\t%d\t%d\t%s\t' ...
                              '%0.3f\t%d\t%d\t%d\t' ...
                              '%s\t%d\t%0.0f\t%0.3f\n'], ...
                        subject, mfilename, Version, trialtime, ...
                        blockPhaseStrings{phase}, trial, targ, ss, ...
                        stimString{stimIndex}, noise, palmerFlag, ...
                        trackLabel, reversal, responseString, acc, rt, ...
                        actualExposureDur);
                fclose(fid);

                % clear screen after feedback duration
                Screen('FillRect', winMain, colBackground, rectDisplay);
                Screen('Flip', winMain, tNextOnset);

                % Check whether block is done
                if (any(phase == [1 3]) && trial >= nTrials)
                    blockDone = 1;
                elseif (phase == 2 && doStaircase && all(staircaseIsDone))
                    blockDone = 1;
                end

            end % trial loop
            Priority(0);
        end % block loop

    catch
        %this "catch" section executes in case of an error in the "try" section
        %above.  Importantly, it closes the onscreen window if its open.
        ple();
    end %try..catch..

    Priority(0);
    ListenChar();
    ShowCursor;
    fclose('all');
    Screen('CloseAll');
    PsychPortAudio('Close');
    clear all global

function [pos, index] = MakeGrid (rect, rows, cols, stimrect, randomize, xnoise, ynoise)

% MakeGrid generates a grid of equally-spaced rects within a
% rectangle.  Each row of the returned matrix specifies one rect.
%
% MAKEGRID (RECT, ROWS, COLS, STIMRECT, RANDOMIZES, XNOISE, YNOISE)
% arranges rects of size STIMRECT within RECT in an equally spaced
% ROWS X COLS grid.  Non-zero values of RANDOMIZE lead to
% randomization of the order of the rects; otherwise, the rects are
% arranged in order from left-to-right, then top-to-bottom.  Optional
% arguments XNOISE and YNOISE specify the range of uniformly
% distributed horizontal and vertical noise, respectively, added to
% the centers of the rects (e.g., a value of 10 will lead add noise in
% the range of [-5, 4]).
%
% Author: David E. Fencsik (fencsik@gmail.com)
% $LastChangedDate$

    if numel(randomize) ~= 1
        randomize = 0;
    end
    if nargin < 6 || numel(xnoise) ~= 1
        xnoise = 0;
    end
    if nargin < 7 || numel(ynoise) ~= 1
        ynoise = 0;
    end

    n = cols * rows;

    bigW = rect(3) - rect(1);
    bigH = rect(4) - rect(2);
    smallW = stimrect(3) - stimrect(1);
    smallH = stimrect(4) - stimrect(2);

    intBorderX = floor((bigW - cols * smallW) / (cols + 1));
    extBorderX = ceil((bigW - cols * smallW - intBorderX * (cols - 1)) / 2);
    intBorderY = floor((bigH - rows * smallH) / (rows + 1));
    extBorderY = ceil((bigH - rows * smallH - intBorderY * (rows - 1)) / 2);

    xOffset = rect(RectLeft);
    yOffset = rect(RectTop);

    pos = zeros(n, 4);

    for r = 1:rows
        for c = 1:cols
            pos(cols * (r - 1) + c, :) = ...
                [extBorderX + (smallW + intBorderX) * (c - 1), ...
                 extBorderY + (smallH + intBorderY) * (r - 1), ...
                 extBorderX + (smallW + intBorderX) * (c - 1) + smallW, ...
                 extBorderY + (smallH + intBorderY) * (r - 1) + smallH];
        end
    end

    if xnoise > 0
        pos(:, [1 3]) = pos(:, [1 3]) + repmat(Randi(xnoise, [n, 1]) - ceil(xnoise / 2) - 1, [1, 2]);
    end
    if ynoise > 0
        pos(:, [2 4]) = pos(:, [2 4]) + repmat(Randi(ynoise, [n, 1]) - ceil(ynoise / 2) - 1, [1, 2]);
    end

    pos = pos + repmat([xOffset yOffset xOffset yOffset], size(pos, 1), 1);

    if randomize
        [tmp, index] = sort(rand(n, 1));
        pos = pos(index, :);
    else
        index = 1:n;
    end


function [pos, index] = MakeRing (rect, stimrect, num, radius, randomize, equidistant)

% MakeRing (RECT, STIMRECT, NUM, RADIUS, RANDOMIZE, EQUIDISTANT)
%
% Generates stimulus positions in a circle around the center of a
% supplied display rect.
%
% Generates NUM positions, each with a rect the size of STIMRECT
% located RADIUS pixels from the center of RECT.  If RANDOMIZE is 1,
% then the order of the positions is randomized (default 0).  If
% EQUIDISTANT is greater than N, then the stimulus positions have
% angular displacements as if there were EQUIDISTANT stimuli equally
% spaced around the circle; otherwise, all N stimuli are equally
% spaced.

    if nargin < 3 || numel(randomize) ~= 1
        randomize = 0;
    end
    if nargin < 4 || numel(equidistant) ~= 1
        equidistant = 0;
    end

    [centerX, centerY] = RectCenter(rect);

    if equidistant > num
        delta = 2 * pi / equidistant;
    else
        delta = 2 * pi / num;
    end

    start = rand * 2 * pi;

    pos = zeros(num, 4);

    for n = 1:num
        theta = start + delta * (n - 1);
        x = radius * sin(theta);
        y = radius * cos(theta);
        pos(n, :) = CenterRectOnPoint(stimrect, centerX + x, centerY - y);
    end

    if randomize
        [tmp, index] = sort(rand(num, 1));
        pos = pos(index, :);
    else
        index = 1:n;
    end



function varargout = DialogBox (title, varargin)
    n = (nargin - 1);
    if nargout ~= n / 3
        error('input and output arguments must match');
    end
    prompt = varargin(1:3:n);
    defaults = varargin(2:3:n);
    toNum = varargin(3:3:n);
    param = inputdlg(prompt, title, 1, defaults);
    if isempty(param)
        error('Dialog box cancelled');
    end
    varargout = cell(1, nargout);
    for i = 1:length(param)
        p = param{i};
        if toNum{i}
            n = [];
            if ~exist(p)
                n = str2num(p);
                if ~isempty(n)
                    varargout{i} = n;
                end
            end
            if isempty(n)
                error(['parameter ''%s'' value ''%s'' could not be ', ...
                       'converted to numeric as requested'], prompt{i}, p);
            end
        else
            varargout{i} = p;
        end
    end
