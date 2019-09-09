from trainers.base_trainer import BaseTrainer
from tqdm import tqdm
import numpy as np
import os
import scipy.io as sio
import random
import tensorflow as tf


class GANTrainer(BaseTrainer):
    def __init__(self, sess, model, data, config, logger):
        super(GANTrainer, self).__init__(sess, model, data, config, logger)

    def train_epoch(self):
        loop = tqdm(range(self.config.num_iter_per_epoch))

        # filenames of tfRecords
        src_dir = os.path.join(self.config.database_dir, "single", "train")
        src_pair_dir = os.path.join(self.config.database_dir, "pair", "train")
        training_filenames = [os.path.join(src_dir, tfr_file) for tfr_file in os.listdir(src_dir)]
        training_filenames_pair = [os.path.join(src_pair_dir, tfr_file) for tfr_file in os.listdir(src_pair_dir)]
        random.shuffle(training_filenames)
        random.shuffle(training_filenames_pair)
        self.sess.run(self.data.iterator.initializer, feed_dict={self.data.filenames: training_filenames})
        self.sess.run(self.data.iterator_pair.initializer, feed_dict={self.data.filenames_pair: training_filenames_pair})

        for _ in loop:
            fake_charts_np, disc_cost_np, gen_cost_np, rank_cost_np, rank_fake_cost_np = self.train_step()

        print('epoch ' + str(self.sess.run(self.model.cur_epoch_tensor)) + " - disc cost:" + str(disc_cost_np) + ", gen cost:" + str(gen_cost_np) + ", rank cost:" + str(rank_cost_np) + ", rank fake cost:" + str(rank_fake_cost_np))

        if self.sess.run(self.model.cur_epoch_tensor) % self.config.save_period == 0:
            noise = tf.random_normal([1, self.config.latent_vec_dim])
            noise = tf.tile(noise,[tf.shape(self.model.real_charts)[0],1])
            noise = self.sess.run(noise)
            rank = self.sess.run(self.model.rank)
            c = self.sess.run(self.model.generator(tf.convert_to_tensor(noise), tf.convert_to_tensor(rank)))
            _,d = self.sess.run(self.model.discriminator(tf.convert_to_tensor(c)))
            
            save_dir = os.path.join(self.config.results_dir,str(self.sess.run(self.model.cur_epoch_tensor))+'_epoch')
            sio.savemat(save_dir , {'c': c, 'd': d, 'rank': rank})

        if self.sess.run(self.model.cur_epoch_tensor) % self.config.checkpoint_period == 0:
            self.model.save(self.sess)

    def train_step(self):

        for i in range(self.config.critic_iters):
            _, _disc_cost, _real_charts, _rank_cost = self.sess.run([self.model.disc_train_op, self.model.disc_cost, self.model.real_charts, self.model.rank_cost])

        _, _gen_cost, _fake_charts, _rank_fake_cost = self.sess.run([self.model.gen_train_op, self.model.gen_cost, self.model.fake_charts, self.model.rank_fake_cost])

        cur_it = self.model.global_step_tensor.eval(self.sess)
        summaries_dict = {
            'disc_cost': _disc_cost,
            'gen_cost': _gen_cost,
            'rank_cost': _rank_cost,
            'rank_fake_cost': _rank_fake_cost
              }

        if cur_it % 10 == 0:
            self.logger.summarize(cur_it, summaries_dict=summaries_dict)
        return _fake_charts, _disc_cost, _gen_cost, _rank_cost, _rank_fake_cost

