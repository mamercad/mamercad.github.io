---
layout: post
title: A weekly "lint" for your second brain
date: 2026-04-25 09:00:00 -0400
categories: notes second-brain knowledge-management
---

A personal or team wiki does not stay healthy by accident. If you only add pages and never revisit them, you get the same failure mode as a repository full of unreviewed first drafts: the pile grows, trust erodes, and nobody knows which line is still true. A useful way to think about maintenance is the loop people sometimes call a “Karpathy-style” wiki: you ingest raw material, you synthesize it into pages you can navigate, you lint those pages on a schedule, and you log what you did. None of the steps are exotic; the point is to do them in a small, repeated rhythm instead of a heroic annual cleanup.

## How the loop works, in order

**Ingestion** is where you park raw or semi-raw input. A dedicated `sources/` tree (or whatever naming you prefer) is enough. When you add something, name its scope: was it copied from a public document, a ticket, a private note, a conversation, or a command transcript? If you can add a date, add it. You are not trying to be formal; you are trying to make future you honest about *where* a claim entered the system.

**Synthesis** is where you turn that material into pages that are meant to be read: project notes, patterns, runbooks, decisions. A synthesis page is allowed to be short, but it should not present a strong or operational claim as if it were obvious unless that claim is tied to something a reader can follow: a path under `sources/`, a public URL, or a private note you label explicitly. The habit you are building is traceability, not perfect prose.

**Linting** is a scheduled pass. Weekly is a reasonable default; the duration can be as little as fifteen minutes if you keep the scope small. A lint is not a rewrite. Treat it the way you would a code review: you read, you add status labels, you fix or soften broken links, you flag contradictions, and you check that public-facing pages are not quietly accumulating private detail. You are not trying to finish the vault in one sitting.

**Logging** is the final step, and it matters more than it sounds. In a line or a short paragraph, record what you opened, what you changed, and what you explicitly postponed. If you deferred something, add a single line explaining why—no shame, no essay. The log is your audit trail; it is how the system stays accountable to itself.

## What “lint” means in practice

When a page *sounds* authoritative, a reader should be able to see *why* you believe it. If the page cannot point to a source, either soften the language, mark the claim as uncertain, or add the missing reference.

For privacy, a page that is meant to be broadly shareable should not slowly absorb home-lab hostnames, internal URLs, or one-off tokens just because it was faster to paste them there. If the page is mixed, say so in a short note at the top: what kind of information it may contain, and for whom it is written.

For contradictions, do not let two “current” pages give different default truths about the same system. You can update the one that is wrong, you can narrow each page so the scopes no longer overlap, or you can write an “Open questions” block that names the conflict and points to both pages. Ambiguity in the open is better than a silent war between documents.

For decay, anything that described “how things are *right now*” a year ago should either be dated, marked stale, or updated. Time-sensitive “current state” is the kind of content that causes the most damage when it is never revisited, because it still reads with full confidence.

## A calm default: one small scope

When you are short on time, pick exactly one of the following: a project page you will actually use this week, a pattern you rely on when making decisions, or a source map you suspect is going stale. At the top of the page, set a status line if you do not have one: `Status: first-pass` for a shallow or unverified first draft, `Status: current` for something you still endorse after this pass, and `Status: stale` for anything you would not act on without re-checking. Add one entry to your maintenance log. A narrow pass you finish beats a wide pass you never start.

## Why a schedule exists

The failure mode to avoid is *ingestion without digestion*: a vault that only grows, where first-pass pages sit silently in search results as if they were reviewed truth. A weekly or biweekly lint is the opposite of a dramatic overhaul. It is a small, boring habit that keeps the system compounding, the same way short, regular review keeps a code base from rotting in silence.
