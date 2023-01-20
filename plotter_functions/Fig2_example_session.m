function Fig2_example_session(animal_colors)
    datasets = {'Cohen','Schultz'};
    run_wind = 10;      % running window size
    
    %% Plot for each dataset
    
    %% Panel C and D: choice behavior
    for d = 1:numel(datasets)
        dataset_label = datasets{d};
        animal_color = animal_colors.(dataset_label);

        figure(10+d); clf
        set(gcf,'Color','w','Units','normalized','Position',[0.0 1-0.5*d 0.43 0.4]);
        
        if strcmp(dataset_label,'Cohen')
            load('dataset/subj_stats_Cohen.mat','all_stats_subject'); % subject struct data
            animal_ids = fieldnames(all_stats_subject);

            rep_animal_num = 2;
            rep_sess_num = 1;
        elseif strcmp(dataset_label,'Schultz')
            load('dataset/subj_stats_Schultz.mat','all_stats_subject'); 
            animal_ids = ["X51","X53"];
            
            rep_animal_num = 1;
            rep_sess_num = 5;
        end

        animal_id = animal_ids{rep_animal_num};
        this_sess_data = all_stats_subject.(animal_id){rep_sess_num};
        
        if strcmp(dataset_label,'Cohen')
            hr_opt = this_sess_data.hr_side;
            opt_label = "\leftarrowleft    right\rightarrow";
        else
            hr_opt = this_sess_data.hr_stim;
            opt_label = "\leftarrowstimA    stimB\rightarrow";
        end
        plot(smooth(this_sess_data.r.*hr_opt,run_wind),'Color','k','LineWidth',1.5,'LineStyle','-');     % reward smoothed
        hold on;
        plot(smooth(this_sess_data.c,run_wind),'Color',animal_color,'LineWidth',2);     % choice smoothed
        set(gca, 'tickdir', 'out','Box','off');

        % reversal lines
        for r = 2:numel(this_sess_data.block_addresses)-1
            R = xline(this_sess_data.block_addresses(r));
            R.LineStyle = ':';
            R.LineWidth = 3;
            R.Color = ones(3,1)*.5;
        end

        % reward schedules label
        deltaP_set = [];
        for r = 1:numel(this_sess_data.block_addresses)-1
            x_mid = (this_sess_data.block_addresses(r)+this_sess_data.block_addresses(r+1))/2;
            if strcmp(dataset_label,'Shultz')
                prob1 = int16(this_sess_data.probs{r}(1)*100);
                prob2 = int16(this_sess_data.probs{r}(2)*100);
            else
                prob1 = int16(this_sess_data.rewardprob(round(x_mid),1)*100);
                prob2 = int16(this_sess_data.rewardprob(round(x_mid),2)*100);
            end
            text(x_mid,1,[prob1+"/"+prob2],'VerticalAlignment','bottom','HorizontalAlignment','center','FontName','Helvetica','FontSize',14,'Color',ones(3,1)*.0);
            deltaP_set(r) = prob1 - prob2;
        end
        cmap = colormap(autumn(length(unique(deltaP_set))));
        [~,~,ic] = unique(deltaP_set,'sorted');
        P_rank = 1 + max(ic) - ic;
        patch_yPos = 1.02;
        patch_height = 0.09*2;
        for r = 1:numel(deltaP_set)
            Xv = [this_sess_data.block_indices{r}(1) this_sess_data.block_indices{r}(end) this_sess_data.block_indices{r}(end) this_sess_data.block_indices{r}(1)];
            Yv = [patch_yPos patch_yPos patch_yPos+patch_height patch_yPos+patch_height];
            patch('XData',Xv,'YData',Yv,'FaceColor',cmap(P_rank(r),:),'FaceAlpha',0.5,'EdgeColor','none');
        end

        % labels
        ylabel(["Mean selection","\fontsize{18}"+opt_label]);
        L = legend(["reward","choice"],'box','off');
            L.Position(1) = .85;
            L.Position(2) = .84;
        ax = gca;
        ax.Position(1) = 0.17; ax.Position(2) = 0.25;
        ax.Position(3) = 0.8; ax.Position(4) = 0.55;
        ax.XLim(2) = length(this_sess_data.r);
        ax.XTick = [0:100:ax.XLim(2)];
        ax.YLim = [-1 patch_yPos+patch_height];
        ax.YTick = [-1:.5:1];
        xlabel("Trials");
        set(gca,'FontName','Helvetica','FontSize',20,'FontWeight','normal','LineWidth',3);
        
    end

    
    %% Panel E and F: entropy metrics
    
