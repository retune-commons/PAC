function fp_plot_pac_snr

addpath(genpath('~/Dropbox/Franziska/PAC_AAC_estimation/data/'))
DIRDATA = '~/Dropbox/Franziska/PAC_AAC_estimation/data/sim3/';
DIRFIG = '~/Dropbox/Franziska/PAC_AAC_estimation/figures/sim3/';
if ~exist(DIRFIG); mkdir(DIRFIG); end

%%
clear PR

titles = {'-7.4 dB','0 dB','19.1 dB'};
mets = {'Tort','Ortho','Borig','Banti','Borignorm','Bantinorm','Shah'};

for isnr = [1 0 2]
    
    if isnr ==0 
        ip = 1;  
        isnr1 = 1;
        isnr2 = 2; 
    else 
        ip = 3;
        isnr1 = isnr;
        if isnr == 2
            isnr2 = 3; 
        else 
            isnr2 = 1; 
        end
    end 
    params = fp_get_params_pac(ip);
    
    for iit= [1:100]
        
        %     try
        if params.case == 1
            inname = sprintf('pr_univar_iInt%d_iReg%d_snr0%d_iss0%d_filt%s_pip%d_iter%d'...
                ,params.iInt,params.iReg,params.isnr(isnr1)*10,params.iss*10,params.ifilt,params.t,iit);
        elseif params.case == 2
            inname = sprintf('pr_bivar_iInt%d_iReg%d_snr0%d_iss0%d_filt%s_pip%d_iter%d'...
                ,params.iInt,params.iReg,params.isnr(isnr1)*10,params.iss*10,params.ifilt,params.t,iit);
        end
        
        load([DIRDATA inname '.mat'])
        
        PR{1}(isnr2,iit) = pr_standard;
        PR{2}(isnr2,iit) = pr_ortho;
        PR{3}(isnr2,iit) = pr_bispec_o;
        PR{4}(isnr2,iit) = pr_bispec_a;
        PR{5}(isnr2,iit) = pr_bispec_o_norm;
        PR{6}(isnr2,iit) = pr_bispec_a_norm;
        
        
    end
end


%%
for icon = [1:4]
    figure
    figone(6,10)
    o=1;
    
    for isnr = 1:length(titles)
        
        data1 = squeeze(PR{icon}(isnr,:));
        %     mean_pr(o) = mean(data1);
        
        cl = [0.7 0.75 0.75];
        
        subplot(1,length(titles),o)
        
        [h, u] = fp_raincloud_plot_a(data1, cl, 1,0.2, 'ks');
        view([-90 -90]);
        set(gca, 'Xdir', 'reverse');
        set(gca, 'XLim', [0 1]);
        
        htit = title(titles{o});
        htit.Position(1) = -0.12;
        set(gca,'ytick',[])
        ylim([-0.75 2])
        box off
        
        if o==1
            xlabel('PR')
            set(gca,'Clipping','Off')
            xt = xticks;
            for ix = xt
                hu = line([ix ix],[2 -10]);
                set(hu, 'color',[0.9 0.9 0.9])
                uistack(hu,'bottom')
            end
            hu1 = line([0 0],[2 -10]);
            set(hu1, 'color',[0 0 0])
        else
            set(gca,'xticklabel',{[]})
            set(gca,'XColor','none','YColor','none','TickDir','out')
            set(gca,'Clipping','Off')
            for ix = xt
                hu = line([ix ix],[2.2 -0.75]);
                set(hu, 'color',[0.9 0.9 0.9])
                uistack(hu,'bottom')
            end
            hu = line([0 0],[2.2 -0.75]);
            set(hu, 'color',[0 0 0])
        end
        
        o=o+1;
    end
    
    
    %%
%     outname = [DIRFIG 'SNR_' mets{icon} '.png'];
%     print(outname,'-dpng');
    
    outname = [DIRFIG 'SNR_' mets{icon} '.eps'];
    print(outname,'-depsc');
    
    close all
end