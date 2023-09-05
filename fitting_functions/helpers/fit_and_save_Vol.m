function [this_model] = fit_and_save_Vol(all_stats, dataset_label, fitType, this_model, extracted_model, fit_flag, numFitRun)
    %% fitting
    if fit_flag && ~this_model.fit_exists
	
        session_num = length(all_stats);
        block_num = 0;
        for sesscnt = 1:session_num
            stats = all_stats{sesscnt};
            block_num = block_num + numel(stats.block_indices);
        end
        
        if strcmp(fitType,'session')
            LL = NaN(session_num,1);
            BIC = NaN(session_num,1);
            normLL = NaN(session_num,1);
            AIC = NaN(session_num,1);
            fitpars = cell(session_num,1);
        elseif strcmp(fitType,'block')
            LL = NaN(block_num,1);
            BIC = NaN(block_num,1);
            normLL = NaN(block_num,1);
            AIC = NaN(block_num,1);
            fitpars = cell(block_num,1);
        end
        
        blockcnt = 0;
        for sesscnt = 1:session_num
            stats = all_stats{sesscnt};
            if isfield(stats,'cloc')
                stats = rmfield(stats,'cloc'); % correction: remove choice location vector
            end
            if strcmp(fitType,'session')
                %% fit one set of params to each session
                if isempty(extracted_model)
                    minBIC = intmax;
                    % fit using random initpar
                    for i = 1:numFitRun    
                        [qpar, negloglike, bic, nlike, aic] = ...
                            fit_fun(stats, this_model.fun,this_model.initparpool{i},this_model.lb,this_model.ub);
                        if bic<minBIC
                            minBIC = bic;
                            fitpar0 = qpar;
                            LL0 = negloglike;
                            nlike0 = nlike;
                            aic0 = aic;
                        end
                    end 
                    fitpars{sesscnt,1} = fitpar0;
                    LL(sesscnt,1) = LL0; 
                    BIC(sesscnt,1) = minBIC;
                    normLL(sesscnt,1) = nlike0;
                    AIC(sesscnt,1) = aic0;                
                else
                    [fitpars{sesscnt,1},LL(sesscnt,1),BIC(sesscnt,1),normLL(sesscnt,1),AIC(sesscnt,1)] = ...
                        fit_fun_extracted_initpar(stats, this_model, extracted_model.fitpar{sesscnt}, numFitRun);
                end
                display_counter(sesscnt); 
            elseif strcmp(fitType,'block')
                %% fit one set of params to each block
                block_stats = {};   % compile stats by each block within one session
                for b = 1:numel(stats.block_indices)
                    blockcnt = blockcnt + 1;
                    block_stats{b} = struct;
                    block_stats{b}.c = stats.c(stats.block_indices{b});
                    block_stats{b}.r = stats.r(stats.block_indices{b});
                    
                    % set initial V_i
                    if b==1
                        block_stats{b}.initV = [.5 .5];
                    else
                        block_stats{b}.initV = endVals{1};
                    end
                    
                    % obtain parameters which yield the least -LL for each block (setpwise)
                    minBIC = intmax;
                    for i = 1:numFitRun   
                        if ~isempty(extracted_model)
                            if i<=numFitRun/2
                                this_model.initparpool{i}(1:length(extracted_model.fitpar{b})) = extracted_model.fitpar{b};
                            end
                        end                        
                        [qpar, negloglike, bic, nlike, aic, endVals] = ...
                            fit_fun_initV(block_stats{b}, this_model.fun,this_model.initparpool{i},this_model.lb,this_model.ub);
                        if bic<minBIC
                            minBIC = bic;
                            fitpar0 = qpar;
                            LL0 = negloglike;
                            nlike0 = nlike;
                            aic0 = aic;
                        end
                    end 
                    fitpars{blockcnt,1} = fitpar0;
                    LL(blockcnt,1) = LL0; 
                    BIC(blockcnt,1) = minBIC;
                    normLL(blockcnt,1) = nlike0;
                    AIC(blockcnt,1) = aic0;          
                    
                    display_counter(blockcnt); 
                end
            elseif strcmp(fitType,'blockWhole')    
                %% fit one set of params to each block: version2 
                % obtain parameters which yield the least -LL for the given entire session
                
                block_stats = {};
                % compile stats by each block within one session
                if ~isempty(extracted_model)
                    prevFitParams = zeros(numel(stats.block_indices),length(extracted_model.initpar));
                end
                for b = 1:numel(stats.block_indices)
                    block_stats{b} = struct;
                    block_stats{b}.c = stats.c(stats.block_indices{b});
                    block_stats{b}.r = stats.r(stats.block_indices{b});
                    % set initial V_i
                    if b==1
                        block_stats{b}.initV = [.5 .5];
                    end
                    
                    % extract initpar from previous model
                    if ~isempty(extracted_model)
                        prevFitParams(b,:) = extracted_model.fitpar{b};
                    end
                end
                
                % fit blocks within one session: return stats for each block
                minBIC = intmax;
                LBs = repmat(this_model.lb,[length(block_stats),1]);
                UBs = repmat(this_model.ub,[length(block_stats),1]);
                for i = 1:numFitRun
                    initpars = repmat(this_model.initparpool{i},[length(block_stats),1]);
                    if ~isempty(extracted_model)&&i<=numFitRun/2
                        initpars(:,1:length(extracted_model.initpar)) = prevFitParams;
                    end
                    [qpar_blocks, negloglike_blocks, bic_blocks, nlike_blocks, aic_blocks] = ...
                        fit_fun_blocks_withinSession(block_stats, this_model.fun, initpars, LBs, UBs);
                    bic = sum(bic_blocks);
                    if bic<minBIC
                        minBIC = bic_blocks;
                        fitpar0 = qpar_blocks;
                        LL0 = negloglike_blocks;
                        nlike0 = nlike_blocks;
                        aic0 = aic_blocks;
                    end
                end
                % assign fitted params from each block
                for b = 1:numel(stats.block_indices)
                    blockcnt = blockcnt + 1;
                    fitpars{blockcnt,1} = fitpar0(b,:);
                    LL(blockcnt,1) = LL0(b); 
                    BIC(blockcnt,1) = minBIC(b);
                    normLL(blockcnt,1) = nlike0(b);
                    AIC(blockcnt,1) = aic0(b);   
                    
                    display_counter(blockcnt); 
                end
            else
                error("Set correct fit type setting: 'session', 'block', 'blockWhole'");
            end
        end
        fprintf('\n');
        
        this_model.fitpar = fitpars;
        this_model.ll = LL;
        this_model.aic = AIC;
        this_model.bic = BIC;
        this_model.nlike = normLL;
    end
    
    % saving fitting output
    model_struct = this_model;
    if isfield(model_struct,'CrossVal')
        model_struct = rmfield(model_struct,'CrossVal');   % edit: remove fitpars to avoid overlaps
    end
    if ~this_model.fit_exists
        fitfname = strcat('output/model/',dataset_label,'/',fitType,'/',this_model.name,'.mat');    
        save(fitfname, 'model_struct');
    else
        disp('fit loaded');
    end
    
end