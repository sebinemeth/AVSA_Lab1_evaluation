%THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
%AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
%DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
%FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
%DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
%SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
%CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
%OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
%OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

% Nil Goyette
% University of Sherbrooke
% Sherbrooke, Quebec, Canada. April 2012

classdef Stats < handle
    %STATS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess = private, SetAccess = private)
        datasetPath = '';
        resultsPath = '';
        categories = 0;
    end
    
    methods
        function this = Stats(dataPath,resuPath)
            this.datasetPath = dataPath;
            this.resultsPath = resuPath;
            this.categories = containers.Map();
        end
        
        function this = addCategories(this, category)
            if this.categories.isKey(category) == false
                this.categories(category) = containers.Map();
            end
        end
        
        function this = update(this, category, video, confusionMatrix)
            currentCategory = this.categories(category);
            currentCategory(video) = confusionMatrix;       
        end
        
        function this = writeCategoryResult(this, category,disp_flag)
            categoryStats = [];
            
            currentCategory = this.categories(category);
            if isempty(currentCategory)
                fprintf('category %s: No data to compute stats!!!!!\n',category);
                return
            end
            
            fid = fopen([this.resultsPath '\' category '\eval_category.txt'], 'wt');
            
            WriteAnddisp_flag(fid, disp_flag,sprintf('#Results for category %s\n', category));
            WriteAnddisp_flag(fid, disp_flag,'#A description of the metrics can be found here http://jacarini.dinf.usherbrooke.ca/resultEvaluation/\n');
            WriteAnddisp_flag(fid, disp_flag,sprintf('#%s\tvideo\t\t\t\tTP\t\t\tFN\t\t\tFN\t\t\tTN\t\t\t\tSE\n',pad('category',length(category)+1)));            
            
            for video = keys(currentCategory)
                video = video{1};
                currentVideo = currentCategory(video);
                [TP FP FN TN SE stats] = confusionMatrixToVar(currentVideo);
                categoryStats = [categoryStats; stats];
                WriteAnddisp_flag(fid, disp_flag,sprintf('%s\t%s\t\t%u\t\t%u\t\t%u\t\t%u\t\t%u\n', pad(category,max(length(category),length('category'))+1), pad(video,14), TP, FP, FN, TN, SE));                
            end
            
            confusionMatrix = sumCells(values(currentCategory));
            [TP FP FN TN SE] = confusionMatrixToVar(confusionMatrix);             
            WriteAnddisp_flag(fid, disp_flag,sprintf('%s\t%s\t\t%u\t%u\t\t%u\t\t%u\t\t%u\n', pad(category,max(length(category),length('category'))+1), pad('ALL SEQUENCES',14), TP, FP, FN, TN, SE));                
            
            WriteAnddisp_flag(fid, disp_flag,'\nRecall\t\t\tSpecificity\t\tFPR\t\t\t\tFNR\t\t\t\tPBC\t\t\t\tPrecision\t\tFMeasure');                
            WriteAnddisp_flag(fid, disp_flag,sprintf('\n%1.10f\t%1.10f\t%1.10f\t%1.10f\t%1.10f\t%1.10f\t%1.10f', mean(categoryStats)));                            
            
            fclose(fid);
        end
        
        function this = writeOverallResults(this,disp_flag)
            categoryStats = containers.Map();
            
            fid = fopen([this.resultsPath  '\eval_overall.txt'], 'wt');
            fprintf('\n\n');
            WriteAnddisp_flag(fid, disp_flag,'#OVERALL RESULTS\n');
            WriteAnddisp_flag(fid, disp_flag,'#A description of the metrics can be found here http://jacarini.dinf.usherbrooke.ca/resultEvaluation/\n');
            WriteAnddisp_flag(fid, disp_flag,'#category\t\t\t\tvideo\t\t\t\tTP\t\t\tFN\t\t\tFN\t\t\tTN\t\t\t\tSE\n');
            
            for category = keys(this.categories)
                category = category{1};
                categoryStats(category) = [];
                
                currentCategory = this.categories(category);
                if isempty(currentCategory)
                    fprintf('%s\tNo data to compute stats!!!!!\n',category);
                    break;
                end
                
                for video = keys(currentCategory)
                    video = video{1};
                    currentVideo = currentCategory(video);
                    [TP FP FN TN SE stats] = confusionMatrixToVar(currentVideo);
                    categoryStats(category) = [categoryStats(category); stats];
                    WriteAnddisp_flag(fid, disp_flag,sprintf('%s\t%s\t\t%u\t\t%u\t\t%u\t\t%u\t\t%u\n', pad(category,20), pad(video,14), TP, FP, FN, TN, SE));                                    
                end
                
                confusionMatrix = sumCells(values(currentCategory));
                [TP FP FN TN SE] = confusionMatrixToVar(confusionMatrix);
                WriteAnddisp_flag(fid, disp_flag,sprintf('%s\t%s\t\t%u\t%u\t\t%u\t\t%u\t\t%u\n\n', pad(category,20), pad('ALL SEQUENCES',14), TP, FP, FN, TN, SE));                                
            end
            
            sumInMatrix = mapToMatrix(this.categories);
            confusionMatrix = sum(sumInMatrix);
            [TP FP FN TN SE] = confusionMatrixToVar(confusionMatrix);
            WriteAnddisp_flag(fid, disp_flag,sprintf('\n%s\t%s\t\t%u\t%u\t\t%u\t\t%u\t\t%u\n', pad('Overall',20), pad('ALL CATEGORIES',14), TP, FP, FN, TN, SE));                
            
            overallStats = [];
            WriteAnddisp_flag(fid, disp_flag,'\n\n\t\t\tRecall\t\t\tSpecificity\t\tFPR\t\t\t\tFNR\t\t\t\tPBC\t\t\t\tPrecision\t\tFMeasure\n');
            for category = keys(this.categories)
                category = category{1};
                
                skip=0;
                try
                    means = mean(categoryStats(category));                    
                catch
                    skip=1;
                end
                
                if skip == 0 & ~isempty(means) & ~isnan(means)
                    overallStats = [overallStats; means];
                    categoryName = category;
                    if size(categoryName, 2) > 8
                        categoryName = strcat(category(1:7), '..');
                    end
                    WriteAnddisp_flag(fid, disp_flag,sprintf('%s :\t%1.10f\t%1.10f\t%1.10f\t%1.10f\t%1.10f\t%1.10f\t%1.10f\n', categoryName, means));                            
                end
            end
            WriteAnddisp_flag(fid, disp_flag,sprintf('\nOverall:\t%1.10f\t%1.10f\t%1.10f\t%1.10f\t%1.10f\t%1.10f\t%1.10f', mean(overallStats)));                            
            fclose(fid);
        end
    end
    
end

function total = sumCells(cells)
    total = [0 0 0 0 0];
    for cell = cells
        total = total + cell{1};
    end
end


function mat = mapToMatrix(map)
    mat = [];
    maps = values(map);
    for idx = 1:map.length()
        newPart = mapToRows(maps{idx});
        mat = [mat; newPart];
    end
end

function rows = mapToRows(map)
    rows = [];
    for value = values(map)
        rows = [rows; value{1}];
    end
end

function [TP FP FN TN SE stats] = confusionMatrixToVar(confusionMatrix)
    TP = confusionMatrix(1);
    FP = confusionMatrix(2);
    FN = confusionMatrix(3);
    TN = confusionMatrix(4);
    SE = confusionMatrix(5);
    
    recall = TP / (TP + FN);
    specficity = TN / (TN + FP);
    FPR = FP / (FP + TN);
    FNR = FN / (TP + FN);
    PBC = 100.0 * (FN + FP) / (TP + FP + FN + TN);
    precision = TP / (TP + FP);
    FMeasure = 2.0 * (recall * precision) / (recall + precision);
    
    stats = [recall specficity FPR FNR PBC precision FMeasure];
end

function WriteAnddisp_flag(fid, disp_flag,str)
    if disp_flag
       fprintf(str);%display data in command line if "disp_flag" flag is enabled
    end
    fprintf(fid,str);%write data in the file opened with identifier fid
end
