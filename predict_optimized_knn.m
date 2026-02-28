function predictions = predict_optimized_knn(features)
    try
        load('optimized_knn_model.mat');        
        % Get predictions from optimized ANN model
        %[predictions_numeric, ~] = predict(optimizedModel.model, standardizedData);
        predictions = optimized_knn_model.predictFcn(features);
        
    catch ME
        error('Error in KNN prediction: %s', ME.message);
    end
