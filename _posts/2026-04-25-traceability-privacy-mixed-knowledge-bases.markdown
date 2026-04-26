---
layout: post
title: Traceability and privacy in mixed knowledge bases
date: 2026-04-25 14:00:00 -0400
categories: security notes documentation agents
---

If you work with code, wikis, and operational runbooks at the same time—especially with agents in the loop—you are not maintaining a single kind of document. You are maintaining a **mixed** knowledge base. Some pages are public or shareable, some are private, some are quick captures of “how the system looks today,” and some are early drafts that were never revisited. **Trust** and **safety** in that world do not come from a perfect taxonomy on day one. They come from a few steady habits you can follow without turning writing into a ceremony.

## Traceability, or how a reader knows what to believe

A strong claim—about architecture, about an outage, about a policy—ought to sit next to a **source** a reader can open. That source might be a file path in your `sources/` tree, a link to a ticket, a public URL, a commit hash, or a dated private note in a place that is allowed to exist. The question you are answering is not “is this true forever?” The question is “*why* did we think this, on what day, and from what ground?”

When you **cannot** verify a statement quickly in a maintenance pass, the calm move is to mark the page as **stale**, or to add a short “Open questions” section that says what is uncertain. Two pages that both read as the **current** truth but disagree quietly are more dangerous than one page that admits a gap. An honest *unknown* gives the next reader permission to re-check; two silent “current” statements create accidents.

## Privacy, and what must not become invisible background

If a page might combine **broad, shareable** explanation with **specific** hostnames, internal URLs, family context, or credentials—even in mild form—say so at the top in a few sentences. A **Privacy note** does not have to be legal language. It is enough to state the kinds of information the page may contain, who it is meant for, and whether it is safe to copy into a public issue or a client-facing document.

Pay attention to **context laundering**, which is a slow form of over-sharing, not a dramatic leak. A small operational fact slips into a “general” page because you were in a hurry one evening. A month later, that page is the one everyone links. The fact has become ambient truth in the wrong place. The defense is a light habit: when you add detail that is not in scope for the page’s original audience, **move** it to a restricted note or add scope right then, not “later when we clean up.”

## Operator hygiene, or how maintenance stays small

Large annual reviews rarely happen on schedule, and they are painful when they do. A more sustainable rhythm is a **rotating** scope: one project page, one pattern, or one source map in a short session, on whatever cadence you can keep—weekly, biweekly, or monthly. The pass is the same in spirit: read for accuracy, add links, soften claims you cannot support, and align contradictions. Small passes that finish **compound**; sweeping passes that stall do not.

Keep a **single** maintenance log, changelog, or append-only file where you record what you touched, what you changed, and what you postponed. The log entry does not need to be long. It should be enough that someone (including you) can tell *when* a page was last *intentionally* read, and what you decided to leave for another day. The goal is not perfect documentation. The goal is **reversible, inspectable, and honest** state, so the next person—human or agent—does not have to reconstruct reality from a chat transcript or a hope that a timestamp was right.

## What you get in return

When traceability and scope are in good shape, a mixed knowledge base stops feeling like a junk drawer. It feels like a **workshop**: tools are where you expect, sharp edges are labeled, and the next action is clear enough that you are not always starting from zero. That outcome is not flashy, but it is the kind of calm infrastructure that makes hard work a little more predictable over months and years.
