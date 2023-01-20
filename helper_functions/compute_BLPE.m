function [Expected_L, def_label] = compute_BLPE(dataset_label, thisAnimal_blockL, def_version, gammaE)

    N_size = 4; % default N value
    if contains(def_version,"pastN")
        ch = convertStringsToChars(def_version);
        N_size = str2double(ch(regexp(ch,'\d')));
    end
    if contains(def_version,"gammaE")&&~strcmp(def_version,"gammaE")
        ch = convertStringsToChars(def_version);
        gammaE = str2double(ch(regexp(ch,'\.')-1:end));
    end
    
    % initialize
    thisAnimal_blockNum = length(thisAnimal_blockL);
    Median_allL = nan(1,thisAnimal_blockNum);
    Mean_pastN = nan(1,thisAnimal_blockNum);
    gammaE_based = nan(1,thisAnimal_blockNum);
    
    % initialized with mean/median L
    if strcmp(dataset_label,'Cohen')
        gammaE_based(1) = 54;       % median blocks for mice
    elseif strcmp(dataset_label,'Schultz')
        gammaE_based(1) = 51;       % median blocks for monkeys
    end
    
    % loop through all block L
    for i = 2:thisAnimal_blockNum
        Median_allL(i) = median(thisAnimal_blockL(1:i-1),'omitnan');
        Mean_pastN(i) = mean(thisAnimal_blockL(max(i-N_size,1):i-1),'omitnan');
        
        if contains(def_version,"gammaE")
            if isnan(gammaE_based(i-1)) 
                gammaE_based(i) = thisAnimal_blockL(i-1); % first block w/o any previous experience for the day
            else
                gammaE_based(i) = gammaE_based(i-1) + gammaE*(thisAnimal_blockL(i-1)-gammaE_based(i-1));
            end
            if isnan(thisAnimal_blockL(i-1))
                gammaE_based(i) = gammaE_based(i-1);
            end
        end
    end

    % assign output
    if strcmp(def_version,"allL")
        Expected_L = Median_allL;
        def_label = '$E[l_i] = med\left\{l_1,l_2,...,l_{i-1} \right\}$';
    elseif contains(def_version,"pastN")
        Expected_L = Mean_pastN;
        def_label = "$E[l_i]_{N="+N_size+"} = \frac{1}{N}\sum_{j=i-N}^{i-1}{l_j}$";
    elseif contains(def_version,"gammaE")
        Expected_L = gammaE_based;
        def_label = "$E[l_{i+1}]_{\gamma_E="+gammaE+"} = E[l_i] + \gamma_E(l_i - E[l_i])$";
    end
end