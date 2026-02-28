function predictions = predict_optimized_nb(features)
    try
        load('optimized_nb_model.mat','optimized_nb_model');        
        % Get predictions from optimized ANN model
        %[predictions_numeric, ~] = predict(optimizedModel.model, standardizedData);
        predictions = optimized_nb_model.predictFcn(features);
        
    catch ME
        error('Error in NB prediction: %s', ME.message);
    end
