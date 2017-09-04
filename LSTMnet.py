"""
Build LSTM architecture
Author: Simon Hofmann | <[surname].[lastname][at]protonmail.com> | 2017
"""

import tensorflow as tf
# import numpy as np

# TODO Hilbert Transform to power-spectrum of SSD/Spoc components
# with Hilbert you can keep sampl.freq
# needs filtered data (alpha, 8Hz-12Hz)
# Check whether SSD is filtered


class LSTMnet:
    """
    This class implements a LSTM neural network in TensorFlow.
    It incorporates a certain graph model to be trained and to be used
    in inference.

    # Potentially for layer visualization check out Beholder PlugIn
    # https://www.youtube.com/watch?feature=youtu.be&v=06HjEr0OX5k&app=desktop
    """

    def __init__(self, n_classes, weight_regularizer=tf.contrib.layers.l2_regularizer(scale=0.18)):
        """
        Constructor for an LSTMnet object.
        Args:
            n_classes: int, number of classes of the classification problem. This number is required in order to specify
            the output dimensions of the LSTMnet.
            weight_regularizer: to be applied weight regularization
        """

        self.n_classes = n_classes
        self.fc2_post_activation = None
        self.fc1_post_activation = None
        self.post_flatten = None
        self.weight_regularizer = weight_regularizer

    def inference(self, x):
        """
        Performs inference given an input tensor. Here an input
        tensor undergoes a series of nonlinear operations as defined in this method.

        Using variable and name scopes in order to make your graph more intelligible
        for later references in TensorBoard.
        Define name scope for the whole model or for each operator group (e.g. fc+relu)
        individually to group them by name.

        Args:
          x: 3D float Tensor of size [batch_size, input_length, input_channels]

        Returns:
          infer: 2D float Tensor of size [batch_size, self.n_classes]. Returns
                 the infer outputs (before softmax transformation) of the
                 network. These infer(logits) can be used with loss and accuracy
                 to evaluate the model.
        """

        with tf.variable_scope('LSTMnet'):
            # TODO Build Model here
            # TODO lstm_size
            post_lstm, final_state = self._create_lstm_layer(x=x, layer_name="lstm1", lstm_size=None)
            infer = None

            tf.nn.tanh(x=infer, name="tanh_inference")
            pass
        # ,,,
        probabilities = []

        # infer = tf.matmul(output, softmax_w) + softmax_b
        return infer

    def _create_lstm_layer(self, x, layer_name, lstm_size=128):
        """
        Creates a LSTM Layer.
        https://www.tensorflow.org/tutorials/recurrent#lstm
        'Unrolled' version of the network contains a fixed number (num_steps) of LSTM inputs and outputs.

        lstm(num_units)
        The number of units (num_units) is a parameter in the LSTM, referring to the dimensionality of the hidden
        state and dimensionality of the output state (they must be equal)
        (see: https://www.quora.com/What-is-the-meaning-of-“The-number-of-units-in-the-LSTM-cell)
        => num_units = n_hidden = e.g., 128 << hidden layer num of features
        (see: https://github.com/aymericdamien/TensorFlow-Examples/blob/master/examples/
        3_NeuralNetworks/recurrent_network.py)

        'The definition of cell in this package differs from the definition used in the literature.
        In the literature, cell refers to an object with a single scalar output. The definition in this package refers
        to a horizontal array of such units.'

        :param x: Input to layer
        :param layer_name: Name of Layer
        :param lstm_size: Number of hidden units in cell (HyperParameter, to be tuned)
        :return: Layer Output
        """
        with tf.variable_scope(layer_name):
            num_steps = x.shape[0]  # = samp.freq. = 250
            batch_size = 1
            # lstm_size = n_hidden  # TODO HyperParameter, to be tuned

            # Unstack to get a list of 'n_steps' tensors of shape (batch_size, n_input)
            # if x hase shape [batch_size(1), samples-per-second(250), components(2))
            x = tf.unstack(value=x, num=num_steps, axis=1, name="unstack")  # does not work like that
            # Now: x is list of [250 x (1, 2)]

            # Define LSTM cell
            lstm_cell = tf.contrib.rnn.BasicLSTMCell(num_units=lstm_size)
            # lstm_cell.state_size

            # Initial state of the LSTM memory
            state = tf.zeros([batch_size, lstm_cell.state_size])  # initial_state
            # state = lstm.zero_state(batch_size=batch_size, dtype=tf.float32)  # initial_state

            outputs, state = tf.contrib.rnn.static_rnn(cell=lstm_cell, inputs=x, initial_state=state,  # init (optional)
                                                       dtype=tf.float32, sequence_length=num_steps, scope=None)
            #  rnn.static_rnn calculates basically this:
            # outputs = []
            # for input_ in x:
            #     output, state = lstm_cell(input_, state)
            #     outputs.append(output)
            # Check: https://www.tensorflow.org/versions/r1.1/api_docs/python/tf/contrib/rnn/static_rnn

            final_state = state

            # TODO how to define output:
            # Different options: 1) last lstm output 2) average over all outputs
            # or 3) right-weighted average (last values have stronger impact)
            # here option 1)
            lstm_output = outputs[-1]  # = output

        return lstm_output, final_state

    def _create_fc_layer(self, x, layer_name, shape):
        """
        :param x: Input to layer
        :param layer_name: Name of Layer
        :param shape: Shape from input to output
        :return: Layer activation
        """
        with tf.variable_scope(layer_name):
            weights = tf.get_variable(name=layer_name + "/weights",
                                      shape=shape,
                                      initializer=tf.contrib.layers.xavier_initializer(),
                                      # Reg-scale based on practical2 experiment
                                      regularizer=self.weight_regularizer)

            self._var_summaries(weights, layer_name + "/weights")

            biases = tf.get_variable(name=layer_name + "/biases",
                                     shape=[shape[1]],
                                     initializer=tf.constant_initializer(0.0))

            self._var_summaries(biases, layer_name + "/biases")

            # activation:
            with tf.name_scope(layer_name + "/XW_Bias"):
                # Linear activation, using rnn inner loop last output
                pre_activation = tf.matmul(x, weights) + biases
                tf.summary.histogram(layer_name + "/pre_activation", pre_activation)

        return pre_activation

    @staticmethod
    def _var_summaries(var, name):

        with tf.name_scope("summaries"):
            mean = tf.reduce_mean(var)
            tf.summary.scalar("mean/" + name, mean)
            with tf.name_scope("stddev"):
                stddev = tf.sqrt(tf.reduce_mean(tf.square(var - mean)))

            tf.summary.scalar("stddev/" + name, stddev)
            tf.summary.scalar("max/" + name, tf.reduce_max(var))
            tf.summary.scalar("min/" + name, tf.reduce_min(var))
            tf.summary.histogram(name, var)

    @staticmethod
    def accuracy(infer, ratings):
        """
        Calculate the prediction accuracy, i.e. the average correct predictions
        of the network.
        As in self.loss above, use tf.summary.scalar to save
        scalar summaries of accuracy for later use with the TensorBoard.

        Args:
          infer: 2D float Tensor of size [batch_size, self.n_classes].
                       The predictions returned through self.inference (logits).
          ratings: 2D int Tensor of size [batch_size, self.n_classes]
                     with one-hot encoding. Ground truth labels for
                     each observation in batch.

        Returns:
          accuracy: scalar float Tensor, the accuracy of predictions,
                    i.e. the average correct predictions over the whole batch.
        """
        with tf.name_scope("accuracy"):
            with tf.name_scope("correct_prediction"):
                # correct = tf.nn.in_top_k(predictions=logits, targetss=labels, k=1)  # should be: [1,0,0,1,0...]
                correct = tf.equal(tf.argmax(input=infer, dimension=1), tf.argmax(input=ratings, dimension=1))

            with tf.name_scope("accuracy"):
                # Return the number of true entries.
                accuracy = tf.reduce_mean(tf.cast(correct, tf.float32))

            tf.summary.scalar("accuracy", accuracy)

        return accuracy

    @staticmethod
    def loss(infer, ratings):
        """
        Calculates the multiclass cross-entropy loss from infer (logits) predictions and
        the ground truth labels. The function will also add the regularization
        loss from network weights to the total loss that is return.
        Check out: tf.nn.softmax_cross_entropy_with_logits (other option is with tanh)
        Use tf.summary.scalar to save scalar summaries of cross-entropy loss, regularization loss,
        and full loss (both summed) for use with TensorBoard.

        Args:
          infer: 2D float Tensor of size [batch_size, self.n_classes].
                       The predictions returned through self.inference (logits)
          ratings: 2D int Tensor of size [batch_size, self.n_classes]
                       with one-hot encoding. Ground truth labels for each
                       observation in batch.

        Returns:
          loss: scalar float Tensor, full loss = cross_entropy + reg_loss
        """
        reg_losses = tf.get_collection(tf.GraphKeys.REGULARIZATION_LOSSES)

        with tf.name_scope("cross_entropy"):
            # sparse_softmax_cross_entropy_with_logits(), could also be, since we have an exclusive classification
            # diff = tf.nn.sparse_softmax_cross_entropy_with_logits(logits, labels, name='cross_entropy_diff')
            diff = tf.nn.softmax_cross_entropy_with_logits(logits=infer, labels=ratings, name="cross_entropy_diff")

            # print("Just produced the diff in the loss function")

            with tf.name_scope("total"):
                cross_entropy = tf.reduce_mean(diff, name='cross_entropy_mean')
                loss = tf.add(cross_entropy, tf.add_n(reg_losses), name="Full_Loss")  # add_n==tf.reduce_sum(reg_losses)

            with tf.name_scope("summaries"):
                tf.summary.scalar("Full_loss", loss)
                tf.summary.scalar("Cross_Entropy_Loss", cross_entropy)
                tf.summary.scalar("Reg_Losses", tf.reduce_sum(reg_losses))

        return loss

# # Display tf.variables
# Check: https://stackoverflow.com/questions/33633370/how-to-print-the-value-of-a-tensor-object-in-tensorflow
# sess = tf.InteractiveSession()
# test_var = tf.constant([1., 2., 3.])
# test_var.eval()
# # Add print operation
# test_var = tf.Print(input_=test_var, data=[test_var], message="This is a tf. test variable")
# test_var.eval()
# # Add more stuff
# test_var2 = tf.add(x=test_var, y=test_var).eval()
# test_var2