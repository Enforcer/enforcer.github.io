--- 
layout: post
title: Shortening developer's feedback loop
description:
date: 2023-01-26 20:22:34 +0100
published: true 
categories: []
tags: []
lang: 
---

## What’s a shared secret sauce for agile methodologies and developer's productivity?

If I was asked about one thing you have to optimise to make both agile methodologies and developer productivity work I’d say it’s shortening the feedback loop.

It works great not only on the level of the product. Modern product development techniques promote gathering feedback from users early & often. They literally scream “Don’t hoard these features! Let’s show them to the world! (and see if we’re right they actually help)”.

## [early] feedback for software developer

It works in a similar way for a software developer, but we need feedback on our workstation already. And we want to have it early & as often as possible. Many tools come in handy: linters, type checkers, formatters, tests or automatic application reloading. Skilful use of various tools can make a huge difference in terms of productivity and making sure we haven’t broken anything.

That’s why I’m always excited when I see new tools like [ruff](https://github.com/charliermarsh/ruff) emerge. This is Python linter & code transformation tool written in Rust. As you imagine, it’s much faster than any of the existing solutions - 10x-100x faster to be precise (wow!). I encourage you to check it out.

Along with [pydantic-core](https://github.com/pydantic/pydantic-core) (and many more), [ruff](https://github.com/charliermarsh/ruff) follows the trend of very performant libraries with their core written in e.g. C or Rust, then wrapped with a friendly Python API.

PS: Still not sure if Github Copilot/Tabnine/other similar will boost the actual productivity or hamper it by introducing subtle bugs it. I’m testing it thoroughly.

## Other links

- [reloadium](https://reloadium.io/) - advanced hot code reloading

- [renovate bot](https://docs.renovatebot.com/) - general tool for automated upgrades of dependencies

- [pytest-testmon](https://testmon.org/) - selects tests to run based on changed code

- [pytest-sugar](https://pypi.org/project/pytest-sugar/) - shows failures in tests immediately during the execution of test-suite and shows a nice progress bar

- [awesome-pytest](https://github.com/augustogoulart/awesome-pytest) - Github repository with links to other pytest plugins & resources

