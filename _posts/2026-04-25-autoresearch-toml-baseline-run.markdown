---
layout: post
title: "Autoresearch" in software—TOML specs and honest metrics
date: 2026-04-25 11:30:00 -0400
categories: python experiments automation ci
---

People hear “experiment” and picture GPUs and training jobs, but a lot of software work has the same shape: you have a *candidate change*, a *way to measure it*, and a *repeated procedure* to keep comparisons fair. A **local-first** experiment runner is one way to make that contract explicit. You write a spec (often a small **TOML** file) that says what to run, what paths the run may change, and how success is read from a metrics file. You run a **baseline** or a batch of **repeats**, store the noisy details under a directory you **do not commit**, and only promote a winning change through a normal **pull request** and human review. The runner does not replace judgment; it makes “what we compared” and “how we knew” less ambiguous.

## What you are setting up, step by step

**First, describe the experiment in the spec file.** The spec should name the command that performs evaluation—often a script or a small program—and the list of **mutable** paths the experiment is allowed to touch, alongside **protected** paths that must not change. If a run reaches outside its allowed set, the harness should **fail early** with a clear message, not halfway through a silent edit.

**Second, run the eval with a run id and capture structured metrics.** The evaluation command is responsible for writing JSON (or a format your tool understands) to a path the runner provides, for example through an environment variable such as `AUTORESEARCH_METRICS_FILE`. The spec names which metric field matters, and whether *higher* or *lower* is better. That is how “better” becomes a file on disk, not a feeling in the console.

**Third, keep detailed run output local.** A typical choice is a directory like `.autoresearch/runs/<run-id>/` containing per-attempt data, optional stdout summaries, and anything else you need to debug. Treat this tree like developer scratch space: it may contain local paths, prompts, or half-formed ideas, so **default policy is to keep it out of version control** unless you have a defined export and redaction path.

**Fourth, use CI to validate the *harness*, not to auto-merge winners.** A good CI job checks that specs validate, that tests pass, and that a known example can run from a **clean** checkout. It does *not* need to open pull requests for you. Candidate improvements still flow through branches and review like any other change.

## Reading an experiment block in plain language

In an `[experiment]` section, `eval_command` is the list of program and arguments that must run to completion. The `metric` and `direction` fields tell the runner which number in the metrics JSON matters and which direction is “improvement.” The `mutable_paths` and `protected_paths` fields define the contract between “this experiment is allowed to edit the repo in these places” and “these areas are off limits.”

`timeout_seconds` and `repeats` exist so that a hung process or a flaky environment shows up in the **summary** the same way a bad score does, instead of leaving you to infer failure from a silent shell. The point is to make the failure modes **boring to compare** across machines, not to look dramatic in the terminal.

## Why the runner should be strict about bad outcomes

A useful harness treats a **crash**, a **timeout**, **malformed metrics JSON**, and a **missing metrics file** as *named states*, not as a single generic “it failed.” When those states are first-class, you can sort runs the way you would sort test results: you know whether you are looking at a logic bug, a network flake, a permissions mistake, or a true regression in the metric. Soft failures that collapse into one exit code are hard to learn from; explicit states are the difference between a one-off and a pattern.

## Privacy and the local runs directory

Assume run logs and scratch directories can contain **prompts, absolute paths, environment names, and ideas** you are not ready to share. The calm default is: keep `.autoresearch/` (or your equivalent) in **`.gitignore`**, and if you need to show a result to someone else, copy out a *reduced* summary you are willing to stand behind. The workflow is the same as any other local diagnostic output: the machine is allowed to be messy; the repository should stay legible to strangers.

---

*The commands and field names in your own project may differ; keep the same separation between spec, metrics, and raw logs.*
