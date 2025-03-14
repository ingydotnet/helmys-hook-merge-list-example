helmys-hook-merge-list-example
==============================

Use HelmYS Hooks for Special Merging



## Synopsis

```
$ make test
HELMYS_HOOKS=list-merge-hook.ys \
VALUES_FILE=merge-env.yaml \
helm template cronjob --post-renderer=helmys
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: release-name-cronjob
  labels:
    app: cronjob
    chart: cronjob-0.1.0
    release: release-name
    heritage: Helm
spec:
  schedule: 0 11 * * *
  startingDeadlineSeconds: null
  jobTemplate:
    spec:
      template:
        metadata:
          name: release-name-cronjob
        spec:
          restartPolicy: Never
          imagePullSecrets:
          - name: quay-sts
          containers:
          - name: release-name-cronjob
            imagePullPolicy: Always
            image: 'nginx:'
            args:
            - npm
            - start
            - foo_job
            env:
            - name: FOO
              value: bar
            - name: BAR
              value: foo
```


## Description

This repo shows a solution for https://github.com/helm/helm/issues/3486 done in
a way that is completely customizable.

It was made to show an alternative to https://github.com/helm/helm/pull/30632.


## The Problem

The argument `--values=merge-values.yaml` option for `helm install` merges a
data structure into a matching structure position in a `values.yaml` data
structure.

In 3486 some people wanted it to "merge" sequences of mappings, resulting in
a sequence of mappings where the key `name` was used to determine how a mapping
was added to the result sequence.

This is a very special and specific kind of merge, and just one of countless
ways to merge a data structure.

30632 wants to change Helm's YAML load/rendering to look for certain keys that
trigger this very specific merge algorithm.


## This Solution

This repo uses a custom Helm post-renderer to achieve this specific desired
effect.

The post-renderer strategy uses [HelmYS's](
https://github.com/kubeys/helmys?tab=readme-ov-file#helmys) `HELMYS_HOOKS`
environment variable to provide the code for this custom merge.

That code in turn uses a `VALUES_FILE` variable to indicate the location of the
YAML file to be merged in.


## Repo Layout

* `ReadMe.md` — This file
* `Makefile` — For `make test` to show the solution
* `cronjob/` — A chart using data from issue 3486
* `merge-env.yaml` — The override YAML values file
* `list-merge.ys` — The [YS](https://yamlscript.org) code implementing the
  custom merge algorithm
* `list-merge-hook.ys` — The code that applies the custom merge in the desired
  location(s)

These files are for testing the merge without involving Helm:

* `list-merge-test.ys` - Testing runner
* `values/*.yaml` - Data files to merge

For example:

```
$ ys list-merge-test.ys values/*
- name: MYVAR1
  value: override_this_value
- name: MYVAR2
  value: value2
- name: MYVAR3
  value: add_this
```
