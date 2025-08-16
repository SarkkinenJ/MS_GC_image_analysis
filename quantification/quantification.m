basePath = 'D:\TMA_analysis\TMA_hc_stacksandmasks\ ';
maskPath = '\'; %Input folder name
maskFileName = '_mask.tif';
omePath = '\';
omeSuffix = '.tif';
outputsubfolder = 'quantification';
cropCoordsPath = 'dearray\cropCoords\';
cropCoordsFileName = '*_cropCoords.mat';

channelNames = readtable( [basePath filesep 'channel_names.csv'], 'ReadVariableNames', false);
numChannelNames = size(channelNames, 1); % this is only to allocate memory before loops

% Quantification features
%  - The eccentricity is the ratio of the distance between the foci of 
%    the ellipse and its major axis length. (0 = circle, 1 = segment).
%  - Solidity: Proportion of the pixels in the convex hull that are also in the region
%    . Computed as Area/ConvexArea. Solidity is useful to quantify the 
%    amount and size of concavities in an object boundary. Holes are also 
%    often included. For example, it distinguishes a star from a circle,
%    but doesn?t distinguish a triangle from a circle.
%  - Roundness: C = 4 * pi Area / Perimeter^2 (to replace Solidity in the
%    next datasets.
featureNames = {'Area', 'Eccentricity', 'Perimeter', 'Solidity', 'MajorAxisLength', 'MinorAxisLength'};
XYnames = {'X_position','Y_position'};

% List of samples
sampleList = dir( [ basePath '*_GC*' ] );

%parfor sample = 1:length(selected)
for sample = 1:length(sampleList)
    samp = sample;
    sampleName = sampleList(samp).name;
    disp(sampleName)
    tic
    
    %Read large ome.tif
    sampleImage =  bfGetReader( [ basePath sampleName filesep omePath filesep sampleName omeSuffix ] );
    numChannels = sampleImage.getImageCount();
    
    if numChannelNames ~= numChannels
        disp('ERROR: number of channel names and actual channels do not match');
        continue
    end
    
    %Creating folder for output
    outputFolder = [basePath filesep sampleName filesep outputsubfolder ];
    mkdir( outputFolder );
        
    % Load mask
    mask = imread( [ basePath sampleName filesep maskPath filesep sampleName maskFileName ] );
    l = size(mask);
    boundingBox = [1,1, l(2), l(1)];      
    core = zeros(l(1), l(2), numChannels); 
    box = num2cell(uint16(boundingBox));
        
     for iChan=1:numChannelNames
          % Crop core from ome.tif
          core(:,:,iChan) = bfGetPlane(sampleImage, iChan, box{:});
     end
        
     % Quantify channels
     getMeanFunction = @(iChan) struct2array(regionprops(mask, core(:,:,iChan), 'MeanIntensity'))';
     meanIntensities = cell2mat(arrayfun(getMeanFunction,1:numChannelNames, 'UniformOutput',0));

    % Calculate morphological features
    shapeFeatures = regionprops(mask, featureNames);
    roundness = (4 * pi * [shapeFeatures.Area]') ./ [shapeFeatures.Perimeter]'.^2;
    % Calculate X and Y positions
    xystruct = regionprops(mask, 'Centroid');
    xytemp = cat(1, xystruct.Centroid);
        
    % Write all variables as CSV file
    lenIDs = unique(mask);
    CellId = array2table(double(lenIDs(lenIDs ~= 0)), 'VariableNames', {'CellId'});
    SampleId = array2table( repmat(string(sampleName), size(CellId,1), 1), 'VariableNames', {'SampleId'});
    meanData = array2table(meanIntensities,'VariableNames', table2cell(channelNames) );
    morphData = struct2table(shapeFeatures);
    roundData = array2table(roundness, 'VariableNames',{'Roundness'} );
    xyData = array2table( [xytemp(:,1) xytemp(:,2) ], 'VariableNames', XYnames);
        
    %Next is to detect jumps of pixels values in the mask 
    %A jump is when a instensity value is skiped from the mask (1,2,4,5), so that
    %cell (3) dont exists
    %When there is a jum, that row will contain only NaN+
    [rows, columns] = size(meanData);
    for row=1:rows
        if (all(isnan(meanIntensities(row,:))))
            meanData(row,:) = [];
            morphData(row,:) = [];
            roundData(row,:) = [];
            xyData(row,:) = [];
        end
    end

    output = [ SampleId, CellId, meanData, morphData, roundData, xyData ];

    %changed \t --> , 
    %also should add Sample column as a first column which would contain only sample number
    %or should we pool data from same wsi together?
    writetable( output, [ outputFolder filesep sampleName] , 'Delimiter', ',');
   toc
end
