function CrossoverSDT8b

% One-Shot Search Control for Confidence Ratings studies
%
% $LastChangedDate: 2006-03-23 14:11:22 -0500 (Thu, 23 Mar 2006) $

%%%
%%% 02/13/06 Changed to Method of Constant Stimuli by EMP
%%%          50 TP and 50 TA trials at Noise Levels: 10:10:90
%%%
%%% 03/03/06 Changed timing of presentation to 160 ms flag, 80 ISI, 80 stim
%%% 03/23/06 DEF: 1. cleaned up window opening code
%%%               2. added 2v5 task
%%% 
%%%
%%% 05/31/06 EMP: Same as 7b, except cue then physical set size manipulation instead of just Palmer flag
%%%        
%%% 06/08/06 EMP: Same as 8, except locks in noise value after 20 reversals. Noise value is average of 
%%%               last 10 reversals.
%%%
%%% 06/09/06 EMP: Add capability to set a starting noise value.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%clear everything before you begin
clear all;

%set the state of the random number generator to some random value (based on the clock)
rand('state',sum(100*clock));
%USED IN CENTERTEXT
global win1 screenX screenY


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SETUP WINDOWS

ttr=10;
bcolor=[128 128 128];
c1=[200 150 250];
cuecolor=[0 0 100];

%%% % We used to open a full-screen window in order to determine the
%%% % center of the display, but this is inefficient.  Also note that the
%%% % full-screen rect was computed from display 0, while the actual window
%%% % was opened on the highest-numbered display, meaning that the display
%%% % wouldn't be centered if you have two monitors that weren't the same
%%% % size.
%%%
%%% [fullwin,screenRect]=SCREEN(0,'OpenWindow',0,[],32);
%%% 
%%% %screenX and screenY are determined by the resolution of the main window
%%% screenX=screenRect(1,3);
%%% screenY=screenRect(1,4);
%%% 
%%% centx=screenX/2;
%%% centy=screenY/2;
%%% screenNumber = max(Screen('Screens'));
%%% [win1,screenRect]=SCREEN(screenNumber,'OpenWindow',0,[centx-512 centy-359 centx+512 centy+359],32);

% a different way to center the screen rect is this:
screenNumber = max(Screen('Screens'));
fullRect = Screen(screenNumber, 'Rect');
screenRect = CenterRect([0 0 1024 768], fullRect);
[win1,screenRect] = Screen(screenNumber, 'OpenWindow', 0, screenRect, 32);

SCREEN(win1,'TextSize',24);
SCREEN(win1,'FillRect',128);
Blank=SCREEN(win1,'OpenOffscreenWindow',bcolor,screenRect);
stim=SCREEN(win1,'OpenOffscreenWindow',bcolor,screenRect);
preScreen=SCREEN(win1,'OpenOffscreenWindow',bcolor,screenRect);
cueScreen=SCREEN(win1,'OpenOffscreenWindow',bcolor,screenRect);
stimON=SCREEN(win1,'OpenOffscreenWindow',bcolor,screenRect);
stimOFF=SCREEN(win1,'OpenOffscreenWindow',bcolor,screenRect);
Screen(win1,'WindowToFront');
refreshDuration = 1000 / Screen(win1, 'FrameRate', []);

SCREEN(Blank,'FillRect',128);

%screenX and screenY are determined by the resolution of the main window
screenX=screenRect(1,3);
screenY=screenRect(1,4);

centx=screenX/2;
centy=screenY/2;

rad=screenX/4;	% if the stimulus doesn't fit on the screen change this denominator (make it bigger)
ItemSize=round(rad/4);
CellCount=8;

smx=750;
smy=500;

ymove=0; % shifts the display up the screen



%get input
%prompt={'Enter initials:','1=Col,2=Ori,3-Conj,4-TLconj,5-TvL,6-easyTvL,7-2v5','Practice Trials:','Number Reversals Until Stable','Trials Per Cell After Stable',...
%'proportion noise (0-1)','noise UP step', 'noise DOWN step', 'color1','color2','orient1','orient2','palmerStyle 0=AccNo 1=AccYes, 2=RTno, 3=RTyes '};
%def={['x' num2str(randi(100))],'7','50','20','50','.5','.025','.1','170 170 170', '0 255 255','0','90','0'};
%title='Input Variables';
%lineNo=1;
%userinput=inputdlg(prompt,title,lineNo,def,'on');

prompt={'Enter initials:','1=Col,2=Ori,3-Conj,4-TLconj,5-TvL,6-easyTvL,7-2v5','Practice Trials:','1=Staircase, 2=Fixed Noise','color1','color2','orient1','orient2','palmerStyle 0=AccNo 1=AccYes, 2=RTno, 3=RTyes '};
def={['x' num2str(randi(100))],'7','50','1','170 170 170', '0 255 255','20','0','0'};
title='Input Variables';
lineNo=1;
userinput=inputdlg(prompt,title,lineNo,def,'on');



%Convert User Input
sinit=(userinput{1,1});
taskflag=str2num(userinput{2,1});
ptrials=str2num(userinput{3,1});
stair_fix=str2num(userinput{4,1});
c1=str2num(userinput{5,1});
c2=str2num(userinput{6,1});
or1=str2num(userinput{7,1});
or2=str2num(userinput{8,1});
palmerFlag=str2num(userinput{9,1});


if stair_fix==1
	%%% STAIRCASE DIALOG BOX
	prompt2={'Number Reversals Until Stable','Trials Per Cell After Stable','Starting Noise Value (0-1)','Noise UP Step', 'Noise DOWN Step',};
	def2={'40','100','.5','.025','.1'};
	title2='Staircase Variables';
	lineNo2=1;
	userinput2=inputdlg(prompt2,title2,lineNo2,def2,'on');
	
	numReversals=str2num(userinput2{1,1});
	numtrials=str2num(userinput2{2,1});
	noiseParam=str2num(userinput2{3,1});
	noiseUp=str2num(userinput2{4,1});
	noiseDown=str2num(userinput2{5,1});
	
