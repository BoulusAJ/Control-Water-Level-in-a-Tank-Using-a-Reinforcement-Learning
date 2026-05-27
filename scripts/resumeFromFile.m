%% Agent / resume (discover resume file under project/data)
resumeTraining = true;
resumeFilePattern = "WaterTankDDPG_curriculum_stage_01*.mat"; % pattern to match

% determine project root from this script location (assumes script in .../scripts)
scriptFullPath = mfilename('fullpath');
if isempty(scriptFullPath) % when running from command window, use pwd
    scriptsFolder = pwd;
else
    scriptsFolder = fileparts(scriptFullPath);
end
projectRoot = fileparts(scriptsFolder); % parent of scripts (project root)
dataRoot = fullfile(projectRoot, "data/run 3 - 20260526_1"); % .../data

% search recursively for matching files
matches = dir(fullfile(dataRoot, "**", resumeFilePattern));
if isempty(matches)
    error("No resume file matching '%s' found under %s", resumeFilePattern, dataRoot);
end

% pick the newest matched file
[~, idx] = max([matches.datenum]);
resumeFileFullPath = fullfile(matches(idx).folder, matches(idx).name);

if resumeTraining
    S = load(resumeFileFullPath);
    agent = S.agent;
    startStage = 2;

    fprintf("Resuming from %s\n", resumeFileFullPath);
    if isfield(S,"postStageEval")
        disp(S.postStageEval.summary);
    end
else
    agent = createDDPGAgent(obsInfo, actInfo, cfg);
    startStage = 1;
end
