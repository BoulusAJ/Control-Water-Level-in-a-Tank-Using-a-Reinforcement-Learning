function [r, isDone] = rewardFcn(e, u, u_prev, h, stepCount, params)

if isa(params, 'Simulink.Parameter')
    params = params.Value;
end

fn = fieldnames(params);
for i = 1:numel(fn)
    v = params.(fn{i});
    if isa(v, 'Simulink.Parameter')
        params.(fn{i}) = v.Value;
    end
end

if ~isfield(params,'mode'),          params.mode = 3; end
if ~isfield(params,'thr'),           params.thr = 0.1; end
if ~isfield(params,'posReward'),     params.posReward = 10; end
if ~isfield(params,'negReward'),     params.negReward = -1; end
if ~isfield(params,'unsafePenalty'), params.unsafePenalty = 100; end
if ~isfield(params,'h_min'),         params.h_min = 0; end
if ~isfield(params,'h_max'),         params.h_max = 20; end
if ~isfield(params,'lambda_u'),      params.lambda_u = 0; end
if ~isfield(params,'lambda_du'),     params.lambda_du = 0; end
if ~isfield(params,'e_scale'),       params.e_scale = 1; end
if ~isfield(params,'tol'),           params.tol = 0.05; end
if ~isfield(params,'tolBonus'),      params.tolBonus = 0; end

isDone = (h <= params.h_min) || (h >= params.h_max);

switch params.mode

    case 1
        if abs(e) < params.thr
            r = params.posReward;
        else
            r = params.negReward;
        end

    case 2
        eNorm = e / params.e_scale;
        r = -(eNorm.^2);

    case 3
        if stepCount <= 1
            duPenalty = 0;
        else
            duPenalty = params.lambda_du * ((u - u_prev).^2);
        end
        eNorm = e / params.e_scale;

        r = -(eNorm.^2) ...
            - params.lambda_u  * (u.^2) ...
            - duPenalty;

        if abs(e) < params.tol
            r = r + params.tolBonus;
        end

    otherwise
        error('rewardFcn:InvalidMode','Unknown mode %d', params.mode);

end

if isDone
    r = r - params.unsafePenalty;
end

end