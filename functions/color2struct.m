function stim = color2struct(plainColor)
%% function color2struct
%
%    Convert 3-by-1 color vector to color structure (.dir & .scale)
%
%  Inputs:
%    plainColor - 3-by-1 color vector, can be in RGB, LMS, XYZ or other
%                 color space, can be real color or contrast
%
%  Outputs:
%    stim       - color structure, containing .dir and .scale field
%
%  Example:
%    stim = color2struct(refContrast);
%
%  (HJ) VISTASOFT Team 2013

%% Check inputs
if nargin < 1, error('Color input required'); end
if length(plainColor) ~= 3, error('Color format not recognized'); end

%% Generate output structure
if all(plainColor == 0)
    stim.dir = [1 1 1];
    stim.scale = 0;
    return;
end

stim.dir   = plainColor/max(abs(plainColor));
stim.scale = max(abs(plainColor));

end

