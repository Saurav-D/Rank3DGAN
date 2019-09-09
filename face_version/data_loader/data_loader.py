# DataLoader class - handles data loading
#       creates dataset object within tensorflow dataset API

import tensorflow as tf
import multiprocessing


class DataLoader:
    def __init__(self, config):
        self.config = config
        self.set_dataset()

    def set_dataset(self):
        '''
        creates a tensorflow dataset object
        initializable iterator with placeholder input for filenames
        '''

        self.filenames = tf.placeholder(tf.string, shape=[None])   # filenames placeholder
        dataset = tf.data.TFRecordDataset(self.filenames)
        dataset = dataset.map(self._parse_function, num_parallel_calls=multiprocessing.cpu_count())  # Parse the record into tensors.
        dataset = dataset.repeat()
        dataset = dataset.shuffle(self.config.dataLoader_buffer)
        dataset = dataset.batch(self.config.batch_size)
        self.iterator = dataset.make_initializable_iterator()
        
        self.filenames_pair = tf.placeholder(tf.string, shape=[None])
        dataset_pair = tf.data.TFRecordDataset(self.filenames_pair)
        dataset_pair = dataset_pair.map(self._parse_function, num_parallel_calls=multiprocessing.cpu_count())
        dataset_pair = dataset_pair.repeat()
        dataset_pair = dataset_pair.shuffle(self.config.dataLoader_buffer)
        dataset_pair = dataset_pair.batch(self.config.batch_size//2)
        self.iterator_pair = dataset_pair.make_initializable_iterator()
        

    def get_next(self):
        self.get_next = self.iterator.get_next()
        self.get_next_pair = self.iterator_pair.get_next()
        return (tf.decode_raw(self.get_next["image_string"], tf.float32), tf.decode_raw(self.get_next_pair["image_string"], tf.float32))

    @staticmethod
    def _parse_function(example_proto):
        features = {"image_string": tf.FixedLenFeature((), tf.string, default_value="")}
        parsed_features = tf.parse_single_example(example_proto, features)
        return parsed_features



