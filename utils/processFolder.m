function processFolder(datasetPath, resultsPath, DISPLAY_STATS)
% This function evaluates foreground segmentation masks using the following
% metrics:(1)Recall, (2)Specificity, (3)FPR, (4)FNR, (5)PBC, (6)Precision, (7)FMeasure.
%
% Test sequences are from the ChangeDetection 2012 http://changedetection.net/
% and can be downloaded at http://jacarini.dinf.usherbrooke.ca/static/dataset/dataset2012.zip
% 
% Script based on the MATLAB evaluation tool available at
% http://jacarini.dinf.usherbrooke.ca/static/code/MatlabCodeStats2012.zip
%
% Author: Juan C. SanMiguel
% Date: February 2018
	
%check root dataset folder (full or lite versions)
if filesys('isRootDatasetFolder?', datasetPath) == false && ...
   filesys('isRootDatasetFolderLite?', datasetPath) == false
    disp(['The folder' datasetPath 'is not a valid root folder.']);
    return        
end

stats = Stats(datasetPath,resultsPath); %create the stats structure

%% evaluate each category
categoryList = filesys('getFolders', datasetPath); %get categories from dataset
for strCategory = categoryList

    category = strCategory{1};                      %get category in string format
    stats.addCategories(category);                  %add category to stats object        
    categoryPath = fullfile(datasetPath, category); %get full path of category

    fprintf('\n\nEVALUATING CATEGORY %s:\n', category);
    videoList = filesys('getFolders', categoryPath);
    for strVideo = videoList

        video = strVideo{1};                        %get test video in string format            
        videoPath = fullfile(categoryPath, video);  %get full path of video (ground-truth)
        resulPath = fullfile(resultsPath, category, video);%get full path of result

        if filesys('isValidGroundTruthFolder?', videoPath) == true &&...
            filesys('isValidResultsFolder?', resulPath) %check if paths are valid

            confusionMatrix = processVideoFolder(videoPath, resulPath); %evaluate results
            stats.update(category, video, confusionMatrix);             %store the evaluation measures
        else
            fprintf('Input data not valid\n\t-Groundtruth:%s\n\t-Results:%s\n',videoPath,resulPath);                
        end
    end
    stats.writeCategoryResult(category,DISPLAY_STATS); %write results in "eval_category.txt"
end
stats.writeOverallResults(DISPLAY_STATS);%write results in "eval_overall.txt"