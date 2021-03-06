from utils.config import process_config
from utils.utils import get_args
import os
import scipy.io as sio
import numpy as np


def main():
    # capture the config path from the run arguments
    args = get_args()
    # process the json configuration file
    config = process_config(args.config)

    # configure devices
    os.environ["CUDA_VISIBLE_DEVICES"] = config.gpus

    import tensorflow as tf
    from data_loader.data_loader import DataLoader
    from models.gan_model import GANModel

    # set GPUS configuration
    gpuconfig = tf.ConfigProto(allow_soft_placement=True, log_device_placement=False)
    gpuconfig.gpu_options.visible_device_list = config.gpus
    gpuconfig.gpu_options.allow_growth = True

    # create tensorflow session
    sess = tf.Session(config=gpuconfig)
    # create your data generator
    data = DataLoader(config)

    # create an instance of the model
    model = GANModel(data, config)
    # load model
    model.load(sess)

    # generate random noise vector (could replace by a specified noise)
    noise = tf.random_normal([1, config.latent_vec_dim])
    noise = tf.tile(noise,[config.batch_size,1])
    label = np.zeros((config.batch_size, 1))
    for i in range(config.batch_size):
        label[i] = -1+2*i/config.batch_size
    noise = sess.run(noise)
    generated_charts = sess.run(model.generator(tf.convert_to_tensor(noise),tf.cast(tf.convert_to_tensor(label), tf.float32)))
    # create generations folder
    generations_path = os.path.join('experiments', config.exp_name, 'generations')
    if not os.path.isdir(generations_path):
           os.mkdir(generations_path)
    sio.savemat(os.path.join(generations_path, 'generated_charts'), {'generated_charts': generated_charts})

    print('done')


if __name__ == '__main__':
    main()
