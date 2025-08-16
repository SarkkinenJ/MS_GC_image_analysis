%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Default parameters

outputPath = 'D:\users\fperez\Mikas_segmentation';
mainPath='E:\CAJ101_rSeqP2\';

%sampleList = dir( [ basePath 'TMA*' ] );
%parfor sample = 1:length(sampleList)
sample='Sample_1';

mkdir([ outputPath filesep sample] );


cytoMethod = 'distanceTransform';
upSample = 2;
paths.metadata = ['metadata'];
paths.dearray = ['dearray' ];
paths.probabilitymaps= ['prob_maps'];
paths.segmentation = ['segmentation'];
paths.analysis = ['analysis'];
paths.registration = ['registration'];
FileExt = '*ome.tif';
searchPath = ['registration'];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Important parameters

nucleiRegionS={'watershedContourInt', 'watershedContourDist', 'watershedBWDist'};
nucleiFilterS ={'Int' 'IntPM'};
logSigmaMinS = [6 8 10];
logSigmaMaxS=[30 50 60];


%%Starting analysis

for j = 1:length(nucleiRegionS)
    nucleiRegion= char(nucleiRegionS(j));
    for i = 1:length(nucleiFilterS)
        nucleiFilter= char(nucleiFilterS(i));
        for l = 1:length(logSigmaMinS)
            logSigmaMin=logSigmaMinS(l);
            for m = 1:length(logSigmaMaxS)
                logSigmaMax=logSigmaMaxS(m);
                logSigma = [logSigmaMin logSigmaMax];
                
                %Other parameters
                mask = 'tissue';
                resizeFactor = 1;
                cytoMaskChan = [43 44 46];
                TissueMaskChan = 2;
                
                disp(['Now using:' 'nucleiRing_nucleiRegion-' nucleiRegionS '_nucleiFilterS-' nucleiFilterS '_logSigmaMin-' num2str(logSigmaMin) '_logSigmaMax-' num2str(logSigmaMax)]);


                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Getting filepaths and metadata
                ome=dir([mainPath filesep sample filesep searchPath filesep FileExt]);
                metadata =bfGetReader([mainPath filesep sample filesep searchPath filesep FileExt]);            
                numChan =metadata.getImageCount;

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% case 'unet'

                classProbPath = [mainPath filesep sample filesep paths.probabilitymaps];
                listing = dir([classProbPath filesep '*_ContoursPM*']);
                PMfileName = listing.name;
                pmI = strfind(PMfileName,'_ContoursPM_');
                probMapSuffix= cellstr(PMfileName(pmI:end));
                nucMaskChan = sscanf(char(probMapSuffix), '_ContoursPM_%d.tif');
                if nucMaskChan >numChan
                     nucMaskChan = nucMaskChan - numChan;
                end
                nucleiPMListing = dir([classProbPath filesep '*_NucleiPM*']);


                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% case 'noCrop' ; read nuclei channel

                nucleiCrop = imread([ome.folder filesep ome.name], nucMaskChan);
                fullResSize = size(nucleiCrop);
                nucleiCrop = imresize(nucleiCrop,resizeFactor);
                rect = round([1 1 size(nucleiCrop,2) size(nucleiCrop,1)]);
                PMrect= rect;

                nucleiPM=[];
                for iPM = 1:numel(probMapSuffix)
                     nucleiProbMaps = imread([classProbPath filesep sample probMapSuffix{iPM}],1);
                     PMSize = size(nucleiProbMaps);
                     nucleiProbMaps = imresize(nucleiProbMaps,fullResSize);
                     nucleiPM(:,:,iPM) = imcrop(nucleiProbMaps,PMrect);
                end
                PMUpsampleFactor = fullResSize(1)/PMSize(1);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% mask the core/tissue; noCrop

                tissue =[];
                for iChan = TissueMaskChan
                      tissue= cat(3,tissue,normI(double(imresize(imread([ome.folder filesep ome.name],iChan),resizeFactor))));
                end

                tissueCrop = sum(tissue,3);
                tissue_gauss = imgaussfilt3(tissueCrop,1);
                TMAmask=imresize(tissue_gauss>thresholdMinimumError(tissue_gauss,'model','poisson'),size(tissueCrop));

                clear tissue_gauss, clear maxTissue, clear tissueCrop, clear tissue, clear distMask



                %%%%%%%%%%%%%%%%%%  Getting segmentation  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                [nucleiMask,largestNucleiArea] = S3NucleiSegmentationWatershed(nucleiPM,nucleiCrop,logSigma,'mask',TMAmask,'inferNucCenters','UNet', 'nucleiFilter',nucleiFilter,'nucleiRegion',nucleiRegion,'resize',1);
                disp(['Segmented Nuclei']);

                cellMask = bwlabel(bwmorph(nucleiMask>0,'thicken',9));
                mask = ones(size(cellMask));

                stats=regionprops(cellMask,mask,'MeanIntensity','Area');
                idx = find([stats.MeanIntensity] > 0.05 );
                tissueCellMask = bwlabel(mask.*ismember(cellMask,idx));

                stats=regionprops(tissueCellMask,nucleiMask>0,'MaxIntensity','Area');
                clear cyto, clear mask
                idx = find([stats.MaxIntensity] > 0 & [stats.Area]>5  & [stats.Area]<prctile(cat(1,stats.Area),99.9));
                finalCellMask = bwlabel(ismember(tissueCellMask,idx));
                clear tissueCellMask
                nucleiMask = cast(nucleiMask>0,class(finalCellMask)).*finalCellMask; 
                cytoplasmMask = finalCellMask - nucleiMask;

                exportMasks(nucleiMask,nucleiCrop,[outputPath filesep sample filesep],['nucleiRing_nucleiRegion-' nucleiRegion '_nucleiFilterS-' nucleiFilter '_logSigmaMin-' num2str(logSigmaMin) '_logSigmaMax-' num2str(logSigmaMax) '-'],'true','true');


                %%Comparing results
                nucleousProb= im2uint16(nucleiProbMaps);
                output = imread([outputPath filesep sample filesep 'nucleiRing_nucleiRegion-' nucleiRegion '_nucleiFilterS-' nucleiFilter '_logSigmaMin-' num2str(logSigmaMin) '_logSigmaMax-' num2str(logSigmaMax) '-Outlines.tif']);

                segmentation = output(:,:,1);
                nucleous = output(:,:,2);

                minratio=0.8;
                maxratio=1.2;

                %Ratio
                x = rdivide(nucleousProb,nucleous);
                nucleosANDprob = (x > minratio & x < maxratio);
                intersect = (segmentation & nucleosANDprob);
                noIntersect = ~(segmentation & nucleosANDprob);
                FPmatrix = (noIntersect & segmentation);
                FNmatrix = (noIntersect & nucleosANDprob);


                TP = sum(intersect(:) == 1);
                FP = sum(FPmatrix(:) == 1);
                FN = sum(FNmatrix(:) == 1);
                f1=2*TP/(2*TP + FN + FP);

                A = [TP FP FN f1];
                fileID = fopen([outputPath filesep sample filesep 'nucleiRing_nucleiRegion-' nucleiRegion '_nucleiFilterS-' nucleiFilter '_logSigmaMin-' num2str(logSigmaMin) '_logSigmaMax-' num2str(logSigmaMax) '-F1.txt'],'w');
                fprintf(fileID,'TP FP FN f1\n');
                fprintf(fileID,'%8d %8d %8d %8d\n',A);
                fclose(fileID);
    
            end
        end
    end