elseif stair_fix==2
	%%% FIXED NOISE DIALOG BOX
	prompt3={'What is your noise value?','Trials Per Cell'};
	def3={'0.000','100'};
	title3='Fixed Noise Value';
	lineNo3=1;
	userinput3=inputdlg(prompt3,title3,lineNo3,def3,'on');
	
	fixedNoiseValue=str2num(userinput3{1,1});
	numtrials=str2num(userinput3{2,1});
	
	usethisnoise=fixedNoiseValue;
end

%%% HARD-CODING SOME EXPERIMENT OPTIONS TO MAKE ROOM IN DIALOG BOX.
SS=[1 2 4 8];
cuedur=160;
cuestimISI=440;
stimdur=80;
stimmaskISI=80;

%get input
%prompt={'proportion noise (0-1)','noise UP step', 'noise DOWN step'};
%def={'.5','.025','.1'};
%title='Input Variables';
%lineNo=1;
%userinput=inputdlg(prompt,title,lineNo,def,'on');

%noiseParam=str2num(userinput{1,1});
%noiseUp=str2num(userinput{2,1});
%noiseDown=str2num(userinput{3,1});
%oldParam=0;
%revList=[];


c1str=[num2str(c1(1)),'_'num2str(c1(2)),'_'num2str(c1(3))];
c2str=[num2str(c2(1)),'_'num2str(c2(2)),'_'num2str(c2(3))];
or1str=[num2str(or1),'deg'];
or2str=[num2str(or2),'deg'];


ssnum=length(SS);

cuedurRefreshes = floor(cuedur / refreshDuration);
cuestimISIRefreshes = floor(cuestimISI / refreshDuration);
durnum=length(stimdur);
stimDurRefreshes = floor(stimdur / refreshDuration);
ISInum=length(stimmaskISI);
stimmaskISIRefreshes = floor(stimmaskISI / refreshDuration);
%noisenum=length(noiseLevels);


feedflag=2;	% normal feedback

%%xtrials=celltr*2*durnum*ssnum*noisenum;		% total experimental trials  %% Eliminated because using staircase version


% Make a ring of big item locations (cell 1-8) and small item locations (cell 9-16)
for c=0:7;
	x=sin(c*0.25*pi)*rad;
	y=cos(c*0.25*pi)*rad;
	x1=centx+x-ItemSize;
	x2=centx+x+ItemSize;
	y1=(centy+y-ItemSize)-ymove;
	y2=(centy+y+ItemSize)-ymove;
	cell{c+1}=[x1 y1 x2 y2];
	% 	SCREEN(win1,'FillRect',[randi(255) randi(255) randi(255)],cell{c+1});
	x=sin((c+0.5)*0.25*pi)*rad/2;
	y=cos((c+0.5)*0.25*pi)*rad/2;
	x1=centx+x-ItemSize/2;
	x2=centx+x+ItemSize/2;
	y1=(centy+y-ItemSize/2)-ymove;
	y2=(centy+y+ItemSize/2)-ymove;
	cell{c+9}=[x1 y1 x2 y2];
	% 	SCREEN(win1,'FillRect',[randi(255) randi(255) randi(255)],cell{c+9});
end
% make the pre screen
SCREEN(preScreen,'FillRect',128);
SCREEN(preScreen,'FillRect',250,[centx-10 centy-10 centx+10 centy+10]);
for m=1:8
	SCREEN(preScreen,'FillRect',[100 100 100],cell{m});
end

SCREEN('COPYWINDOW', preScreen, win1);	% puts up the place holders

% MAKE THE STIMULI
% hard T v L

% T(1)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
% SCREEN(T(1),'FillRect',c1,[0 10 100 30]);
% SCREEN(T(1),'FillRect',c1,[40 0 60 100]);
% T(2)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
% SCREEN(T(2),'FillRect',c1,[0 70 100 90]);
% SCREEN(T(2),'FillRect',c1,[40 0 60 100]);
% T(3)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
% SCREEN(T(3),'FillRect',c1,[10 0 30 100]);
% SCREEN(T(3),'FillRect',c1,[0 40 100 60]);
% T(4)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
% SCREEN(T(4),'FillRect',c1,[70 0 90 100]);
% SCREEN(T(4),'FillRect',c1,[0 40 100 60]);

% HARD L black
L(1)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(L(1),'FillRect',0,[0 10 100 30]);
SCREEN(L(1),'FillRect',0,[10 0 30 100]);
L(2)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(L(2),'FillRect',0,[70 0 90 100]);
SCREEN(L(2),'FillRect',0,[0 10 100 30]);
L(3)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(L(3),'FillRect',0,[70 0 90 100]);
SCREEN(L(3),'FillRect',0,[0 10 100 30]);
L(4)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(L(4),'FillRect',0,[0 70 100 90]);
SCREEN(L(4),'FillRect',0,[10 0 30 100]);


% HARD L c1
Lc1(1)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(Lc1(1),'FillRect',c1,[0 10 100 30]);
SCREEN(Lc1(1),'FillRect',c1,[10 0 30 100]);
Lc1(2)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(Lc1(2),'FillRect',c1,[70 0 90 100]);
SCREEN(Lc1(2),'FillRect',c1,[0 10 100 30]);
Lc1(3)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(Lc1(3),'FillRect',c1,[70 0 90 100]);
SCREEN(Lc1(3),'FillRect',c1,[0 10 100 30]);
Lc1(4)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(Lc1(4),'FillRect',c1,[0 70 100 90]);
SCREEN(Lc1(4),'FillRect',c1,[10 0 30 100]);

