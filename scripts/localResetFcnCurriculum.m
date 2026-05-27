function in = localResetFcnCurriculum(in)

p = evalin("base","curriculumParams");

blkRef = sprintf("rlwatertank/Desired \nWater Level");
blkH   = "rlwatertank/Water-Tank System/H";

%% Fixed reset mode for evaluation
% Used by the custom evaluator to run deterministic test cases.
% Example:
%   curriculumParams.mode = "fixed";
%   curriculumParams.h0 = 5;
%   curriculumParams.hRef = 9;
if isfield(p,"mode") && string(p.mode) == "fixed"

    hRef = p.hRef;
    h0   = p.h0;

    in = setBlockParameter(in, blkRef, Value=num2str(hRef));
    in = setBlockParameter(in, blkH, InitialCondition=num2str(h0));

    return;

end

%% Reference
hRef = p.hRefStd*randn + p.hRefMean;

while hRef <= p.hMin || hRef >= p.hMax
    hRef = p.hRefStd*randn + p.hRefMean;
end

%% Initial height
switch string(p.mode)

    case "offset"

        valid = false;

        while ~valid
            errMag = p.minInitialError + ...
                (p.maxInitialError - p.minInitialError)*rand;

            if rand < 0.5
                h0 = hRef + errMag;
            else
                h0 = hRef - errMag;
            end

            valid = h0 > p.hMin && h0 < p.hMax;
        end

    case "independent"

        h0 = p.hRefStd*randn + p.hRefMean;

        while h0 <= p.hMin || h0 >= p.hMax
            h0 = p.hRefStd*randn + p.hRefMean;
        end

    otherwise
        error("Unknown reset mode: %s", p.mode);

end

in = setBlockParameter(in, blkRef, Value=num2str(hRef));
in = setBlockParameter(in, blkH, InitialCondition=num2str(h0));

end