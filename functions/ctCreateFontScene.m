function scene = ctCreateFontScene(vd, viewDist, stim, useClearType)
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
%   vd           - CT toolbox virtual display structure
%   viewDist     - viewing distance in meters
%   stim         - a character stimulus
%   useClearType - bool, indicator for using clearType fonts
%
% Output Parameter:
%   scene        - scene structure for the letter on display
%
% (c) PDCSOFT Team (HJ) 2013

%% Check inputs
if nargin < 8, filter = [0 0 0; 0 0 0;  0.2 0.6 0.2; 0 0 0;0 0 0]; end
%% Customize vDisplay structure
% User should be able to specify this.  It should not be forced by the
% subroutine.
%
% Set over-sampling parameter 
% vd = vDisplaySet(vd,'osample',19);

if ieNotDefined('vd'), error('Virtual display required.'); end
if ieNotDefined('viewDist'), viewDist = 0.5; end      % Half a meter
if ieNotDefined('stim'), error('Letter stimulus required.'); end

% Set letter parameters
letter     = stimGet(stim,'letter');
fontSize   = stimGet(stim,'font size');
fontFamily = stimGet(stim,'font family');
dpi        = stimGet(stim,'font dpi');

% Set viewing distance and pixel size
vd        = vDisplaySet(vd,'viewing distance',viewDist);
pixelSize = vDisplayGet(vd,'pixel size');
scalar    = vDisplayGet(vd,'dpi') / dpi;
vd        = vDisplaySet(vd,'pixel size',pixelSize*scalar);

%% Create font image

% This rendering move should be shorter, probably a function like
% ctRenderImage that takes stim and vd as input.
%
%    [renGD, renImage] = ctRenderStim(renGD, vd,stim);
%
% And we should probably start with
%
%    renGD = guidata(ctRenderW);
%
% Init renGD - details about renGD could be found in ctToolbox (HJ)
% This should be constructed to allow RGBW and other configurations (BW)
renGD.rgbLayout = 'RGB';

%  Init stimulus
stimList{1} = stim;
renGD = renderSet(renGD,'stimList',stimList);
renGD = renderSet(renGD,'nSelected',1);

%  Set parameters to renGD
renGD  = renderSet(renGD,'vdisplay',vd);
renGD  = renderSet(renGD, 'useGamma', 1);
renGD  = renderSet(renGD, 'defaultDPI', dpi);
renGD  = renderSet(renGD, 'filterCoefficients', filter);

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

% Check clear type settings
% If non-clearType, erase the effect of sub-pixel rendering
if ~useClearType
    rawData = rgb2gray(rawData);
    rawData = repmat(double(rawData > 0.5),[1 1 3]);
end

% Store raw font bitmap in vDisplay
vd    = vDisplaySet(vd, 'inputImage', rawData);

% Compute output image from vDiplay for normal people
renImage = vdisplayCompute(vd,'Input image',1);
vd = vDisplaySet(vd, 'Image raw data', renImage);

% Compute colorblind image (No effects on current stage)
cbType   = renderGet(renGD, 'Colorblind type');
renImage = ctdpRendered2RGB(vd,renImage,cbType);


%% Convert font image to scene
vd       = vDisplaySet(vd,'output image', renImage);
renGD    = renderSet(renGD,'vDisplay',vd);
scene    = ctrdRenderImage2SceneWithDist(renGD,0,viewDist); 

end