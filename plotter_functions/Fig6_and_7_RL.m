function Fig6_and_7_RL(allOutput, plot_settings, def_versions, animal_colors, gca_fontsize)
    datasets = fieldnames(allOutput);
    
    show_stats = 1;
    show_insets = 1;
    
    lessUncert_col = ones(1,3)*0.4;     % grey
    moreUncert_col = [.05 .48 .86];     %
    
    XTck = [0.5 1.5];
    XLm = [-1 3];
    inset_yFactor = 0.55;

    %% Plot figure for each species
        
    for d = 1:numel(datasets)
        dataset_label = datasets{d};
        disp(dataset_label+"=====================");
        if d==1
            model_to_plot = 2;  % RL1_decay
            beta_lim = 25;
        elseif d==2
            model_to_plot = 1;  % RL1
            beta_lim = 10;
        end
        
        switch model_to_plot
            case 1   
                modelName = 'RW1';  modeLabel = 'RL1';
                param_lbls = ["\alpha","\beta"];
            case 2    
                modelName = 'RW2';  modeLabel = 'RL1_decay';
                param_lbls = ["\alpha","\beta","\gamma_{\it{decay}}"];
            case 3
                modelName = 'RL1';  modeLabel = 'RL2';
                param_lbls = ["\alpha_+","\beta","\alpha_-"];
            case 4             
                modelName = 'RL2';  modeLabel = 'RL2_decay';
                param_lbls = ["\alpha_+","\beta","\alpha_-","\gamma_{\it{decay}}"];
        end
        
        figure(5+d); clf; 
        set(gcf,'Color','w','Units','normalized','Position',[0.0 0.1 0.61 0.54]);
        
        animal_ids = fieldnames(allOutput.(dataset_label));
        
        % plot for each row
        for E = 1:2
            % plot each param
            for p = 1:numel(param_lbls)
                allParams = [];
                subplotNum = p+(E-1)*4;
                SP = subplot(2,4,subplotNum);
                if subplotNum<5
                    SP.Position(2) = SP.Position(2) - 0.01;
                else
                    SP.Position(2) = SP.Position(2) + 0.01;
                end
    
                if contains(modelName,"RL")
                    if p==2; paramNum = 3;
                    elseif p==3; paramNum = 2;
                    else paramNum = p; end
                else
                    paramNum = p;
                end
                % loop through subjects
                NegPos_bin{1} = []; % neg
                NegPos_bin{2} = []; % pos
                LessMore_bin{1} = []; % Less uncertain
                LessMore_bin{2} = []; % More uncertain
                MoreUncertain_NegPos{1} = []; MoreUncertain_NegPos{2} = [];
                LessUncertain_NegPos{1} = []; LessUncertain_NegPos{2} = [];

                for animalcnt = 1:numel(animal_ids)
                    animal_id = animal_ids{animalcnt};
                    thisAnimal_output = allOutput.(dataset_label).(animal_id);
                    thisAnimal_blockL = thisAnimal_output.blockL;

                    yy = cell2mat(thisAnimal_output.(modelName).params);
                    yy = yy(:,paramNum);
                    
                    % 1. BLPE
                    [Expected_L, ~] = compute_BLPE(dataset_label, thisAnimal_blockL, def_versions(1)); % BLPE
                    if strcmp(dataset_label,'Schultz')&&plot_settings.Schultz>=2
                        currL = thisAnimal_output.allBlockL;
                    else
                        currL = thisAnimal_blockL;
                    end    
                    BLPE = currL' - Expected_L';
                    
                    % 2. Uncertainty
                    if contains(def_versions(2),"deltaP")
                        [u_p, ~] = compute_Uncertainty(allOutput.(dataset_label).(animal_ids{animalcnt}), "deltaP");
                        deltaP = u_p';
                    end                  

                    % interaction plot data: median split
                    if strcmp(dataset_label,'Schultz')
                        if contains(def_versions(2),"deltaP")
                            moreUncertain_idx = deltaP<median(deltaP,'omitnan');
                            lessUncertain_idx = deltaP>median(deltaP,'omitnan');
                        end
                    elseif strcmp(dataset_label,'Cohen')
                        % split based on two schedules
                        if contains(def_versions(2),"deltaP")
                            moreUncertain_idx = deltaP<median(deltaP,'omitnan');
                            lessUncertain_idx = deltaP>median(deltaP,'omitnan');
                        end
                    end
                    
                    if E==1
                        LessMore_bin{1} = [LessMore_bin{1}; yy(lessUncertain_idx)];
                        LessMore_bin{2} = [LessMore_bin{2}; yy(moreUncertain_idx)];
                        allParams = [allParams; yy];
                    elseif E==2
                        NegPos_bin{1} = [NegPos_bin{1}; yy(BLPE<0)];     
                    	NegPos_bin{2} = [NegPos_bin{2}; yy(BLPE>0)];
                        MoreUncertain_NegPos{1} = [MoreUncertain_NegPos{1}; yy(BLPE<0&moreUncertain_idx)];
                        MoreUncertain_NegPos{2} = [MoreUncertain_NegPos{2}; yy(BLPE>0&moreUncertain_idx)];
                        LessUncertain_NegPos{1} = [LessUncertain_NegPos{1}; yy(BLPE<0&lessUncertain_idx)];
                        LessUncertain_NegPos{2} = [LessUncertain_NegPos{2}; yy(BLPE>0&lessUncertain_idx)];
                    end
                end
                disp("========"+param_lbls(paramNum)+": M = "+mean(allParams,'omitnan')+", SD = "+std(allParams,'omitnan')+"; Median = "+median(allParams,'omitnan'));

                if E==1
                    bin_to_plot =  LessMore_bin;    % row1: uncertainty
                    disp(param_lbls(p)+" Less uncertain: M = "+round(mean(LessMore_bin{1},'omitnan')*1000)/1000+", SD = "+round(std(LessMore_bin{1},'omitnan')*1000)/1000);
                    disp(param_lbls(p)+" More uncertain: M = "+round(mean(LessMore_bin{2},'omitnan')*1000)/1000+", SD = "+round(std(LessMore_bin{2},'omitnan')*1000)/1000);
                elseif E==2
                    bin_to_plot = NegPos_bin;       % row2: BLPE
                    disp(param_lbls(p)+" BLPE-: M = "+round(mean(NegPos_bin{1},'omitnan')*1000)/1000+", SD = "+round(std(NegPos_bin{1},'omitnan')*1000)/1000);
                    disp(param_lbls(p)+" BLPE+: M = "+round(mean(NegPos_bin{2},'omitnan')*1000)/1000+", SD = "+round(std(NegPos_bin{2},'omitnan')*1000)/1000);
                end
                
                % bar plots
                for f = 1:2
                    allMean(f) = mean(bin_to_plot{f},'omitnan');
                    if f==1
                        Ori = 'left';
                        ViolFaceCol = lessUncert_col;   % BLPE- 
                    elseif f==2
                        if E==1; ViolFaceCol = animal_colors.(dataset_label);   % moreUncert_col
                        elseif E==2; ViolFaceCol = animal_colors.(dataset_label); 
                        end
                        Ori = 'right';
                    end

                    DistWidth = 0.4;
                    if contains(param_lbls(paramNum),"gamma")
                        al_goodplot(bin_to_plot{f}, 1, DistWidth*1, ViolFaceCol, Ori, 0.1);
                    elseif contains(param_lbls(paramNum),"beta")
                        al_goodplot(bin_to_plot{f}, 1, DistWidth*1, ViolFaceCol, Ori, 5);
                    else
                        al_goodplot(bin_to_plot{f}, 1, DistWidth*1, ViolFaceCol, Ori, 0.05);
                    end
                    % interaction data
                    if E==2
                        MoreUncertain_Mean(f) = mean(MoreUncertain_NegPos{f},'omitnan');
                        MoreUncertain_SEM(f) = std(MoreUncertain_NegPos{f},'omitnan')/sqrt(sum(~isnan(MoreUncertain_NegPos{f})));
                        LessUncertain_Mean(f) = mean(LessUncertain_NegPos{f},'omitnan');
                        LessUncertain_SEM(f) = std(LessUncertain_NegPos{f},'omitnan')/sqrt(sum(~isnan(LessUncertain_NegPos{f})));
                    end
                end
                hold on;
                plot(1.+[-.2 +.2],allMean,':k','marker','none');
                [KS_pval, ks2_D, astK] = two_sample_KS_test(bin_to_plot{1},bin_to_plot{2}, numel(param_lbls), 'both');
                ypos = 1;
                if contains(param_lbls(paramNum),"beta"); ypos = 100; end
                K = text(1,ypos,astK,'FontSize',gca_fontsize,'VerticalAlignment','bottom','HorizontalAlignment','center'); 
                if show_stats
                    effect_sizes = ["\it{D} = \rm"+num2str(round(ks2_D*1000)/1000,3),"\it{p} = \rm"+num2str(KS_pval,3)+""];
                    text(0.05,0.75,effect_sizes,'Units','normalized','FontSize',gca_fontsize-2,'HorizontalAlignment','left');
                end

                % axis settings
                xticks(XTck); xticklabels([]);
                ax = gca;
                if E==1
                    xLbl = {["Less"],["More"]};
                elseif E==2
                    xLbl = {["SE"],["LE"]};
                end
                ax.XTickLabel = xLbl;
                xticklabels(xLbl); xtickangle(30);
                ax.XRuler.TickLabelGapOffset = -4;
                text(0.05,1,param_lbls(paramNum),'FontSize',18,'Units','normalized','HorizontalAlignment','left','VerticalAlignment','middle');
                ylim([0 1]);
                xlim(XLm);
                yticks(0:0.25:1);
                if strcmp(param_lbls(paramNum),"\beta"); ylim([0 100]); yticks(0:25:100); end
                set(ax,'FontName','Helvetica','FontSize',gca_fontsize,'FontWeight','normal','LineWidth',1,'tickdir', 'out','Box','off');      

                % panel label
                text(-.25,1.05,char(p+(E-1)*numel(param_lbls)+'A'-1),'Units','normalized','FontWeight','bold','FontSize',18,'FontName','helvetica','VerticalAlignment','bottom');

                if E==2&&show_insets
                    % inset showing interaction effects
                    ax2 = axes('Position',[SP.Position(1)+SP.Position(3)*.68, SP.Position(2)+SP.Position(4)*inset_yFactor, SP.Position(3)*.25, SP.Position(4)*0.3],'box','off','tickdir','out');
                    ax2.YAxis(1).Visible = 'off';
                    yyaxis right
                    ax2.YAxis(2).Color = 'k';
                    boxchart(categorical(1*ones(length(LessUncertain_NegPos{1}),1)),LessUncertain_NegPos{1},'BoxFaceColor',lessUncert_col,'BoxFaceAlpha',0,'WhiskerLineColor',lessUncert_col,'MarkerStyle','.','MarkerColor',lessUncert_col); 
                    hold on
                    boxchart(categorical(2*ones(length(LessUncertain_NegPos{2}),1)),LessUncertain_NegPos{2},'BoxFaceColor',lessUncert_col,'BoxFaceAlpha',0.7,'WhiskerLineColor',lessUncert_col,'MarkerStyle','.','MarkerColor',lessUncert_col);
                    boxchart(categorical(3*ones(length(MoreUncertain_NegPos{1}),1)),MoreUncertain_NegPos{1},'BoxFaceColor',moreUncert_col,'BoxFaceAlpha',0,'WhiskerLineColor',moreUncert_col,'MarkerStyle','.','MarkerColor',moreUncert_col);
                    boxchart(categorical(4*ones(length(MoreUncertain_NegPos{2}),1)),MoreUncertain_NegPos{2},'BoxFaceColor',moreUncert_col,'BoxFaceAlpha',0.7,'WhiskerLineColor',moreUncert_col,'MarkerStyle','.','MarkerColor',moreUncert_col);

                    % axis settings
                    xticklabels(["-","+","-","+"]);
                    ax2.YTick = [0:0.5:1.0];
                    if strcmp(param_lbls(paramNum),"\beta"); ax2.YLim = [0 beta_lim]; ax2.YTick = [0:10:beta_lim]; end
                    ax2.XTickLabelRotation = 0;
                        RotVal = 20;
                        multFact = 1; %if strcmp(param_lbls(paramNum),"\beta"); multFact = beta_lim; end
                        text(0.0,-.15*multFact,["less"],'Color',lessUncert_col,'Units','normalized','HorizontalAlignment','center','VerticalAlignment','top','FontSize',gca_fontsize-1,'Rotation',RotVal);
                        text(0.0,-.35*multFact,["  uncert."],'Color',lessUncert_col,'Units','normalized','HorizontalAlignment','center','VerticalAlignment','top','FontSize',gca_fontsize-1,'Rotation',RotVal);
                        text(0.9,-.15*multFact,["more"],'Color',moreUncert_col,'Units','normalized','HorizontalAlignment','center','VerticalAlignment','top','FontSize',gca_fontsize-1,'Rotation',RotVal);
                        text(0.9,-.35*multFact,[" uncert."],'Color',moreUncert_col,'Units','normalized','HorizontalAlignment','center','VerticalAlignment','top','FontSize',gca_fontsize-1,'Rotation',RotVal);
                   
                    ax2.XRuler.TickLabelGapOffset = -4;
                    
                    % K-S test
                    [KS_pval, ks2_D, astK] = two_sample_KS_test(LessUncertain_NegPos{1},LessUncertain_NegPos{2}, numel(param_lbls)*2, 'both');
                    disp(param_lbls(p)+" BLPE in Less: D = "+round(ks2_D*1000)/1000+", p-val = "+KS_pval);
                    if strcmp(astK,""); astK = "n.s"; end
                    text(1.5, ax2.YLim(2),astK,'FontSize',gca_fontsize-2,'VerticalAlignment','bottom','HorizontalAlignment','center','Color',lessUncert_col);
                    
                    % T-test (parametric)
                    [tpv1, D, ~, stats] = two_sample_T_test(LessUncertain_NegPos{1},LessUncertain_NegPos{2}, numel(param_lbls)*2, 'both');
                    disp("              : t("+stats.df+") = "+stats.tstat+", Cohen's d = "+round(D*1000)/1000+", p-val = "+tpv1);
                    
                    [KS_pval, ks2_D, astK] = two_sample_KS_test(MoreUncertain_NegPos{1},MoreUncertain_NegPos{2}, numel(param_lbls)*2, 'both');
                    disp(param_lbls(p)+" BLPE in More: D = "+round(ks2_D*1000)/1000+", p-val = "+KS_pval);
                    if strcmp(astK,""); astK = "n.s"; end
                    text(3.5, ax2.YLim(2),astK,'FontSize',gca_fontsize-2,'VerticalAlignment','bottom','HorizontalAlignment','center','Color',moreUncert_col); 
                    
                    % T-test (parametric)
                    [tpv1, D, ~, stats] = two_sample_T_test(MoreUncertain_NegPos{1},MoreUncertain_NegPos{2}, numel(param_lbls)*2, 'both');
                    disp("              : t("+stats.df+") = "+stats.tstat+", Cohen's d = "+round(D*1000)/1000+", p-val = "+tpv1);
                    
                    set(ax2,'FontName','Helvetica','FontSize',gca_fontsize-2,'FontWeight','normal','LineWidth',1,'tickdir', 'out','Box','off');
                end 
            end
        end
    end
end