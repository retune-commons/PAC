function [pm] = fp_pr_pac(cc,iroi_amplt,iroi_phase)

%number of interactions 
nints = numel(iroi_phase);
%number of regions 
nroi = size(cc,1);

%true labels 
label= zeros(nroi,nroi);
for iint = 1:numel(iroi_phase)
    label(iroi_amplt(iint),iroi_phase(iint)) = 1;
end

lab = label(:);
tr = find(lab==1); %index of true label 

%estimated scores 
[~, idx] = sort(cc(:),'descend');

%rank of estimated scores 
for it = 1:numel(tr)
    r1(it) = find(idx==tr(it));
end



%% percentage rank

pm = mean(1 - (r1 ./ numel(lab)));

for it = 1:nints
    perfectPm(it) = 1 - (it / numel(lab));
    noSkillPm(it) = 1 - (numel(lab)-it+1)/numel(lab);
end

perfectPm = mean(perfectPm);
noSkillPm = mean(noSkillPm);

pm = (pm-noSkillPm)/(perfectPm-noSkillPm);


