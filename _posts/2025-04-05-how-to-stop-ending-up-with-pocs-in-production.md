---
title: How to stop ending up with PoCs in production?
date: 2025-04-05 19:11
categories: [software engineering, architecture]
---

## Half-baked stuff causes indigestion

How does a life with Proof of Concept in production look like? 

Constant hiccups. Little problems constantly popping up. No tests or other way of verification but manual checks. Builds breaking all the time because there was never time to do it *right*. Deploy involving many manual steps.

The list can go on.

## Whose fault is that?!

![Ben Kenobi saying it's him](/assets/2025/ben_kenobi.jpg){: width="700" height="400" }

Perhaps you've experienced something similar. Maybe even it was you who pushed PoC to production. You certainly didn't mean for it to end up like this because it's obvious from the start that this will end up being a huge pain in the neck.

Maybe you wanted to ship something fast and improve it later. But *later* never came.

Maybe you listened to gentle management asks and give up on team's/company's standards to speed up things?

> Come one, just this once! It's really important to get this thing out of the doors fast

So you did as you were asked, but were not happy about it.

Regardless of the reason, maintenance-heavy monster is a problem and it will cost extra time *to make things right*. Time no one has.

## An incident or *that's how we do things here*?

If you have many projects that are not production-ready but sit in production and this is reoccuring thing, then something's definitely wrong with the process.

It is a vicious circle that makes developer experience awful. It also keeps productivity and satisfaction levels low.

## What's a PoC, actually?

A proof of concept, in my book - figuratively speaking - is a work artifact that proves that some implementation is feasible. And it does it by being a bare minimum.

It can be a throwaway script or manual changes made in configuration that will be overriden with the next deployment.

It is not meant to be deployed in production as part of the actual application. It is only to prove that a certain approach to implementation is reasonable.

To me, word "prototype" is a synonym. And a protype can be built in staging/test environment or on a local computer, even with another programming language.

## Meet Walking Skeleton

Once one knows that a given approach is *the way* (with or without a preceding Proof of Concept), they should rather start building a [Walking Skeleton](https://wiki.c2.com/?WalkingSkeleton) instead of PoC in production.

This is a minimal implementation with all key components in place. I'd add that all of them should meet production-readiness criteria we have at the company. For example, build and deployment should be automated. Some leaven for tests, monitoring, log collection etc.

Since one knows that a given piece of software is going to stay there, there is literally no point in cutting corners.

Benefits are delusionary, whatever time one saved by not automating deployment, they'll pay double or triple deploying manually.

Of course things are different if there actually are no production-readiness criteria in the company or no automation anywhere. Then a problem is much bigger, i.e. a poor engineering culture.

## A middle ground - an experiment

As much as previous paragraphs might appear blunt, I acknowledge that world is not always black and white (painting world as such is actually a manipulation technique - beware ☠️).

What if we want to put something in production but we're not sure if it will stick?

I call it "an experiment". There are two things required so that abandoned experiments do not bog down teams in the longer term.

Firstly, an experiment should have an end date. We don't know if someone will be interested in a given feature? Let's add it, formulating success criteria beforehand (e.g. how many users utilize it). When an end date comes, we decide whether to keep it and treat as first-class citizen or remove it. Naturally, we can extend the experiment.

Secondly, we need to have an architecture that will support experimentation. Automation and metrics are bare minimum. In other words, we need to ensure that running experiments is cheap and build whatever is needed to support experiments coming and going.

As you can see, none of them is code-related. Having multiple forgotten experiments in production is not a code or architecture problem and solution does not lie in code or architecture either.

This is a process and prioritization problem.

Long running experiments and a big number of them are two typical red flags.

## Conclusion

As a professional, you shouldn't allow for a situation when you have lots of half-baked code in production (unless you work in startup).

This is detrimental to productivity and wellbeing.

For proof of concepts, do as little as possible just to verify if a thing would take off.

If you need to deploy it to production, it's no longer a proof of concept. If you expect it to stick and it needs something built from scratch, go ahead with Walking Skeleton.

If something is experiment (meaning no one knows if it will be kept), then make sure there are success criteria and an end date. Keep an eye for a large number of running experiments and long-lasting ones.