%     DataToPlot = 1; %"RunWinMet";
%     DataToPlot = 2;  %"BlockMet";
    DataToPlot = 3;  % both
    
    for d = 1:numel(datasets)
        dataset_label = datasets{d};
        
        figure(100+d); clf
        set(gcf,'Color','w','Units','normalized','Position',[0.4 1-0.5*d 0.43 0.4]);
        
        if strcmp(dataset_label,'Cohen')
            load('dataset/subj_stats_Cohen.mat','all_stats_subject'); % subject struct data
            animal_ids = fieldnames(all_stats_subject);
            animal_color = animal_colors.(dataset_label); %"#882255"; %;
            rep_animal_num = 2;
            rep_sess_num = 1;
        elseif strcmp(dataset_label,'Schultz')
            load('dataset/subj_stats_Schultz.mat','all_stats_subject'); 
            animal_ids = ["X51","X53"];
            animal_color = animal_colors.(dataset_label);
            rep_animal_num = 1;
            rep_sess_num = 5;
        end

        animal_id = animal_ids{rep_animal_num};
        this_sess_data = all_stats_subject.(animal_id){rep_sess_num};        

        % reversal lines
        hold on;
        for r = 2:numel(this_sess_data.block_addresses)-1
            R = xline(this_sess_data.block_addresses(r));
            R.LineStyle = ':';
            R.LineWidth = 3;
            R.Color = ones(3,1)*.5;
            R.HandleVisibility = 'off';
        end
        if strcmp(dataset_label,'Cohen')
            hr_opt = this_sess_data.hr_side;
            opt_label = "\leftarrowleft    right\rightarrow";
        else
            hr_opt = this_sess_data.hr_stim;
            opt_label = "\leftarrowstimA    stimB\rightarrow";
        end

        % moving ERDS
        reward = this_sess_data.r;
        choice = this_sess_data.c;
        RunWinMet = struct;
        BlockMet = struct;
        % loop through all trials
        for t = 1:length(reward)
            if t==1
                RunWinMet.pCorrect = NaN;
                RunWinMet.ERDS = NaN;   RunWinMet.MIRS = NaN;  
                RunWinMet.EODS = NaN;   RunWinMet.MIOS = NaN; 
                continue; 
            end
            rew = this_sess_data.r(max(t-run_wind+1,1):t);
            cho = this_sess_data.c(max(t-run_wind+1,1):t);
            opt = hr_opt(max(t-run_wind+1,1):t);
            str = cho(1:end-1)==cho(2:end);     % stay(=1) or switch(=0)
            thisOutput = conditional_entropy(str, rew(1:end-1), "ERDS");
            RunWinMet.ERDS(t) = thisOutput.ERDS;
            thisOutput = conditional_entropy(cho(2:end), rew(1:end-1), "ERDC");
            RunWinMet.ERDC(t) = thisOutput.ERDC;
            thisOutput = mutual_information(str, rew(1:end-1), "MIRS");
            RunWinMet.MIRS(t) = thisOutput.MIRS;
            thisOutput = conditional_entropy(str, opt(1:end-1), "EODS");
            RunWinMet.EODS(t) = thisOutput.EODS;
            thisOutput = conditional_entropy(cho(2:end), opt(1:end-1), "EODC");
            RunWinMet.EODC(t) = thisOutput.EODC;
            thisOutput = mutual_information(str, opt(1:end-1), "MIOS");
            RunWinMet.MIOS(t) = thisOutput.MIOS;
            RunWinMet.pCorrect(t) = mean(cho==opt);
        end
        % loop through each block
        for b = 1:numel(this_sess_data.block_indices)
            thisBlockIdx = this_sess_data.block_indices{b};
            rew = this_sess_data.r(thisBlockIdx(10+1:end));
            cho = this_sess_data.c(thisBlockIdx(10+1:end));
            opt = hr_opt(thisBlockIdx(10+1:end));
            str = cho(1:end-1)==cho(2:end);
            BlockMet.pCorrect(b) = mean(cho==opt);
            thisOutput = conditional_entropy(str, rew(1:end-1), "ERDS");
            BlockMet.ERDS(b) = thisOutput.ERDS;
            thisOutput = conditional_entropy(cho(2:end), rew(1:end-1), "ERDC");
            BlockMet.ERDC(b) = thisOutput.ERDC;
            thisOutput = conditional_entropy(str, opt(1:end-1), "EODS");
            BlockMet.EODS(b) = thisOutput.EODS;
            thisOutput = conditional_entropy(cho(2:end), opt(1:end-1), "EODC");
            BlockMet.EODC(b) = thisOutput.EODC;
        end
        
        switch DataToPlot
            case 1
                plot(RunWinMet.pCorrect,'Color',ones(3,1)*.45,'LineWidth',1.2,'LineStyle','-');     %pBetter
                plot(RunWinMet.ERDS,'Color',animal_color,'LineWidth',2,'LineStyle','-');     % ERDS
            case 2
                for b = 1:numel(this_sess_data.block_indices)
                    thisBlockIdx = this_sess_data.block_indices{b};
                    plot(thisBlockIdx(10+1:end),ones(1,length(thisBlockIdx(10+1:end)))*BlockMet.ERDS(b),'Color',animal_color,'LineWidth',2,'LineStyle','-');     % ERDS
                    plot(thisBlockIdx(10+1:end),ones(1,length(thisBlockIdx(10+1:end)))*BlockMet.pCorrect(b),'Color',ones(3,1)*.45,'LineWidth',1.2,'LineStyle','-');     %pBetter
                end
            case 3
                plot(smooth(RunWinMet.pCorrect),'Color',ones(3,1)*.45,'LineWidth',.8,'LineStyle','-','HandleVisibility','off');     %pBetter
                plot(smooth(RunWinMet.ERDS),'Color',animal_color,'LineWidth',.8,'LineStyle','-','HandleVisibility','off');     % ERDS
                for b = 1:numel(this_sess_data.block_indices)
                    thisBlockIdx = this_sess_data.block_indices{b};
                    plot(thisBlockIdx(10+1:end),ones(1,length(thisBlockIdx(10+1:end)))*BlockMet.ERDS(b),'Color',animal_color,'LineWidth',2,'LineStyle','-');     % ERDS
                    plot(thisBlockIdx(10+1:end),ones(1,length(thisBlockIdx(10+1:end)))*BlockMet.pCorrect(b),'Color',ones(3,1)*.45,'LineWidth',2,'LineStyle','-');     %pBetter
                end
        end        
       

        % reward schedules label / block length L label
        L_set = [];
        for r = 1:numel(this_sess_data.block_addresses)-1
            x_mid = (this_sess_data.block_addresses(r)+this_sess_data.block_addresses(r+1))/2;
            L_set(r) = length(this_sess_data.block_indices{r});
        end
       
        cmap = flip(colormap(summer(length(L_set))),1);
        [~,~,ic] = unique(L_set,'sorted');
        L_rank = 1 + max(ic) - ic;
        patch_yPos = 1.02;
        patch_height = 0.08;
        for r = 1:numel(L_set)
            Xv = [this_sess_data.block_indices{r}(1) this_sess_data.block_indices{r}(end) this_sess_data.block_indices{r}(end) this_sess_data.block_indices{r}(1)];
            Yv = [patch_yPos patch_yPos patch_yPos+patch_height patch_yPos+patch_height];
            patch('XData',Xv,'YData',Yv,'FaceColor',cmap(L_rank(r),:),'FaceAlpha',0.5,'EdgeColor','none'); 
            x_mid = (this_sess_data.block_addresses(r)+this_sess_data.block_addresses(r+1))/2;
            text(x_mid,1,[num2str(L_set(r))],'VerticalAlignment','bottom','HorizontalAlignment','center','FontName','Helvetica','FontSize',14,'Color',ones(3,1)*.3);
        end
        
        L = legend({'\it{P}(Better)','ERDS'},'box','off');
        L.Position(1) = .84;
        L.Position(2) = .84;

        % labels
        xlabel("Trials");     % ylabel(["ERDS"]);
        ax = gca;
        ax.YLim = [0 patch_yPos+patch_height];
        ax.Position(1) = 0.17; ax.Position(2) = 0.25;
        ax.Position(3) = 0.8; ax.Position(4) = 0.55;
        ax.XLim(2) = length(this_sess_data.r);
        ax.XTick = [0:100:ax.XLim(2)];
        ax.YTick = [0:.25:1];
        set(gca, 'tickdir', 'out','Box','off');
        set(gca,'FontName','Helvetica','FontSize',20,'FontWeight','normal','LineWidth',3); 
        
    end
    
end