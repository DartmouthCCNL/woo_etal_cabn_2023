function Fig3_BeforeAfter_reversal(trial_length, plot_settings, animal_colors, gca_fontsize)
    datasets = {'Cohen','Schultz'};

    Metrics.set = ["pbetter","H_str","ERDS","MIRS","EODS","MIOS"];
    Metrics.labels = ["P(Better)","H(str)","ERDS","MIRS","EODS","MIOS"];
    
    show_stats = 1; 
    show_insets = 1;
    
    N_sided_test = 2;
    multComp = 2;
    
    histColor = [.05 .48 .86];
    
    %% Load output
    
    beforeLOutput = struct;
    afterLOutput = struct;
    for d = 1:numel(datasets)
        dataset_label = datasets{d};
        fname = "output\"+dataset_label+plot_settings.(dataset_label)+"_BeforeAfterL_EL_gammaE0.10_N"+trial_length+".mat";
        load(fname,'new_output');
        animal_ids = fieldnames(new_output.actualL.before);
        for animalcnt = 1:numel(animal_ids)
            animal_id = animal_ids{animalcnt};
            beforeLOutput.(dataset_label).(animal_id) = new_output.actualL.before.(animal_id);
            afterLOutput.(dataset_label).(animal_id) = new_output.actualL.after.(animal_id);
        end
    end    
    
    %% Violin box plot: Before & After block reversals
    YLim1 = [0.0, 1.0];
    YLim2 = [0, 0.6];
    
    for d = 1:numel(datasets)
        figure(20+d); clf; 
        set(gcf,'Color','w','Units','normalized','Position',[0.0 0.9-0.4*d 0.56 0.28],'PaperOrientation','landscape');
        dataset_label = datasets{d};
        disp(dataset_label+"==========");
        animal_ids = fieldnames(beforeLOutput.(dataset_label)); 
        
        beforeRev_col = ones(1,3)*0.5; %"#FFC325";
        afterRev_col = animal_colors.(dataset_label); %"#0C7BDC"; 
        
        for m = 1:numel(Metrics.set)
            if mod(m,2)==1
                S = subplot(1,3,ceil(m/2));
                S.Position(2) = 0.15; 
                S.Position(4) = 0.7; 
            end
            MET_name = Metrics.set(m); 
            MET_lbl = Metrics.labels(m); 

            % MI: smaller Y-axis
            if contains(MET_lbl,"MI")
                ax2 = axes('Position',[S.Position(1)+S.Position(3)/2, S.Position(2), S.Position(3)/2, S.Position(4)/2],'box','off','tickdir','out');
                ax2.YAxis(1).Visible = 'off';
                yyaxis right
                ax2.XTick = [3.75, 4.75];
                ax2.XTickLabel = [];
            end

            % loop through subjects
            BeforeAfter_bin{1} = [];     % before rev.
            BeforeAfter_bin{2} = [];     % after rev.
            for animalcnt = 1:numel(animal_ids)
                animal_id = animal_ids{animalcnt};
                thisAnimal_output_beforeL = beforeLOutput.(dataset_label).(animal_id);
                thisAnimal_output_afterL = afterLOutput.(dataset_label).(animal_id);
                
                yy1 = thisAnimal_output_beforeL.(MET_name);
                yy2 = thisAnimal_output_afterL.(MET_name);
                
                BeforeAfter_bin{1} = [BeforeAfter_bin{1}; yy1];     
                BeforeAfter_bin{2} = [BeforeAfter_bin{2}; yy2];  
            end

            % bar plots
            if m==2; axes(ax); end
            for f = 1:2
                allMean(f) = mean(BeforeAfter_bin{f},'omitnan');
                allMed(f) = median(BeforeAfter_bin{f},'omitnan');
                allSEM(f) = std(BeforeAfter_bin{f},'omitnan')/sqrt(sum(~isnan(BeforeAfter_bin{f})));
                if f==1
                    faceCol = beforeRev_col; %'none';   % 
                    Ori = 'left';                    
                elseif f==2
                    faceCol = afterRev_col;    %
                    Ori = 'right';
                end
                if contains(MET_lbl,"MI"); yyaxis right; end
                DistWidth = 0.4;
                al_goodplot(BeforeAfter_bin{f}, 1.5+mod(m+1,2)*2+mod(m+1,2)*.75, DistWidth*2, faceCol, Ori);
                hold on;
            end
            disp(MET_lbl+" Before: M = "+round(mean(BeforeAfter_bin{1},'omitnan')*1000)/1000+", SD = "+round(std(BeforeAfter_bin{1},'omitnan')*1000)/1000);
            disp(MET_lbl+" After: M = "+round(mean(BeforeAfter_bin{2},'omitnan')*1000)/1000+", SD = "+round(std(BeforeAfter_bin{2},'omitnan')*1000)/1000);
            plot([1 2]+mod(m+1,2)*2+mod(m+1,2)*.75,allMean,':k','marker','none');

            % Significant test: nonparametric
            if N_sided_test==1
                if contains(MET_name,"DS")||contains(MET_name,"H_")
                    % hypothesize the entropies to be larger for target category
                    tail_dir = 'left';
                elseif contains(MET_name,"MI")||strcmp(MET_name,"pbetter")
                    % hypothesize the mutual info & performace to be smaller for target category
                    tail_dir = 'right';
                else
                    % e.g., pBetter tests only for significant difference
                    tail_dir = 'both';
                end
            else
                tail_dir = 'both';
            end
            
            % significace bar
            if contains(MET_name,"MI"); ypos = min(YLim2(2), max([BeforeAfter_bin{1};BeforeAfter_bin{2}])); if d==1; ypos = 0.5; end; end
            
            % metrics label
            if contains(MET_lbl,"MI")
                yyaxis left; 
                text(mean([1 2]+mod(m+1,2)*2+mod(m+1,2)*.75),2.1,MET_lbl,'FontSize',15,'HorizontalAlignment','center','VerticalAlignment','bottom');
            else
                text(mean([1 2]+mod(m+1,2)*2+mod(m+1,2)*.75),1.05,MET_lbl,'FontSize',15,'HorizontalAlignment','center','VerticalAlignment','bottom');
                % panel label
                text(-.2,1.05,char(ceil(m/2)+'A'-1+(d-1)*3),'Units','normalized','FontWeight','bold','FontSize',18,'FontName','helvetica','VerticalAlignment','bottom');
            end
            if contains(MET_lbl,"MI"); yyaxis right; end

            % axis settings
            ax = gca;
            ax.XLim = [0 5.75]; 
            ax.YLim = YLim1;    
            if contains(MET_lbl,"MI")
                ax.YColor = 'k';
                ax.XLim = [5.75/2 5.75];
                ax.YLim = YLim2;            
            end
            xticks([1,2, 3.75,4.75]); xticklabels([]);

            RotVal = 20;
            text(-0.1+1+mod(m+1,2)*2+mod(m+1,2)*.75,-0.03,["Before"],'Color','k','HorizontalAlignment','center','VerticalAlignment','top','FontSize',gca_fontsize,'Rotation',RotVal);
            text(+0.1+2+mod(m+1,2)*2+mod(m+1,2)*.75,-0.03,["After"],'Color','k','HorizontalAlignment','center','VerticalAlignment','top','FontSize',gca_fontsize,'Rotation',RotVal);

            set(ax,'FontName','Helvetica','FontSize',gca_fontsize-1,'FontWeight','normal','LineWidth',1,'tickdir','out','Box','off'); 

            % inset showing histogram of paired delta (before - after)
            if show_insets
                if mod(m,2)==1
                    ax_insets{m} = axes('Position',[S.Position(1)+(0.35-0.05*(d-1))*S.Position(3), S.Position(2)+S.Position(4)*(0.07+mod(d,2)*0.03), S.Position(3)*.2, S.Position(4)*.2],'box','on','tickdir','out');
                elseif m==2
                    ax_insets{m} = axes('Position',[S.Position(1)+0.85*S.Position(3), S.Position(2)+S.Position(4)*(0.07+mod(d,2)*0.03), S.Position(3)*.2, S.Position(4)*.2],'box','on','tickdir','out');
                else
                    ax_insets{m} = axes('Position',[S.Position(1)+0.75*S.Position(3), S.Position(2)+S.Position(4)*0.62, S.Position(3)*.2, S.Position(4)*.2],'box','on','tickdir','out');
                end
                histogram(BeforeAfter_bin{1} - BeforeAfter_bin{2},[-1:0.1:1],'FaceColor',histColor); hold on
                mu = mean(BeforeAfter_bin{1} - BeforeAfter_bin{2},'omitnan');
                
                % paired sample T-test
                [tpv1, cohen_d, astT, stats] = paired_sample_T_test(BeforeAfter_bin{1},BeforeAfter_bin{2}, multComp, tail_dir);
                disp("Paired sample T-test: t("+stats.df+") = "+round(stats.tstat*100)/100+", p = "+ tpv1); % if strcmp(astT,"n.s."); astT  = ""; end
                text(mu,ax_insets{m}.YLim(2),astT,'FontSize',gca_fontsize-1,'Color',histColor,'HorizontalAlignment','center','VerticalAlignment','bottom');
                ax_insets{m}.YTick = [];
                ax_insets{m}.XLim = [-1 1];
    
                if show_stats
                    effect_sizes = ["\it{d} = \rm"+num2str(round(cohen_d*1000)/1000,3),"\it{p} = \rm"+num2str(tpv1,3)];
                    text(0, 1*1.25,effect_sizes,'Units','normalized','FontSize',gca_fontsize-2,'Color',histColor,'HorizontalAlignment','left','VerticalAlignment','bottom');
                end
            end
            
            % animal picture
            if m==2
                axes('Position',[S.Position(1)+0.01, S.Position(2)+S.Position(4)*0.05, S.Position(3)*.15, S.Position(4)*.15],'box','off','tickdir','out');
                imshow("output\figures\"+dataset_label+".png");
            end
        end
        
        if show_insets
            for m = 1:numel(Metrics.set)
                axes(ax_insets{m}); % show insets
                set(ax_insets{m},'FontName','Helvetica','FontSize',gca_fontsize/2,'FontWeight','normal','LineWidth',.5,'tickdir','out','Box','off');
            end
        end
        
    end  
    
    %% G-J: Running averages
    
    run_windows.before = trial_length;
    run_windows.after = trial_length;
    
    output_settings = 4;    % bootstrapping
    numSample = 10000;
    Conf_Interval = 95;
    
    figure_size_option = 1;
    
    figure(23); 
    set(gcf,'PaperOrientation','landscape','PaperSize',[12, 6.5]);  
    switch figure_size_option
        case 1
            set(gcf,'Color','w','Units','normalized','Position',[0 1-d*0.4 .56 .21]);  % copy to ppt
            x_margin = 0.13;
            SP_width = 0.15;    SP_gap = 0.21;
            fontsize_plus = 0;
            panel_xPos = -0.20; horAl = 'right';
        case 2
            set(gcf,'Color','w','Units','normalized','Position',[0 1-d*0.4 .56 .25]);    % save as pdf
            x_margin = 0.05;
            SP_width = 0.18; SP_gap = 0.25;
            fontsize_plus = 1;
            panel_xPos = -0.25; horAl = 'left';
            
    end
    
    gap_length = "                ";
    additional_gap = "";
    
    runAvg = struct;
    for d = 1:numel(datasets)
        dataset_label = datasets{d};
        plot_setting_v = plot_settings.(dataset_label);        
        runAvg_fname = ["output/behavior/"+dataset_label+"_raw_runAvg"+trial_length+"-"+trial_length+"_output"+plot_setting_v+"_func"+output_settings+"_N"+numSample];
        if output_settings==3&&trial_length~=20
            runAvg_fname = ["output/behavior/"+dataset_label+"_raw_runAvg"+20+"-"+20+"_output"+plot_setting_v+"_func"+output_settings+"_N"+numSample];
        end
        load([runAvg_fname+".mat"],'runningAvg_output');
        disp("File loaded: "+runAvg_fname+".mat");
        runAvg.(dataset_label) = runningAvg_output;
    end        
        
    % Plot both dataset
    for m = 1:numel(Metrics.set) 
        %% plot for each metric
        MET_name = Metrics.set(m);
        MET_lbl = Metrics.labels(m);

        SPnum = m;
        if strcmp(MET_lbl,"MIRS")
            SPnum = 3; 
        elseif strcmp(MET_lbl,"EODS")||strcmp(MET_lbl,"MIOS")
            SPnum = 4; 
        end
        if ~contains(MET_lbl,"MI")
            SP = subplot(1,4,SPnum); hold on;
            SP.Position(1) = x_margin +(SPnum-1)*SP_gap; % gap b/w subplots
            SP.Position(2) = 0.2;  % y_pos
            SP.Position(3) = SP_width;  % width
            SP.Position(4) = 0.67;  % height
        end
        
        for d = 1:numel(datasets)
            dataset_label = datasets{d};
            runningAvg_output = runAvg.(dataset_label);
            
            % initialize value bins
            YY_cat1 = struct;
            YY_cat1.before = []; YY_cat1.after = [];

            % loop through each animal and compile metrics
            animal_ids = setdiff(fieldnames(runningAvg_output.before),{'CI_80','CI_90','CI_95'});
            for animalcnt = 1:numel(animal_ids)
                animal_id = animal_ids{animalcnt};
                yy = struct;
                for timepoint = ["before","after"]
                    if ~isfield(runningAvg_output.(timepoint).(animal_id), "raw"); continue; end
                    % each session metrics
                    yy.(timepoint).cat1 = cell2mat(runningAvg_output.(timepoint).(animal_id).raw.(MET_name)');
                    if output_settings==3&&trial_length~=20
                        switch timepoint
                            case "before"
                                yy.(timepoint).cat1 = yy.(timepoint).cat1(:,end-trial_length+1:end);
                            case "after" 
                                yy.(timepoint).cat1 = yy.(timepoint).cat1(:,1:trial_length);
                        end
                    end
                    YY_cat1.(timepoint) = [YY_cat1.(timepoint); yy.(timepoint).cat1];
                end         
            end

            % plot for each category
            % Category 1: negative BLPE
            meanYY1_before = mean(YY_cat1.before,1, 'omitnan');     %disp(MET_lbl+": BLPE- before "+mean(meanYY1_before));
            meanYY1_after = mean(YY_cat1.after,1, 'omitnan');
            meanYY1 = [meanYY1_before,meanYY1_after];   
            all_trials{d} = meanYY1;
            
            if output_settings~=4
                semYY1_before = std(YY_cat1.before,1, 'omitnan')./sqrt(sum(~isnan(YY_cat1.before)));
                semYY1_after = std(YY_cat1.after,1, 'omitnan')./sqrt(sum(~isnan(YY_cat1.after)));
                semYY1 = [semYY1_before, semYY1_after]; 
                if size(YY_cat1.before,1)==1; semYY1 = nan(size(meanYY1)); end
                shadedErrorBar([1:length(meanYY1)], meanYY1, semYY1, 'lineProps',{'LineWidth',1.5,'LineStyle','-','Color',animal_colors.(dataset_label)});
            else
                semYY1_before = cell2mat(runningAvg_output.before.("CI_"+Conf_Interval).raw.(MET_name)');
                semYY1_after = cell2mat(runningAvg_output.after.("CI_"+Conf_Interval).raw.(MET_name)');
                CI_nn = [semYY1_before, semYY1_after];
                CI_neg = abs(CI_nn(1,:));
                CI_pos = CI_nn(2,:);
                shadedErrorBar([1:length(meanYY1)], meanYY1, [CI_pos; CI_neg], 'lineProps',{'LineWidth',1.5,'LineStyle','-','Color',animal_colors.(dataset_label)});
            end
        
            % reversal line
            R = xline(run_windows.before+1);
            R.LineStyle = ':';
            R.LineWidth = 2;
            R.Color = ones(3,1)*.5;
            R.HandleVisibility = 'off';

            ax = gca;
            ax.XLim = [1, length(meanYY1)+1];
            ax.XTick = [1:5:length(meanYY1)+1];
            ax.XTickLabel = [-run_windows.before:5:run_windows.after+1];
            ax.YLim = [0 1];
            ax.YTick = [0:0.2:1];
            
            xlabel("Trials from block switch"); 
            MET_xPos = 0.05; MET_fontSz = 14;
            if SPnum==1
                l = legend(["Mice","Monkeys"],'box','off','Location','northeast','FontSize',gca_fontsize-2);                
                l.Position(1) = l.Position(1) + 0.02;
                l.Position(2) = l.Position(2) + 0.1;
                text(MET_xPos, 0.1, MET_lbl, 'Units','normalized','FontSize',MET_fontSz,'HorizontalAlignment','left','VerticalAlignment','bottom');
            elseif SPnum==2
                text(MET_xPos, 0.1, MET_lbl, 'Units','normalized','FontSize',MET_fontSz,'HorizontalAlignment','left','VerticalAlignment','bottom');
            elseif SPnum==3
                text(MET_xPos, 0.95, "ERDS", 'Units','normalized','FontSize',MET_fontSz,'HorizontalAlignment','left','VerticalAlignment','bottom');
                text(MET_xPos, 0.3, "MIRS", 'Units','normalized','FontSize',MET_fontSz,'HorizontalAlignment','left','VerticalAlignment','bottom');                
            elseif SPnum==4
                text(MET_xPos, 0.95, "EODS", 'Units','normalized','FontSize',MET_fontSz,'HorizontalAlignment','left','VerticalAlignment','bottom');
                text(MET_xPos, 0.3, "MIOS", 'Units','normalized','FontSize',MET_fontSz,'HorizontalAlignment','left','VerticalAlignment','bottom');
            end
            set(gca,'FontName','Helvetica','FontSize',gca_fontsize-1,'FontWeight','normal','LineWidth',1,'tickdir', 'out','Box','off');
            
            text(panel_xPos,1.0,char(SPnum+'G'-1),'Units','normalized','FontWeight','bold','FontSize',18+fontsize_plus,'FontName','helvetica','HorizontalAlignment',horAl,'VerticalAlignment','bottom');
        end
        
%         % stats on running average metrics
%         disp("-----------------------------");
%         disp(MET_lbl+" mean shown: mice = "+mean(all_trials{1})+" / monkeys = "+mean(all_trials{2}));
%         [tpv1, D, ~, stats] = two_sample_T_test(all_trials{1},all_trials{2},1,'both');
%         disp("Two-sample sample T-test: t("+stats.df+") = "+round(stats.tstat*100)/100+", p = "+ tpv1+"; Cohen's d = "+D);
%         [paired_p, paired_d, ~, stats] = paired_sample_T_test(all_trials{1},all_trials{2},1,'both');
%         disp("Paired sample T-test: t("+stats.df+") = "+round(stats.tstat*100)/100+", p = "+ paired_p+"; Cohen's d = "+paired_d);
        
    end    
    
end