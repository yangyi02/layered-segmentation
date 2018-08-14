function num = countoverlap(left1,top1,right1,down1,left2,top2,right2,down2)

if right2 < left1 || right1 < left2 || down1 < top2 || down2 < top1
    num = 0;
else
    if left1 < left2
        left = left2;
    else
        left = left1;
    end

    if right1 < right2
        right = right1;
    else
        right = right2;
    end

    if top1 < top2
        top = top2;
    else
        top = top1;
    end

    if down1 < down2
        down = down1;
    else
        down = down2;
    end
    num = (right - left + 1) * (down - top + 1);
end