end


function exportMasks(mask,image,outputPath,fileNameNuclei,saveFig,saveMasks)
   image = im2double(image);
   if isequal(saveFig,'true')
    t = Tiff([outputPath filesep fileNameNuclei 'Outlines.tif'],'w8');
    setTag(t,'Photometric',Tiff.Photometric.MinIsBlack);
    setTag(t,'Compression',Tiff.Compression.None);
    setTag(t,'BitsPerSample',16);
    setTag(t,'SamplesPerPixel',2);
    setTag(t,'ImageLength',size(mask,1));
    setTag(t,'ImageWidth',size(mask,2));
    setTag(t,'SampleFormat',Tiff.SampleFormat.UInt);
    setTag(t,'PlanarConfiguration',Tiff.PlanarConfiguration.Separate);
    setTag(t,'RowsPerStrip', 1);    
    write(t,cat(3,uint16(bwperim(mask))*65535,image*65535));
    close(t);
%     TiffWrite(cat(3,uint16(bwperim(mask))*65535,image*65535),[outputPath filesep fileNameNuclei 'Outlines.tif'])
   end
   if isequal(saveMasks,'true')
    t = Tiff([outputPath filesep fileNameNuclei 'Mask.tif'],'w8');
    setTag(t,'Photometric',Tiff.Photometric.MinIsBlack);
    setTag(t,'Compression',Tiff.Compression.None);
    setTag(t,'BitsPerSample',32);
    setTag(t,'SamplesPerPixel',1);
    setTag(t,'ImageLength',size(mask,1));
    setTag(t,'ImageWidth',size(mask,2));
    setTag(t,'SampleFormat',Tiff.SampleFormat.UInt);
    setTag(t,'PlanarConfiguration',Tiff.PlanarConfiguration.Chunky);
    setTag(t,'RowsPerStrip', 1);
    write(t,uint32(mask));
    close(t);
%     TiffWrite(mask,[outputPath filesep fileNameNuclei 'Mask.tif'])
   end
end
