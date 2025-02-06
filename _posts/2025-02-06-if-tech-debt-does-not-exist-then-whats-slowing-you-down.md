---
title: If tech debt doesn't exist, then what's slowing you down?
date: 2025-02-06 21:30:00
categories: [software engineering]
---

## There is no spoon

Some smartasses on the internet claim there is no such a thing as tech debt. Controversial headlines sell well. In this world companies fiercely compete for our attention, so you rarely read an interesting article these days without clickbaits. I know because I use them myself!

Let's forget for now about definitions and admit one thing - crappy code and crappy work environment DO exist.

First, what tech debt is not...

## Cutting scope

Coming up with a simpler implementation thanks to reducing scope of the project is not a tech debt.

Payment is accepted in one way only. You handle .csv files only. Other types will be supported one day... or never. You deliberately assume &Pi; equals 5 to simplify your calculations, aware of consequences. You gave up on supporting Firefox, because Chrome holds majority of the web browser market.

BTW, if you don't support Firefox then you're a terrible person and I hate you.

Out of all other things, cutting scope is harmless. In the worst case, after some time a solution would be insufficient. For example, results will be off too much with an assumption that &pi; equals 5.

But that's often fine - after all, something is delivered fast and risk of getting it completely wrong is minimized. Very agile, isn't it?

## Learning process

Don't tell anyone, but programmers learn how to code mostly on the job. Especially early in their careers. Learning process for juniors is very, very fast. Code we wrote one day *sucks* in our eyes just months later. Not to mention you don't want to admit to your creation two years later.

One learns simpler, more efficient, more reliable ways to achieve the same result. But it all happens in their heads and code they wrote before somehow doesn't follow by itself.

Such a thing is an impediment for the author because their brain is literally wired in a different way than it was when the code was originally written.

Without mentoring in the team and other forms of support, things start to pile up. Then, if no time for refactoring is given or made, one will have to live with it.

## Habitual skill gaps

There is a pathological fork in the road one may take during their professional journey, that is never learn some skills and constantly work around it.

You face circular imports in Python, then move imports to the body of a function, because *Python is stupid and there's no other way*? You're **not** incurring a tech debt - you're producing a poor design. Dependencies should be unidirectional.

You habitaully skip writing tests because that way you ship faster? You never learned how to write testable code or lean testing strategies. You're not being smart - it's cutting corners.

Truth is that once you learn it, you never have to even consider such trade offs again. Nicely organized code with unidirectional dependencies writes almost itself. You don't even remotely consider not writing tests because you internalized them so much that it becomes part of your workflow. You start feeling lost when having to modify a code base that is not tested.

Again, it's not a tech debt. This is a pure neglect that should be weeded out.

## Management-induced pressure

Sometimes it's not the programmers that are willing to skip writing tests. It's the management that encourages them to do so.

> This task has estimate of 5 SP, how many it will be if you skip tests?

🤦

They want to have more delivered for less. And I can respect this. But the approach taken is *extremely* short-sighted.

Firstly, testing only takes significantly more time if you need to learn how to do it while working on the task. Once it is internalized and becomes part of your workflow, then it seems absurd to skip it.

More sinister is a situation when management understands that developers are learning on the job and prevents them to advance this way. They may have their own reasons - sure, but long-term, it's catastrophic. Let's just say such companies are not a good place to stay in for longer.

On the other hand, management can indeed improve velocity if they mean to improve developer experience, reduce cognitive load and make sure there is a right mix of skills in the team.

## Road to [technical] excellence is a bumpy one

> Software development is a learning process; working code is a side-effect.
>
> Alberto Brandolini

We hate to admit it but software development is a state of constant deficit. We lack time, technical skills and domain knowledge. And yet we deliver SOMETHING with what we have at the moment. 

It is not possible to know everything beforehand. If just more planning or thinking would help, then we'd all be working in waterfall.

However, this SOMETHING we built is based on more or less naive assumptions. And surprise-surprise, occassionaly we miss the point terribly.

Unless there was some gross negligence, we still got the best possible result we could in our position.

By refactoring code, modernizing architecture or reorganizing teams we're not just moving code/services/people around. We're knowledge-shifters. We rearrange knowledge carriers around so they better support a flow we want.

I don't think it's fair to call a state before a "rearrangement" a tech debt, either.

It is rather a trail of knowledge evolution.

The only hard part is admit that we could be wrong, although we could not know that in that moment. And only then, free of prejudice, we can act and reorganize the knowledge.
