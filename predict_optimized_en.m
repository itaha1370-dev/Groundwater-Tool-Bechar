function predictions = predict_optimized_en(features)
    try
        load('optimized_en_model.mat','optimized_en_model');        
        % Get predictions from optimized ANN model
        %[predictions_numeric, ~] = predict(optimizedModel.model, standardizedData);
        predictions = optimized_en_model.predictFcn(features);
        
    catch ME
        error('Error in EN prediction: %s', ME.message);
    end