% HARD L c2
Lc2(1)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(Lc2(1),'FillRect',c2,[0 10 100 30]);
SCREEN(Lc2(1),'FillRect',c2,[10 0 30 100]);
Lc2(2)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(Lc2(2),'FillRect',c2,[70 0 90 100]);
SCREEN(Lc2(2),'FillRect',c2,[0 10 100 30]);
Lc2(3)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(Lc2(3),'FillRect',c2,[70 0 90 100]);
SCREEN(Lc2(3),'FillRect',c2,[0 10 100 30]);
Lc2(4)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(Lc2(4),'FillRect',c2,[0 70 100 90]);
SCREEN(Lc2(4),'FillRect',c2,[10 0 30 100]);

% easy T black
T(1)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
SCREEN(T(1),'FillRect',0,[0 0 100 20]);
SCREEN(T(1),'FillRect',0,[40 0 60 100]);
T(2)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(T(2),'FillRect',0,[0 80 100 100]);
SCREEN(T(2),'FillRect',0,[40 0 60 100]);
T(3)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); % Left
SCREEN(T(3),'FillRect',0,[0 0 20 100]);
SCREEN(T(3),'FillRect',0,[0 40 100 60]);
T(4)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); %Right
SCREEN(T(4),'FillRect',0,[80 0 100 100]);
SCREEN(T(4),'FillRect',0,[0 40 100 60]);

% easy T c1
Tc1(1)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
SCREEN(Tc1(1),'FillRect',c1,[0 0 100 20]);
SCREEN(Tc1(1),'FillRect',c1,[40 0 60 100]);
Tc1(2)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(Tc1(2),'FillRect',c1,[0 80 100 100]);
SCREEN(Tc1(2),'FillRect',c1,[40 0 60 100]);
Tc1(3)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); % Left
SCREEN(Tc1(3),'FillRect',c1,[0 0 20 100]);
SCREEN(Tc1(3),'FillRect',c1,[0 40 100 60]);
Tc1(4)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); %Right
SCREEN(Tc1(4),'FillRect',c1,[80 0 100 100]);
SCREEN(Tc1(4),'FillRect',c1,[0 40 100 60]);

% easy T c2
Tc2(1)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
SCREEN(Tc2(1),'FillRect',c2,[0 0 100 20]);
SCREEN(Tc2(1),'FillRect',c2,[40 0 60 100]);
Tc2(2)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(Tc2(2),'FillRect',c2,[0 80 100 100]);
SCREEN(Tc2(2),'FillRect',c2,[40 0 60 100]);
Tc2(3)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); % Left
SCREEN(Tc2(3),'FillRect',c2,[0 0 20 100]);
SCREEN(Tc2(3),'FillRect',c2,[0 40 100 60]);
Tc2(4)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); %Right
SCREEN(Tc2(4),'FillRect',c2,[80 0 100 100]);
SCREEN(Tc2(4),'FillRect',c2,[0 40 100 60]);



%easy L
eL(1)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(eL(1),'FillRect',c1,[0 0 100 20]);
SCREEN(eL(1),'FillRect',c1,[0 0 20 100]);
eL(2)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(eL(2),'FillRect',c1,[80 0 100 100]);
SCREEN(eL(2),'FillRect',c1,[0 0 100 20]);
eL(3)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(eL(3),'FillRect',c1,[80 0 100 100]);
SCREEN(eL(3),'FillRect',c1,[0 0 100 20]);
eL(4)=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]);
SCREEN(eL(4),'FillRect',c1,[0 80 100 100]);
SCREEN(eL(4),'FillRect',c1,[0 0 20 100]);


% 2 vs. 5, color 1
two = Screen(win1, 'OpenOffscreenWindow', bcolor, [0 0 100 100]);
Screen(two, 'FillRect', c1, [  0   0 100  20]);
Screen(two, 'FillRect', c1, [  0  40 100  60]);
Screen(two, 'FillRect', c1, [  0  80 100 100]);
Screen(two, 'FillRect', c1, [ 80   0 100  60]);
Screen(two, 'FillRect', c1, [  0  40  20 100]);
five = Screen(win1, 'OpenOffscreenWindow', bcolor, [0 0 100 100]);
Screen(five, 'FillRect', c1, [  0   0 100  20]);
Screen(five, 'FillRect', c1, [  0  40 100  60]);
Screen(five, 'FillRect', c1, [  0  80 100 100]);
Screen(five, 'FillRect', c1, [  0   0  20  60]);
Screen(five, 'FillRect', c1, [ 80  40 100 100]);


% Conj stimuli
o1x1=50-(40*sin(or1/57.2958));
o1x2=50+(40*sin(or1/57.2958));
o1y1=50+(40*cos(or1/57.2958));
o1y2=50-(40*cos(or1/57.2958));

o2x1=50-(40*sin(or2/57.2958));
o2x2=50+(40*sin(or2/57.2958));
o2y1=50+(40*cos(or2/57.2958));
o2y2=50-(40*cos(or2/57.2958));

c1o1=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
SCREEN(c1o1,'DrawLine',c1,o1x1,o1y1,o1x2,o1y2,[12],[12]);
c2o1=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
SCREEN(c2o1,'DrawLine',c2,o1x1,o1y1,o1x2,o1y2,[12],[12]);
c1o2=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
SCREEN(c1o2,'DrawLine',c1,o2x1,o2y1,o2x2,o2y2,[12],[12]);
c2o2=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
SCREEN(c2o2,'DrawLine',c2,o2x1,o2y1,o2x2,o2y2,[12],[12]);

% 45 deg Conj stimuli
c1_135=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
SCREEN(c1_135,'DrawLine', c1,20,20,80,80, [12],[12]);
c2_135=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
SCREEN(c2_135,'DrawLine', c2, 20,20,80,80,[12],[12]);
c1_45=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
SCREEN(c1_45,'DrawLine', c1, 20,80,80,20, [12],[12]);
c2_45=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
SCREEN(c2_45,'DrawLine', c2, 20,80,80,20, [12],[12]);

