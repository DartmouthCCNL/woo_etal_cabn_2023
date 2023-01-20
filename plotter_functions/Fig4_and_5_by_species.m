function Fig4_and_5_by_species(allOutput, plot_settings, def_versions, animal_colors, gca_fontsize)
    datasets = fieldnames(allOutput);

    Metrics.set = ["pbetter","H_str","ERDS","MIRS","EODS","MIOS"];
    Metrics.labels = ["P(Better)","H(str)","ERDS","MIRS","EODS","MIOS"];
        
    show_stats = 1;
    
    lessUncert_col = ones(1,3)*0.55; 
    
    YLim1 = [0.0, 1.0];
    YLim2 = [0, 0.5];
    
    for d = 1:numel(datasets)
        %% 1. Uncertainty
        def_version = def_versions(1); 
        
        figure((d+3)*1000); clf; 
        set(gcf,'Color','w','Units','normalized','Position',[0.0 0.0 0.56 0.54],'PaperOrientation','landscape');
        dataset_label = datasets{d};
        disp(dataset_label+"====================");
        animal_ids = fieldnames(allOutput.(dataset_label)); 
        for m = 1:numel(Metrics.set)
            if mod(m,2)==1
                S = subplot(2,3,ceil(m/2));
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
            BelAbo_bin{1} = [];     % below median
            BelAbo_bin{2} = [];     % above median
            all_xvar = [];
            for animalcnt = 1:numel(animal_ids)
                animal_id = animal_ids{animalcnt};
                thisAnimal_output = allOutput.(dataset_label).(animal_id);
                
                [u_p, ~] = compute_Uncertainty(thisAnimal_output, def_version);
                if strcmp(def_version,"deltaP")
                    deltaP = u_p';  
                end
                % divide into more/less uncertain (median split)
                if strcmp(def_version,"deltaP")
                    moreUncertain_idx = deltaP<median(deltaP,'omitnan');
                    lessUncertain_idx = deltaP>median(deltaP,'omitnan');
                    all_xvar = [all_xvar; deltaP];
                end
                yy = thisAnimal_output.(MET_name);
                BelAbo_bin{1} = [BelAbo_bin{1}; yy(lessUncertain_idx)];     
                BelAbo_bin{2} = [BelAbo_bin{2}; yy(moreUncertain_idx)];  
            end
            disp("Mean deltaP = "+mean(all_xvar)+", SD = "+std(all_xvar)+"; Median = "+median(all_xvar));

            % bar plots
            for f = 1:2
                allMean(f) = mean(BelAbo_bin{f},'omitnan');
                allMed(f) = median(BelAbo_bin{f},'omitnan');
                allSEM(f) = std(BelAbo_bin{f},'omitnan')/sqrt(sum(~isnan(BelAbo_bin{f})));
                if f==1
                    faceCol = lessUncert_col;  
                    Ori = 'left';                    
                elseif f==2
                    faceCol = animal_colors.(dataset_label);    
                    Ori = 'right';
                end
                if contains(MET_lbl,"MI"); yyaxis right; end
                DistWidth = 0.4;
                al_goodplot(BelAbo_bin{f}, 1.5+mod(m+1,2)*2+mod(m+1,2)*.75, DistWidth*2, faceCol, Ori);
                hold on;
            end
            plot([1 2]+mod(m+1,2)*2+mod(m+1,2)*.75,allMean,':k','marker','none');

            % Significant test: nonparametric          
            disp(MET_lbl+" Less uncertain: M = "+round(mean(BelAbo_bin{1},'omitnan')*1000)/1000+", SD = "+round(std(BelAbo_bin{1},'omitnan')*1000)/1000);
            disp(MET_lbl+" More uncertain: M = "+round(mean(BelAbo_bin{2},'omitnan')*1000)/1000+", SD = "+round(std(BelAbo_bin{2},'omitnan')*1000)/1000);
            
            % nonparametric test        
            [KS_pval, ks2_D, astK] = two_sample_KS_test(BelAbo_bin{1},BelAbo_bin{2}, 2, 'both');
            disp(MET_lbl+" K-S test: D = "+ks2_D+", p = "+KS_pval);
            
            % parametric test
            [T_pval, cohen_D, ~] = two_sample_T_test(BelAbo_bin{1},BelAbo_bin{2}, 2, 'both');
            disp("    T-test2: Cohen's d = "+cohen_D+", p = "+T_pval);

            % significace bar
            ypos = max([BelAbo_bin{1};BelAbo_bin{2}]);
            if contains(MET_lbl,"MI"); ypos = min([ypos, 0.45]); end
            K = text(mean([1 2]+mod(m+1,2)*2+mod(m+1,2)*.75),ypos,astK,'FontSize',gca_fontsize,'VerticalAlignment','bottom','HorizontalAlignment','center'); 
            effect_sizes = ["\it{D} = \rm"+num2str(ks2_D,3),"\it{p} = \rm"+num2str(KS_pval,3)+""];
            if show_stats
                if ~contains(MET_lbl,"MI")
                    xPos = 0.12+mod(m+1,2)*.48;
                    text(xPos,0.25,effect_sizes,'Units','normalized','FontSize',gca_fontsize-1,'HorizontalAlignment','left');
                else
                    xPos = 0.2174;
                    text(xPos,1.5,effect_sizes,'Units','normalized','FontSize',gca_fontsize-1,'HorizontalAlignment','left');
                end
            end

            % metrics label
            if contains(MET_lbl,"MI")
                yyaxis left; 
                text(mean([1 2]+mod(m+1,2)*2+mod(m+1,2)*.75),2.1,MET_lbl,'FontSize',15,'HorizontalAlignment','center','VerticalAlignment','bottom');
            else
                text(mean([1 2]+mod(m+1,2)*2+mod(m+1,2)*.75),1.05,MET_lbl,'FontSize',15,'HorizontalAlignment','center','VerticalAlignment','bottom');
                % panel label
                text(-.2,1.05,char(ceil(m/2)+'A'-1),'Units','normalized','FontWeight','bold','FontSize',18,'FontName','helvetica','VerticalAlignment','bottom');
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
            text(-0.1+1+mod(m+1,2)*2+mod(m+1,2)*.75,-0.015,["Less"],'Color','k','HorizontalAlignment','center','VerticalAlignment','top','FontSize',gca_fontsize,'Rotation',RotVal);
            text(+0.1+2+mod(m+1,2)*2+mod(m+1,2)*.75,-0.015,["More"],'Color','k','HorizontalAlignment','center','VerticalAlignment','top','FontSize',gca_fontsize,'Rotation',RotVal);
                
            set(ax,'FontName','Helvetica','FontSize',gca_fontsize-1,'FontWeight','normal','LineWidth',1,'tickdir','out','Box','off');      
        end
        
        % 2. BLPE
        def_version = def_versions(2);
        
        for m = 1:numel(Metrics.set)
            if mod(m,2)==1
                S = subplot(2,3,3+ceil(m/2));
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
            NegPos_bin{1} = []; % neg
            NegPos_bin{2} = []; % pos
            for animalcnt = 1:numel(animal_ids)
                animal_id = animal_ids{animalcnt};
                thisAnimal_output = allOutput.(dataset_label).(animal_id);
                thisAnimal_blockL = thisAnimal_output.blockL;
                [Expected_L, ~] = compute_BLPE(dataset_label, thisAnimal_blockL, def_version); % BLPE
                if strcmp(dataset_label,'Schultz')&&plot_settings.Schultz>=2
                    currL = thisAnimal_output.allBlockL;
                else
                    currL = thisAnimal_blockL;
                end    
                BLPE = currL' - Expected_L';
                yy = thisAnimal_output.(MET_name);
                NegPos_bin{1} = [NegPos_bin{1}; yy(BLPE<0)];     
                NegPos_bin{2} = [NegPos_bin{2}; yy(BLPE>0)];  
            end

            % violin plots
            for f = 1:2
                allMean(f) = mean(NegPos_bin{f},'omitnan');
                allMed(f) = median(NegPos_bin{f},'omitnan');
                allSEM(f) = std(NegPos_bin{f},'omitnan')/sqrt(sum(~isnan(NegPos_bin{f})));
                if f==1
                    faceCol = ones(1,3)*0.6; %'none';   % BLPE-
                    Ori = 'left';                    
                elseif f==2
                    faceCol = animal_colors.(dataset_label);    % BLPE+
                    Ori = 'right';
                end
                if contains(MET_lbl,"MI"); yyaxis right; end
                al_goodplot(NegPos_bin{f}, 1.5+mod(m+1,2)*2+mod(m+1,2)*.75, 0.5*2, faceCol, Ori);
                hold on;
            end
            plot([1 2]+mod(m+1,2)*2+mod(m+1,2)*.75,allMean,':k','marker','none');

            % Significant test: nonparametric
            [KS_pval, ks2_D, astK] = two_sample_KS_test(NegPos_bin{1},NegPos_bin{2}, 2, 'both');
            disp(MET_lbl+" K-S test: D = "+ks2_D+", p = "+KS_pval);
            
            % parametric test
            [T_pval, cohen_D, ~, stats] = two_sample_T_test(NegPos_bin{1},NegPos_bin{2}, 2, 'both');
            disp("    T-test2: t("+stats.df+") = "+stats.tstat+", Cohen's d = "+cohen_D+", p = "+T_pval);            
            
            % significace bar
            ypos = max([NegPos_bin{1};NegPos_bin{2}]);
            if contains(MET_lbl,"MI"); ypos = min([ypos, 0.5]); end
            K = text(mean([1 2]+mod(m+1,2)*2+mod(m+1,2)*.75),ypos,astK,'FontSize',gca_fontsize,'VerticalAlignment','bottom','HorizontalAlignment','center'); 
            effect_sizes = ["\it{D} = \rm"+num2str(ks2_D,3),"\it{p} = \rm"+num2str(KS_pval,3)+""];
            if show_stats
                if ~contains(MET_lbl,"MI")
                    xPos = 0.12+mod(m+1,2)*.48;
                    text(xPos,0.25,effect_sizes,'Units','normalized','FontSize',gca_fontsize-1,'HorizontalAlignment','left');
                else
                    xPos = 0.2174;
                    text(xPos,1.5,effect_sizes,'Units','normalized','FontSize',gca_fontsize-1,'HorizontalAlignment','left');
                end
            end

            % metrics label
            if contains(MET_lbl,"MI")
                yyaxis left; 
                text(mean([1 2]+mod(m+1,2)*2+mod(m+1,2)*.75),2.1,MET_lbl,'FontSize',15,'HorizontalAlignment','center','VerticalAlignment','bottom');
            else
                text(mean([1 2]+mod(m+1,2)*2+mod(m+1,2)*.75),1.05,MET_lbl,'FontSize',15,'HorizontalAlignment','center','VerticalAlignment','bottom');
                % panel label
                text(-.2,1.05,char(ceil(m/2)+'D'-1),'Units','normalized','FontWeight','bold','FontSize',18,'FontName','helvetica','VerticalAlignment','bottom');
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
            xticks([1,2, 3.75,4.75]);
            if ~contains(MET_lbl,"MI")
                xticklabels(["SE","LE","SE","LE"]);
                xtickangle(30);
            end
            ax.XRuler.TickLabelGapOffset = -4;
            set(ax,'FontName','Helvetica','FontSize',gca_fontsize-1,'FontWeight','normal','LineWidth',1,'tickdir','out','Box','off');      
        end

    end  
    
end