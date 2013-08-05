%% s_caColorDiscrimination
%
%    script use to test color discrimination for certain color
%
%  ToDo:
%    1. Constrain on max iteration - done
%    2. Compute a reasonable tolerance - done
%    3. Get rid of annoying outputs
%    4. Report Progress
%    5. Create an OLED struct - done
%    6. Compute reasonable eye isolation
%
%  (HJ) VISTASOFT Team 2013

%% Init & clean up
clear; clc;
bgColor     = [0.5 0.5 0.5]';
refColor    = [35 152 101]'/255;
dispFile    = 'OLED-SonyBVM.mat';

ang = 0:30:359; % direction in degrees
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
for curAngle = 1 : length(ang)
    dir = [cos(ang(curAngle)) sin(ang(curAngle)) 0]';
    % binary search for moving length
    contrastDiff = 1/50; % starting moving length
    minPos = 0; maxPos = contrastDiff*2;
    while maxPos - minPos > 1e-4
        % Generate match color
        matchContrast.dir = refContrast + contrastDiff * dir;
        matchContrast.scale = matchContrast.dir(1);
        matchContrast.dir = matchContrast.dir / matchContrast.scale;
        
        matchColorLMS(curAngle,:) = refContrast + contrastDiff * dir;
        tt = cone2RGB(display,matchContrast);
        matchColor = 0.5+tt.scale*tt.dir;
        % Compute Accuracy
        acc = caColorDiscrimination(dispFile,refColor,matchColor);
        acc = acc(1);
        if acc > tgtAcc + tol % Acc too high, move closer
            maxPos = contrastDiff;
            contrastDiff = (minPos + maxPos) / 2;
        elseif acc < tgtAcc - tol % Acc too low, get further away
            min = contrastDiff;
            contrastDiff = (minPos + maxPos) / 2;
        else
            break;
        end
    end
    dist75(curAngle) = contrastDiff;
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