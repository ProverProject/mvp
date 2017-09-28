function Pts=detectSURFFeatures(I, varargin)
%detectSURFFeatures Finds SURF features.
%   points = detectSURFFeatures(I) returns a SURFPoints object, points, 
%   containing information about SURF features detected in a 2-D grayscale 
%   image I. detectSURFFeatures uses Speeded-Up Robust Features 
%   (SURF) algorithm to find blob features.
%
%   points = detectSURFFeatures(I,Name,Value) specifies additional
%   name-value pair arguments described below:
%
%   'MetricThreshold'  A non-negative scalar which specifies a threshold
%                      for selecting the strongest features. Decrease it to
%                      return more blobs.
%
%                      Default: 1000.0
%
%   'NumOctaves'       Integer scalar, NumOctaves >= 1. Number of octaves 
%                      to use. Increase this value to detect larger
%                      blobs. Recommended values are between 1 and 4.
%
%                      Default: 3
%
%   'NumScaleLevels'   Integer scalar, NumScaleLevels >= 3. Number of
%                      scale levels to compute per octave. Increase
%                      this number to detect more blobs at finer scale 
%                      increments. Recommended values are between 3 and 6.
%
%                      Default: 4
%
%   'ROI'              A vector of the format [X Y WIDTH HEIGHT],
%                      specifying a rectangular region in which corners
%                      will be detected. [X Y] is the upper left corner of
%                      the region.                      
%
%                      Default: [1 1 size(I,2) size(I,1)]
%
%   Notes
%   -----
%   - Each octave spans a number of scales that are analyzed using varying
%     size filters:
%         octave     filter sizes
%         ------     ------------------------------
%           1        9x9,   15x15, 21x21, 27x27, ...
%           2        15x15, 27x27, 39x39, 51x51, ...
%           3        27x27, 51x51, 75x75, 99x99, ...
%           4        ....
%     Higher octaves use larger filters and sub-sample the image data.
%     Larger number of octaves will result in finding larger size blobs. 
%     'NumOctaves' should be selected appropriately for the image size.
%     For example, 50x50 image should not require NumOctaves > 2. The
%     number of filters used per octave is controlled by the parameter
%     'NumScaleLevels'. To analyze the data in a single octave, at least 3
%     levels are required.
%
%   Class Support
%   -------------
%   The input image I can be logical, uint8, int16, uint16, single, 
%   or double, and it must be real and nonsparse.
%
%   Example
%   -------  
%   % Detect interest points and mark their locations
%   I = imread('cameraman.tif');
%   points = detectSURFFeatures(I);
%   imshow(I); hold on;
%   plot(points.selectStrongest(10));
%
%   See also SURFPoints, extractFeatures, matchFeatures,
%            detectBRISKFeatures, detectFASTFeatures, detectHarrisFeatures,
%            detectMinEigenFeatures, detectMSERFeatures

%   Copyright 2010 The MathWorks, Inc.

%   References:
%      Herbert Bay, Andreas Ess, Tinne Tuytelaars, Luc Van Gool "SURF: 
%      Speeded Up Robust Features", Computer Vision and Image Understanding
%      (CVIU), Vol. 110, No. 3, pp. 346--359, 2008

%#codegen

checkImage(I);

Iu8 = im2uint8(I);

if isSimMode()
    [Iu8, params] = parseInputs(Iu8,varargin{:});
    PtsStruct=ocvFastHessianDetector(Iu8, params);
    
else
    [I_u8, params] = parseInputs_cg(Iu8,varargin{:});
    
    % get original image size
    nRows = size(I_u8, 1);
    nCols = size(I_u8, 2);
    numInDims = 2;
    
    % column-major (matlab) to row-major (opencv)
    Iu8 = I_u8';
    
    % output variable size and it's size cannot be determined here; 
    % Inside OpenCV algorithm, vector is used to hold output; 
    % Vector is grown by pushing element into it; Once OpenCV computation is
    % done, output size is known, and we use that size to create output
    % memory using malloc; Then elements are copied from OpenCV Vector to EML
    % output buffer
    
    [PtsStruct_Location, PtsStruct_Scale, PtsStruct_Metric, PtsStruct_SignOfLaplacian] = ...
        vision.internal.buildable.fastHessianDetectorBuildable.fastHessianDetector_uint8(Iu8, ...
        int32(nRows), int32(nCols), int32(numInDims), ...
        int32(params.nOctaveLayers), int32(params.nOctaves), int32(params.hessianThreshold));  
    
    PtsStruct.Location        = PtsStruct_Location;
    PtsStruct.Scale           = PtsStruct_Scale;
    PtsStruct.Metric          = PtsStruct_Metric;
    PtsStruct.SignOfLaplacian = PtsStruct_SignOfLaplacian;       
end

PtsStruct.Location = vision.internal.detector.addOffsetForROI(PtsStruct.Location, params.ROI, params.usingROI);

