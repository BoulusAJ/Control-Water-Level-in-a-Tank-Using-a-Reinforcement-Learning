function row = computeWaterTankMetrics(experiences, caseID, h0, hRef, evalCfg)

[t, h, hRefSig, u] = extractWaterTankSignals(experiences, hRef, evalCfg);

e = hRefSig - h;

dt = evalCfg.Ts;

IAE = sum(abs(e)) * dt;
ISE = sum(e.^2) * dt;

uEnergy = sum(u.^2) * dt;

du = [0; diff(u)];
duEnergy = sum(du.^2) * dt;

failed = any(h <= evalCfg.h_min) || any(h >= evalCfg.h_max);

finalWindowStart = max(t(1), t(end) - evalCfg.FinalWindowSeconds);
idxFinal = t >= finalWindowStart;

finalMAE = mean(abs(e(idxFinal)));
finalBias = mean(e(idxFinal));
finalMaxAbsError = max(abs(e(idxFinal)));

overshoot = max(h - hRefSig);
undershoot = max(hRefSig - h);

settlingTime = computeSettlingTime(t, e, evalCfg.SettlingTol);

caseCost = computeCaseCost( ...
    finalMAE, finalMaxAbsError, IAE, uEnergy, duEnergy, failed, evalCfg);

row = table( ...
    caseID, h0, hRef, ...
    IAE, ISE, ...
    settlingTime, ...
    overshoot, undershoot, ...
    finalMAE, finalBias, finalMaxAbsError, ...
    uEnergy, duEnergy, ...
    failed, caseCost, ...
    'VariableNames', [ ...
        "CaseID","h0","hRef", ...
        "IAE","ISE", ...
        "SettlingTime", ...
        "Overshoot","Undershoot", ...
        "FinalMAE","FinalBias","FinalMaxAbsError", ...
        "UEnergy","DuEnergy", ...
        "Failed","CaseCost"]);

end

function settlingTime = computeSettlingTime(t, e, tol)

inside = abs(e) <= tol;
settlingTime = NaN;

for k = 1:numel(t)
    if all(inside(k:end))
        settlingTime = t(k);
        return;
    end
end

end

function caseCost = computeCaseCost(finalMAE, finalMaxAbsError, IAE, uEnergy, duEnergy, failed, evalCfg)

if failed
    caseCost = evalCfg.Score.failureBasePenalty;
else
    caseCost = ...
        evalCfg.Score.meanFinalMAEWeight * finalMAE + ...
        evalCfg.Score.maxFinalMAEWeight  * finalMaxAbsError + ...
        evalCfg.Score.meanIAEWeight      * IAE + ...
        evalCfg.Score.meanUEnergyWeight  * uEnergy + ...
        evalCfg.Score.meanDuEnergyWeight * duEnergy;
end

end