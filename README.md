# Layered Object Detection for Multi-Class Segmentation

## Introduction

This is a Matlab implementation of the layered object segmentation algorithm described in [1, 2]. The algorithm utilizes the object detection results obtained from deformable part-based models [3] with superpixels obtained from [4], and builds a Bayesian inference framework towards the semantic and instance segmentation of multi-class objects. The code is trained and tested using the PASCAL VOC dataset [5]. 

Acknowledgements: We graciously thank the authors of the previous code releases and image benchmarks for making them publically available.

## Using the code

The Matlab code is actually not runnable anymore. The repo is only used for a proof of concept. 

The codes are mainly located in `initialization`, `bias field` and `segmentation`, where `bias field` contains the bias field learning code and `segmentation` contains the layered segmentation inference code.

## References

[1] Y. Yang, S. Hallman, D. Ramanan, C. Fowlkes. [Layered Object Detection for Multi-Class Segmentation](https://yangyi02.github.io/research/layers/index.html). CVPR 2010.

[2] Y. Yang, S. Hallman, D. Ramanan, C. Fowlkes. [Layered Object Models for Image Segmentation](https://yangyi02.github.io/research/layers/index.html). PAMI 2012.

[3] P. Felzenszwalb, R. Girshick, D. McAllester, D. Ramanan. [Discriminatively Trained Deformable Part Models](http://www.rossgirshick.info/latent/). PAMI 2010.

[4] P. Arbelaez, M. Maire, C. Fowlkes, J. Malik. [Contour Detection and Hierarchical Image Segmentation](https://www2.eecs.berkeley.edu/Research/Projects/CS/vision/grouping/resources.html). PAMI 2011.

[5] M. Everingham, L. Van Gool, J. Winn, A. Zisserman. [The PASCAL Visual Object Classes (VOC) Challenge](http://host.robots.ox.ac.uk/pascal/VOC/). IJCV 2010.

