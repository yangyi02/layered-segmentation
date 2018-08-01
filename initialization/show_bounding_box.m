function showboundingbox(im,objbox,objboxind,boxdetind,col,VOCopts)

% view detection for each image
imagesc(im); axis image; axis off; hold on;

D = length(objboxind);

if D > 0
    [score ind] = sort(objbox(:,30));

    for d = 1:D
        if boxdetind(ind(d)) == 1
            x1 = objbox(ind(d),1);
            y1 = objbox(ind(d),2);
            x2 = objbox(ind(d),3);
            y2 = objbox(ind(d),4);

            k = objboxind(ind(d));
            line([x1 x1 x2 x2 x1]', [y1 y2 y2 y1 y1]', 'color', col{k}, 'linewidth', 2);
            text(x1+5,y1+5,VOCopts.classes{k},'FontSize',12);   
        end
    end
    hold off;
    drawnow;
end