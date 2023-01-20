function [tpv1, cohen_d, astT, stats] = paired_sample_T_test(Sample1, Sample2, multcomp, tail_type)
    % parametric test
    [~,tpv1,~,stats] = ttest(Sample1, Sample2,'tail',tail_type); 
    cohen_d = computeCohen_d(Sample1, Sample2, 'paired');
    
    astT = "";
%     astT = "n.s.";
    if tpv1<.05/multcomp; astT = "∗";
%         if tpv1 <.01/multcomp; astT = "∗∗"; 
%             if tpv1<.001/multcomp; astT = "∗∗∗"; end; end
    end
end