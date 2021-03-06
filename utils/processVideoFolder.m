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

function confusionMatrix = processVideoFolder(videoPath, resultPath)
    % A video folder should contain 2 folders ['input', 'groundtruth']
	% and the "temporalROI.txt" file to be valid. The choosen method will be
	% applied to all the frames specified in \temporalROI.txt
    
    range = readTemporalFile(videoPath);
    idxFrom = range(1);
    idxTo = range(2);
    %inputFolder = fullfile(videoPath, 'input');
    %display(['Comparing ', videoPath, ' with ', resultPath, char(10), 'From frame ' ,  num2str(idxFrom), ' to ',  num2str(idxTo), char(10)]);

    % Compare your images with the groundtruth and compile statistics
    groundtruthFolder = fullfile(videoPath, 'groundtruth');
    display(['  Comparing ', groundtruthFolder, ' with ', resultPath, ' (from frame ' ,  num2str(idxFrom), ' to ',  num2str(idxTo),')']);
    confusionMatrix = compareImageFiles(groundtruthFolder, resultPath, idxFrom, idxTo);
end

function range = readTemporalFile(path)
    % Reads the temporal file and returns the important range
    
    fID = fopen([path, '/temporalROI.txt']);
    if fID < 0
        disp(ferror(fID));
        exit(0);
    end
    
    C = textscan(fID, '%d %d', 'CollectOutput', true);
    fclose(fID);
    
    m = C{1};
    range = m';
end

function confusionMatrix = compareImageFiles(gtFolder, resFolder, idxFrom, idxTo)
    % Compare the binary files with the groundtruth files.
    
    threshold = 0; %threshold to binarize result images (need if JPEG format is used)
    
    %get filenames for the result images
    extensions = {'png','jpeg','jpg','bmp'};   
    for i=1:numel(extensions)        
        resfiles=cell2mat(extractfield(dir(fullfile(resFolder, ['*.' extensions{i}])), 'name')');        
        if ~isempty(resfiles)
           threshold = strcmp(extensions{i}, '.jpg') == 1 || strcmp(extensions{i}, '.jpeg') == 1;
           break; 
        end
    end

    %get filenames for the ground-truth images
    gtfiles=cell2mat(extractfield(dir(fullfile(gtFolder, '*.png')), 'name')');    
   
    if(size(resfiles,1) ~= size(gtfiles,1))
        fprintf('ERROR! No equal number of files in ground-truth and result directories. (currently %d gt files and %d results)\n\n',size(gtfiles,1),size(resfiles,1))
        confusionMatrix=[];
        return
    end
    
    confusionMatrix = [0 0 0 0 0]; % TP FP FN TN SE
    for idx = idxFrom:idxTo                
        imGtruth = imread(fullfile(gtFolder, gtfiles(idx,:))); %read ground-truth image
        imResult = imread(fullfile(resFolder, resfiles(idx,:)));%read result image
        
        %check if result image is logical
        if islogical(imResult)
            imResult = uint8(imResult)*255;
        end
        
        %check if result image needs to be binarized
        if threshold
            imResult = im2bw(imResult, 0.5);
            imResult = im2uint8(imResult);
        end
        
        confusionMatrix = confusionMatrix + compare(imResult, imGtruth);
    end
    
 %   extension = '.png'; % TODO Change extension if required
%    threshold = strcmp(extension, '.jpg') == 1 || strcmp(extension, '.jpeg') == 1;
    
%     imResult = imread(fullfile(resFolder, ['bin', num2str(idxFrom, '%.6d'), extension]));
%     int8trap = isa(imResult, 'uint8') && min(min(imResult)) == 0 && max(max(imResult)) == 1;
%     
%     confusionMatrix = [0 0 0 0 0]; % TP FP FN TN SE
%     for idx = idxFrom:idxTo
%         fileName = num2str(idx, '%.6d');
%         imResult = imread(fullfile(resFolder, ['bin', fileName, extension]));
%         if size(imResult, 3) > 1
%             imResult = rgb2gray(imResult);
%         end
%         if islogical(imResult) || int8trap
%             imResult = uint8(imResult)*255;
%         end
%         if threshold
%             imResult = im2bw(imResult, 0.5);
%             imResult = im2uint8(imResult);
%         end
%         imGT = imread(fullfile(gtFolder, ['gt', fileName, '.png']));
%         
%         confusionMatrix = confusionMatrix + compare(imResult, imGT);
%     end
end

function confusionMatrix = compare(imResult, imGT)
    % Compares a binary frames with the groundtruth frame
    
    TP = sum(sum(imGT==255&imResult==255));		% True Positive 
    TN = sum(sum(imGT<=50&imResult==0));		% True Negative
    FP = sum(sum((imGT<=50)&imResult==255));	% False Positive
    FN = sum(sum(imGT==255&imResult==0));		% False Negative
    SE = sum(sum(imGT==50&imResult==255));		% Shadow Error
	
    confusionMatrix = [TP FP FN TN SE];
end
