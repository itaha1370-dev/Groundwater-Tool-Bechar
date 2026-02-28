function predictions = predict_optimized_svm(features)
    try
        load('optimized_svm_model.mat','optimized_svm_model');        
        % Get predictions from optimized ANN model
        %[predictions_numeric, ~] = predict(optimizedModel.model, standardizedData);
        predictions = optimized_svm_model.predictFcn(features);
        
    catch ME
        error('Error in SVM prediction: %s', ME.message);
    end
