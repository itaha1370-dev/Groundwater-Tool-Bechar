function predictions = predict_optimized_da(features)
    try
        load('optimized_da_model.mat','optimized_da_model');        
        % Get predictions from optimized ANN model
        %[predictions_numeric, ~] = predict(optimizedModel.model, standardizedData);
        predictions = optimized_da_model.predictFcn(features);
        
    catch ME
        error('Error in DA prediction: %s', ME.message);
    end
