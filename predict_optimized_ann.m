function predictions = predict_optimized_ann(features)
    try
        load('optimized_ann_model.mat','optimized_ann_model');        
        % Get predictions from optimized ANN model
        %[predictions_numeric, ~] = predict(optimizedModel.model, standardizedData);
        predictions = optimized_ann_model.predictFcn(features);
        
    catch ME
        error('Error in ANN prediction: %s', ME.message);
    end
