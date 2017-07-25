function allMets=evaluateTrackingGRAM(allSeq,resDir,dataDir,...
    start_idx_list, end_idx_list)
%% evaluate CLEAR MOT and other metrics
% concatenate ALL sequences and evaluate as one!
%
% SETUP:
%
% define directories for tracking results...
% resDir = fullfile('res','data',filesep);
% ... and the actual sequences
% dataDir = fullfile('..','data','2DMOT2015','train',filesep);
%
%

fprintf('Sequences: \n');
disp(allSeq')

% concat gtInfo
gtInfo=[];
gtInfo.X=[];
allFgt=zeros(1,length(allSeq));

% Find out the length of each sequence
% and concatenate ground truth
gtInfoSingle=[];
seqCnt=0;
id = 1;
for s=allSeq
    seqCnt=seqCnt+1;
    seqName = char(s);
    seqFolder= [dataDir, 'Images', filesep, seqName, filesep];
    
    assert(isdir(seqFolder),'Sequence folder %s missing',seqFolder);
    start_idx = start_idx_list(id);
    end_idx = end_idx_list(id);
    gtFile = fullfile(dataDir,'Annotations', sprintf('%s.txt', seqName));
    gtI = convertTXTToStructGRAM(gtFile, seqFolder, start_idx, end_idx);
    id = id + 1;
    
    [Fgt,Ngt] = size(gtInfo.X);
    [FgtI,NgtI] = size(gtI.Xi);
    newFgt = Fgt+1:Fgt+FgtI;
    newNgt = Ngt+1:Ngt+NgtI;
    
    gtInfo.Xi(newFgt,newNgt) = gtI.Xi;
    gtInfo.Yi(newFgt,newNgt) = gtI.Yi;
    gtInfo.W(newFgt,newNgt) = gtI.W;
    gtInfo.H(newFgt,newNgt) = gtI.H;
    
    gtInfoSingle(seqCnt).wc=0;
    
    % fill in world coordinates if they exist
    if isfield(gtI,'Xgp') && isfield(gtI,'Ygp')
        gtInfo.Xgp(newFgt,newNgt) = gtI.Xgp;
        gtInfo.Ygp(newFgt,newNgt) = gtI.Ygp;
        gtInfoSingle(seqCnt).wc=1;
    end
    
    % check if bounding boxes available in solution
    imCoord=1;
    if all(gtI.Xi(find(gtI.Xi(:)))==-1)
        imCoord=0;
    end
    
    gtInfo.X=gtInfo.Xi;gtInfo.Y=gtInfo.Yi;
    if ~imCoord 
        gtInfo.X=gtInfo.Xgp;gtInfo.Y=gtInfo.Ygp; 
    end
    
    allFgt(seqCnt) = FgtI;
    
    gtInfoSingle(seqCnt).gtInfo=gtI;
    
end
gtInfo.frameNums=1:size(gtInfo.Xi,1);

allMets=[];

mcnt=1;


fprintf('Evaluating ... \n');


clear stInfo
stInfo.Xi=[];

evalMethod=1;

% flags for entire benchmark
% if one seq missing, evaluation impossible
eval2D=1;
eval3D=1;

seqCnt=0;
tracked_frac_list = {};
tracked_total_list = {};
gt_total_list = {};
id = 1;
% iterate over each sequence
figure('Visible','off'), hold on;
MT_thresh = 0.1:0.01:1;
for s=allSeq
    
    seqCnt=seqCnt+1;
    seqName = char(s);
    
    fprintf('\t... %s\n',seqName);
    
    start_idx = start_idx_list(id);
    end_idx = end_idx_list(id);
    id = id + 1;
    
    % if a result is missing, we cannot evaluate this tracker
    resFile = fullfile(resDir,...
        sprintf('%s_%d_%d.txt', seqName, start_idx, end_idx));
    if ~exist(resFile,'file')
        fprintf('WARNING: result file for %s not available: %s\n',seqName, resFile);
        eval2D=0;
        eval3D=0;
        continue;
    end   
    
    stI = convertTXTToStructGRAM(resFile);
%     stI.Xi(find(stI.Xi(:)))=-1;
    % check if bounding boxes available in solution
    imCoord=1;
    if all(stI.Xi(find(stI.Xi(:)))==-1)
        imCoord=0;
    end
    
    worldCoordST=0; % state
    if isfield(stI,'Xgp') && isfield(stI,'Ygp')
        worldCoordST=1;
    end
    
    [FI,NI] = size(stI.Xi);
    
    
    % if stateInfo shorter, pad with zeros
    % GT and result must be equal length
    if FI<allFgt(seqCnt)
        missingFrames = FI+1:allFgt(seqCnt);
        stI.Xi(missingFrames,:)=0;
        stI.Yi(missingFrames,:)=0;
        stI.W(missingFrames,:)=0;
        stI.H(missingFrames,:)=0;
        stI.X(missingFrames,:)=0;
        stI.Y(missingFrames,:)=0;
        if worldCoordST
            stI.Xgp(missingFrames,:)=0; stI.Ygp(missingFrames,:)=0;
        end
        [FI,NI] = size(stI.Xi);
        
    end
    
    % get result for one sequence only
    [mets, MT_list, tracked_frac, tracked_total, gt_total]=CLEAR_MOT_HUN(gtInfoSingle(seqCnt).gtInfo,stI);
    tracked_frac_list{end+1} = tracked_frac;
    tracked_total_list{end+1} = tracked_total;
    gt_total_list{end+1} = gt_total;
    filename = sprintf('tracked_frac_%s.txt', seqName);
    tracked_frac_file = fullfile(resDir, filename); 
    dlmwrite(tracked_frac_file,tracked_frac, '\n');
    
    plot(MT_thresh, MT_list), grid on;

    allMets(mcnt).mets2d(seqCnt).name=seqName;
    allMets(mcnt).mets2d(seqCnt).m=mets;
    
    allMets(mcnt).mets3d(seqCnt).name=seqName;
    allMets(mcnt).mets3d(seqCnt).m=zeros(1,length(mets));
    
    if imCoord        
        fprintf('*** 2D (Bounding Box overlap) ***\n'); printMetrics(mets, MT_list); fprintf('\n');
    else
        fprintf('*** Bounding boxes not available ***\n\n');
        eval2D=0;
    end
    
    % if world coordinates available, evaluate in 3D
    if  gtInfoSingle(seqCnt).wc &&  worldCoordST
        evopt.eval3d=1;evopt.td=1;
        [mets, MT_list, tracked_frac, tracked_total, gt_total]=CLEAR_MOT_HUN(gtInfoSingle(seqCnt).gtInfo,stI,evopt);
            allMets(mcnt).mets3d(seqCnt).m=mets;
                
        fprintf('*** 3D (in world coordinates) ***\n'); printMetrics(mets, MT_list); fprintf('\n');            
    else
        eval3D=0;
    end
    
    
    [F,N] = size(stInfo.Xi);
    newF = F+1:F+FI;
    newN = N+1:N+NI;
    
    % concat result
    stInfo.Xi(newF,newN) = stI.Xi;
    stInfo.Yi(newF,newN) = stI.Yi;
    stInfo.W(newF,newN) = stI.W;
    stInfo.H(newF,newN) = stI.H;
    if isfield(stI,'Xgp') && isfield(stI,'Ygp')
        stInfo.Xgp(newF,newN) = stI.Xgp;stInfo.Ygp(newF,newN) = stI.Ygp;
    end
    stInfo.X=stInfo.Xi;stInfo.Y=stInfo.Yi;
    if ~imCoord 
        stInfo.X=stInfo.Xgp;stInfo.Y=stInfo.Ygp; 
    end
    
end
legend(allSeq);
plotFile = fullfile(resDir, sprintf('MT.png'));
hist_edges = 0:0.1:1;
saveas(gcf, plotFile);
hold off;
for plot_id=1:numel(tracked_frac_list)    
    seq_name = char(allSeq{plot_id});
    
    tracked_frac = tracked_frac_list{plot_id};
    plotFile = fullfile(resDir, sprintf('tracked_frac_hist_%s.png', seq_name));    
    % figure('Visible','off');
    histogram(tracked_frac, hist_edges);
    xlabel('Correctly Tracked Fraction (CTF)'), ylabel('No. of Trajectories');
    title('Correctly Tracked Fraction Distribution');
    saveas(gcf, plotFile);  
    
    tracked_total = tracked_total_list{plot_id};
    plotFile = fullfile(resDir, sprintf('tracked_total_hist_%s.png', seq_name));    
    % figure('Visible','off');
    histogram(tracked_total);
    xlabel('No. of Frames'), ylabel('No. of Trajectories');
    title('Tracked Trajectory Size Distribution');
    saveas(gcf, plotFile);
    
    gt_total = gt_total_list{plot_id};
    plotFile = fullfile(resDir, sprintf('gt_total_hist_%s.png', seq_name));    
    histogram(gt_total);
    xlabel('No. of Frames'), ylabel('No. of Trajectories');
    title('Ground Truth Trajectory Size Distribution');
    saveas(gcf, plotFile);
end

stInfo.frameNums=1:size(stInfo.Xi,1);


if eval2D
    fprintf('\n');
    fprintf(' ********************* Your Benchmark Results (2D) ***********************\n');

    [m2d, MT_list, tracked_frac, tracked_total, gt_total]=CLEAR_MOT_HUN(gtInfo,stInfo);
    
    plotFile = fullfile(resDir, sprintf('tracked_frac_hist_all.png'));    
    histogram(tracked_frac, hist_edges);
    xlabel('Correctly Tracked Fraction (CTF)'), ylabel('No. of Trajectories');
    title('Correctly Tracked Fraction Distribution');
    saveas(gcf, plotFile);  
    
    plotFile = fullfile(resDir, sprintf('tracked_total_hist_all.png'));    
    histogram(tracked_total);
    xlabel('No. of Frames'), ylabel('No. of Trajectories');
    title('Tracked Trajectory Size Distribution');
    saveas(gcf, plotFile);
    
    plotFile = fullfile(resDir, sprintf('gt_total_hist_all.png'));    
    histogram(gt_total);
    xlabel('No. of Frames'), ylabel('No. of Trajectories');
    title('Ground Truth Trajectory Size Distribution');
    saveas(gcf, plotFile);
    
    allMets.bmark2d=m2d;
    
    filename = sprintf('eval2D_all.txt');
    evalFile = fullfile(resDir, filename);  
    
    printMetrics(m2d, MT_list);
    dlmwrite(evalFile,m2d);
    
    
end    

if eval3D
    fprintf('\n');
    fprintf(' ********************* Your Benchmark Results (3D) ***********************\n');

    evopt.eval3d=1;evopt.td=1;
       
    [m3d, MT_list, tracked_frac, tracked_total, gt_total]=CLEAR_MOT_HUN(gtInfo,stInfo,evopt);
    allMets.bmark3d=m3d;
    
    evalFile = fullfile(resDir, 'eval3D.txt');
    
    printMetrics(m3d, MT_list);
    dlmwrite(evalFile,m3d);    
end
if ~eval2D && ~eval3D
    fprintf('ERROR: results cannot be evaluated\n');
end
