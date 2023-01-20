function [u_p, def_label] = compute_Uncertainty(thisAnimal_output, def_version)

    thisAnimal_blockProbs = thisAnimal_output.blockProb;
    thisAnimal_blockNum = size(thisAnimal_blockProbs,1);
    H_p = nan(1,thisAnimal_blockNum);
    deltaP = nan(1,thisAnimal_blockNum);
    
    for i = 1:thisAnimal_blockNum
        p1 = thisAnimal_blockProbs(i,1);
        p2 = thisAnimal_blockProbs(i,2);
        H_p(i) = -(p1*log2(p1) + p2*log2(p2));
        deltaP(i) = abs(p1 - p2);
    end
    
    if strcmp(def_version,"entropy")
        u_p = H_p;
        def_label = '$H(p_i) = -\sum_{i=1}^{2}p_i\log_2{p_i}$';
    elseif strcmp(def_version,"deltaP")
        u_p = deltaP;
        def_label = '$\Delta P = p_B - p_W$';
    else
        error("Set correct definition type");
    end
end
