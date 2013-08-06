%% s_caColorDiscrimination
%
%    script use to test color discrimination for certain color
%
%  ToDo:
%    1. Get rid of annoying outputs - should be done in isetbio
%       - sceneFromFile line 112
%       - vcReadImage line 132 dac2rgb, should accept some gamma input
%    2. Fix progress report for 90 degree and 270 degree
%
%  (HJ) VISTASOFT Team 2013

%% Init & clean up
%clear; clc;
bgColor     = [0.5 0.5 0.5]';
refColor    = [35 152 101]'/255;
dispFile    = 'OLED-SonyBVM.mat';

%ang = 0:30:359; % direction in degrees
ang = 0:30:359;%[0 30 60 120 150 180 210 240 300 330];
ang = ang / 180 * pi; % direction in radiance

tgtAcc = 0.75; % Target accuracy - 75%
tol = 0.05; % tolerance

%% Load display & Compute contrast
c = load(dispFile);
display = c.d;

refContrast   = RGB2ConeContrast(display,color2struct(refColor-bgColor));
dist75        = zeros(1,length(ang));
matchColorLMS = zeros(length(ang),3);

%% Predict 75% Accuracy
%  Print out title of report
fprintf('\tAngle\tcontrast diff\n');

%  Start working on each angle
for curAngle = 1 : length(ang)
    dir = [cos(ang(curAngle)) sin(ang(curAngle)) 0]';
    
    % binary search for moving length
    contrastDiff = 1/50; % starting moving length
    minPos = 0; maxPos = contrastDiff*5; % Use a large upper bound
    while maxPos - minPos > 1e-4
        % Generate match color
        matchContrast.dir = refContrast + contrastDiff * dir;
        matchContrast.scale = matchContrast.dir(1);
        matchContrast.dir = matchContrast.dir / matchContrast.scale;
        
        matchColorLMS(curAngle,:) = refContrast + contrastDiff * dir;
        tt = cone2RGB(display,matchContrast);
        matchColor = 0.5+tt.scale*tt.dir;
        % Compute Accuracy
        acc = caColorDiscrimination(dispFile,refColor,matchColor);%,'cbType',2);
        if acc(1) > tgtAcc + acc(2) % Acc too high, move closer
            maxPos = contrastDiff;
            contrastDiff = (minPos + maxPos) / 2;
        elseif acc(1) < tgtAcc - acc(2) % Acc too low, get further away
            minPos = contrastDiff;
            contrastDiff = (minPos + maxPos) / 2;
        elseif acc(2) < tol
            break;
        else
            warning('Variance too large');
        end
    end
    dist75(curAngle) = contrastDiff;
    % Report progress
    fprintf('\t%d\t%f\n',round(180/pi*ang(curAngle)),...
        (matchColorLMS(curAngle,1)-refContrast(1))/cos(ang(curAngle)));
end

%% Fit and Plot
%  Init figure
figure('Name','Color Discrimination by SVM',...
       'NumberTitle','off'); 
axis; hold on; grid on;
xlabel('L'); ylabel('M'); zlabel('S');
hold on;
% Plot Reference Point
plot3(refContrast(1),refContrast(2),refContrast(3),'+r');

% Plot Match Color 75% Data Points
for i = 1 : length(ang)
    plot3(matchColorLMS(i,1),matchColorLMS(i,2),matchColorLMS(i,3),'.r');
end