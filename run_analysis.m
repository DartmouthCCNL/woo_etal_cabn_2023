%% Run analysis
% computes metrics by each block

%% load processed_data
disp("Running analysis for: "+dataset_label+" dataset");

if strcmp(dataset_label,'Cohen')
    schedule_subsets = ["prob1040","prob540"];
    load('dataset/subj_stats_Cohen.mat','all_stats_subject');      % subject struct data
    animal_ids = fieldnames(all_stats_subject);
    plot_setting_v = 2;
        % 0 = include 40/5 & 40/10 schedules only
        % 1 = include all schedules
        % 2 = include two-prob task only
elseif strcmp(dataset_label,'Schultz')
    load('dataset/subj_stats_Schultz.mat','all_stats_subject'); 
    animal_ids = ["X51","X53"];
    plot_setting_v = 3;
end

fitType = 'block';
models = initialize_vol_models(dataset_label, fitType, 1, 0);

%% Calculate metrics by block

% initialization
metricOutput = struct;
all_sesscnt = 0; all_blockcnt = 0; cutOff_blockcnt = 0;

fprintf('all blocks: ');

% loop through each subject
for animalcnt = 1:numel(animal_ids)
    animal_id = animal_ids{animalcnt};
    disp(animalcnt+"."+animal_id);
    
    % initialization
    metricOutput.(animal_id) = struct;
    subj_blockcnt = 0;

    
    this_animal_data = all_stats_subject.(animal_id);
    % loop through each session day
    for sescnt = 1:length(this_animal_data)
        this_sess_data = this_animal_data{sescnt};
        all_sesscnt = all_sesscnt + 1;
    
        if strcmp(dataset_label,'Cohen')
            RP = unique(this_sess_data.rewardprob);
            if length(RP)==2
                %disp(all_sesscnt+". Two prob task session: "+RP(1)+"/"+RP(2));
                twoProb_task = 1;
            else
                %disp(all_sesscnt+". Multiple prob task session");
                twoProb_task = 0;
            end
        end
        
        % loop through each block within session 
        for blockcnt = 1:numel(this_sess_data.block_indices)
            all_blockcnt = all_blockcnt + 1;
            subj_blockcnt = subj_blockcnt + 1;
            this_block_idxes = this_sess_data.block_indices{blockcnt};
        
            % specify higher reward option
            if strcmp(dataset_label,'Cohen')
                stats.hr_opt = this_sess_data.hr_side(this_block_idxes);    % better side
                stats.rewardprob = this_sess_data.rewardprob(this_block_idxes,:);
                if sum(stats.rewardprob(:,1)==stats.rewardprob(:,2))==length(stats.hr_opt)
                    stats.hr_opt = zeros(length(stats.hr_opt),1);
                end
            elseif strcmp(dataset_label,'Schultz')
                stats.hr_opt = this_sess_data.hr_stim(this_block_idxes);    % better simtulus
            end
        
            stats.r = this_sess_data.r(this_block_idxes);   % reward
            stats.c = this_sess_data.c(this_block_idxes);   % choice
            
            % Select last N trials of each block
            cutOff_block = 0;
            if lastN_trials~=0
                if length(stats.r)>=lastN_trials+10 % add 10 trials to select steady state only
                    stats.r = stats.r(end-lastN_trials+1:end);
                    stats.c = stats.c(end-lastN_trials+1:end);
                    stats.hr_opt = stats.hr_opt(end-lastN_trials+1:end);
                else
                    cutOff_block = subj_blockcnt;
                    cutOff_blockcnt = cutOff_blockcnt + 1;
                end 
            end
            
            %% Compute metrics
            
            beh_met = behavioral_metrics(stats.c, stats.r, stats.hr_opt);
            ent_met = entropy_metrics(stats.c, stats.r, stats.hr_opt);
            % store output
            metricOutput.(animal_id) = append_to_fields(metricOutput.(animal_id), {beh_met, ent_met});
            
            % Track other info for the block
            metricOutput.(animal_id).blockL(subj_blockcnt) = length(this_block_idxes);
            metricOutput.(animal_id).counted_blockL(subj_blockcnt) = length(this_block_idxes);
            metricOutput.(animal_id).blockProb(subj_blockcnt,:) = this_sess_data.rewardprob(this_sess_data.block_indices{blockcnt}(1),:);
            metricOutput.(animal_id).firstBlock_idx(subj_blockcnt) = (blockcnt==1);     % indexes whether first block of the session
            
            % Cohen data: select two-prob sessions only
            if (strcmp(dataset_label,'Cohen')&&~twoProb_task)
                metricOutput.(animal_id).counted_blockL(subj_blockcnt) = NaN;
            end
            % Schultz data: exclude L of single-block sessions
            if strcmp(dataset_label,'Schultz')
                metricOutput.(animal_id).allBlockL(subj_blockcnt) = length(this_block_idxes);
                if numel(this_sess_data.block_indices)==1
                    metricOutput.(animal_id).blockL(subj_blockcnt) = NaN;
                    metricOutput.(animal_id).counted_blockL(subj_blockcnt) = NaN;
                end                    
            end
            
            % block schedule
            if strcmp(dataset_label,'Cohen')
                metricOutput.(animal_id).(schedule_subsets(1))(subj_blockcnt,1) = this_sess_data.(schedule_subsets(1))(blockcnt);
                metricOutput.(animal_id).(schedule_subsets(2))(subj_blockcnt,1) = this_sess_data.(schedule_subsets(2))(blockcnt);
                % remove multiple probs task
                if sum(this_sess_data.prob1040)~=length(this_sess_data.prob1040)
                    metricOutput.(animal_id).prob1040(subj_blockcnt,1) = 0;
                end
                if sum(this_sess_data.prob540)~=length(this_sess_data.prob540)
                    metricOutput.(animal_id).prob540(subj_blockcnt,1) = 0;
                end
            elseif strcmp(dataset_label,'Schultz')
                metricOutput.(animal_id).rewardprob(subj_blockcnt,1) = convertCharsToStrings(this_sess_data.prob{blockcnt});
            end
            
            % remove unqualified blocks with too short length (for comparing effect of L)
            if cutOff_block~=0||(strcmp(dataset_label,'Cohen')&&~twoProb_task)
                Fields = setdiff(fieldnames(metricOutput.(animal_id)),{'RL1','RL2','RW1','RW2','blockL','counted_blockL','allBlockL','prob1040','prob540','blockProb','firstBlock_idx'});
                for f = 1:numel(Fields)
                    metricOutput.(animal_id).(Fields{f})(subj_blockcnt,:) = nan(size(metricOutput.(animal_id).(Fields{f})(subj_blockcnt,:)));
                end
            end
           
           display_counter(subj_blockcnt);
        end
    end
    fprintf('\n');
end