Pts = SURFPoints(PtsStruct.Location, PtsStruct);

%========================================================================== 
function checkImage(I)
vision.internal.inputValidation.validateImage(I, 'I', 'grayscale');
               
%========================================================================== 
function flag = isSimMode()

flag = isempty(coder.target);

%==========================================================================
% Parse and check inputs - simulation
%==========================================================================
function [img, params] = parseInputs(Iu8, varargin)

sz = size(Iu8);
defaults = getDefaultParametersVal(sz);

% Parse the PV pairs
parser = inputParser;
parser.addParameter('MetricThreshold', defaults.MetricThreshold, @checkMetricThreshold);
parser.addParameter('NumOctaves',      defaults.NumOctaves,      @checkNumOctaves);
parser.addParameter('NumScaleLevels',  defaults.NumScaleLevels,  @checkNumScaleLevels);
parser.addParameter('ROI',             defaults.ROI, @(x)vision.internal.detector.checkROI(x,sz));

% Parse input
parser.parse(varargin{:});

% Populate the parameters to pass into OpenCV's icvfastHessianDetector()
params.nOctaveLayers    = parser.Results.NumScaleLevels-2;
params.nOctaves         = parser.Results.NumOctaves;
params.hessianThreshold = parser.Results.MetricThreshold;
params.ROI              = parser.Results.ROI;

params.usingROI = isempty(regexp([parser.UsingDefaults{:} ''],...
    'ROI','once')); %#ok<EMCA>

img = vision.internal.detector.cropImageIfRequested(Iu8, params.ROI, params.usingROI);


%==========================================================================
% Parse and check inputs - code-generation
%==========================================================================
function [img, params] = parseInputs_cg(Iu8, varargin)

% varargin must be non-empty
defaultsVal   = getDefaultParametersVal(size(Iu8));
defaultsNoVal = getDefaultParametersNoVal();
properties    = getEmlParserProperties();
optarg = eml_parse_parameter_inputs(defaultsNoVal, properties, varargin{:});
MetricThreshold = (eml_get_parameter_value( ...
        optarg.MetricThreshold, defaultsVal.MetricThreshold, varargin{:}));
NumOctaves = (eml_get_parameter_value( ...
        optarg.NumOctaves, defaultsVal.NumOctaves, varargin{:}));
NumScaleLevels = (eml_get_parameter_value( ...
        optarg.NumScaleLevels, defaultsVal.NumScaleLevels, varargin{:}));        
ROI  = eml_get_parameter_value(optarg.ROI, ...
    defaultsVal.ROI, varargin{:});
        
checkMetricThreshold(MetricThreshold);
checkNumOctaves(NumOctaves);
checkNumScaleLevels(NumScaleLevels);

% check whether ROI parameter is specified
usingROI = optarg.ROI ~=uint32(0);

if usingROI
    vision.internal.detector.checkROI(ROI, size(Iu8));    
end

params.nOctaveLayers    = uint32(NumScaleLevels)-uint32(2);
params.nOctaves         = uint32(NumOctaves);
params.hessianThreshold = uint32(MetricThreshold);
params.usingROI         = usingROI;
params.ROI              = ROI;

img = vision.internal.detector.cropImageIfRequested(Iu8, params.ROI, usingROI);         

%==========================================================================
function defaultsVal = getDefaultParametersVal(imgSize)

defaultsVal = struct(...
    'MetricThreshold', uint32(1000), ...
    'NumOctaves', uint32(3), ...
    'NumScaleLevels', uint32(4),...
    'ROI',int32([1 1 imgSize([2 1])]));

%==========================================================================
function defaultsNoVal = getDefaultParametersNoVal()

defaultsNoVal = struct(...
    'MetricThreshold', uint32(0), ... 
    'NumOctaves',      uint32(0), ... 
    'NumScaleLevels',  uint32(0), ...
    'ROI',             uint32(0));

%==========================================================================
function properties = getEmlParserProperties()

properties = struct( ...
    'CaseSensitivity', false, ...
    'StructExpand',    true, ...
    'PartialMatching', false);

%==========================================================================
function tf = checkMetricThreshold(threshold)
validateattributes(threshold, {'numeric'}, {'scalar','finite',...
    'nonsparse', 'real', 'nonnegative'}, 'detectSURFFeatures'); %#ok<EMCA>
tf = true;

%==========================================================================
function tf = checkNumOctaves(numOctaves)
validateattributes(numOctaves, {'numeric'}, {'integer',... 
    'nonsparse', 'real', 'scalar', 'positive'}, 'detectSURFFeatures'); %#ok<EMCA>
tf = true;

%==========================================================================
function tf = checkNumScaleLevels(scales)
validateattributes(scales, {'numeric'}, {'integer',...
    'nonsparse', 'real', 'scalar', '>=', 3}, 'detectSURFFeatures'); %#ok<EMCA>
tf = true;

