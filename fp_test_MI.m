function fp_test_MI
%test motor imagery left vs right

DIRIN = '~/Dropbox/Franziska/PAC_AAC_estimation/data/RDE/bispectra/';

DIRFIG = '~/Dropbox/Franziska/PAC_AAC_estimation/RDE_figures/';

%subjects with high performance classification
subs = [3 4 5 8 9 11 12 14 15 16 17 18 19 21 22 23 25 27 28 29 30 31 33 34 35 37];
%%
isb = 1;
for isub = subs
    
    sub = ['vp' num2str(isub)];
    load([DIRIN sub '_PAC.mat'])
    
    BOR(isb,:,:,:,:)=bor;
    BOL(isb,:,:,:,:)=bol;
    BAR(isb,:,:,:,:)=bar;
    BAL(isb,:,:,:,:)=bal;
    isb = isb+1;
    
end

%%
fp_plot_pac(DIRFIG,BOL,BAL,'left_norm')
fp_plot_pac(DIRFIG,BOR,BAR,'right_norm')

%%
pa = nan(size(squeeze(BAL(1,:,:,:,:))));
ta = nan(size(squeeze(BAL(1,:,:,:,:))));
po = nan(size(squeeze(BAL(1,:,:,:,:))));
to = nan(size(squeeze(BAL(1,:,:,:,:))));

nroi = size(BAR,4);
for ifq = 1:size(BAR,2)
    for jfq =ifq+1:size(BAR,3)
        if ifq+jfq < size(BAR,3)
            for iroi=1:nroi
                for jroi = 1:nroi
                    
                    %                     [~, po(ifq,jfq,iroi,jroi), ~, stats] ...
                    %                         = ttest(squeeze(BOR(:,ifq,jfq,iroi,jroi)),squeeze(BOL(:,ifq,jfq,iroi,jroi)),...
                    %                         'alpha',0.05);
                    %                     to(ifq,jfq,iroi,jroi) = sign(stats.tstat);
                    %
                    %                     [~, pa(ifq,jfq,iroi,jroi), ~, stats] ...
                    %                         = ttest(squeeze(BAR(:,ifq,jfq,iroi,jroi)),squeeze(BAL(:,ifq,jfq,iroi,jroi)),...
                    %                         'alpha',0.05);
                    %                     ta(ifq,jfq,iroi,jroi) = sign(stats.tstat);
                    
                    [po(ifq,jfq,iroi,jroi), ~, stats] ...
                        = signrank(squeeze(BOL(:,ifq,jfq,iroi,jroi)),squeeze(BOR(:,ifq,jfq,iroi,jroi)),...
                        'alpha',0.05);
                    
                    to(ifq,jfq,iroi,jroi) = sign(stats.zval);
                    
                    [pa(ifq,jfq,iroi,jroi), ~, stats] ...
                        = signrank(squeeze(BAL(:,ifq,jfq,iroi,jroi)),squeeze(BAR(:,ifq,jfq,iroi,jroi)),...
                        'alpha',0.05);
                    ta(ifq,jfq,iroi,jroi) = sign(stats.zval);
                    
                end
            end
        end
    end
end

%%
fp_plot_pac_pvals(DIRFIG,po,pa,to,ta)
