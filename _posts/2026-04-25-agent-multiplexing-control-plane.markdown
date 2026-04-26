---
layout: post
title: Agent multiplexing—one control plane, many workers
date: 2026-04-25 12:45:00 -0400
categories: agents terminal tmux workflow
---

Sometimes the work in front of you is not one long thought in a single chat. It is a set of **independent** tasks, each of which is large enough that you would happily give it its own **CLI agent** or automation session, but small enough that you do not need a new project for each. In that situation, *multiplexing* is a way to run many workers under **one** mental model: a control plane for starting sessions, reading status, and recovering when a worker dies, instead of you personally babysitting a grid of ad hoc terminals. The point is not to make one “bigger” brain in one window; the point is to make **parallel work** and **observability** first-class so you are not the bottleneck for every attach and detach.

## What the pattern looks like, piece by piece

**Durable process containers** are the bedrock. In many setups that means **tmux** sessions, windows, or panes, because they survive SSH drops, let you step away, and let you reattach with context intact. A worker is not a fragile foreground shell you must keep open; it is a named place where a process is expected to live for a while.

**Isolation** means one worker, one home in that substrate. If two agents share one directory and one git state without rules, you will get accidental interference. A common step up is a **separate worktree** or workspace per task so that branches, uncommitted work, and build artifacts do not tangle. You are not trying to be fancy; you are trying to make “who owns this tree” obvious.

**Coordination** is how you avoid plan drift when multiple sessions run at once. A **task board** or a shared message channel—lightweight, even a text file with locks—is where “claimed,” “in progress,” and “blocked” should live, so it does not exist only in one transcript. The human operator, and any orchestrator, should be able to answer “what is running?” without opening every session.

**Observability** is the ability to see health without N separate attach sequences. A simple **dashboard** or a tail on structured logs, even if it is minimal, is enough to know which workers are still alive, which are stuck, and which finished with a non-zero exit. The goal is to reduce surprise when you return after an hour.

**Recovery** is the honest admission that processes crash, networks flap, and agents loop. A **watchdog** or a periodic health check can restart a worker, but the dangerous version is a blind restart that replays a destructive or stale action. Good recovery is tied to **task state** you trust: a checkpoint, a branch name, a commit hash, an explicit “do not re-run if already done” flag. The operator should be able to read why a worker restarted, not just that it did.

## When the extra structure earns its keep

If you are making a small, safe edit in a repo you know well, you do not need a multiplexing stack. The overhead pays for itself when **parallelism** really reduces wall-clock time, when **resumability** matters because sessions are long, and when you need **visibility** because more than one person or system is touching the work. In those cases, a little ceremony up front is cheaper than hours lost to “which terminal was that?” and half-merged state.

## Risks to plan for, in calm terms

**Drift** is when the task board says *done* but the git worktree is dirty, or the branch never merged, or the fix only lived in a local patch. The remedy is a tight definition of *done* that points at the tree: pushed branch, clean status, or an explicit “blocked on X” with a name.

**Log leakage** is a quiet problem. Shared boards, shared log files, and shared HTTP endpoints for status can end up with **local paths, prompt text, or secrets** if the tools are chatty. Treat those surfaces the way you would treat app logs: scope them, redact by default, and do not let long-lived storage fill with content nobody owns.

**Dumb retries** are automatic restarts that run the same bad command again because the *task* record never advanced. The remedy is to connect recovery to **sanitized, explicit** state, not to hope the second attempt is luckier. If a step is destructive, the task record should make that step **idempotent** or **gated** by a human.

You do not need a particular brand of tool to apply the pattern. You need a **task contract** that everyone—the operator, the agents, and the future reader of the logs—can follow without improvising. Once that exists, the control plane is simply the place where those contracts are visible.

---

*The names in your own stack (tmux, custom TUIs, APIs) will differ; the structure above is the part that carries between setups.*
