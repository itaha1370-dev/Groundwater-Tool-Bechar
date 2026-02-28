function predictions = predict_optimized_dt(features)
    try
        load('optimized_dt_model.mat','optimized_dt_model');        
        % Get predictions from optimized ANN model
        %[predictions_numeric, ~] = predict(optimizedModel.model, standardizedData);
        predictions = optimized_nb_model.predictFcn(features);
        
    catch ME
        error('Error in DT prediction: %s', ME.message);
    end
