classdef ModelComparisonApp_Ibrahim < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        DatasetSelectionPanel           matlab.ui.container.Panel
        LoadDatasetButton               matlab.ui.control.Button
        DatasetInfoLabel                matlab.ui.control.Label
        ModelSelectionPanel             matlab.ui.container.Panel
        ModelSelectionLabel             matlab.ui.control.Label
        ModelSelectionDropdown          matlab.ui.control.DropDown
        SelectAllCheckbox               matlab.ui.control.CheckBox
        RunPredictionsButton            matlab.ui.control.Button
        ShowComparisonButton            matlab.ui.control.Button
        ResultsVisualizationPanel       matlab.ui.container.Panel
        ConfusionMatrixAxes             matlab.ui.control.UIAxes
        ModelSelectorLabel              matlab.ui.control.Label
        ModelSelector                   matlab.ui.control.DropDown
        ExportToFigureButton            matlab.ui.control.Button
        ExportPanel                     matlab.ui.container.Panel
        ExportToExcelButton             matlab.ui.control.Button
        ResultsTable                    matlab.ui.control.Table
        ManualInputPanel                matlab.ui.container.Panel
        FeatureInputFields              matlab.ui.control.NumericEditField
        PredictManualButton             matlab.ui.control.Button
        ClearManualButton               matlab.ui.control.Button
        ManualPredictionResultLabel     matlab.ui.control.Label
        SelectedModelsList              matlab.ui.control.ListBox
        RemoveSelectedButton            matlab.ui.control.Button
        ClearSelectionButton            matlab.ui.control.Button
        % New components for manual results table
        ManualResultsPanel              matlab.ui.container.Panel
        ManualResultsTable              matlab.ui.control.Table
        ExportManualResultsButton       matlab.ui.control.Button
    end

    % Properties for storing data
    properties (Access = private)
        models = {'KNN', 'ANN', 'SVM', 'EN', 'DA', 'NB', 'DT'};
        modelFunctions = {@predict_optimized_knn, ...
                          @predict_optimized_ann, ...
                          @predict_optimized_svm, ...
                          @predict_optimized_en, ...
                          @predict_optimized_da, ...
                          @predict_optimized_nb, ...
                          @predict_optimized_dt};
        results = struct();
        featureNames = {'Feature 1', 'Feature 2', 'Feature 3', 'Feature 4', ...
                        'Feature 5', 'Feature 6', 'Feature 7', 'Feature 8', ...
                        'Feature 9', 'Feature 10', 'Feature 11', 'Feature 12'};
        classNames = {'F1', 'F2', 'F3', 'F4'};
        dataset = [];
        features = [];
        labels = [];
        selectedModels = {}; % Store selected models
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Initialize the app with enhanced visual settings
            app.ModelSelector.Items = {'KNN', 'ANN', 'SVM', 'EN', 'DA', 'NB', 'DT'};
            app.ModelSelector.Value = 'KNN';
            
            % Initialize model selection dropdown
            app.ModelSelectionDropdown.Items = {'KNN', 'ANN', 'SVM', 'EN', 'DA', 'NB', 'DT'};
            app.ModelSelectionDropdown.Value = 'KNN';
            
            % Initialize selected models list
            app.SelectedModelsList.Items = {};
            
            % Set up the results table with enhanced styling including Kappa
            app.ResultsTable.ColumnName = {'Model', 'Accuracy', 'Precision', 'Recall', 'F1-Score', 'Kappa'};
            app.ResultsTable.Data = cell(0, 6);
            app.ResultsTable.FontName = 'Segoe UI';
            app.ResultsTable.FontSize = 11;
            app.ResultsTable.BackgroundColor = [1 1 1; 0.96 0.96 0.96];
            
            % Initialize manual results table
            app.ManualResultsTable.ColumnName = {'Model', 'Prediction', 'Confidence'};
            app.ManualResultsTable.Data = cell(0, 3);
            app.ManualResultsTable.FontName = 'Segoe UI';
            app.ManualResultsTable.FontSize = 11;
            app.ManualResultsTable.BackgroundColor = [1 1 1; 0.96 0.96 0.96];
            app.ManualResultsTable.ColumnWidth = {120, 120, 140};
            
            % Disable comparison button initially
            app.ShowComparisonButton.Enable = 'off';
            
            % Initialize manual input fields with better visual settings
            for i = 1:12
                app.FeatureInputFields(i).Value = 0;
                app.FeatureInputFields(i).FontName = 'Consolas';
                app.FeatureInputFields(i).FontSize = 11;
            end
            
            % Set up axes for better visualization
            app.ConfusionMatrixAxes.FontName = 'Segoe UI';
            app.ConfusionMatrixAxes.FontSize = 10;
            app.ConfusionMatrixAxes.TitleFontSizeMultiplier = 1.2;
            app.ConfusionMatrixAxes.LabelFontSizeMultiplier = 1.1;
            
            % Enhanced button colors
            app.RunPredictionsButton.BackgroundColor = [0.9, 0.3, 0.3];
            app.RunPredictionsButton.FontColor = [1, 1, 1];
            app.ExportToExcelButton.BackgroundColor = [0.2, 0.6, 0.2];
            app.ExportToExcelButton.FontColor = [1, 1, 1];
            app.PredictManualButton.BackgroundColor = [0.2, 0.5, 0.8];
            app.PredictManualButton.FontColor = [1, 1, 1];
            app.RemoveSelectedButton.BackgroundColor = [0.9, 0.6, 0.2];
            app.RemoveSelectedButton.FontColor = [1, 1, 1];
            app.ClearSelectionButton.BackgroundColor = [0.8, 0.2, 0.2];
            app.ClearSelectionButton.FontColor = [1, 1, 1];
            app.ExportManualResultsButton.BackgroundColor = [0.2, 0.6, 0.2];
            app.ExportManualResultsButton.FontColor = [1, 1, 1];
        end

        % Button pushed function: LoadDatasetButton
        function LoadDatasetButtonPushed(app, event)
            [filename, pathname] = uigetfile({'*.mat;*.csv;*.xlsx', 'Data Files (*.mat, *.csv, *.xlsx)'}, ...
                                             'Select Dataset');
            if isequal(filename, 0)
                return;
            end
            
            [~, ~, ext] = fileparts(filename);
            filepath = fullfile(pathname, filename);
            
            try
                if strcmpi(ext, '.mat')
                    loadedData = load(filepath);
                    % Handle different MATLAB file structures
                    vars = fieldnames(loadedData);
                    data = loadedData.(vars{1});
                elseif strcmpi(ext, '.csv') || strcmpi(ext, '.xlsx')
                    data = readtable(filepath);
                    data = table2array(data);
                end
                
                % Check if data has 12 (predictions) or 13 (evaluation) columns
                if size(data, 2) == 12
                    app.features = data;
                    app.labels = [];
                    infoText = sprintf('Dataset: %s, Samples: %d, Features: %d (Prediction Mode)', ...
                                      filename, size(data, 1), 12);
                elseif size(data, 2) == 13
                    app.features = data(:, 1:12);
                    app.labels = data(:, 13);
                    infoText = sprintf('Dataset: %s, Samples: %d, Features: %d (Evaluation Mode)', ...
                                      filename, size(data, 1), 12);
                else
                    uialert(app.UIFigure, 'Dataset must have 12 features (prediction) or 13 columns (evaluation)', 'Invalid Dataset');
                    return;
                end
                
                app.dataset = data;
                app.DatasetInfoLabel.Text = infoText;
                app.DatasetInfoLabel.FontColor = [0 0.4 0]; % Dark green for success
                
            catch ME
                uialert(app.UIFigure, sprintf('Error loading dataset: %s', ME.message), 'Load Error');
            end
        end

        % Value changed function: ModelSelectionDropdown
        function ModelSelectionDropdownValueChanged(app, event)
            % This function can be used to add models to the selection
            selectedModel = app.ModelSelectionDropdown.Value;
            
            % Check if model is already selected
            if ~ismember(selectedModel, app.selectedModels)
                app.selectedModels{end+1} = selectedModel;
                app.SelectedModelsList.Items = app.selectedModels;
            end
            
            % Update Select All checkbox
            updateSelectAllCheckbox(app);
        end

        % Value changed function: SelectAllCheckbox
        function SelectAllCheckboxValueChanged(app, event)
            if app.SelectAllCheckbox.Value
                % Select all models
                app.selectedModels = app.models;
                app.SelectedModelsList.Items = app.selectedModels;
                app.SelectAllCheckbox.FontColor = [0 0.5 0]; % Green when selected
            else
                % Clear selection
                app.selectedModels = {};
                app.SelectedModelsList.Items = {};
                app.SelectAllCheckbox.FontColor = [0 0 0]; % Black when not selected
            end
        end

        % Update Select All checkbox based on current selection
        function updateSelectAllCheckbox(app)
            if length(app.selectedModels) == length(app.models)
                app.SelectAllCheckbox.Value = true;
                app.SelectAllCheckbox.FontColor = [0 0.5 0]; % Green when all selected
            else
                app.SelectAllCheckbox.Value = false;
                app.SelectAllCheckbox.FontColor = [0 0 0]; % Black when not all selected
            end
        end

        % Button pushed function: RemoveSelectedButton - FIXED VERSION
        function RemoveSelectedButtonPushed(app, event)
            try
                % Get the current selection
                selectedItems = app.SelectedModelsList.Value;
                
                if isempty(selectedItems)
                    uialert(app.UIFigure, 'Please select models to remove from the list', 'No Selection');
                    return;
                end
                
                % Convert to cell array if it's a single string
                if ischar(selectedItems) || isstring(selectedItems)
                    selectedItems = {char(selectedItems)};
                end
                
                % Remove selected items from the list
                for i = 1:length(selectedItems)
                    modelToRemove = selectedItems{i};
                    
                    % Find and remove the model from selectedModels
                    idxToRemove = strcmp(app.selectedModels, modelToRemove);
                    if any(idxToRemove)
                        app.selectedModels(idxToRemove) = [];
                    end
                end
                
                % Update the listbox
                app.SelectedModelsList.Items = app.selectedModels;
                
                % Clear the selection in the listbox
                app.SelectedModelsList.Value = {};
                
                % Update the Select All checkbox state
                updateSelectAllCheckbox(app);
                
            catch ME
                uialert(app.UIFigure, sprintf('Error removing selected models: %s', ME.message), 'Remove Error');
            end
        end

        % Button pushed function: ClearSelectionButton
        function ClearSelectionButtonPushed(app, event)
            app.selectedModels = {};
            app.SelectedModelsList.Items = {};
            app.SelectedModelsList.Value = {}; % Clear selection
            app.SelectAllCheckbox.Value = false;
            app.SelectAllCheckbox.FontColor = [0 0 0];
        end

        % Button pushed function: RunPredictionsButton
        function RunPredictionsButtonPushed(app, event)
            if isempty(app.dataset)
                uialert(app.UIFigure, 'Please load a dataset first', 'No Dataset');
                return;
            end
            
            if isempty(app.selectedModels)
                uialert(app.UIFigure, 'Please select at least one model', 'No Models Selected');
                return;
            end
            
            % Create enhanced progress dialog
            d = uiprogressdlg(app.UIFigure, 'Title', 'Processing Models', ...
                              'Message', 'Initializing...', 'Indeterminate', 'off');
            d.Value = 0;
            
            % Enhanced results structure with Kappa
            results = struct('modelName', {}, 'predictions', {}, 'accuracy', {}, ...
                             'precision', {}, 'recall', {}, 'f1', {}, 'kappa', {}, ...
                             'confusionMat', {});
            
            for i = 1:length(app.selectedModels)
                modelName = app.selectedModels{i};
                
                % Find the index of the selected model
                modelIdx = find(strcmp(app.models, modelName));
                if isempty(modelIdx)
                    uialert(app.UIFigure, sprintf('Model %s not found', modelName), 'Model Error');
                    continue;
                end
                
                modelFunc = app.modelFunctions{modelIdx};
                
                d.Message = sprintf('Running %s prediction... (%d/%d)', modelName, i, length(app.selectedModels));
                d.Value = (i-1)/length(app.selectedModels);
                
                try
                    predictions = modelFunc(app.features);
                    
                    % Convert categorical predictions to numeric
                    if iscategorical(predictions)
                        predictions = double(predictions);
                    end
                    
                    % Handle evaluation vs prediction mode
                    if ~isempty(app.labels)
                        [accuracy, precision, recall, f1, kappa] = calculateEnhancedMetrics(app.labels, predictions);
                        confusionMat = confusionmat(app.labels, predictions);
                    else
                        accuracy = NaN;
                        precision = NaN;
                        recall = NaN;
                        f1 = NaN;
                        kappa = NaN;
                        confusionMat = [];
                    end
                    
                    results(end+1) = struct('modelName', modelName, 'predictions', predictions, ...
                                            'accuracy', accuracy, 'precision', precision, ...
                                            'recall', recall, 'f1', f1, 'kappa', kappa, ...
                                            'confusionMat', confusionMat);
                    
                catch ME
                    errorMsg = sprintf('Error in %s: %s', modelName, ME.message);
                    uialert(app.UIFigure, errorMsg, 'Prediction Error');
                end
            end
            
            app.results = results;
            updateResultsTable(app);
            
            if ~isempty(app.labels)
                updateVisualization(app);
                app.ShowComparisonButton.Enable = 'on';
                app.ShowComparisonButton.BackgroundColor = [0.3 0.7 0.3]; % Green when enabled
                app.ShowComparisonButton.FontColor = [1, 1, 1];
            else
                cla(app.ConfusionMatrixAxes);
                app.ConfusionMatrixAxes.Visible = 'off';
                app.ShowComparisonButton.Enable = 'off';
                app.ShowComparisonButton.BackgroundColor = [0.8 0.8 0.8]; % Gray when disabled
            end
            
            close(d);
            
            % Enhanced success message
            msg = sprintf('Predictions completed!\n%d models processed successfully.', length(app.selectedModels));
            uialert(app.UIFigure, msg, 'Success', 'Icon', 'success');
        end

        % Value changed function: ModelSelector
        function ModelSelectorValueChanged(app, event)
            updateVisualization(app);
        end

        % Update visualization with enhanced graphics
        function updateVisualization(app)
            if isempty(app.results)
                return;
            end
            
            modelIdx = app.ModelSelector.Value;
            
            availableModels = {app.results.modelName};
            app.ModelSelector.Items = availableModels;
            
            if ischar(modelIdx) || isstring(modelIdx)
                % Find the index of the selected model
                modelName = char(modelIdx);
                for i = 1:length(availableModels)
                    if strcmp(availableModels{i}, modelName)
                        modelIdx = i;
                        break;
                    end
                end
            end
            
            if modelIdx > length(app.results)
                modelIdx = 1;
                app.ModelSelector.Value = availableModels{1};
            end
            
            confusionMat = app.results(modelIdx).confusionMat;
            plotEnhancedConfusionMatrix(app.ConfusionMatrixAxes, confusionMat, app.classNames, ...
                                sprintf('Confusion Matrix - %s', app.results(modelIdx).modelName));
        end

        % Update results table with enhanced styling including Kappa
        function updateResultsTable(app)
            if isempty(app.results)
                return;
            end
            
            % Updated table with Kappa column
            tableData = cell(length(app.results), 6);
            for i = 1:length(app.results)
                tableData{i, 1} = app.results(i).modelName;
                if ~isempty(app.labels)
                    tableData{i, 2} = sprintf('%.2f%%', app.results(i).accuracy * 100);
                    tableData{i, 3} = sprintf('%.2f%%', nanmean(app.results(i).precision) * 100);
                    tableData{i, 4} = sprintf('%.2f%%', nanmean(app.results(i).recall) * 100);
                    tableData{i, 5} = sprintf('%.2f', nanmean(app.results(i).f1));
                    tableData{i, 6} = sprintf('%.3f', app.results(i).kappa);
                else
                    tableData{i, 2} = 'N/A';
                    tableData{i, 3} = 'N/A';
                    tableData{i, 4} = 'N/A';
                    tableData{i, 5} = 'N/A';
                    tableData{i, 6} = 'N/A';
                end
            end
            
            app.ResultsTable.Data = tableData;
        end

        % Enhanced comparison button function with Kappa
        function ShowComparisonButtonPushed(app, event)
            if isempty(app.results) || isempty(app.labels)
                uialert(app.UIFigure, 'No results to compare or no true labels available', 'No Results');
                return;
            end
            
            compFig = figure('Name', 'Model Comparison', ...
                             'NumberTitle', 'off', ...
                             'Position', [150, 50, 700, 600], ...
                             'Color', [0.95, 0.95, 0.95]);
            
            modelNames = {app.results.modelName};
            numModels = length(modelNames);
            numClasses = length(app.classNames);
            
            accuracy = [app.results.accuracy] * 100;
            meanPrecision = cellfun(@mean, {app.results.precision}) * 100;
            meanRecall = cellfun(@mean, {app.results.recall}) * 100;
            meanF1 = cellfun(@mean, {app.results.f1}) * 100;
            kappaValues = [app.results.kappa] * 100; % Scale for better visualization
            
            modelColors = [
                0.2, 0.6, 0.8;
                0.8, 0.2, 0.2;
                0.2, 0.8, 0.4;
                0.8, 0.6, 0.2;
                0.6, 0.2, 0.8;
                0.9, 0.5, 0.1;
                0.3, 0.7, 0.7  % New color for DT
            ];
            
            if numModels > size(modelColors, 1)
                additionalColors = lines(numModels - size(modelColors, 1));
                modelColors = [modelColors; additionalColors];
            end
            
            modelColors = modelColors(1:numModels, :);
            
            abbreviatedNames = cell(size(modelNames));
            for i = 1:numModels
                switch modelNames{i}
                    case 'KNN'
                        abbreviatedNames{i} = 'KNN';
                    case 'ANN'
                        abbreviatedNames{i} = 'ANN';
                    case 'SVM'
                        abbreviatedNames{i} = 'SVM';
                    case 'EN'
                        abbreviatedNames{i} = 'EN';
                    case 'DA'
                        abbreviatedNames{i} = 'DA';
                    case 'NB'
                        abbreviatedNames{i} = 'NB';
                    case 'DT'
                        abbreviatedNames{i} = 'DT';
                    otherwise
                        abbreviatedNames{i} = modelNames{i};
                end
            end
            
            subplot(2, 2, 1);
            barHandle1 = bar(accuracy, 'FaceColor', 'flat');
            for i = 1:numModels
                barHandle1.CData(i, :) = modelColors(i, :);
            end
            title('Accuracy Comparison', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel('Accuracy (%)');
            set(gca, 'XTickLabel', abbreviatedNames, 'XTickLabelRotation', 45);
            grid on;
            
            subplot(2, 2, 2);
            barHandle2 = bar(meanPrecision, 'FaceColor', 'flat');
            for i = 1:numModels
                barHandle2.CData(i, :) = modelColors(i, :);
            end
            title('Precision Comparison', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel('Precision (%)');
            set(gca, 'XTickLabel', abbreviatedNames, 'XTickLabelRotation', 45);
            grid on;
            
            subplot(2, 2, 3);
            barHandle3 = bar(meanRecall, 'FaceColor', 'flat');
            for i = 1:numModels
                barHandle3.CData(i, :) = modelColors(i, :);
            end
            title('Recall Comparison', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel('Recall (%)');
            set(gca, 'XTickLabel', abbreviatedNames, 'XTickLabelRotation', 45);
            grid on;
            
            subplot(2, 2, 4);
            barHandle4 = bar(meanF1, 'FaceColor', 'flat');
            for i = 1:numModels
                barHandle4.CData(i, :) = modelColors(i, :);
            end
            title('F1-Score Comparison', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel('F1-Score');
            set(gca, 'XTickLabel', abbreviatedNames, 'XTickLabelRotation', 45);
            grid on;
        end

% Button pushed function: ExportToExcelButton
function ExportToExcelButtonPushed(app, event)
    if isempty(app.results)
        uialert(app.UIFigure, 'No results to export', 'Export Error', 'Icon', 'error');
        return;
    end
    
    [filename, pathname] = uiputfile('*.xlsx', 'Save Predictions');
    if isequal(filename, 0)
        return;
    end
    
    filepath = fullfile(pathname, filename);
    
    try
        % Enhanced progress dialog for export
        d = uiprogressdlg(app.UIFigure, 'Title', 'Exporting Data', ...
                          'Message', 'Preparing Excel file...', 'Indeterminate', 'on');
        
        % Sheet 1: Features and Predictions with Consensus
        exportData = array2table(app.features, 'VariableNames', app.featureNames);
        
        % Add true labels if available
        if ~isempty(app.labels)
            exportData.TrueLabels = app.labels;
        end
        
        % Add individual model predictions and calculate consensus
        allPredictions = [];
        for i = 1:length(app.results)
            exportData.(app.results(i).modelName) = app.results(i).predictions;
            allPredictions = [allPredictions, app.results(i).predictions];
        end
        
        % Calculate consensus predictions
        [numSamples, numModels] = size(allPredictions);
        consensusPredictions = zeros(numSamples, 1);
        for i = 1:numSamples
            samplePredictions = allPredictions(i, :);
            if all(samplePredictions == round(samplePredictions))
                consensusPredictions(i) = mode(samplePredictions);
            else
                consensusPredictions(i) = median(samplePredictions);
            end
        end
        
        exportData.Consensus = consensusPredictions;
        
        % Sheet 2: Summary Results with Consensus metrics (only if we have true labels)
        if ~isempty(app.labels)
            % Calculate consensus metrics
            [consensusAccuracy, consensusPrecision, consensusRecall, consensusF1, consensusKappa] = ...
                calculateEnhancedMetrics(app.labels, consensusPredictions);
            
            summaryData = cell(length(app.results) + 2, 6); % +2 for header and consensus row
            summaryData{1, 1} = 'Model';
            summaryData{1, 2} = 'Accuracy (%)';
            summaryData{1, 3} = 'Precision (%)';
            summaryData{1, 4} = 'Recall (%)';
            summaryData{1, 5} = 'F1-Score';
            summaryData{1, 6} = 'Kappa';
            
            % Add individual model results
            for i = 1:length(app.results)
                summaryData{i+1, 1} = app.results(i).modelName;
                summaryData{i+1, 2} = app.results(i).accuracy * 100;
                summaryData{i+1, 3} = nanmean(app.results(i).precision) * 100;
                summaryData{i+1, 4} = nanmean(app.results(i).recall) * 100;
                summaryData{i+1, 5} = nanmean(app.results(i).f1);
                summaryData{i+1, 6} = app.results(i).kappa;
            end
            
            % Add consensus results as the final row
            summaryData{length(app.results) + 2, 1} = 'CONSENSUS';
            summaryData{length(app.results) + 2, 2} = consensusAccuracy * 100;
            summaryData{length(app.results) + 2, 3} = nanmean(consensusPrecision) * 100;
            summaryData{length(app.results) + 2, 4} = nanmean(consensusRecall) * 100;
            summaryData{length(app.results) + 2, 5} = nanmean(consensusF1);
            summaryData{length(app.results) + 2, 6} = consensusKappa;
            
            summaryTable = cell2table(summaryData(2:end, :), 'VariableNames', summaryData(1, :));
            
            % Write both sheets to Excel
            writetable(exportData, filepath, 'Sheet', 'Predictions with Consensus');
            writetable(summaryTable, filepath, 'Sheet', 'Summary Results');
            
            % Sheet 3: Detailed Metrics
            if ~isempty(app.classNames)
                numClasses = length(app.classNames);
                detailedData = cell(length(app.results) + 2, 1 + numClasses * 3);
                detailedData{1, 1} = 'Model';
                
                % Create column headers for per-class metrics
                colIdx = 2;
                for c = 1:numClasses
                    detailedData{1, colIdx} = [app.classNames{c} '_Precision'];
                    detailedData{1, colIdx+1} = [app.classNames{c} '_Recall'];
                    detailedData{1, colIdx+2} = [app.classNames{c} '_F1'];
                    colIdx = colIdx + 3;
                end
                
                % Fill in the data for individual models
                for i = 1:length(app.results)
                    detailedData{i+1, 1} = app.results(i).modelName;
                    colIdx = 2;
                    for c = 1:numClasses
                        detailedData{i+1, colIdx} = app.results(i).precision(c) * 100;
                        detailedData{i+1, colIdx+1} = app.results(i).recall(c) * 100;
                        detailedData{i+1, colIdx+2} = app.results(i).f1(c);
                        colIdx = colIdx + 3;
                    end
                end
                
                % Add consensus metrics
                detailedData{length(app.results) + 2, 1} = 'CONSENSUS';
                colIdx = 2;
                for c = 1:numClasses
                    detailedData{length(app.results) + 2, colIdx} = consensusPrecision(c) * 100;
                    detailedData{length(app.results) + 2, colIdx+1} = consensusRecall(c) * 100;
                    detailedData{length(app.results) + 2, colIdx+2} = consensusF1(c);
                    colIdx = colIdx + 3;
                end
                
                detailedTable = cell2table(detailedData(2:end, :), 'VariableNames', detailedData(1, :));
                writetable(detailedTable, filepath, 'Sheet', 'Detailed Metrics');
            end
            
            % Sheet 4: Consensus Analysis (call the integrated function)
            createConsensusAnalysisSheetIntegrated(app, filepath, allPredictions, consensusPredictions);
            
        else
            % Prediction mode - export predictions sheet with consensus and analysis
            writetable(exportData, filepath, 'Sheet', 'Predictions with Consensus');
            
            % Create consensus analysis sheet for prediction mode
            createConsensusAnalysisSheetIntegrated(app, filepath, allPredictions, consensusPredictions);
        end
        
        close(d);
        uialert(app.UIFigure, sprintf('Data exported successfully to:\n%s\n\nSheets included:\n- Predictions with Consensus\n- Summary Results\n- Detailed Metrics\n- Consensus Analysis', filepath), ...
               'Export Complete', 'Icon', 'success');
        
    catch ME
        close(d);
        uialert(app.UIFigure, sprintf('Error exporting data: %s', ME.message), 'Export Error', 'Icon', 'error');
    end
    
        % Nested function for consensus analysis - IMPROVED VERSION
    function createConsensusAnalysisSheetIntegrated(app, filepath, allPredictions, consensusPredictions)
        % Create detailed consensus analysis
        [numSamples, numModels] = size(allPredictions);
        
        % SECTION 1: Sample-wise Agreement Details
        agreementData = cell(numSamples + 1, numModels + 4);
        agreementData{1, 1} = 'Sample';
        for i = 1:numModels
            agreementData{1, i+1} = app.results(i).modelName;
        end
        agreementData{1, numModels + 2} = 'Consensus';
        agreementData{1, numModels + 3} = 'Agreement_Count';
        agreementData{1, numModels + 4} = 'Agreement_Percent';
        
        for i = 1:numSamples
            agreementData{i+1, 1} = i;
            samplePredictions = allPredictions(i, :);
            consensus = consensusPredictions(i);
            
            agreementCount = sum(samplePredictions == consensus);
            agreementPercent = (agreementCount / numModels) * 100;
            
            for j = 1:numModels
                agreementData{i+1, j+1} = samplePredictions(j);
            end
            agreementData{i+1, numModels + 2} = consensus;
            agreementData{i+1, numModels + 3} = agreementCount;
            agreementData{i+1, numModels + 4} = agreementPercent;
        end
        
        % Write SECTION 1
        agreementTable = cell2table(agreementData(2:end, :), 'VariableNames', agreementData(1, :));
        writetable(agreementTable, filepath, 'Sheet', 'Consensus Analysis');
        
        % SECTION 2: Overall Statistics (Column A, after main table)
        summaryStats = cell(8, 2);
        summaryStats{1, 1} = 'OVERALL STATISTICS';
        summaryStats{1, 2} = '';
        summaryStats{2, 1} = 'Total Samples';
        summaryStats{2, 2} = numSamples;
        summaryStats{3, 1} = 'Number of Models';
        summaryStats{3, 2} = numModels;
        
        allAgreements = cell2mat(agreementData(2:end, numModels + 3));
        summaryStats{4, 1} = 'Mean Agreement (%)';
        summaryStats{4, 2} = mean(allAgreements) / numModels * 100;
        summaryStats{5, 1} = 'Median Agreement (%)';
        summaryStats{5, 2} = median(allAgreements) / numModels * 100;
        summaryStats{6, 1} = 'Min Agreement (%)';
        summaryStats{6, 2} = min(allAgreements) / numModels * 100;
        summaryStats{7, 1} = 'Max Agreement (%)';
        summaryStats{7, 2} = max(allAgreements) / numModels * 100;
        summaryStats{8, 1} = 'Total Models Analyzed';
        summaryStats{8, 2} = length(app.results);
        
        summaryStartRow = numSamples + 4;
        summaryTable = cell2table(summaryStats(2:end, :), 'VariableNames', {'Statistic', 'Value'});
        writetable(summaryTable, filepath, 'Sheet', 'Consensus Analysis', 'Range', sprintf('A%d', summaryStartRow));
        
        % SECTION 3: Model-wise Agreement (Column F, after main table)
        modelAgreement = cell(numModels + 1, 3);
        modelAgreement{1, 1} = 'MODEL AGREEMENT WITH CONSENSUS';
        modelAgreement{1, 2} = '';
        modelAgreement{1, 3} = '';
        modelAgreement{2, 1} = 'Model';
        modelAgreement{2, 2} = 'Agreement (%)';
        modelAgreement{2, 3} = 'Disagreement Count';
        
        % Include ALL models
        for i = 1:numModels
            modelPredictions = allPredictions(:, i);
            agreementWithConsensus = sum(modelPredictions == consensusPredictions);
            agreementPercent = (agreementWithConsensus / numSamples) * 100;
            
            modelAgreement{i+2, 1} = app.results(i).modelName; % +2 because of headers
            modelAgreement{i+2, 2} = agreementPercent;
            modelAgreement{i+2, 3} = numSamples - agreementWithConsensus;
        end
        
        modelStartRow = numSamples + 4;
        modelAgreementTable = cell2table(modelAgreement(3:end, :), 'VariableNames', modelAgreement(2, :));
        writetable(modelAgreementTable, filepath, 'Sheet', 'Consensus Analysis', 'Range', sprintf('F%d', modelStartRow));
        
        % SECTION 4: Agreement Distribution (Column F, below model agreement)
        agreementDist = cell(12, 2);
        agreementDist{1, 1} = 'AGREEMENT DISTRIBUTION';
        agreementDist{1, 2} = '';
        agreementDist{2, 1} = 'Agreement Level (%)';
        agreementDist{2, 2} = 'Number of Samples';
        
        agreementLevels = 0:10:100;
        for levelIdx = 1:length(agreementLevels)
            level = agreementLevels(levelIdx);
            if level == 100
                count = sum(allAgreements == numModels);
            else
                minCount = floor(level / 100 * numModels);
                maxCount = ceil((level + 10) / 100 * numModels) - 1;
                count = sum(allAgreements >= minCount & allAgreements <= maxCount);
            end
            agreementDist{levelIdx + 2, 1} = sprintf('%d%%', level);
            agreementDist{levelIdx + 2, 2} = count;
        end
        
        distStartRow = modelStartRow + numModels + 4; % Spacing after model agreement
        agreementDistTable = cell2table(agreementDist(3:end, :), 'VariableNames', agreementDist(2, :));
        writetable(agreementDistTable, filepath, 'Sheet', 'Consensus Analysis', 'Range', sprintf('F%d', distStartRow));
    end
end

   % Button pushed function: ExportToFigureButton
   function ExportToFigureButtonPushed(app, event)
    try
        if isempty(app.results)
            uialert(app.UIFigure, 'No results to export. Please run predictions first.', 'No Results');
            return;
        end
        
        % Get the currently selected model
        modelIdx = app.ModelSelector.Value;
        
        if ischar(modelIdx) || isstring(modelIdx)
            % Find the index of the selected model
            modelName = char(modelIdx);
            availableModels = {app.results.modelName};
            for i = 1:length(availableModels)
                if strcmp(availableModels{i}, modelName)
                    modelIdx = i;
                    break;
                end
            end
        end
        
        if modelIdx > length(app.results)
            uialert(app.UIFigure, 'Invalid model selection', 'Export Error');
            return;
        end
        
        % Create a new figure
        newFig = figure('Name', ['Confusion Matrix - ' app.results(modelIdx).modelName], ...
                        'NumberTitle', 'off', ...
                        'Position', [100, 100, 600, 500]);
        
        % Use built-in confusionchart
        confusionMat = app.results(modelIdx).confusionMat;
        cm = confusionchart(newFig, confusionMat, app.classNames);
        cm.Title = ['Confusion Matrix - ' app.results(modelIdx).modelName];
        cm.FontSize = 12;
        
        % Add a save button to the new figure
        uicontrol('Parent', newFig, ...
                  'Style', 'pushbutton', ...
                  'String', 'Save Figure', ...
                  'Position', [250, 10, 100, 30], ...
                  'Callback', @(src,event) app.saveConfusionMatrixFigure(newFig), ...
                  'FontWeight', 'bold', ...
                  'BackgroundColor', [0.8, 0.9, 1.0]);
              
    catch ME
        uialert(app.UIFigure, sprintf('Error exporting figure: %s', ME.message), 'Export Error');
    end
end

          % Enhanced manual prediction function - IMPROVED TEXT FORMATTING
        function PredictManualButtonPushed(app, event)
            % Get values from input fields
            manualFeatures = zeros(1, 12);
            validInput = true;
            
            % Enhanced input validation with visual feedback
            for i = 1:12
                try
                    manualFeatures(i) = app.FeatureInputFields(i).Value;
                    if isnan(manualFeatures(i)) || isinf(manualFeatures(i))
                        validInput = false;
                        app.FeatureInputFields(i).BackgroundColor = [1, 0.8, 0.8]; % Light red for error
                        uialert(app.UIFigure, sprintf('Invalid value for Feature %d', i), 'Input Error', 'Icon', 'error');
                    else
                        app.FeatureInputFields(i).BackgroundColor = [1, 1, 1]; % White for valid
                    end
                catch
                    validInput = false;
                    app.FeatureInputFields(i).BackgroundColor = [1, 0.8, 0.8]; % Light red for error
                    uialert(app.UIFigure, sprintf('Error reading Feature %d', i), 'Input Error', 'Icon', 'error');
                end
            end
            
            if ~validInput
                return;
            end
            
            if isempty(app.selectedModels)
                uialert(app.UIFigure, 'Please select at least one model', 'No Models Selected', 'Icon', 'warning');
                return;
            end
            
            % Enhanced progress dialog
            d = uiprogressdlg(app.UIFigure, 'Title', 'Manual Prediction', ...
                              'Message', 'Running predictions...', ...
                              'Indeterminate', 'on');
            
            % Initialize results table data
            resultsData = cell(length(app.selectedModels), 3);
            predictions = [];
            modelNames = {};
            
            for i = 1:length(app.selectedModels)
                modelName = app.selectedModels{i};
                
                % Find the index of the selected model
                modelIdx = find(strcmp(app.models, modelName));
                if isempty(modelIdx)
                    resultsData{i, 1} = modelName;
                    resultsData{i, 2} = 'Model Not Found';
                    resultsData{i, 3} = 'N/A';
                    continue;
                end
                
                modelFunc = app.modelFunctions{modelIdx};
                
                d.Message = sprintf('Running %s prediction...', modelName);
                
                try
                    prediction = modelFunc(manualFeatures);
                    
                    % Handle different prediction formats
                    if iscell(prediction)
                        prediction = prediction{1};
                    end
                    
                    % Convert categorical predictions to numeric
                    if iscategorical(prediction)
                        prediction = double(prediction);
                    end
                    
                    % Handle array outputs (take first element if array)
                    if numel(prediction) > 1
                        prediction = prediction(1);
                    end
                    
                    % Enhanced formatting for table display
                    if ~isempty(app.classNames) && isnumeric(prediction) && ...
                       prediction >= 1 && prediction <= length(app.classNames)
                        predictionText = sprintf('%s (Class %d)', app.classNames{prediction}, prediction);
                        confidence = 1.0; % Default confidence for classification
                    else
                        if isnumeric(prediction) && prediction == round(prediction) && ...
                           prediction >= 1 && prediction <= 10
                            predictionText = sprintf('Class %d', prediction);
                            confidence = 1.0;
                        else
                            predictionText = sprintf('%.4f', prediction);
                            confidence = 1.0; % Default for regression
                        end
                    end
                    
                    resultsData{i, 1} = modelName;
                    resultsData{i, 2} = predictionText;
                    resultsData{i, 3} = sprintf('%.3f', confidence);
                    
                    % Store for consensus analysis
                    if isnumeric(prediction)
                        predictions(end+1) = prediction;
                        modelNames{end+1} = modelName;
                    end
                    
                catch ME
                    resultsData{i, 1} = modelName;
                    resultsData{i, 2} = sprintf('ERROR: %s', ME.message);
                    resultsData{i, 3} = 'N/A';
                    uialert(app.UIFigure, sprintf('Error in %s: %s', modelName, ME.message), 'Prediction Error', 'Icon', 'error');
                end
            end
            
            % Update the manual results table
            app.ManualResultsTable.Data = resultsData;
            
            % Build the results text for the left panel with better formatting
            resultLines = {};
            
            % Enhanced consensus analysis for label display
            if length(app.selectedModels) > 1 && ~isempty(predictions)
                resultLines{end+1} = 'CONSENSUS ANALYSIS';
                resultLines{end+1} = '────────────────────';
                resultLines{end+1} = '';
                
                if all(isnumeric(predictions))
                    resultLines{end+1} = sprintf('Mean:    %.4f', mean(predictions));
                    resultLines{end+1} = sprintf('Median:  %.4f', median(predictions));
                    resultLines{end+1} = sprintf('Range:   %.4f to %.4f', min(predictions), max(predictions));
                    resultLines{end+1} = '';
                    
                    if all(predictions == round(predictions))
                        consensus = mode(predictions);
                        resultLines{end+1} = sprintf('Consensus Class: %d', consensus);
                        if ~isempty(app.classNames) && consensus >= 1 && consensus <= length(app.classNames)
                            resultLines{end+1} = sprintf('Consensus Label: %s', app.classNames{consensus});
                        end
                    end
                end
            else
                resultLines{end+1} = 'Individual predictions shown in table.';
            end
            
            % Add spacing
            resultLines{end+1} = '';
            resultLines{end+1} = '';
            
            % Enhanced input features display in label
            resultLines{end+1} = 'INPUT FEATURES';
            resultLines{end+1} = '────────────────';
            resultLines{end+1} = '';
            
            % Display features in a cleaner format
            for i = 1:4:12
                for j = i:min(i+3, 12)
                    if j <= 12
                        resultLines{end+1} = sprintf('F%2d: %10.4f', j, manualFeatures(j));
                    end
                end
                if i < 9
                    resultLines{end+1} = '';
                end
            end
            
            % Update the left panel label with consensus and features
            resultText = strjoin(resultLines, newline);
            app.ManualPredictionResultLabel.Text = resultText;
            app.ManualPredictionResultLabel.FontName = 'Consolas';
            app.ManualPredictionResultLabel.FontSize = 11;
            app.ManualPredictionResultLabel.BackgroundColor = [0.98, 0.98, 0.98];
            
            close(d);
        end
        % Button pushed function: ExportManualResultsButton
                % Button pushed function: ExportManualResultsButton
        function ExportManualResultsButtonPushed(app, event)
            % Export manual results to Excel
            if isempty(app.ManualResultsTable.Data)
                uialert(app.UIFigure, 'No manual prediction results to export.', 'No Data');
                return;
            end
            
            try
                % Create filename with timestamp - FIXED SPACE ISSUE
                timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
                filename = sprintf('manual_predictions_%s.xlsx', timestamp); % Removed space
                
                % Get the results data
                resultsData = app.ManualResultsTable.Data;
                
                % Create a proper table for export
                exportTable = table(resultsData(:,1), resultsData(:,2), resultsData(:,3), ...
                    'VariableNames', {'Model', 'Prediction', 'Confidence'});
                
                % Write to Excel
                writetable(exportTable, filename, 'Sheet', 'Manual Predictions');
                
                % Show success message with proper formatting
                successMessage = sprintf('Manual results exported to:\n%s', filename);
                uialert(app.UIFigure, successMessage, 'Export Successful', 'Icon', 'success');
                
            catch ME
                % Show detailed error message
                errorMessage = sprintf('Error exporting results:\n%s', ME.message);
                uialert(app.UIFigure, errorMessage, 'Export Failed', 'Icon', 'error');
            end
        end

        % Button pushed function: ClearManualButton
        function ClearManualButtonPushed(app, event)
            clearManualInputs(app);
        end

        % Enhanced clear manual inputs function
        function clearManualInputs(app)
            % Clear all manual input fields with visual feedback
            for i = 1:12
                app.FeatureInputFields(i).Value = 0;
                app.FeatureInputFields(i).BackgroundColor = [1, 1, 1]; % Reset to white
            end
            app.ManualPredictionResultLabel.Text = 'Results will appear here';
            app.ManualPredictionResultLabel.BackgroundColor = [1, 1, 1];
            app.ManualResultsTable.Data = cell(0, 3); % Clear the results table
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components with enhanced visual quality
        function createComponents(app)
            % Create UIFigure with enhanced styling
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100, 100, 1100, 760];
            app.UIFigure.Name = 'Water Quality Prediction Tool';
            app.UIFigure.Color = [0.96, 0.96, 0.96]; % Light gray background
            
            % Create DatasetSelectionPanel with enhanced styling
            app.DatasetSelectionPanel = uipanel(app.UIFigure);
            app.DatasetSelectionPanel.Title = 'Dataset Selection';
            app.DatasetSelectionPanel.Position = [22, 660, 1056, 78];
            app.DatasetSelectionPanel.BackgroundColor = [0.92, 0.94, 0.98]; % Light blue-gray
            app.DatasetSelectionPanel.FontWeight = 'bold';
            app.DatasetSelectionPanel.FontSize = 11;
            app.DatasetSelectionPanel.FontName = 'Segoe UI';

            % Create LoadDatasetButton with enhanced styling
            app.LoadDatasetButton = uibutton(app.DatasetSelectionPanel, 'push');
            app.LoadDatasetButton.ButtonPushedFcn = createCallbackFcn(app, @LoadDatasetButtonPushed, true);
            app.LoadDatasetButton.Position = [20, 10, 120, 30];
            app.LoadDatasetButton.Text = 'Load Dataset';
            app.LoadDatasetButton.FontWeight = 'bold';
            app.LoadDatasetButton.FontSize = 11;
            app.LoadDatasetButton.FontName = 'Segoe UI';
            app.LoadDatasetButton.BackgroundColor = [0.2, 0.6, 1.0]; % Nice blue
            app.LoadDatasetButton.FontColor = [1, 1, 1]; % White text

            % Create DatasetInfoLabel with enhanced styling
            app.DatasetInfoLabel = uilabel(app.DatasetSelectionPanel);
            app.DatasetInfoLabel.Position = [150, 10, 400, 30];
            app.DatasetInfoLabel.Text = 'No dataset loaded';
            app.DatasetInfoLabel.HorizontalAlignment = 'left';
            app.DatasetInfoLabel.BackgroundColor = [0.92, 0.94, 0.98];
            app.DatasetInfoLabel.FontWeight = 'bold';
            app.DatasetInfoLabel.FontSize = 11;
            app.DatasetInfoLabel.FontName = 'Segoe UI';
            app.DatasetInfoLabel.FontColor = [0.3, 0.3, 0.3]; % Dark gray

            % Create ModelSelectionPanel with enhanced styling
            app.ModelSelectionPanel = uipanel(app.UIFigure);
            app.ModelSelectionPanel.Title = 'Model Selection (Select 1-7 Models)';
            app.ModelSelectionPanel.Position = [22, 342, 275, 305];
            app.ModelSelectionPanel.BackgroundColor = [0.94, 0.96, 0.92]; % Light green-gray
            app.ModelSelectionPanel.FontWeight = 'bold';
            app.ModelSelectionPanel.FontSize = 11;
            app.ModelSelectionPanel.FontName = 'Segoe UI';

            % Create ModelSelectionLabel
            app.ModelSelectionLabel = uilabel(app.ModelSelectionPanel);
            app.ModelSelectionLabel.HorizontalAlignment = 'right';
            app.ModelSelectionLabel.Position = [10, 260, 120, 20];
            app.ModelSelectionLabel.Text = 'Select Model:';
            app.ModelSelectionLabel.BackgroundColor = [0.94, 0.96, 0.92];
            app.ModelSelectionLabel.FontWeight = 'bold';
            app.ModelSelectionLabel.FontSize = 11;
            app.ModelSelectionLabel.FontName = 'Segoe UI';

            % Create ModelSelectionDropdown
            app.ModelSelectionDropdown = uidropdown(app.ModelSelectionPanel);
            app.ModelSelectionDropdown.Items = {'KNN', 'ANN', 'SVM', 'EN', 'DA', 'NB', 'DT'};
            app.ModelSelectionDropdown.ValueChangedFcn = createCallbackFcn(app, @ModelSelectionDropdownValueChanged, true);
            app.ModelSelectionDropdown.Position = [140, 260, 120, 20];
            app.ModelSelectionDropdown.FontWeight = 'bold';
            app.ModelSelectionDropdown.BackgroundColor = [1, 1, 1];
            app.ModelSelectionDropdown.FontSize = 11;
            app.ModelSelectionDropdown.FontName = 'Segoe UI';

            % Create SelectedModelsList label
            selectedModelsLabel = uilabel(app.ModelSelectionPanel);
            selectedModelsLabel.Position = [10, 225, 150, 20];
            selectedModelsLabel.Text = 'Selected Models:';
            selectedModelsLabel.FontWeight = 'bold';
            selectedModelsLabel.FontSize = 11;
            selectedModelsLabel.FontName = 'Segoe UI';

            % Create SelectedModelsList
            app.SelectedModelsList = uilistbox(app.ModelSelectionPanel);
            app.SelectedModelsList.Position = [10, 130, 250, 90];
            app.SelectedModelsList.FontName = 'Segoe UI';
            app.SelectedModelsList.FontSize = 10;
            app.SelectedModelsList.FontWeight = 'bold';
            app.SelectedModelsList.BackgroundColor = [1, 1, 1];

            % Create RemoveSelectedButton
            app.RemoveSelectedButton = uibutton(app.ModelSelectionPanel, 'push');
            app.RemoveSelectedButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveSelectedButtonPushed, true);
            app.RemoveSelectedButton.Position = [10, 90, 120, 25];
            app.RemoveSelectedButton.Text = 'Remove Selected';
            app.RemoveSelectedButton.FontWeight = 'bold';
            app.RemoveSelectedButton.BackgroundColor = [0.9, 0.6, 0.2];
            app.RemoveSelectedButton.FontColor = [1, 1, 1];
            app.RemoveSelectedButton.FontSize = 10;
            app.RemoveSelectedButton.FontName = 'Segoe UI';

            % Create ClearSelectionButton
            app.ClearSelectionButton = uibutton(app.ModelSelectionPanel, 'push');
            app.ClearSelectionButton.ButtonPushedFcn = createCallbackFcn(app, @ClearSelectionButtonPushed, true);
            app.ClearSelectionButton.Position = [140, 90, 120, 25];
            app.ClearSelectionButton.Text = 'Clear All';
            app.ClearSelectionButton.FontWeight = 'bold';
            app.ClearSelectionButton.BackgroundColor = [0.8, 0.2, 0.2];
            app.ClearSelectionButton.FontColor = [1, 1, 1];
            app.ClearSelectionButton.FontSize = 10;
            app.ClearSelectionButton.FontName = 'Segoe UI';

            % Create SelectAllCheckbox
            app.SelectAllCheckbox = uicheckbox(app.ModelSelectionPanel);
            app.SelectAllCheckbox.Text = 'Select All Models';
            app.SelectAllCheckbox.Position = [10, 55, 150, 20];
            app.SelectAllCheckbox.ValueChangedFcn = createCallbackFcn(app, @SelectAllCheckboxValueChanged, true);
            app.SelectAllCheckbox.FontWeight = 'bold';
            app.SelectAllCheckbox.FontSize = 11;
            app.SelectAllCheckbox.FontName = 'Segoe UI';

            % Create RunPredictionsButton
            app.RunPredictionsButton = uibutton(app.ModelSelectionPanel, 'push');
            app.RunPredictionsButton.ButtonPushedFcn = createCallbackFcn(app, @RunPredictionsButtonPushed, true);
            app.RunPredictionsButton.Position = [10, 10, 125, 30];
            app.RunPredictionsButton.Text = 'Run Predictions';
            app.RunPredictionsButton.FontWeight = 'bold';
            app.RunPredictionsButton.BackgroundColor = [0.9, 0.3, 0.3];
            app.RunPredictionsButton.FontColor = [1, 1, 1];
            app.RunPredictionsButton.FontSize = 11;
            app.RunPredictionsButton.FontName = 'Segoe UI';

            % Create ShowComparisonButton
            app.ShowComparisonButton = uibutton(app.ModelSelectionPanel, 'push');
            app.ShowComparisonButton.ButtonPushedFcn = createCallbackFcn(app, @ShowComparisonButtonPushed, true);
            app.ShowComparisonButton.Position = [145, 10, 115, 30];
            app.ShowComparisonButton.Text = 'Show Comparison';
            app.ShowComparisonButton.FontWeight = 'bold';
            app.ShowComparisonButton.BackgroundColor = [0.8, 0.8, 0.8];
            app.ShowComparisonButton.FontSize = 11;
            app.ShowComparisonButton.FontName = 'Segoe UI';
            app.ShowComparisonButton.Enable = 'off';

            % Create ResultsVisualizationPanel
            app.ResultsVisualizationPanel = uipanel(app.UIFigure);
            app.ResultsVisualizationPanel.Title = 'Results Visualization';
            app.ResultsVisualizationPanel.Position = [308, 342, 440, 305];
            app.ResultsVisualizationPanel.BackgroundColor = [0.96, 0.94, 0.98]; % Light purple-gray
            app.ResultsVisualizationPanel.FontWeight = 'bold';
            app.ResultsVisualizationPanel.FontSize = 11;
            app.ResultsVisualizationPanel.FontName = 'Segoe UI';

            % Create ConfusionMatrixAxes
            app.ConfusionMatrixAxes = uiaxes(app.ResultsVisualizationPanel);
            app.ConfusionMatrixAxes.Position = [10, 10, 400, 250];
            app.ConfusionMatrixAxes.Visible = 'off';

            % Create ModelSelectorLabel
            app.ModelSelectorLabel = uilabel(app.ResultsVisualizationPanel);
            app.ModelSelectorLabel.HorizontalAlignment = 'right';
            app.ModelSelectorLabel.Position = [4, 260, 150, 20];
            app.ModelSelectorLabel.Text = 'Select Model to Visualize:';
            app.ModelSelectorLabel.BackgroundColor = [0.96, 0.94, 0.98];
            app.ModelSelectorLabel.FontWeight = 'bold';
            app.ModelSelectorLabel.FontSize = 11;
            app.ModelSelectorLabel.FontName = 'Segoe UI';

            % Create ModelSelector
            app.ModelSelector = uidropdown(app.ResultsVisualizationPanel);
            app.ModelSelector.Items = {'KNN', 'ANN', 'SVM', 'EN', 'DA', 'NB', 'DT'};
            app.ModelSelector.ValueChangedFcn = createCallbackFcn(app, @ModelSelectorValueChanged, true);
            app.ModelSelector.Position = [158, 260, 150, 20];
            app.ModelSelector.FontWeight = 'bold';
            app.ModelSelector.BackgroundColor = [1, 1, 1];
            app.ModelSelector.FontSize = 11;
            app.ModelSelector.FontName = 'Segoe UI';

            % Create ExportToFigureButton
            app.ExportToFigureButton = uibutton(app.ResultsVisualizationPanel, 'push');
            app.ExportToFigureButton.ButtonPushedFcn = createCallbackFcn(app, @ExportToFigureButtonPushed, true);
            app.ExportToFigureButton.Position = [315, 260, 120, 20];
            app.ExportToFigureButton.Text = 'Export to Figure';
            app.ExportToFigureButton.FontWeight = 'bold';
            app.ExportToFigureButton.BackgroundColor = [0.8, 0.9, 1.0];
            app.ExportToFigureButton.HorizontalAlignment = 'left';
            app.ExportToFigureButton.FontSize = 10;
            app.ExportToFigureButton.FontName = 'Segoe UI';

            % Create ExportPanel
            app.ExportPanel = uipanel(app.UIFigure);
            app.ExportPanel.Title = 'Export Results';
            app.ExportPanel.Position = [759, 342, 319, 305];
            app.ExportPanel.BackgroundColor = [0.98, 0.96, 0.92]; % Light orange-gray
            app.ExportPanel.FontWeight = 'bold';
            app.ExportPanel.FontSize = 11;
            app.ExportPanel.FontName = 'Segoe UI';

            % Create ExportToExcelButton
            app.ExportToExcelButton = uibutton(app.ExportPanel, 'push');
            app.ExportToExcelButton.ButtonPushedFcn = createCallbackFcn(app, @ExportToExcelButtonPushed, true);
            app.ExportToExcelButton.Position = [20, 10, 120, 30];
            app.ExportToExcelButton.Text = 'Export to Excel';
            app.ExportToExcelButton.FontWeight = 'bold';
            app.ExportToExcelButton.BackgroundColor = [0.2, 0.6, 0.2];
            app.ExportToExcelButton.FontColor = [1, 1, 1];
            app.ExportToExcelButton.HorizontalAlignment = 'left';
            app.ExportToExcelButton.FontSize = 11;
            app.ExportToExcelButton.FontName = 'Segoe UI';

            % Create ResultsTable
            app.ResultsTable = uitable(app.ExportPanel);
            app.ResultsTable.ColumnName = {'Model', 'Accuracy', 'Precision', 'Recall', 'F1-Score', 'Kappa'};
            app.ResultsTable.RowName = {};
            app.ResultsTable.Position = [20, 50, 280, 228];
            app.ResultsTable.FontWeight = 'bold';
            app.ResultsTable.BackgroundColor = [1, 1, 1; 0.96, 0.96, 0.96];
            app.ResultsTable.FontSize = 11;
            app.ResultsTable.FontName = 'Segoe UI';

            % Create ManualInputPanel - make it smaller to accommodate results beside it
            app.ManualInputPanel = uipanel(app.UIFigure);
            app.ManualInputPanel.Title = 'Manual Input (Enter 12 Feature Values)';
            app.ManualInputPanel.Position = [22, 30, 520, 300]; % Reduced width
            app.ManualInputPanel.BackgroundColor = [0.94, 0.98, 0.96]; % Light cyan-gray
            app.ManualInputPanel.FontWeight = 'bold';
            app.ManualInputPanel.FontSize = 11;
            app.ManualInputPanel.FontName = 'Segoe UI';

            % Create FeatureInputFields as individual components
            % Adjust positions to fit in the narrower panel
            % Feature 1
            app.FeatureInputFields(1) = uieditfield(app.ManualInputPanel, 'numeric');
            app.FeatureInputFields(1).Position = [20, 220, 80, 30];
            app.FeatureInputFields(1).Value = 0;
            
            % Feature 2
            app.FeatureInputFields(2) = uieditfield(app.ManualInputPanel, 'numeric');
            app.FeatureInputFields(2).Position = [120, 220, 80, 30];
            app.FeatureInputFields(2).Value = 0;
            
            % Feature 3
            app.FeatureInputFields(3) = uieditfield(app.ManualInputPanel, 'numeric');
            app.FeatureInputFields(3).Position = [220, 220, 80, 30];
            app.FeatureInputFields(3).Value = 0;
            
            % Feature 4
            app.FeatureInputFields(4) = uieditfield(app.ManualInputPanel, 'numeric');
            app.FeatureInputFields(4).Position = [320, 220, 80, 30];
            app.FeatureInputFields(4).Value = 0;
            
            % Feature 5
            app.FeatureInputFields(5) = uieditfield(app.ManualInputPanel, 'numeric');
            app.FeatureInputFields(5).Position = [420, 220, 80, 30];
            app.FeatureInputFields(5).Value = 0;
            
            % Feature 6
            app.FeatureInputFields(6) = uieditfield(app.ManualInputPanel, 'numeric');
            app.FeatureInputFields(6).Position = [20, 170, 80, 30];
            app.FeatureInputFields(6).Value = 0;
            
            % Feature 7
            app.FeatureInputFields(7) = uieditfield(app.ManualInputPanel, 'numeric');
            app.FeatureInputFields(7).Position = [120, 170, 80, 30];
            app.FeatureInputFields(7).Value = 0;
            
            % Feature 8
            app.FeatureInputFields(8) = uieditfield(app.ManualInputPanel, 'numeric');
            app.FeatureInputFields(8).Position = [220, 170, 80, 30];
            app.FeatureInputFields(8).Value = 0;
            
            % Feature 9
            app.FeatureInputFields(9) = uieditfield(app.ManualInputPanel, 'numeric');
            app.FeatureInputFields(9).Position = [320, 170, 80, 30];
            app.FeatureInputFields(9).Value = 0;
            
            % Feature 10
            app.FeatureInputFields(10) = uieditfield(app.ManualInputPanel, 'numeric');
            app.FeatureInputFields(10).Position = [420, 170, 80, 30];
            app.FeatureInputFields(10).Value = 0;
            
            % Feature 11
            app.FeatureInputFields(11) = uieditfield(app.ManualInputPanel, 'numeric');
            app.FeatureInputFields(11).Position = [20, 120, 80, 30];
            app.FeatureInputFields(11).Value = 0;
            
            % Feature 12
            app.FeatureInputFields(12) = uieditfield(app.ManualInputPanel, 'numeric');
            app.FeatureInputFields(12).Position = [120, 120, 80, 30];
            app.FeatureInputFields(12).Value = 0;

            % Configure all feature input fields
            for i = 1:12
                app.FeatureInputFields(i).Limits = [-Inf, Inf];
                app.FeatureInputFields(i).RoundFractionalValues = 'off';
                app.FeatureInputFields(i).FontSize = 11;
                app.FeatureInputFields(i).FontName = 'Consolas';
                app.FeatureInputFields(i).BackgroundColor = [1, 1, 1];
                
                % Create label for each feature
                featureLabel = uilabel(app.ManualInputPanel);
                featureLabel.Text = sprintf('F%d', i); % Shorter label to fit
                featureLabel.Position = app.FeatureInputFields(i).Position + [0, 25, 0, 0];
                featureLabel.HorizontalAlignment = 'center';
                featureLabel.FontWeight = 'bold';
                featureLabel.FontSize = 10; % Smaller font
            end

            % Create PredictManualButton
            app.PredictManualButton = uibutton(app.ManualInputPanel, 'push');
            app.PredictManualButton.ButtonPushedFcn = createCallbackFcn(app, @PredictManualButtonPushed, true);
            app.PredictManualButton.Position = [20, 20, 150, 30];
            app.PredictManualButton.Text = 'Predict Manual Input';
            app.PredictManualButton.FontWeight = 'bold';
            app.PredictManualButton.BackgroundColor = [0.2, 0.5, 0.8];
            app.PredictManualButton.FontColor = [1, 1, 1];
            app.PredictManualButton.FontSize = 11;
            app.PredictManualButton.FontName = 'Segoe UI';

            % Create ClearManualButton
            app.ClearManualButton = uibutton(app.ManualInputPanel, 'push');
            app.ClearManualButton.ButtonPushedFcn = createCallbackFcn(app, @ClearManualButtonPushed, true);
            app.ClearManualButton.Position = [180, 20, 80, 30];
            app.ClearManualButton.Text = 'Clear';
            app.ClearManualButton.FontWeight = 'bold';
            app.ClearManualButton.BackgroundColor = [0.9, 0.3, 0.3];
            app.ClearManualButton.FontColor = [1, 1, 1];
            app.ClearManualButton.FontSize = 11;
            app.ClearManualButton.FontName = 'Segoe UI';

            % Create ManualPredictionResultLabel
            app.ManualPredictionResultLabel = uilabel(app.ManualInputPanel);
            app.ManualPredictionResultLabel.Position = [280, 16, 225, 140];
            app.ManualPredictionResultLabel.Text = 'Results will appear here';
            app.ManualPredictionResultLabel.VerticalAlignment = 'top';
            app.ManualPredictionResultLabel.HorizontalAlignment = 'left';
            app.ManualPredictionResultLabel.BackgroundColor = [1, 1, 1];
            app.ManualPredictionResultLabel.FontWeight = 'bold';
            app.ManualPredictionResultLabel.WordWrap = 'on';            
            app.ManualPredictionResultLabel.FontSize = 11;

            % Create ManualResultsPanel beside the ManualInputPanel
            app.ManualResultsPanel = uipanel(app.UIFigure);
            app.ManualResultsPanel.Title = 'Manual Prediction Results';
            app.ManualResultsPanel.Position = [580, 30, 500, 300]; % Positioned beside manual input
            app.ManualResultsPanel.BackgroundColor = [0.98, 0.96, 0.92]; % Light orange-gray
            app.ManualResultsPanel.FontWeight = 'bold';
            app.ManualResultsPanel.FontSize = 11;
            app.ManualResultsPanel.FontName = 'Segoe UI';

            % Create ManualResultsTable for row distribution display
            app.ManualResultsTable = uitable(app.ManualResultsPanel);
            app.ManualResultsTable.ColumnName = {'Model', 'Prediction', 'Confidence'};
            app.ManualResultsTable.RowName = {};
            app.ManualResultsTable.Position = [20, 50, 446, 230];
            app.ManualResultsTable.FontWeight = 'bold';
            app.ManualResultsTable.BackgroundColor = [1, 1, 1; 0.96, 0.96, 0.96];
            app.ManualResultsTable.FontSize = 11;
            app.ManualResultsTable.FontName = 'Segoe UI';
            app.ManualResultsTable.ColumnWidth = {120, 120, 140};

            % Create ExportManualResultsButton
            app.ExportManualResultsButton = uibutton(app.ManualResultsPanel, 'push');
            app.ExportManualResultsButton.ButtonPushedFcn = createCallbackFcn(app, @ExportManualResultsButtonPushed, true);
            app.ExportManualResultsButton.Position = [20, 10, 150, 30];
            app.ExportManualResultsButton.Text = 'Export Results';
            app.ExportManualResultsButton.FontWeight = 'bold';
            app.ExportManualResultsButton.BackgroundColor = [0.2, 0.6, 0.2];
            app.ExportManualResultsButton.FontColor = [1, 1, 1];
            app.ExportManualResultsButton.FontSize = 11;
            app.ExportManualResultsButton.FontName = 'Segoe UI';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ModelComparisonApp_Ibrahim

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end

% ... (keep all the helper functions the same as before)

% Enhanced helper functions with Kappa support
function [accuracy, precision, recall, f1, kappa] = calculateEnhancedMetrics(trueLabels, predictedLabels)
    cm = confusionmat(trueLabels, predictedLabels);
    accuracy = sum(diag(cm)) / sum(cm(:));
    
    % Calculate Cohen's Kappa
    n = sum(cm(:));
    po = accuracy; % observed agreement
    pe = sum(sum(cm, 1) .* sum(cm, 2)') / (n * n); % expected agreement
    kappa = (po - pe) / (1 - pe + eps);
    
    numClasses = size(cm, 1);
    precision = zeros(1, numClasses);
    recall = zeros(1, numClasses);
    f1 = zeros(1, numClasses);
    
    for i = 1:numClasses
        tp = cm(i, i);
        fp = sum(cm(:, i)) - tp;
        fn = sum(cm(i, :)) - tp;
        
        precision(i) = tp / (tp + fp + eps);
        recall(i) = tp / (tp + fn + eps);
        f1(i) = 2 * (precision(i) * recall(i)) / (precision(i) + recall(i) + eps);
    end
end

function plotEnhancedConfusionMatrix(ax, confMat, classNames, titleText)
    % Enhanced confusion matrix plotting function
    cla(ax);
    
    if ~isvalid(ax)
        error('Invalid axes handle');
    end
    
    % Enhanced color map
    blueMap = [0.95, 0.98, 1.0; 
               0.85, 0.92, 1.0;
               0.75, 0.86, 1.0;
               0.65, 0.80, 1.0;
               0.45, 0.70, 1.0;
               0.25, 0.60, 1.0];
    lightRed = [1.0, 0.9, 0.9];
    
    set(ax, 'Visible', 'on');
    
    % Create enhanced color matrix
    colorMatrix = ones(size(confMat, 1), size(confMat, 2), 3);
    maxDiagValue = max(diag(confMat));
    if maxDiagValue == 0
        maxDiagValue = 1;
    end
    
    for i = 1:size(confMat, 1)
        for j = 1:size(confMat, 2)
            if i == j
                intensity = confMat(i, j) / maxDiagValue;
                % FIX: Ensure colorIndex is always a valid integer between 1 and size(blueMap, 1)
                colorIndex = max(1, min(size(blueMap, 1), ceil(intensity * size(blueMap, 1))));
                % Additional safety check
                if colorIndex < 1 || colorIndex > size(blueMap, 1) || isnan(colorIndex)
                    colorIndex = 1;
                end
                colorMatrix(i, j, :) = blueMap(colorIndex, :);
            elseif confMat(i, j) > 0
                colorMatrix(i, j, :) = lightRed;
            else
                colorMatrix(i, j, :) = [1, 1, 1];
            end
        end
    end
    
    % Enhanced image plot
    image(ax, colorMatrix);
    title(ax, titleText, 'FontSize', 14, 'FontWeight', 'bold', 'Color', [0.2, 0.2, 0.5]);
    
    % Enhanced grid lines
    for x = 0.5:1:size(confMat, 2)+0.5
        line(ax, [x, x], [0.5, size(confMat, 1)+0.5], 'Color', [0.6, 0.6, 0.6], 'LineWidth', 1.2);
    end
    for y = 0.5:1:size(confMat, 1)+0.5
        line(ax, [0.5, size(confMat, 2)+0.5], [y, y], 'Color', [0.6, 0.6, 0.6], 'LineWidth', 1.2);
    end
    
    % Enhanced text annotations
    textStrings = num2str(confMat(:), '%d');
    textStrings = strtrim(cellstr(textStrings));
    [x, y] = meshgrid(1:size(confMat, 2), 1:size(confMat, 1));
    
    for i = 1:length(textStrings)
        row = y(i);
        col = x(i);
        if row ~= col && confMat(row, col) == 0
            textStrings{i} = '';
        end
    end
    
    textColors = cell(size(textStrings));
    for i = 1:length(textStrings)
        if isempty(textStrings{i})
            continue;
        end
        row = y(i);
        col = x(i);
        if row == col
            intensity = confMat(row, col) / maxDiagValue;
            if intensity > 0.5
                textColors{i} = 'w';
            else
                textColors{i} = 'k';
            end
        else
            textColors{i} = 'k';
        end
    end
    
    hStrings = text(ax, x(:), y(:), textStrings(:), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'FontSize', 12, ...
        'FontWeight', 'bold');
    
    for i = 1:length(hStrings)
        if ~isempty(textStrings{i})
            hStrings(i).Color = textColors{i};
        end
    end
    
    % Enhanced axes properties
    set(ax, 'XTick', 1:size(confMat, 2), ...
             'XTickLabel', classNames, ...
             'YTick', 1:size(confMat, 1), ...
             'YTickLabel', classNames, ...
             'TickLength', [0, 0], ...
             'FontSize', 11, ...
             'FontWeight', 'bold', ...
             'Box', 'on', ...
             'LineWidth', 1.5);
    
    xlabel(ax, 'Predicted Class', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel(ax, 'True Class', 'FontSize', 12, 'FontWeight', 'bold');
    
    colormap(ax, [blueMap; lightRed]);
    axis(ax, 'equal');
    axis(ax, 'tight');
end

function saveEnhancedFigure(src, ~, fig)
    [filename, pathname] = uiputfile({'*.png', 'PNG Image (*.png)'; ...
                                      '*.jpg', 'JPEG Image (*.jpg)'; ...
                                      '*.pdf', 'PDF File (*.pdf)'; ...
                                      '*.fig', 'MATLAB Figure (*.fig)'}, ...
                                     'Save Enhanced Figure As');
    if isequal(filename, 0)
        return;
    end
    
    filepath = fullfile(pathname, filename);
    [~, ~, ext] = fileparts(filename);
    
    try
        switch lower(ext)
            case {'.png', '.jpg'}
                % Save with high resolution
                print(fig, filepath, ['-d' ext(2:end)], '-r300');
            case '.pdf'
                print(fig, filepath, '-dpdf', '-r300');
            case '.fig'
                saveas(fig, filepath, 'fig');
        end
        msgbox(sprintf('Figure successfully saved to:\n%s', filepath), 'Save Complete', 'help');
    catch ME
        errordlg(sprintf('Error saving figure: %s', ME.message), 'Save Error');
    end
end

% Model prediction functions
function predictions = predict_optimized_svm(features)
    try
        load('optimized_svm_model.mat','optimized_svm_model');        
        predictions = optimized_svm_model.predictFcn(features);
    catch ME
        error('Error in SVM prediction: %s', ME.message);
    end
end

function predictions = predict_optimized_ann(features)
    try
        load('optimized_ann_model.mat','optimized_ann_model');        
        predictions = optimized_ann_model.predictFcn(features);
    catch ME
        error('Error in ANN prediction: %s', ME.message);
    end
end

function predictions = predict_optimized_knn(features)
    try
        load('optimized_knn_model.mat');        
        predictions = optimized_knn_model.predictFcn(features);
    catch ME
        error('Error in KNN prediction: %s', ME.message);
    end
end

function predictions = predict_optimized_en(features)
    try
        load('optimized_en_model.mat','optimized_en_model');        
        predictions = optimized_en_model.predictFcn(features);
    catch ME
        error('Error in EN prediction: %s', ME.message);
    end
end

function predictions = predict_optimized_da(features)
    try
        load('optimized_da_model.mat','optimized_da_model');        
        predictions = optimized_da_model.predictFcn(features);
    catch ME
        error('Error in DA prediction: %s', ME.message);
    end
end

function predictions = predict_optimized_nb(features)
    try
        load('optimized_nb_model.mat','optimized_nb_model');        
        predictions = optimized_nb_model.predictFcn(features);
    catch ME
        error('Error in NB prediction: %s', ME.message);
    end
end

function predictions = predict_optimized_dt(features)
    try
        load('optimized_dt_model.mat','optimized_dt_model');        
        predictions = optimized_dt_model.predictFcn(features);
    catch ME
        error('Error in DT prediction: %s', ME.message);
    end
end

