#!/bin/bash

# Default values, HyperParameter to be tuned
# LEARNING_RATE_DEFAULT = 1e-2
# BATCH_SIZE_DEFAULT = 1
# RANDOM_BATCH_DEFAULT = True
# S_FOLD_DEFAULT = 10
# REPETITION_SCALAR_DEFAULT = 1
# MAX_STEPS_DEFAULT = REPETITION_SCALAR_DEFAULT*(270 - 270/S_FOLD_DEFAULT)/BATCH_SIZE_DEFAULT
# EVAL_FREQ_DEFAULT = EVAL_FREQ_DEFAULT = (S_FOLD_DEFAULT - 1)/BATCH_SIZE_DEFAULT
# CHECKPOINT_FREQ_DEFAULT = MAX_STEPS_DEFAULT
# PRINT_FREQ_DEFAULT = int(MAX_STEPS_DEFAULT/8)
# OPTIMIZER_DEFAULT = 'ADAM'
# WEIGHT_REGULARIZER_DEFAULT = 'l2'
# WEIGHT_REGULARIZER_STRENGTH_DEFAULT = 0.18
# ACTIVATION_FCT_DEFAULT = 'elu'
# LSTM_SIZE_DEFAULT = '50, 10'
# FC_NUM_HIDDEN_UNITS = '100'  # this are two layers n_hidden(FC1)=[lstm,100], n_hidden(FC2)=[100,1]
# FEAT_EPOCH_DEFAULT = CHECKPOINT_FREQ_DEFAULT-1
# HILBERT_POWER_INPUT_DEFAULT = True
# COMPONENT_DEFAULT = "best"
# SUMMARIES_DEFAULT = True
# SUBJECT_DEFAULT = 36

# Scripts will be processed successively
### Task: LSTM-Network

# Testing
# python3 NeVRo.py --summaries False
# python3 LSTM_pred_plot.py Save_plots Path_Specificities(empty or 'subfolder/')
# python3 LSTM_pred_plot.py True lstm-150_fc-150/
# python3 NeVRo.py --subject 36 --lstm_size 150,50 --summaries True --plot True --path_specificities test_lstm-150-50/
# python3 NeVRo.py --subject 36 --lstm_size 150 --fc_n_hidden 100 --summaries False --plot True --path_specificities test2_lstm-150_fc-100/
# python3 NeVRo.py --subject 36 --lstm_size 150,100 --fc_n_hidden 100 --summaries False --plot True --path_specificities test2_lstm-150-100_fc-150/

## Hyperparameter Search (HPS)

# Specific Search: 2-LSTM + 1-FC, Learning Rate, Weight Reg-Strength
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 50,25 --path_specificities HPS_lstm-50-25/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 50,25 --learning_rate 1e-4 --path_specificities HPS_lstm-50-25_lr-1e-4/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 50,25 --weight_reg_strength 0.36 --path_specificities HPS_lstm-50-25_l2-036/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 50,25 --weight_reg_strength 0.36 --learning_rate 1e-4 --path_specificities HPS_lstm-50-25_l2-036_lr-1e-4/

# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 50,50 --path_specificities HPS_lstm-50-50/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 50,50 --learning_rate 1e-4 --path_specificities HPS_lstm-50-50_lr-1e-4/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 50,50 --weight_reg_strength 0.36 --path_specificities HPS_lstm-50-50_l2-0.36/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 50,50 --weight_reg_strength 0.36 --learning_rate 1e-4 --path_specificities HPS_lstm-50-50_l2-0.36_lr-1e-4/

# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 75,25 --path_specificities HPS_lstm-75-25/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 75,25 --learning_rate 1e-4 --path_specificities HPS_lstm-75-25_lr-1e-4/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 75,25 --weight_reg_strength 0.36 --path_specificities HPS_lstm-75-25_l2-036/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 75,25 --weight_reg_strength 0.36 --learning_rate 1e-4 --path_specificities HPS_lstm-75-25_l2-036_lr-1e-4/

# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 50,25 --path_specificities HPS_lstm-50-25/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 50,25 --learning_rate 1e-4 --path_specificities HPS_lstm-50-25_lr-1e-4/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 50,25 --weight_reg_strength 0.36 --path_specificities HPS_lstm-50-25_l2-036/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 50,25 --weight_reg_strength 0.36 --learning_rate 1e-4 --path_specificities HPS_lstm-50-25_l2-036_lr-1e-4/

# Learning Rate
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --learning_rate 1e-2 --path_specificities HPS_lr-1e-2/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --learning_rate 1e-3 --path_specificities HPS_lr-1e-3/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --learning_rate 1e-4 --path_specificities HPS_lr-1e-4/

# Weight Reg
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --weight_reg none --path_specificities HPS_wreg-none/

# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --weight_reg l1 --weight_reg_strength 0.18 --path_specificities HPS_wreg-l1-018/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --weight_reg l1 --weight_reg_strength 0.36 --path_specificities HPS_wreg-l1-036/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --weight_reg l1 --weight_reg_strength 0.72 --path_specificities HPS_wreg-l1-072/

# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --weight_reg l2 --weight_reg_strength 0.18 --path_specificities HPS_wreg-l2-018/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --weight_reg l2 --weight_reg_strength 0.36 --path_specificities HPS_wreg-l2-036/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --weight_reg l2 --weight_reg_strength 0.72 --path_specificities HPS_wreg-l2-072/

# Activation Function
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --activation_fct elu --path_specificities HPS_actfunc-elu/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --activation_fct relu --path_specificities HPS_actfunc-relu/

# LSTM-Size
# 1-LSTM + 1-FC
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 50 --path_specificities HPS_lstm-50/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 100 --path_specificities HPS_lstm-100/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 200 --path_specificities HPS_lstm-200/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 250 --path_specificities HPS_lstm-250/

# 2-LSTM + 1-FC
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 50,50 --path_specificities HPS_lstm-50-50/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 100,50 --path_specificities HPS_lstm-100-50/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 200,50 --path_specificities HPS_lstm-200-50/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 250,50 --path_specificities HPS_lstm-250-50/

# 1-LSTM + 2-FC
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --fc_n_hidden 25 --path_specificities HPS_fc-25/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --fc_n_hidden 50 --path_specificities HPS_fc-50/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --fc_n_hidden 100 --path_specificities HPS_fc-100/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --fc_n_hidden 200 --path_specificities HPS_fc-200/

# 2-LSTM + 2-FC
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 50,50 --fc_n_hidden 25 --path_specificities HPS_lstm-50-50_fc-25/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 100,50 --fc_n_hidden 50 --path_specificities HPS_lstm-100-50_fc-50/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 200,50 --fc_n_hidden 100 --path_specificities HPS_lstm-200-50_fc-100/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 250,50 --fc_n_hidden 200 --path_specificities HPS_lstm-250-50_fc-200/

# New Accuracy 1-LSTM + 1-FC (Oct 29, 2017)
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 50 --path_specificities HPS_new_acc_lstm-50/

# # Fine-Grainded Search
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 100,50,25 --weight_reg_strength 0.36 --path_specificities HPS_lstm-100-50-25_l2-0.36/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 50,50 --weight_reg_strength 0.36 --path_specificities HPS_lstm-50-50_l2-0.36/
# python3 NeVRo.py --subject 36 --seed True --repet_scalar 320 --lstm_size 100 --weight_reg_strength 0.36 --path_specificities HPS_lstm-100_l2-0.36/