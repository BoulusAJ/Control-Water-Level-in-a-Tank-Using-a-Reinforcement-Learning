function result = evaluateWaterTankController(agent, env, cases, evalCfg, opts)

arguments
    agent
    env
    cases table
    evalCfg struct
    opts.ControllerName string = "controller"
    opts.EvalSetName string = "eval"
    opts.StageIndex double = NaN
    opts.StageName string = ""
    opts.TrainingEpisode double = NaN
end

metrics = table();

simOpts = rlSimulationOptions( ...
    MaxSteps=evalCfg.MaxSteps, ...
    StopOnError="on");

oldResetFcn = env.ResetFcn;

cleanupObj = onCleanup(@() restoreResetFcn(env, oldResetFcn));

for i = 1:height(cases)

    fixedReset.mode = "fixed";
    fixedReset.h0 = cases.h0(i);
    fixedReset.hRef = cases.hRef(i);
    fixedReset.hMin = evalCfg.h_min;
    fixedReset.hMax = evalCfg.h_max;

    assignin("base","curriculumParams",fixedReset);

    env.ResetFcn = @localResetFcnCurriculum;

    experiences = sim(env, agent, simOpts);

    caseMetrics = computeWaterTankMetrics( ...
        experiences, ...
        cases.CaseID(i), ...
        cases.h0(i), ...
        cases.hRef(i), ...
        evalCfg);

    caseMetrics.ControllerName = opts.ControllerName;
    caseMetrics.EvalSetName = opts.EvalSetName;
    caseMetrics.StageIndex = opts.StageIndex;
    caseMetrics.StageName = opts.StageName;
    caseMetrics.TrainingEpisode = opts.TrainingEpisode;
    caseMetrics.EvaluatedAt = datetime("now");

    metrics = [metrics; caseMetrics]; 

end

summary = summarizeWaterTankMetrics(metrics, evalCfg);

summary.ControllerName = opts.ControllerName;
summary.EvalSetName = opts.EvalSetName;
summary.StageIndex = opts.StageIndex;
summary.StageName = opts.StageName;
summary.TrainingEpisode = opts.TrainingEpisode;
summary.EvaluatedAt = datetime("now");

result = struct();
result.metrics = metrics;
result.summary = summary;
result.cases = cases;
result.evalCfg = evalCfg;

end

function restoreResetFcn(env, oldResetFcn)
env.ResetFcn = oldResetFcn;
end