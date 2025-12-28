function fval = FixIfBelowFmin(fval, funcNum, cecName)
    % آستانه مجاز برای اختلاف
    thresholdRatio = 1e-10;

    % مقدارهای بهینه سراسری برای مجموعه‌های مختلف
    switch num2str(cecName)
        case '1'    %'2005'
            fminList = [ ...
                0, 0, 0, 0, 0, 0, 0, -12569.487, 0, 0, 0, 0, 0, 1, 0.0003, ...
                -1.0316, 0.398, 3, -3.86, -3.32, -10.1532, -10.4028, -10.5363];

        case '2'    %'2014'
            fminList = 100 * (1:30);

        case '3'    %'2017'
            fminList = 100 * (1:29);

        case '4'    %'2019'
            fminList = ones(1, 10);

        case '5'    %'2020'
            fminList = [100, 1100, 700, 1900, 1700, 1600, 2100, 2200, 2400, 2500];

        case '6'    %'2022'
            fminList = [300, 400, 600, 800, 900, 1800, 2000, 2200, 2300, 2400, 2600, 2700];

        otherwise
            return;  % اگه مجموعه ناشناخته بود، هیچ کاری نکن
    end

    % بررسی اعتبار شماره تابع
    if funcNum > numel(fminList)
        return;
    end

    fmin = fminList(funcNum);

    % اگر مقدار از fmin کمتر بود و اختلاف کم بود، اصلاح کن
    if fval < fmin
        diff = abs(fval - fmin);
        if diff < abs(fmin) * thresholdRatio
            fval = fmin;
        end
    end
end