R0=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
SCREEN(R0,'DrawLine', c1,50,0,50,100, [14],[14]);
G0=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
SCREEN(G0,'DrawLine', c2, 50,0,50,100, [14],[14]);
R90=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
SCREEN(R90,'DrawLine', c1, 0,50,100,50, [14],[14]);
G90=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
SCREEN(G90,'DrawLine', c2, 0,50,100,50, [14],[14]);

CD{1}=R0;
CD{2}=G0;
CD{3}=c1_45;
CD{4}=c2_135;

% Masks
for i=1:16
	M(i)=SCREEN(win1,'OpenOffscreenWindow',[125 125 125],[0 0 100 100]); 
	for j=1:30
		SCREEN(M(i),'DrawLine', [randi(255,[1,3])],randi(100),randi(100),randi(100),randi(100), [randi(10)],[randi(10)]);
	end
	SCREEN('COPYWINDOW',M(i), win1,[0 0 100 100], cell{i});%put the masks into the window
end



loc=shuffle(1:8);


FlushEvents('KeyDown');
GetChar;	
% break

SCREEN(win1,'FillRect',128);


%Make some beeps
[Hibeep,samplingRate]=makeBeep(1500,.01);
[Lobeep,samplingRate]=makeBeep(150,.03);
[Clickbeep,samplingRate]=makeBeep(1000,.01);
[beep,samplingRate]=makeBeep(650,.1);
[errbeep,samplingRate] = MakeBeep(850,.11);


HideCursor;

cstr{1}='NoFeed';
cstr{2}='WithFeed';
tstr{1}='ColorFeat';
tstr{2}='OrFeat';
tstr{3}='Conj';
tstr{4}='TvLConj';
tstr{5}='TvL';
tstr{6}='easyTvL';
tstr{7}='2v5';


cond=[tstr{taskflag}];

fileName1 = ['CrossoverSDT8b_',tstr{taskflag},'_',num2str(palmerFlag),'_', sinit];
fid1=fopen(fileName1, 'a');

%datastr1='sinit\tcond\tpalmerFlag\tcolor1\tcolor2\torient1\torient2\tvarOrient1\tvarOrient2\trefreshDur\tstimdur\tnRefreshes\tstimmaskISI';
%datastr2='\tmRefreshes\tactualdur\tpr/exp\tctr\tss\tTP?\tRT\tresponse\tmessage\terr\tTloc\tnoiseParam\trevString\t1TP\t1TA\t2TP\t2TA\t4TP\t4TA\t8TP\t8TA\n';

