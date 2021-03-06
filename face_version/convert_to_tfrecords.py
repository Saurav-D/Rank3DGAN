import os
import numpy as np
import tensorflow as tf
import scipy.io as sio
import random
import glob
import argparse


def main():
    """ main:
        gather all the images from src_dir and save them into tfrecords in dst_dir
        the maximum num of examples in each tfr will be tfr_size.

        Arguments:
            1. src_dir: the directory with the flattened images in .mat format
            2. dst_dir: the tfrecords directory to save the tfrecords in

        Process:
        1. Gather all the .mat files
        2. split them into val and train (train_size, num_files-train_size)
        3. turn mat files into ndarrays
        4. concatenate the ndarrays in batches of tfr_size in the shape [tfr_size, image_numel]
        5. save each batch into a tfrrecord
    """

    argparser = argparse.ArgumentParser(description=__doc__)
    argparser.add_argument('-d', '--database_signature', metavar='D', default='None', help='The signature of the database')
    argparser.add_argument('-s', '--train_size_percent', metavar='S', default=100, help='The percentage of the training set')
    argparser.add_argument('-tfsz', '--tfr_size', metavar='TFSZ', default=500, help='Number of examples in tfrecord')
    argparser.add_argument('-p', '--pairs', default=False, action='store_true', help='Set flag for single meshes or pair meshes')

    args = argparser.parse_args()

    src_dir = 'databases/images/' + args.database_signature
    dst_dir = 'databases/tfrecords/' + args.database_signature + ('/single' if not args.pairs else '/pair')
    file_name_prefix = 'data'
    print_period = 1000

    print('converting {0} to {1}'.format(src_dir, dst_dir))
    # 1. Gather all the .mat files
    # 'single' folder has mesh dataset. 'pair_1' and 'pair_2' folders have mesh pairs dataset such that meshes with similar names have more attribute emphasis in 'pair_1' than 'pair_2'
    if not args.pairs:
        files = glob.glob(os.path.join(src_dir + '/single', '**/*.mat'), recursive=True)
    else:
        files_1 = glob.glob(os.path.join(src_dir + '/pair_1', '**/*.mat'), recursive=True)
        files_2 = glob.glob(os.path.join(src_dir + '/pair_2', '**/*.mat'), recursive=True)
        if len(files_1) != len(files_2):
            print('pairs mismatch. folders pair_1 and pair_2 should have the same number of files')
            return
        files = [ h for h in zip(files_1, files_2)]
    
    
    print(len(files))

    train_size = int((args.train_size_percent*len(files))/100)

    # 2. Split the files into val and train
    random.shuffle(files)
    train_files = files[: train_size]
    val_files = files[train_size:]
    all_files = [val_files, train_files]

    # convert each dataset into tfrecords
    dst_dir_val = os.path.join(dst_dir, 'val')
    dst_dir_train = os.path.join(dst_dir, 'train')
    dst_dirs = [dst_dir_val, dst_dir_train]

    # save info file
    dictionary = {'train_size': train_size,
                  'val_size': len(files)-train_size,
                  'dataset_size': len(files)}

    create_or_recreate_dir(dst_dir)
    np.save(os.path.join(dst_dir, 'info.npy'), dictionary)

    for files, dst_dir, data_type in zip(all_files, dst_dirs, ['val', 'train']):
        print('converting {0} dataset of size {1}'.format(data_type, len(files)))
        create_or_recreate_dir(dst_dir)
        turn_dataset_to_tfrecords(files=files, dst_dir=dst_dir, tfr_size=args.tfr_size, file_name_prefix=file_name_prefix, print_period=print_period, pairs=args.pairs)


def create_or_recreate_dir(dir):
    import shutil
    if os.path.isdir(dir):
        #shutil.rmtree(dir)
        return
    os.makedirs(dir)


def turn_dataset_to_tfrecords(files, dst_dir, tfr_size, file_name_prefix, print_period, pairs):
    tfr_counter = 0
    data_list = []
    file_paths_list = []

    for index, file_path in enumerate(files):
        # read mat file into ndarray
        print(file_path)
        if not pairs:
            data = sio.loadmat(file_path, verify_compressed_data_integrity=False)['data']
        else:
            data = np.stack([ sio.loadmat(file_path[0], verify_compressed_data_integrity=False)['data'], sio.loadmat(file_path[1], verify_compressed_data_integrity=False)['data'] ]).flatten()
        # append to images list
        data_list.append(data)
        # append path to paths list
        file_paths_list.append(file_path)

        if (index % print_period == 0) and index > 0:
            print('gathered {0} images to turn to tfrecord'.format(index))

        if index % tfr_size == 0 and index > 0:
            tfr_path = os.path.join(dst_dir, '{0}_{1}.tfrecord'.format(file_name_prefix, tfr_counter))
            create_tfr(data_list, file_paths_list, tfr_path)
            # increase the tfr counter
            tfr_counter += 1
            # restart the images list
            data_list = []

    # if the list has remaining images (less than tfr_size)
    # save it into another tfr
    if len(data_list) != 0:
        tfr_path = os.path.join(dst_dir, '{0}_{1}.tfrecord'.format(file_name_prefix, tfr_counter))
        create_tfr(data_list, file_paths_list, tfr_path)


def create_tfr(data_list, file_paths_list, tfr_path):
    writer = tf.python_io.TFRecordWriter(tfr_path)

    for image_np, path in zip(data_list, file_paths_list):
        # conver the image to string
        image_string = image_np.tostring()
        # make the example from the image and it's path
        example = tf.train.Example(
            features=tf.train.Features(feature={
                'image_string': _bytes_feature(image_string),
			    }
            ))
        # write the example to the tfr
        writer.write(example.SerializeToString())

    # close the tfr
    writer.close()


def _bytes_feature(value):
    return tf.train.Feature(bytes_list=tf.train.BytesList(value=[value]))

def _int64_feature(value):
    return tf.train.Feature(int64_list=tf.train.Int64List(value=[value]))

def _float_feature(value):
    return tf.train.Feature(float_list=tf.train.FloatList(value=[value]))


if __name__ == '__main__':

    main()


