% RUN_APP.m - Launch the Model Comparison App
function RUN_APP()
    % Launch the app
    app = ModelComparisonApp_Ibrahim;
        % Keep the app reference if you need to programmatically interact with it
    assignin('base', 'ModelComparisonApp', app);
    
    fprintf('Model Comparison App launched successfully!\n');
end