%eval(['fprint(fid1, ''' datastr1 '' datastr2 ''' );']);

fprintf(fid1,'sinit\tcond\tpalmerFlag\tcolor1\tcolor2\torient1\torient2\tvarOrient1\tvarOrient2\trefreshDur\tstimdur\tnRefreshes\tstimmaskISI');
fprintf(fid1,'\tmRefreshes\tactualdur\tpr/exp\tctr\tss\tTP?\tRT\tresponse\tmessage\terr\tTloc\tnoiseParam\trevString\tnumReversals\tStable?\n'); %write the data 
moo=fclose(fid1);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%instructions
txsz=18;
SCREEN(win1,'TextSize',txsz);
top=-200;
if taskflag==1
	CenterText('You are looking for a square of this color',0,top+txsz*1.5*1,c1);	
	CenterText('among the distractors of this color ',0,top+txsz*1.5*2,c2);	
elseif taskflag==2
	CenterText(['You are looking for a line tilted ' num2str(or1) 'deg'],0,top+txsz*1.5*1,[255 255 0]);	
	CenterText(['among lines tilted ' num2str(or2) 'deg'],0,top+txsz*1.5*2,[255 255 0]);	
elseif taskflag==3 
	CenterText(['You are looking for a line of this color tilted ' num2str(or1) ' deg'],0,top+txsz*1.5*1,c1);	
	CenterText(['among lines line of this color tilted ' num2str(or2) ' deg'],0,top+txsz*1.5*2,c1);	
	CenterText(['and lines of this color tilted ' num2str(or1) ' deg'],0,top+txsz*1.5*3,c2);	
elseif taskflag==4
	CenterText(['You are looking for a T of this color'],0,top+txsz*1.5*1,c1);	
	CenterText(['among Ls of this color'],0,top+txsz*1.5*2,c1);	
	CenterText(['and Ls of this color'],0,top+txsz*1.5*3,c2);	
elseif taskflag==5 
	CenterText('You are looking for a T among Ls',0,top+txsz*1.5*1,[255 255 0]);
elseif taskflag==6 
	CenterText('You are looking for a T among Ls',0,top+txsz*1.5*1,[255 255 0]);	
elseif taskflag==7
	CenterText('You are looking for a 2 among 5s',0,top+txsz*1.5*1,[255 255 0]);	
end	
CenterText('A target is present on 50% of the trials',0,top+txsz*1.5*5,[255 255 0]);	
CenterText('Hit the quote key if you think a  target is present',0,top+txsz*1.5*6,[255 255 0]);	
CenterText('Hit the A key, if you do not',0,top+txsz*1.5*7,[255 255 0]);	
CenterText('Press any key to continue',0,260,[255 255 0]);


FlushEvents('KeyDown');
GetChar;

SCREEN('CopyWindow',Blank,win1);
waitsecs(.5);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%get key assignments
Key1=57;
Key2=57;
pauseKey=50;

while (Key1==Key2)
	SCREEN('CopyWindow',Blank,win1);
	CenterText('Press a key for "target present" responses',0,-40,[255 255 255]);
	
	FlushEvents('keyDown');
	
	while(1)
		[keyIsDown,secs,keyCode]=KbCheck;
		if keyIsDown
			Key1=find(keyCode);
			Key1=Key1(1);
			break;
		end
	end

	SCREEN('CopyWindow',Blank,win1);
	WaitSecs(.5);
	
	CenterText('Press a key for "target absent" responses',0,-40,[255 255 255]);
	
	FlushEvents('keyDown');
	
	while(1)
		[keyIsDown,secs,keyCode]=KbCheck;
		if keyIsDown
			Key2=find(keyCode);
			Key2=Key2(1);
			break;
		end
	end
end

SCREEN('CopyWindow',Blank,win1,[],screenRect);

if stair_fix==1
	startingNoise = noiseParam;
end
	
for a=1:2
	if a==1
		ttr=ptrials;
		CenterText(['Begin ' num2str(ttr) ' practice trials'],0,-40,[255 255 255]);
		prstr='practice';
		startcounting=0;
	else
		if stair_fix==2
			startcounting=1;
			usethisnoise=fixedNoiseValue;
		end
		ttr=2*ssnum*numtrials;
		CenterText(['Begin experimental trials'],0,-40,[255 255 255]);
		prstr='exp';
	end
	CenterText('Press any key to continue',0,0,[0 0 180]);
	FlushEvents('KeyDown');
	GetChar;
	SND('Play',Hibeep);
	SCREEN(win1,'FillRect',128);
	CenterText(['thanks'],0,40,[0 130 200]);
	waitsecs(.6);
	% 	FlushEvents('KeyDown');
	% 	SCREEN(win1,'FillRect',255);
	
	% set up trials
	temp=0;
	for z=0:1	% YN
		for s=1:ssnum
			for i=1:numtrials
				temp=temp+1;
				YNlist(temp)=z;
				SSlist(temp)=SS(s);
			end
		end
	end

	tord=shuffle(1:ttr);
	
	exit=0;
	ctr=0;
	revList=[];
	trialctr=0;
	
	if (a==1)&(ptrials==0)
		exit=1;
	end

	if stair_fix==1
		noiseParam=startingNoise;
	else
		noiseParam=fixedNoiseValue;
	end
	
	
	if stair_fix==1
		startcounting=0;
	elseif a==2
		startcounting=1;
		trialctr=1;
	end
	
		
	%for ctr=1:ttr  %% Removed because stopping after certain number of reversals
	while exit~=1	
		
		ctr=ctr+1;
		
		randConj=randi(2);	% this will be used to make sure that you don't always do the conj distractors in the sameorder 
		response=9000;
		
		%ss=SS(ssn(tord(ctr)));
		
		if startcounting~=1
			temp=shuffle(shuffle(shuffle(SS)));
			ss=temp(1);
			YN=round(rand);
		else
			ss=SSlist(tord(trialctr));
			YN=YNlist(tord(trialctr));
		end
		
		
		% 		SCREEN(win1,'FillRect',128);	
		loc=shuffle(1:CellCount);
		ori=randi(4,[1,CellCount]);
		%nRefreshes = stimDurRefreshes(durindex(tord(ctr)));
		%mRefreshes = stimmaskISIRefreshes(1);	% need to change if there is ever more than 1 ISI
		
		nRefreshes = stimDurRefreshes;
		mRefreshes = stimmaskISIRefreshes;	% need to change if there is ever more than 1 ISI
		
		SCREEN(stim,'FillRect',128);
		for mm=1:8 % make  a new mask
			SCREEN('COPYWINDOW',M(randi(16)), stimOFF,[0 0 100 100], cell{mm});%put the masks into the window
		end
	
		%noiseParam=noiseLevels(noiseindex(tord(ctr)));		% Removed for staircase version
		
		% recalculate orientations for the variable version	
		% 		vor1=round(or1+(3*randn(1)));
		% 		vor2=round(or2+(3*randn(1)));
		
		% otherwise no variability in orientation
		vor1=or1;
		vor2=or2;
		
		o1x1=50-(40*sin(vor1/57.2958));
		o1x2=50+(40*sin(vor1/57.2958));
		o1y1=50+(40*cos(vor1/57.2958));
		o1y2=50-(40*cos(vor1/57.2958));
		
		o2x1=50-(40*sin(vor2/57.2958));
		o2x2=50+(40*sin(vor2/57.2958));
		o2y1=50+(40*cos(vor2/57.2958));
		o2y2=50-(40*cos(vor2/57.2958));
		
		%c1vo1=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
		%SCREEN(c1vo1,'DrawLine',c1,o1x1,o1y1,o1x2,o1y2,[12],[12]);
		%c2vo1=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
		%SCREEN(c2vo1,'DrawLine',c2,o1x1,o1y1,o1x2,o1y2,[12],[12]);
		%c1vo2=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
		%SCREEN(c1vo2,'DrawLine',c1,o2x1,o2y1,o2x2,o2y2,[12],[12]);
		%c2vo2=SCREEN(win1,'OpenOffscreenWindow',bcolor,[0 0 100 100]); 
		%SCREEN(c2vo2,'DrawLine',c2,o2x1,o2y1,o2x2,o2y2,[12],[12]);
		
		% make the cue screen, Space the probes as evenly as possible
		SCREEN('COPYWINDOW', preScreen, cueScreen);	% puts up the place holders
		cueAt=[];
		if ss==1
			cueAt=loc(1);
		elseif ss==2
			cueAt=[0 4]+loc(1);
		elseif ss==3
			cueAt=[0 3 6]+loc(1);
		elseif ss==4
			cueAt=[0 2 4 6]+loc(1);
		elseif ss==6
			cueAt=[0 1 2 4 5 6]+loc(1);
		elseif ss > 4
			cueAt=(0:ss-1)+loc(1);
		end
		ca=find(cueAt >8);
		cueAt(ca)=cueAt(ca)-8;
		if palmerFlag==0 | palmerFlag==1 | palmerFlag==3	% generate cues to tell you where the target might be
			for m=cueAt
				% 				SCREEN(cueScreen,'FillRect',[170 170 170],cell{m}+[45 45 -45 -45]); % small cue
				SCREEN(cueScreen,'FillRect',[0 0 0],cell{m});	% big cue
			end
		end
		SCREEN(stim,'FillRect',250,[centx-10 centy-10 centx+10 centy+10]);
		%if(YN(tord(ctr)) == 1)
		if YN==1
			if taskflag==1	% then this is COLOR FEATURE exp
				SCREEN(stim,'fillrect',c1, cell{loc(1)});%put color c1 into the window
			elseif taskflag==2  % then this is ORIENT FEATURE exp
				SCREEN('COPYWINDOW',c1o1,stim,[0 0 100 100], cell{loc(1)});%put orient o1 into the window
			elseif  taskflag==3  % then this is CONJ c1o1 exp
				SCREEN('COPYWINDOW',c1o1, stim,[0 0 100 100], cell{loc(1)});	%USE the FIXED c1 Vor1
			elseif  taskflag==4 % then this is a TvLconj exp
				SCREEN('COPYWINDOW',Tc1(randi(4)), stim,[0 0 100 100], cell{loc(1)});%put the Tc1 into the window
			elseif  taskflag==5  % tvl 
				SCREEN('COPYWINDOW',Tc1(randi(4)), stim,[0 0 100 100], cell{loc(1)});%put the Tc1 into the window
			elseif  taskflag==6  % tvl 
				SCREEN('COPYWINDOW',Tc1(randi(4)), stim,[0 0 100 100], cell{loc(1)});%put the Tc1 into the window
			elseif taskflag==7 % 2v5
				Screen('CopyWindow', two, stim,[0 0 100 100], cell{loc(1)});%put the 2 into the window
			end
			Tloc=loc(1);
		else
			if taskflag==1	% then this is COLOR FEATURE exp
				SCREEN(stim,'fillrect',c2, cell{loc(1)});%put color c2 into the window
			elseif taskflag==2  % then this is ORIENT FEATURE exp
				SCREEN('COPYWINDOW',c1o2,stim,[0 0 100 100], cell{loc(1)});%put orient o2 into the window
			elseif  taskflag==3  % then this is CONJ c1o1 exp
				SCREEN('COPYWINDOW',c1o2, stim,[0 0 100 100], cell{loc(1)});%USE c1o2
			elseif  taskflag==4 % then this is a TvLconj exp
				SCREEN('COPYWINDOW',Lc1(randi(4)), stim,[0 0 100 100], cell{loc(1)});%put the Lc1 into the window
			elseif  taskflag==5  % tvl 
				SCREEN('COPYWINDOW',Lc1(randi(4)), stim,[0 0 100 100], cell{loc(1)});%put the Lc1 into the window
			elseif  taskflag==6  % tvl 
				SCREEN('COPYWINDOW',eL(randi(4)), stim,[0 0 100 100], cell{loc(1)});%put the Lc1 into the window
			elseif taskflag==7 % 2v5
				Screen('CopyWindow', five, stim,[0 0 100 100], cell{loc(1)});%put the 5 into the window
			end
			Tloc=999;	% mark an absent trial
		end
		for i=2:length(cueAt)	% this puts up the actual set size of stimuli
			if taskflag==1 % color
				SCREEN(stim,'fillrect',c2, cell{cueAt(i)});%put color c1 into the window
			elseif taskflag==2 
				SCREEN('COPYWINDOW',c1o2,stim,[0 0 100 100], cell{cueAt(i)});%put orient o2 into the window
			elseif taskflag==3 
				if(mod(i+randConj,2) == 0)
					SCREEN('COPYWINDOW',c1o2, stim,[0 0 100 100], cell{cueAt(i)}); %USE the VARIABLE c1 Vor1
				else
					SCREEN('COPYWINDOW',c2o1, stim,[0 0 100 100], cell{cueAt(i)});  %USE the VARIABLE c2 Vor1
				end
			elseif taskflag==4
				if(mod(i+randConj,2) == 0)
					SCREEN('COPYWINDOW',Lc2(randi(4)), stim,[0 0 100 100], cell{cueAt(i)});%put the Tc2into the window
				else
					SCREEN('COPYWINDOW',Lc1(randi(4)), stim,[0 0 100 100], cell{cueAt(i)});%put the Lc1 into the window
				end
			elseif taskflag==5 % TvL
				SCREEN('COPYWINDOW',Lc1(randi(4)), stim,[0 0 100 100], cell{cueAt(i)});%put the Lc1 into the window
			elseif taskflag==6 % easyTvL
				SCREEN('COPYWINDOW',eL(randi(4)), stim,[0 0 100 100], cell{cueAt(i)});%put the Lc1 into the window
			elseif taskflag==7 % 2v5
				Screen('CopyWindow', five, stim,[0 0 100 100], cell{cueAt(i)});%put the 5 into the window
			end
		end
		cueNot=[];
		if palmerFlag==1 | palmerFlag==3 % then you need all the other locations filled too
			for i=1:8
				if sum(i==cueAt) == 0 % then this is a filler location
					cueNot=[cueNot i];
				end
			end
			for i=1:length(cueNot)	% this puts up the actual set size of stimuli
				if taskflag==1 % color
					SCREEN(stim,'fillrect',c2, cell{cueNot(i)});%put color c1 into the window
				elseif taskflag==2 
					SCREEN('COPYWINDOW',c1o2,stim,[0 0 100 100], cell{cueNot(i)});%put orient o2 into the window
				elseif taskflag==3 
					if(mod(i+randConj,2) == 1)
						SCREEN('COPYWINDOW',c1o2, stim,[0 0 100 100], cell{cueNot(i)}); %USE the VARIABLE c1 Vor1
					else
						SCREEN('COPYWINDOW',c2o1, stim,[0 0 100 100], cell{cueNot(i)});  %USE the VARIABLE c2 Vor1
					end
				elseif taskflag==4
					if(mod(i+randConj,2) == 1)
						SCREEN('COPYWINDOW',Lc2(randi(4)), stim,[0 0 100 100], cell{cueNot(i)});%put the Tc2into the window
					else
						SCREEN('COPYWINDOW',Lc1(randi(4)), stim,[0 0 100 100], cell{cueNot(i)});%put the Lc1 into the window
					end
				elseif taskflag==5 % TvL
					SCREEN('COPYWINDOW',Lc1(randi(4)), stim,[0 0 100 100], cell{cueNot(i)});%put the Lc1 into the window
				elseif taskflag==6 % easy TvL
					SCREEN('COPYWINDOW',eL(randi(4)), stim,[0 0 100 100], cell{cueNot(i)});%put the Lc1 into the window
                                elseif taskflag==7 % 2v5
                                   Screen('CopyWindow',five, stim,[0 0 100 100], cell{cueNot(i)});%put the 5 into the window
				end
			end
		end
		% put noise on stim
		
		if startcounting==1
			noiseParam=usethisnoise;
		end
				
		for ii=1:8
			imageArray=double(screen(stim,'GetImage',[cell{ii}])); % copy from stim
			sz=size(imageArray);
			noiseArray=randi(255,[sz(1), sz(2)]); % full contrast noise
			noiseArray=repmat(noiseArray,[1,1,3]);	% makes it 3D again
			newArray=(imageArray.*(1-noiseParam))+(noiseArray.*noiseParam);	% noiseParam = fraction of noise
			newArray=min(255,max(0,round(newArray)));
			SCREEN(stim,'PutImage',newArray,cell{ii});	% copy to stim
		end
		% 		SCREEN('COPYWINDOW', stim, win1);		
		% 		FlushEvents('KeyDown');
		% 		GetChar;
		
		SCREEN(stim,'FillRect',250,[centx-10 centy-10-ymove centx+10 centy+10-ymove]); %% CHANGED BY EMP & DF 3/10/06
		SCREEN(stimOFF,'FillRect',250,[centx-10 centy-10-ymove centx+10 centy+10-ymove]); %% CHANGED BY EMP & DF 3/10/06
		SCREEN('COPYWINDOW', stim, stimON);
		
		
		t1=getsecs;
		%start trials
		if palmerFlag < 2 % this is an accuracy version
			SND('Play',Hibeep);
			SCREEN('COPYWINDOW', preScreen, win1);	% puts up the place holders
			%waitsecs(1);
			waitsecs(.25);
			button=0;
			Screen(win1,'WaitBlanking');
			% cue
			Screen('CopyWindow', cueScreen,win1);
			Screen(win1,'WaitBlanking',cuedurRefreshes);	% wait for 4 refreshes	%%% THIS IS cueScreen DURATION
			SCREEN('COPYWINDOW', preScreen, win1);	% puts up the place holders (If you want a blank cue->stim ISI)
			Screen(win1,'WaitBlanking',cuestimISIRefreshes);	% wait for 5 refreshes	%%% ISI BETWEEN cueScreen AND stimON
			% uncover stim
			t3=getsecs;
			Screen('CopyWindow', stimON,win1);
			Snd('Play',beep);
			Screen(win1,'WaitBlanking'); % wait for stimuli to appear
			t2=getsecs; % mark the time, since the stimuli are now visible
			Screen(win1,'WaitBlanking', nRefreshes - 1); % wait for remaining refreshes
			%SCREEN(win1,'FillRect',128);		% blank
			Screen('CopyWindow', preScreen,win1);  % CHANGED BY EMP 03/10/06
			Screen(win1,'WaitBlanking', mRefreshes); % wait for a ISIs worth of refreshes
			Screen('CopyWindow', stimOFF, win1); % draw masks
			Screen(win1,'WaitBlanking'); % stimuli are now covered
			actualdur = (GetSecs - t2) * 1000;
			%wait for response
			while 1
				[keyIsDown,secs,keyCode]=KbCheck;
				if keyIsDown
					RT=secs-t2;
					%find(keycode) gets you a vector of all the keys that have been pressed
					%the first key pressed is response(1)
					response=find(keyCode);
					response=response(1);
					break;
				end
			end
			SCREEN('COPYWINDOW', preScreen, win1);	% puts up the place holders 		replace: SCREEN(win1,'FillRect',128); % blank screen
		else	% this is an RT version
			RT=9999;
			SND('Play',Hibeep);
			SCREEN('COPYWINDOW', preScreen, win1);	% puts up the place holders
			%waitsecs(1);
			waitsecs(.5);
			button=0;
			Screen(win1,'WaitBlanking');
			% cue
			Screen('CopyWindow', cueScreen,win1);
			Screen(win1,'WaitBlanking',8);	% wait for 8 refreshes	
			% 			SCREEN('COPYWINDOW', preScreen, win1);	% puts up the place holders (If you want a blank cue->stim ISI)
			% 			Screen(win1,'WaitBlanking',5);	% wait for five refreshes	
			% uncover stim
			t3=getsecs;
			Screen('CopyWindow', stimON,win1);
			t2=getsecs; % mark the time, since the stimuli are now visible
			Snd('Play',beep);
			%wait for response
			while RT == 9999
				[keyIsDown,secs,keyCode]=KbCheck;
				if keyIsDown
					RT=secs-t2;
					actualdur = (secs - t2) * 1000;
					%find(keycode) gets you a vector of all the keys that have been pressed
					%the first key pressed is response(1)
					response=find(keyCode);
					response=response(1);
					break;
				end
			end
			SCREEN('COPYWINDOW', preScreen, win1);	% puts up the place holders 		replace: SCREEN(win1,'FillRect',128); % blank screen
		end
		%check response
		NoiseThisTrial=noiseParam;  %% EMP--Added this variable so datafile says what noise was on current trial rather than what it will be on next trial.
		
		if response==Key1 % then you hit the right hand key 
			response='RIGHT';
			if YN==1
				error(ctr)=0;
				message{ctr}='HIT';
				if stair_fix==1
					noiseParam=noiseParam+noiseUp;	% small step up  	
				end
			else
				error(ctr)=1;
				message{ctr}='FA';
				if stair_fix==1
					noiseParam=noiseParam-noiseDown;	% big step down	
				end
			end
		
		elseif response==Key2 % you hit the left hand key 
			response='LEFT';
			if YN==0
				error(ctr)=0;
				message{ctr}='TNEG';
				if stair_fix==1
					noiseParam=noiseParam+noiseUp;	% small step up	
				end
			else
				error(ctr)=1;
				message{ctr}='MISS';
				if stair_fix==1
					noiseParam=noiseParam-noiseDown;	% big step down		
				end
			end
		else
			message{ctr}='Wrong Key!!!';
			error(ctr)=1;
			SND('Play',errbeep);
			SND('Play',errbeep);
			SND('Play',errbeep);
			SND('Play',errbeep);
		end
	
	
		% check for reversal
		
		noiseParam=min(1,max(noiseParam,0));	% range=0,1  %% EMP--Copied line 775 to here to avoid negative numbers going into revList
		
		if ctr > 1
			if error(ctr) == error(ctr-1)
				if error(ctr) == 1
					revString='DOWN';
				else
					revString='UP';
				end
			else
				revString='REVERSE';
				revList=[revList oldParam];
			end
		else
			revString='START';
		end
	
		oldParam=noiseParam;
		
		% FEEDBACK
		%waitsecs(.5);
		waitsecs(.25);
		SCREEN('COPYWINDOW', preScreen, win1);	% puts up the place holders		SCREEN(win1,'FillRect',128);
		noiseParam=min(1,max(noiseParam,0));	% range=0,1
		% 		CenterText([num2str(ctr) '  ' message{ctr} '  RT = ' num2str(RT)],0,-40,[0 130 200]);
		if error(ctr) == 0;
			CenterText(['Trial ' num2str(ctr) ' - CORRECT'],0,-40,[0 250 200]);
		else
			CenterText(['Trial ' num2str(ctr) ' - ERROR'],0,-40,[250 200 0]);
		end
		fid1=fopen(fileName1, 'a');
		fprintf(fid1,'%s\t%s\t%d\t%s\t%s\t%s\t%s\t%d\t%d\t%f\t%d\t%d\t%d\t%d\t%f\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d\t%f\t%s\t%d\t%d\n', ...
		sinit, cond, palmerFlag, c1str, c2str, or1str, or2str, vor1, vor2, refreshDuration, stimdur, nRefreshes, cuestimISI, mRefreshes, actualdur,  prstr, ctr, ss,  YN, ...
		round(RT*1000), response, message{ctr}, error(ctr), Tloc, NoiseThisTrial,revString, length(revList),startcounting); %write the data  %% EMP--Replaced noiseParam in output with NoiseThisTrial
		moo=fclose(fid1);
		%waitsecs(.6);
		waitsecs(.5);
		SCREEN('COPYWINDOW', preScreen, win1);	% puts up the place holders		SCREEN(win1,'FillRect',255);
		% 		FlushEvents('KeyDown');
		% 		GetChar;		
		
		%take a break
		if mod(ctr,100)==0
			
			SCREEN('CopyWindow',Blank,win1);
			WaitSecs(.5);
			
			CenterText('Take a break for a moment...',0,-40,[255 255 255]);
			CenterText('Press any key when you are ready to continue',0,40,[255 255 255]);
			
			FlushEvents('keyDown');
			while(1)
				[keyIsDown,secs,keyCode]=KbCheck;
				if keyIsDown
					break;
				end
			end
			FlushEvents('keyDown');
			
			
			SCREEN('CopyWindow',Blank,win1);
			WaitSecs(.5);
		end
	
	
		%%% EXIT CONDITIONS
		if (a==1) & (ctr==ptrials)
			exit=1;
		end
	
		if (a==2)
			if stair_fix==1
				if length(revList)>=numReversals
					startcounting=1;
					trialctr=trialctr+1;
					usethisnoise=mean(revList((numReversals/2)+1:numReversals));
				end
			elseif stair_fix==2
				trialctr=trialctr+1;
			end
		end
	
		if (a==2)&(trialctr>length(tord))
			exit=1;
		end
		
			
	end %while loop


end % pract/exp loop

%StaircaseResult=mean(revList(max(1,length(revList)-39:length(revList))))	% mean of the last 40 reversals
%StaircaseResult=mean(revList)

fprintf('\n\n**************************\nYour Noise Value is: %1.3f\n**************************\n\n',usethisnoise);

CenterText(['Experiment Complete. Thank-you'],0,-40,[0 0 0]);
FlushEvents('KeyDown');
GetChar;
ShowCursor;

clear all;
close all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [newX, newY] = CenterText (message, xoffset, yoffset, color)
% print a text string centered on the screen
% if you want the text offset from center, use xoffset and yoffset

global screenX
global screenY
global win1

[oldPixelSize,oldIc1,pages]=SCREEN(win1,'PixelSize'); %determine the pixel size for this screen

if nargin == 1
	xoffset=0;
	yoffset=0;
	if oldPixelSize==8
		color=[];
	else
		color=[];
	end
elseif nargin == 2
	yoffset=0;
	if oldPixelSize==8
		color=[];
	else
		color=[];
	end
elseif nargin == 3
	if oldPixelSize==8
		color=[];
	else
		color=[];
	end
end

if isempty(xoffset)
	xoffset=0;
end
if isempty(yoffset)
	yoffset=0;
end

width = SCREEN(win1,'TextWidth',message);
[newX, newY] = SCREEN(win1, 'DrawText', message, ((screenX/2)-(width/2))+xoffset,(screenY/2)+yoffset,color);
