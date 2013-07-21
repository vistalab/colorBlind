function scene = ctCreateBinaryFontScene(vd, viewDist, letter, fontSize, fontFamily, dpi)
% Create ISET scene structure for certain letter
%
%   scene = ctCreateFontScene(vd, viewDist, letter, fontSize, fontFamily,...
%                       useClearType, dpi)
%
% General Process:
%   1. Customize virtual display to user-defined dpi and viewing distance
%   2. Load cached clearType font data, convert to non-clearType if needed
%   3. Compute virtual display output image, to colorblind if needed
%   4. Convert output Image to Scene
%
% Input Parameters:
%   vd           - virtual display structure, more details can be found in ISET
%   viweDist     - viewing distance
%   letter       - single letter to be displayed, i.e. 'a'
%   fontSize     - font size, integer, i.e., 14
%   fontFamily   - font family, i.e., 'arial'
%   dpi          - The dpi of vDisplay to be used, can be different from vd
%
% Output Parameter:
%   scene        - scene structure for the letter on display
%       scene{1} - clearType scene
%       scene{2} - tripled dpi binary scene
%

%% Customize vDisplay structure
%  Set over-sampling parameter 
vd = vDisplaySet(vd,'osample',19);

% Set viewing distance and pixel size
vd        = vDisplaySet(vd,'viewingdistance',viewDist);
pixelSize = vDisplayGet(vd,'pixelsize');
scalar    = vDisplayGet(vd,'dpi') / dpi;
vd        = vDisplaySet(vd,'pixelsize',pixelSize*scalar);

% Convert psf to mm to be consistant with ctToolbox
psf = vDisplayGet(vd, 'psf');
for i = 1:length(psf)
    psf{i}.sCustomData.samp = ((psf{i}.sCustomData.samp / (10^3)) * ieUnitScaleFactor('m'));
end
vd = vDisplaySet(vd, 'psf', psf);

%% Create font image
%  Init renGD structure, details about renGD could be found in ctToolbox
renGD.rgbLayout = 'RGB';

%  Init stimulus
stimList{1} = stimCreate;
stimList{1} = stimSet(stimList{1}, 'character', letter);
renGD = renderSet(renGD,'stimList',stimList);
renGD = renderSet(renGD,'nSelected',1);

%  Set parameters to renGD
renGD  = renderSet(renGD,'vdisplay',vd);
renGD  = renderSet(renGD, 'useGamma', 1);
renGD  = renderSet(renGD, 'defaultDPI', dpi);
%renGD  = renderSet(renGD, 'filterCoefficients', [0 0 0 0 0; 0 0 0 0 0; 0 0 1 0 0; 0 0 0 0 0; 0 0 0 0 0]);
renGD  = renderSet(renGD, 'filterCoefficients', [0 0 0; 0 0 0;  0.2 0.6 0.2; 0 0 0;0 0 0]);

%  Set stimulus to renGD
renGD = renderSet(renGD,'stimList',stimList);
renGD = renderSet(renGD,'nSelected',1);

%  Load font data
%  Try to load clear-type bit-map first
overScale.x     = vDisplayGet(vd, 'SubpixelOverscaleX');
overScale.y     = vDisplayGet(vd, 'SubpixelOverscaleY');
bmSrc           = ctCaptureClearType(letter, dpi, fontSize, fontFamily, [], overScale);
kernel          = renderGet(renGD, 'filtercoef');
[rawData]       = ctFontFilter(bmSrc,kernel);

% Store raw font bitmap in vDisplay
vd    = vDisplaySet(vd, 'inputImage', rawData);

% Compute output image from vDiplay for normal people
renImage = vdisplayCompute(vd,'inputImage',1);
vd = vDisplaySet(vd, 'ImageRawData', renImage);

% Compute colorblind image (No effects on current stage)
cbType = renderGet(renGD, 'Colorblind Type');
renImage = ctdpRendered2RGB(vd,renImage,cbType);


%% Convert font image to scene
vd       = vDisplaySet(vd,'outputImage', renImage);
renGD    = renderSet(renGD,'vDisplay',vd);
scene{1} = ctrdRenderImage2SceneWithDist(renGD,0,viewDist);

%% Gene tripled dpi scene
% Store raw font bitmap in vDisplay
pixelSize = vDisplayGet(vd,'pixelsize');
scalar    = vDisplayGet(vd,'dpi') / dpi/3;
vd        = vDisplaySet(vd,'pixelsize',pixelSize*scalar);
renGD  = renderSet(renGD, 'defaultDPI', 3*dpi);

[r,c,~] = size(rawData);
t = rawData;
rawData = zeros(r,c*3);
rawData(:,1:3:end) = t(:,:,1);
rawData(:,2:3:end) = t(:,:,2);
rawData(:,3:3:end) = t(:,:,3);
t = rawData;
rawData = zeros(3*r,3*c);
rawData(1:3:end,:) = t;
rawData(2:3:end,:) = t;
rawData(3:3:end,:) = t;
rawData = repmat(rawData,[1 1 3]);
vd    = vDisplaySet(vd, 'inputImage', rawData);

% Compute output image from vDiplay for normal people
renImage = vdisplayCompute(vd,'inputImage',1);
vd = vDisplaySet(vd, 'ImageRawData', renImage);

% Compute colorblind image (No effects on current stage)
cbType = renderGet(renGD, 'Colorblind Type');
renImage = ctdpRendered2RGB(vd,renImage,cbType);


% Convert font image to scene
vd       = vDisplaySet(vd,'outputImage', renImage);
renGD    = renderSet(renGD,'vDisplay',vd);
scene{2} = ctrdRenderImage2SceneWithDist(renGD,0,viewDist);
end