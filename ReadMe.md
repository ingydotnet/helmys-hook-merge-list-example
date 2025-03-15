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

The argument `--values=merge-values.yaml` option for `helm install` (or `helm
template` or `helm upgrade`) merges the data structure from the
`merge-values.yaml` file with the data structure from the chart's `values.yaml`
file.

In [3486](https://github.com/helm/helm/issues/3486) some people wanted it to
"merge" sequences of mappings, resulting in a sequence of mappings where the
key `name` was used to determine how a mapping was added to the result
sequence.

This is a very special and specific kind of merge, and just one of countless
possible ways to merge/transform a data structure.

[30632](https://github.com/helm/helm/pull/30632) wants to change Helm's
internal YAML load/rendering algorithm to look for certain keys that trigger
this very specific merge algorithm.


## This Solution

This repo example uses a custom Helm post-renderer to achieve the specific
desired effect.

The post-renderer strategy shown here uses [HelmYS](
https://github.com/kubeys/helmys?tab=readme-ov-file#helmys) as the
post-renderer and its `HELMYS_HOOKS` environment variable to provide the code
for this custom merge.

That code in turn uses a `VALUES_FILE` variable to indicate the location of the
YAML file to be merged in.

The `list-merge` function looks like:

```yaml
defn list-merge(key list1 list2): !:vals
  reduce _ omap() list1.concat(list2):
    fn(o elem): o.assoc(elem.$key elem)
```


## Conclusion

Using a post-renderer is a good way to get desired special behaviors from Helm.

It doesn't require any core changes to Helm or to the way it interprets YAML.

HelmYS is a powerful way to write custom post-renderers, but certainly not the
only way.


## Repo Layout

* [`ReadMe.md`](ReadMe.md)
  — This file
* [`Makefile`](Makefile)
  — For `make test` to show the solution
* [`cronjob/`](cronjob/)
  — A chart using data from issue [3486](https://github.com/helm/helm/issues/3486)
* [`merge-env.yaml`](merge-env.yaml)
  — The override YAML values file
* [`list-merge.ys`](list-merge.ys)
  — The [YS](https://yamlscript.org) code implementing the custom merge
  algorithm
* [`list-merge-hook.ys`](list-merge-hook.ys)
  — The code that applies the custom merge in the desired location(s)
* [`my-post-renderer`](my-post-renderer)
  — Example of creating your own post-renderer file with HelmYS

These files are for testing the `list-merge` function without involving Helm:

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


## Hosting Hooks Online

The example above requires a hook file, a merge library file and the values
override file.

These files can be hosted on the web if you want to share or reuse them in
various contexts.

Here's an example of using a hook file from a GitHub URL instead of a local
file:

```
$ HELMYS_HOOKS=https://raw.githubusercontent.com/ingydotnet/helmys-hook-merge-list-example/refs/heads/main/list-merge-hook.ys \
VALUES_FILE=merge-env.yaml \
helmys template cronjob
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


## Making Your Own post-renderer File

You can make your own post-renderer file with the above info:

Create `my-post-renderer`:

```bash
#!/usr/bin/env bash

export HELMYS_HOOKS=https://raw.githubusercontent.com/ingydotnet/helmys-hook-merge-list-example/refs/heads/main/list-merge-hook.ys

helmys
```

Make it executable and then run:

```
$ VALUES_FILE=merge-env.yaml helm template cronjob --post-renderer=./my-post-renderer
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
